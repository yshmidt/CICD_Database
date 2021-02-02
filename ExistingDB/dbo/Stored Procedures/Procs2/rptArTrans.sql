-- =============================================
-- Author:		<Debbie>
-- Create date: <10/10/2014>
-- Description:	Used on ARTRANS   "AR Transactions"
-- Modified:	10/09/2014 DRP:  I had originally created in a VIEW, but needed to recreate it in this stored procedure to work properly with WebManex.  Deleted "rptARTransactionView"
-- Since I was re-creating the procedure for QuickView only.  At this time then I implemented running Total values into the results rather than caclulating that within the Report Designer. 
-- 01/06/2015 DRP:  Added @customerStatus Filter 
-- 01/21/15   YS -- @lcDateStart and @lcDateEnd patrameters not used in the code 
-- 01/26/15   YS -- control the order of the id populated in @Trans 
-- 03/02/2016 VL:   Added FC code
-- 04/08/2016 VL:	 Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 05/12/16   DRP	The date range was not picking up the tranactions properly.
-- 01/11/17   VL:	 added one more parameter for fn_CalculateFCRateVariance() which is the rate ratio calculated based on functional currency or presentation currency
-- 01/13/17   VL:	 Added functional currency fields
-- 05/09/17 DRP:  added <<and AR1.isManualCM = 0>> to make sure that the Manual Credit Memos would not be listed twice on the results (one with value and one without value) 
-- 08/11/17 VL The FUNC and PR InvTotal were always calculated to use latest rate to show in this report, but Penang decided we should use original rate (don't recalculate), so will remove 
-- the fn_CalculateFCRateVariance(), Zendesk#1183
-- 08/28/17 VL found RunningTotal should be selected from @TransFC
-- =============================================
CREATE PROCEDURE [dbo].[rptArTrans]

--declare 
@lcDateStart as smalldatetime = null
,@lcDateEnd as smalldatetime = null
,@lcCustNo as varChar(max) = 'All'
,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
,@userId uniqueidentifier = null

as
begin 

/*CUSTOMER LIST*/	
	--01/21/15   YS -- @lcDateStart and @lcDateEnd patrameters not used in the code 	
	-- make sure start and end date has no time, only date
	-- if start date is null get month from the end date , if the end date is null assign today's date
	select  @lcDateEnd = CASE WHEN  @lcDateEnd is null then DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0) else DATEADD(day, DATEDIFF(day, 0, @lcDateEnd), 0) END
	select @lcDateStart = CASE WHEN @lcDateStart IS null THEN DATEADD(day,-30,DATEADD(day, DATEDIFF(day, 0, @lcDateEnd), 0)) ELSE DATEADD(day, DATEDIFF(day, 0, @lcDateStart), 0) END
		  
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;

		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END

/*SELECT STATEMENT*/

-- 03/01/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN

	declare @Trans as table (CustName char(35),TransDate smalldatetime,[Type] char (15),InvNo char(10),Amount numeric(12,2),Reference char (15),Applied char(25),Custno char(10)
							,id int)

	--01/21/15   YS -- @lcDateStart and @lcDateEnd patrameters not used in the code 
	;with zDetail as (
	SELECT	AR1.CUSTNO, AR1.INVDATE AS TransDate, CAST(CASE WHEN LEFT(invno, 4) = 'PPay' THEN 'AR PrePay' ELSE 'AR Invoice' END AS char(15)) AS Type
			,AR1.INVNO, AR1.INVTOTAL, CAST(' ' AS char(15)) AS Reference, CAST('' AS char(25)) AS Applied
	FROM	ACCTSREC AS AR1 
	-- 01/22/15 YS cheange the where to be more optimizable
	WHERE EXISTS (SELECT 1 FROM @customer c where c.custno=ar1.custno)
	--where	1 = case when AR1.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
	--		and (ar1.INVTOTAL <> 0.00 or ar1.arcredits <> 0.00)
	--01/21/15   YS -- @lcDateStart and @lcDateEnd patrameters not used in the code 
	--AND AR1.INVDATE >= @lcDateStart and AR1.INVDATE<=@lcDateEnd	--05/12/16 DRP:  REPLACED WITH THE BELOW
	and DATEDIFF(day, @lcDateStart,AR1.INVDATE) >=0 AND DATEDIFF(day,AR1.INVDATE,@lcDateEnd )>=0
	and AR1.isManualCM = 0	-- 05/09/17 DRP:  addded
			
	UNION

	SELECT	custno, aro2.DATE AS tRANSDATE, 'AR-Offset' AS Type, CAST('' AS CHAR(10)) AS INVNO, aro2.AMOUNT AS InvTotal, CAST(' ' AS char(15)) AS Reference
			,CAST('For InvNo: ' + aro2.INVNO AS char(25)) AS Applied
	FROM	AROFFSET AS aro2 
	-- 01/22/15 YS cheange the where to be more optimizable
	--where	1 = case when CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
	WHERE EXISTS (SELECT 1 FROM @customer c where c.custno=aro2.custno)
	--and aro2.DATE >= @lcDateStart  and aro2.DATE<=@lcDateEnd		--05/12/16 DRP:  REPLACED WITH THE BELOW
		AND DATEDIFF(day, @lcDateStart,aro2.date) >=0 AND DATEDIFF(day,aro2.date,@lcDateEnd )>=0	
	UNION

	SELECT	arc3.custno, ARC3.REC_DATE AS Transdate,CAST(CASE WHEN arc3.rec_type = 'Credit Memo' THEN 'AR Credit' WHEN arc3.rec_type = 'Apply PPay' THEN 'PP Applied' ELSE 'AR Deposits' END AS char(15)) AS Type
			, ARC3.REC_ADVICE AS InvNo, - ARC3.REC_AMOUNT AS InvTotal, CAST('' AS char(15)) AS Reference
			, CAST(CASE WHEN arc3.rec_type = 'Credit Memo' AND cmmain.cmtype = 'I' THEN 'For InvNo: ' + arc3.invno 
							WHEN arc3.rec_type = 'Credit Memo' AND cmmain.cmtype = 'M' THEN 'For Reference: ' + arc3.invno ELSE 'For InvNo: ' + arc3.invno END AS char(25)) AS Applied
	FROM	ARCREDIT AS ARC3 
			LEFT OUTER JOIN CMMAIN ON ARC3.REC_ADVICE = dbo.CMMAIN.CMEMONO
	WHERE	(ARC3.REC_TYPE <> 'PrePay')
		-- 01/22/15 YS cheange the where to be more optimizable
		--where	1 = case when CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
		AND EXISTS (SELECT 1 FROM @customer c where c.custno=arc3.custno)
		--and ARC3.REC_DATE >= @lcDateStart  and ARC3.REC_DATE<=@lcDateEnd		05/12/16 DRP:  REPLACED WITH THE BELOW
		AND DATEDIFF(day, @lcDateStart,ARC3.REC_DATE) >=0 AND DATEDIFF(day,ARC3.REC_DATE,@lcDateEnd )>=0	
		--and 1 = case when arc3.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end


	UNION

	SELECT	arrc4.custno, arrc4.RET_DATE AS TransDate, CAST('Check Return' AS char(15)) AS Type, arrd4.REC_ADVICE AS InvNo, arrd4.REC_AMOUNT AS InvTotal
			, CAST(' ' AS char(15)) AS Reference, CAST('For InvNo: ' + arrd4.INVNO AS char(25)) AS Applied
	FROM	ARRETDET AS arrd4 
			INNER JOIN ARRETCK AS arrc4 ON arrd4.DEP_NO = arrc4.DEP_NO
	where
	-- 01/22/15 YS cheange the where to be more optimizable
		--where	1 = case when CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
		EXISTS (SELECT 1 FROM @customer c where c.custno=arrc4.custno)
		--and arrc4.RET_DATE  >= @lcDateStart  and arrc4.RET_DATE <=@lcDateEnd	05/12/16 DRP:  REPLACED WITH THE BELOW
		AND DATEDIFF(day, @lcDateStart,ARRC4.RET_DATE) >=0 AND DATEDIFF(day,ARRC4.RET_DATE,@lcDateEnd )>=0
	--1 = case when arrc4.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
			
	UNION

	SELECT	custno, AR_WO.WODATE AS TransDate, CAST('AR Write Off' AS char(15)) AS Type, CAST('' AS char(10)) AS InvNo
			, - dbo.AR_WO.WO_AMT AS InvTotal, CAST(' ' AS char(15)) AS Reference, CAST('For InvNo: ' + dbo.AcctsRec.INVNO AS char(25)) AS Applied
	FROM	AR_WO 
			INNER JOIN AcctsRec ON Ar_wo.Uniquear = AcctsRec.UniqueAr 
	where	
	-- 01/22/15 YS cheange the where to be more optimizable
		--where	1 = case when CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
		EXISTS (SELECT 1 FROM @customer c where c.custno=AcctsRec.custno)
		--and AR_WO.WODATE   >= @lcDateStart  and AR_WO.WODATE  <=@lcDateEnd	05/12/16 DRP:  REPLACED WITH THE BELOW
		AND DATEDIFF(day, @lcDateStart,AR_WO.WODATE) >=0 AND DATEDIFF(day,AR_WO.WODATE,@lcDateEnd )>=0	
	--1 = case when CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end		
	)
	
	/*INSERT THE DETAIL INTO THE TABLE SO AN ID CAN BE ASSIGNED TO IT AND LATER USED FOR THE RUNNING TOTAL*/
	insert into @Trans
	select	custname,TransDate,Type,InvNo,InvTotal,Reference,Applied,Customer.Custno,
		ROW_NUMBER() OVER (PARTITION BY Customer.CustNO ORDER BY TransDate ) as id
	from	CUSTOMER
			inner join zDetail as D1 on Customer.CUSTNO = D1.CUSTNO
	
	
	/*SELECT THE RESULTS AND CACULATE THE RUNNING TOTAL THAT WILL BREAK/RESTART AT EACH CHANGE OF CUSTNO*/
	select	a.CustName,a.TransDate,a.[Type],a.InvNo,a.Amount,a.Reference,a.Applied,a.Custno,a.id,
		(select SUM(b.Amount)from @Trans b where b.id <= a.id and b.custno = a.custno) as RunningTotal
	from	@Trans as a 
	order by CustName, a.id 

	END
ELSE
-- FC installed
	BEGIN
	-- 01/13/17 VL added functional currency fields
	declare @TransFC as table (CustName char(35),TransDate smalldatetime,[Type] char (15),InvNo char(10),Amount numeric(12,2),Reference char (15),Applied char(25),Custno char(10)
							, AmountFC numeric(12,2)--, Currency char(3)
							, AmountPR numeric(12,2),TSymbol char(3), PSymbol char(3), FSymbol char(3), id int)

	--01/21/15   YS -- @lcDateStart and @lcDateEnd patrameters not used in the code 
	;with zDetail as (
	SELECT	AR1.CUSTNO, AR1.INVDATE AS TransDate, CAST(CASE WHEN LEFT(invno, 4) = 'PPay' THEN 'AR PrePay' ELSE 'AR Invoice' END AS char(15)) AS Type
			,AR1.INVNO, AR1.INVTOTAL, CAST(' ' AS char(15)) AS Reference, CAST('' AS char(25)) AS Applied, AR1.INVTOTALFC, AR1.FCHIST_KEY
			-- 01/13/17 VL added functional currency fields
			--, Fcused.Symbol AS Currency
			,AR1.INVTOTALPR, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	FROM	ACCTSREC AS AR1 
		-- 01/13/17 VL changed criteria to get 3 currencies
		INNER JOIN Fcused PF ON AR1.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON AR1.FuncFcused_uniq = FF.Fcused_uniq			
		INNER JOIN Fcused TF ON AR1.Fcused_uniq = TF.Fcused_uniq								
	-- 01/22/15 YS cheange the where to be more optimizable
	WHERE EXISTS (SELECT 1 FROM @customer c where c.custno=ar1.custno)
	--where	1 = case when AR1.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
	--		and (ar1.INVTOTAL <> 0.00 or ar1.arcredits <> 0.00)
	--01/21/15   YS -- @lcDateStart and @lcDateEnd patrameters not used in the code 
	--AND AR1.INVDATE >= @lcDateStart and AR1.INVDATE<=@lcDateEnd	--05/12/16 DRP:  REPLACED WITH THE BELOW
	and DATEDIFF(day, @lcDateStart,AR1.INVDATE) >=0 AND DATEDIFF(day,AR1.INVDATE,@lcDateEnd )>=0
	and AR1.isManualCM = 0	-- 05/09/17 DRP:  addded
			
	UNION

	SELECT	custno, aro2.DATE AS tRANSDATE, 'AR-Offset' AS Type, CAST('' AS CHAR(10)) AS INVNO, aro2.AMOUNT AS InvTotal, CAST(' ' AS char(15)) AS Reference
			,CAST('For InvNo: ' + aro2.INVNO AS char(25)) AS Applied, aro2.AMOUNTFC AS InvTotalFC, aro2.FCHIST_KEY
			-- 01/13/17 VL added functional currency fields
			--, Fcused.Symbol AS Currency
			,aro2.AMOUNTPR AS InvTotalPR, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	FROM	AROFFSET AS aro2 
		-- 01/13/17 VL changed criteria to get 3 currencies
		INNER JOIN Fcused PF ON ARo2.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON ARo2.FuncFcused_uniq = FF.Fcused_uniq			
		INNER JOIN Fcused TF ON ARo2.Fcused_uniq = TF.Fcused_uniq								
	-- 01/22/15 YS cheange the where to be more optimizable
	--where	1 = case when CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
	WHERE EXISTS (SELECT 1 FROM @customer c where c.custno=aro2.custno)
	--and aro2.DATE >= @lcDateStart  and aro2.DATE<=@lcDateEnd		--05/12/16 DRP:  REPLACED WITH THE BELOW
		AND DATEDIFF(day, @lcDateStart,aro2.date) >=0 AND DATEDIFF(day,aro2.date,@lcDateEnd )>=0	
	UNION

	SELECT	arc3.custno, ARC3.REC_DATE AS Transdate,CAST(CASE WHEN arc3.rec_type = 'Credit Memo' THEN 'AR Credit' WHEN arc3.rec_type = 'Apply PPay' THEN 'PP Applied' ELSE 'AR Deposits' END AS char(15)) AS Type
			, ARC3.REC_ADVICE AS InvNo, - ARC3.REC_AMOUNT AS InvTotal, CAST('' AS char(15)) AS Reference
			, CAST(CASE WHEN arc3.rec_type = 'Credit Memo' AND cmmain.cmtype = 'I' THEN 'For InvNo: ' + arc3.invno 
							WHEN arc3.rec_type = 'Credit Memo' AND cmmain.cmtype = 'M' THEN 'For Reference: ' + arc3.invno ELSE 'For InvNo: ' + arc3.invno END AS char(25)) AS Applied
			,- ARC3.REC_AMOUNTFC AS InvTotalFC, arc3.FCHIST_KEY
			-- 01/13/17 VL added functional currency fields
			--, Fcused.Symbol AS Currency
			,- ARC3.REC_AMOUNTPR AS InvTotalPR, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	FROM	ARCREDIT AS ARC3 
		-- 01/13/17 VL changed criteria to get 3 currencies
		INNER JOIN Fcused PF ON ARC3.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON ARC3.FuncFcused_uniq = FF.Fcused_uniq			
		INNER JOIN Fcused TF ON ARC3.Fcused_uniq = TF.Fcused_uniq								
			LEFT OUTER JOIN CMMAIN ON ARC3.REC_ADVICE = dbo.CMMAIN.CMEMONO
	WHERE	(ARC3.REC_TYPE <> 'PrePay')
		-- 01/22/15 YS cheange the where to be more optimizable
		--where	1 = case when CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
		AND EXISTS (SELECT 1 FROM @customer c where c.custno=arc3.custno)
		--and ARC3.REC_DATE >= @lcDateStart  and ARC3.REC_DATE<=@lcDateEnd		05/12/16 DRP:  REPLACED WITH THE BELOW
		AND DATEDIFF(day, @lcDateStart,ARC3.REC_DATE) >=0 AND DATEDIFF(day,ARC3.REC_DATE,@lcDateEnd )>=0
		--and 1 = case when arc3.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end


	UNION

	SELECT	arrc4.custno, arrc4.RET_DATE AS TransDate, CAST('Check Return' AS char(15)) AS Type, arrd4.REC_ADVICE AS InvNo, arrd4.REC_AMOUNT AS InvTotal
			, CAST(' ' AS char(15)) AS Reference, CAST('For InvNo: ' + arrd4.INVNO AS char(25)) AS Applied,arrd4.REC_AMOUNTFC AS InvTotalFC, arrd4.FCHIST_KEY
			-- 01/13/17 VL added functional currency fields
			--, Fcused.Symbol AS Currency
			,arrd4.REC_AMOUNTPR AS InvTotalPR, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	-- 01/13/17 VL re-write this part
	--FROM	Fcused INNER JOIN Fchistory ON Fchistory.Fcused_uniq = Fcused.Fcused_uniq 
	--		INNER JOIN ARRETDET AS arrd4 ON arrd4.Fchist_key = Fchistory.Fchist_key
	--		INNER JOIN ARRETCK AS arrc4 ON arrd4.DEP_NO = arrc4.DEP_NO
	FROM ARRETDET AS arrd4 
			INNER JOIN ARRETCK AS arrc4 ON arrd4.DEP_NO = arrc4.DEP_NO
		---- 01/13/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON arrc4.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON arrc4.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON arrc4.Fcused_uniq = TF.Fcused_uniq	

	where
	-- 01/22/15 YS cheange the where to be more optimizable
		--where	1 = case when CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
		EXISTS (SELECT 1 FROM @customer c where c.custno=arrc4.custno)
		--and arrc4.RET_DATE  >= @lcDateStart  and arrc4.RET_DATE <=@lcDateEnd	05/12/16 DRP:  REPLACED WITH THE BELOW
		AND DATEDIFF(day, @lcDateStart,ARRC4.RET_DATE) >=0 AND DATEDIFF(day,ARRC4.RET_DATE,@lcDateEnd )>=0
	--1 = case when arrc4.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
			
	UNION

	SELECT	custno, AR_WO.WODATE AS TransDate, CAST('AR Write Off' AS char(15)) AS Type, CAST('' AS char(10)) AS InvNo
			, - dbo.AR_WO.WO_AMT AS InvTotal, CAST(' ' AS char(15)) AS Reference, CAST('For InvNo: ' + dbo.AcctsRec.INVNO AS char(25)) AS Applied
			, - dbo.AR_WO.WO_AMTFC AS InvTotalFC, Ar_wo.FCHIST_KEY
			-- 01/13/17 VL added functional currency fields
			--, Fcused.Symbol AS Currency
			,- dbo.AR_WO.WO_AMTPR AS InvTotalPR, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	FROM	AR_WO 
		---- 01/13/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON AR_WO.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON AR_WO.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON AR_WO.Fcused_uniq = TF.Fcused_uniq		
			INNER JOIN AcctsRec ON Ar_wo.Uniquear = AcctsRec.UniqueAr 
	where	
	-- 01/22/15 YS cheange the where to be more optimizable
		--where	1 = case when CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
		EXISTS (SELECT 1 FROM @customer c where c.custno=AcctsRec.custno)
		--and AR_WO.WODATE   >= @lcDateStart  and AR_WO.WODATE  <=@lcDateEnd	05/12/16 DRP:  REPLACED WITH THE BELOW
		AND DATEDIFF(day, @lcDateStart,AR_WO.WODATE) >=0 AND DATEDIFF(day,AR_WO.WODATE,@lcDateEnd )>=0
	--1 = case when CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end		
	)
	
	/*INSERT THE DETAIL INTO THE TABLE SO AN ID CAN BE ASSIGNED TO IT AND LATER USED FOR THE RUNNING TOTAL*/
	-- 03/02/16 VL get fchist_key from each SQL, now will call dbo.fn_CalculateFCRateVariance to re-calculate HC values with latest rate
	-- 01/13/17 VL added functional currency fields
	-- 08/11/17 VL The FUNC and PR InvTotal were always calculated to use latest rate to show in this report, but Penang decided we should use original rate (don't recalculate), so will remove 
	-- the fn_CalculateFCRateVariance(), Zendesk#1183
	insert into @TransFC
	select	custname,TransDate,Type,InvNo
		--,CAST(InvTotal*dbo.fn_CalculateFCRateVariance(Fchist_key,'F') as numeric(20,2)) AS InvTotal
		,InvTotal
		,Reference,Applied,Customer.Custno
		,InvTotalFC
		--CAST(InvTotalPR*dbo.fn_CalculateFCRateVariance(Fchist_key,'P') as numeric(20,2)) AS InvTotalPR
		,InvTotalPR
		, TSymbol, PSymbol, FSymbol,
		--Currency,
		ROW_NUMBER() OVER (PARTITION BY Customer.CustNO ORDER BY TransDate ) as id
	from	CUSTOMER
			inner join zDetail as D1 on Customer.CUSTNO = D1.CUSTNO
	
	
	/*SELECT THE RESULTS AND CACULATE THE RUNNING TOTAL THAT WILL BREAK/RESTART AT EACH CHANGE OF CUSTNO*/
	-- 08/28/17 VL found RunningTotal should be selected from @TransFC
	select	a.CustName,a.TransDate,a.[Type],a.InvNo,a.Amount,a.Reference,a.Applied,a.Custno,a.id,
		(select SUM(b.Amount)from @TransFC b where b.id <= a.id and b.custno = a.custno) as RunningTotal
		,a.AmountFC, (select SUM(b.AmountFC)from @TransFC b where b.id <= a.id and b.custno = a.custno) as RunningTotalFC
		-- 01/13/17 VL added functional currency and currency fields
		,a.AmountPR, (select SUM(b.AmountPR)from @TransFC b where b.id <= a.id and b.custno = a.custno) as RunningTotalPR, TSymbol, PSymbol, FSymbol
	from	@TransFC as a 
	order by TSymbol, CustName, a.id 
	END
END-- If FC installed
END