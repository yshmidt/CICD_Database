-- =============================================
-- Author:		<Debbie>
-- Create date: <10/09/2014>
-- Description:	Used on AR_REP3.   "AR Collection Status Summary"
-- Modified:	01/06/2015 DRP:  Added @customerStatus Filter
--				03/17/2016 VL:	 Added FC code
--				04/08/2016 VL:	 Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				01/11/2017 VL:	 added one more parameter for fn_CalculateFCRateVariance() which is the rate ratio calculated based on functional currency or presentation currency
--				01/13/2017 VL:	 added functional currency fields
-- =============================================
CREATE PROCEDURE [dbo].[rptArAgeCollectionSummary]

--declare	
@lcCustNo varchar(max) = 'All'
,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
,@userId uniqueidentifier = null

as
Begin

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END


/*SELECT STATEMENT*/

-- 03/17/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN
	;WITH ZAR AS 
	(SELECT	CUSTNO,sum(ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS) as BalAmt,sum(CASE WHEN ACCTSREC.DUE_DATE < GETDATE() THEN ACCTSREC.INVTOTAL - ACCTSREC.ARCREDITS ELSE 0.00 END) AS PastDue
	from	ACCTSREC
	where	1 = case when ACCTSREC.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
	GROUP BY CUSTNO
	)

	SELECT	CUSTOMER.CUSTNAME,ZAR.BalAmt,ZAR.PastDue,customer.AR_CALDATE,customer.AR_CALTIME,customer.AR_CALBY,isnull(customer.AR_CALNOTE,'')as CALNOTE
	FROM	ZAR
			INNER JOIN CUSTOMER ON ZAR.CUSTNO = CUSTOMER.CUSTNO
	WHERE	ZAR.BalAmt <> 0.00
	END
ELSE
-- FC installed
	BEGIN
	-- need to convert to latest rate for home currency (functional currency)
	;WITH ZAR1 AS 
	(SELECT Custno, CAST(InvTotal*dbo.fn_CalculateFCRateVariance(Fchist_key,'F') as numeric(20,2)) AS InvTotal
		,CAST(ARCREDITS*dbo.fn_CalculateFCRateVariance(Fchist_key,'F') as numeric(20,2)) AS ARCREDITS
		,InvTotalFC, ArcreditsFC, Due_date, Fcused_uniq
		-- 01/13/17 VL added functional currency fields
		,CAST(InvTotalPR*dbo.fn_CalculateFCRateVariance(Fchist_key,'P') as numeric(20,2)) AS InvTotalPR
		,CAST(ARCREDITSPR*dbo.fn_CalculateFCRateVariance(Fchist_key,'P') as numeric(20,2)) AS ARCREDITSPR
		,PRFcused_uniq, FuncFcused_uniq 
		FROM Acctsrec
		where	1 = case when ACCTSREC.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
	),
	ZAR AS 
	(SELECT	CUSTNO,sum(INVTOTAL-ARCREDITS) as BalAmt,sum(CASE WHEN DUE_DATE < GETDATE() THEN INVTOTAL - ARCREDITS ELSE 0.00 END) AS PastDue
		,sum(INVTOTALFC-ARCREDITSFC) as BalAmtFC,sum(CASE WHEN DUE_DATE < GETDATE() THEN INVTOTALFC - ARCREDITSFC ELSE 0.00 END) AS PastDueFC
		-- 01/13/17 VL added functional currency fields
		,sum(INVTOTALPR-ARCREDITSPR) as BalAmtPR,sum(CASE WHEN DUE_DATE < GETDATE() THEN INVTOTALPR - ARCREDITSPR ELSE 0.00 END) AS PastDuePR
		,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	from ZAR1 
		-- 01/13/17 VL changed criteria to get 3 currencies
		INNER JOIN Fcused PF ON ZAR1.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON ZAR1.FuncFcused_uniq = FF.Fcused_uniq			
		INNER JOIN Fcused TF ON ZAR1.Fcused_uniq = TF.Fcused_uniq					
	GROUP BY TF.Symbol, PF.Symbol, FF.Symbol, CUSTNO
	)
	-- 01/13/17 VL added functional currency fields
	SELECT	CUSTOMER.CUSTNAME,ZAR.BalAmt,ZAR.PastDue,customer.AR_CALDATE,customer.AR_CALTIME,customer.AR_CALBY,isnull(customer.AR_CALNOTE,'')as CALNOTE
			,ZAR.BalAmtFC,ZAR.PastDueFC,ZAR.BalAmtPR,ZAR.PastDuePR,TSymbol, PSymbol, FSymbol
	FROM	ZAR
			INNER JOIN CUSTOMER ON ZAR.CUSTNO = CUSTOMER.CUSTNO
	WHERE	ZAR.BalAmtFC <> 0.00
	ORDER BY TSymbol, Custname

	END
END-- End of FC installed
end