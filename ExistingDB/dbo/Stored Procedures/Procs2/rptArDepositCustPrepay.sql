-- =============================================
-- Author:		Debbie	
-- Create date:	10/09/15
-- Description:	Customer PrePayment Summary [ar_rep14]
-- Modified:	03/17/16 VL:	Added FC code	
--				04/08/16 VL:	Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				01/13/17 VL:	Added functional currency fields
-- =============================================
CREATE PROCEDURE [dbo].[rptArDepositCustPrepay]


--declare
	@lcDateStart as smalldatetime= null,
	@lcDateEnd as smalldatetime = null,
	@lcCustNo as varchar (max) = 'All',
	@userId uniqueidentifier = null


as
begin

/*CUSTOMER LIST*/
	DECLARE  @tCustomer as tCustomer
			DECLARE @Customer TABLE (custno char(10))
		-- get list of Customers for @userid with access
		INSERT INTO @tCustomer EXEC aspmnxSP_Getcustomers4user @userid,null,'All' ;
		--SELECT * FROM @tCustomer	
		IF @lcCustno is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select Custno from @tCustomer)
		ELSE

		IF  @lccustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT Custno FROM @tCustomer
		END


-- 03/17/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
BEGIN
IF @lFCInstalled = 0
	BEGIN

	select AR.REC_DATE,CUSTNAME,AR.REC_ADVICE,AR.REC_AMOUNT,AR.INVNO,A.lPrepay
	from	ARCREDIT AR
			INNER JOIN CUSTOMER ON AR.CUSTNO = CUSTOMER.CUSTNO
			left outer join ACCTSREC A on ar.CUSTNO = A.CUSTNO AND AR.INVNO = A.INVNO
	WHERE	a.lPrepay = 1
			and DATEDIFF(day, @lcDateStart,REC_DATE) >=0 AND DATEDIFF(day,REC_DATE,@lcDateEnd )>=0
			and (@lcCustNo='All' OR exists (select 1 from @Customer t inner join customer w on t.custno=w.custno where w.custno=AR.custno))
	order by REC_DATE
	END
ELSE
-- FC installed
	BEGIN
	-- 01/13/17 VL:	Added functional currency fields
	select AR.REC_DATE,CUSTNAME,AR.REC_ADVICE,AR.REC_AMOUNT,AR.INVNO,A.lPrepay, AR.REC_AMOUNTFC, 
			AR.REC_AMOUNTPR,
			--Fcused.Symbol AS Currency
			TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	from ARCREDIT AR
			-- 01/13/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON AR.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON AR.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON AR.Fcused_uniq = TF.Fcused_uniq	
				INNER JOIN CUSTOMER ON AR.CUSTNO = CUSTOMER.CUSTNO
			left outer join ACCTSREC A on ar.CUSTNO = A.CUSTNO AND AR.INVNO = A.INVNO
	WHERE	a.lPrepay = 1
			and DATEDIFF(day, @lcDateStart,REC_DATE) >=0 AND DATEDIFF(day,REC_DATE,@lcDateEnd )>=0
			and (@lcCustNo='All' OR exists (select 1 from @Customer t inner join customer w on t.custno=w.custno where w.custno=AR.custno))
	order by TSymbol, REC_DATE

	END
END--IF FC installed
end