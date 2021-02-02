-- =============================================
-- Author:		<Debbie>
-- Create date: <08/18/2015>
-- Description:	<AR Bank Deposits Detail Report <ar_rep5>
-- Modified:	08/19/15 DRP:  Changed the Deposit Date field to only show Date, I don't want to go down to the Time level on this field
--							   Completely removed a ZCheckTotal section that I had.  It was not needed and was causing some duplicate results in same situations. 
--				03/18/16 VL:   Added FC code
--				04/08/16 VL:   Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--			11/18/16 DRP:	Changed the Date filter because there was an issue if the user happen to use the Calendar popup it would not populate the time stamp, and the original filter I had set would incorrectly include those records.
--				01/13/17 VL:	Added functional currency fields
-- 10/04/17 VL added a missing , after D.REC_AMOUNTPR
-- 03/22/19 VL:	Added Due_date, request by Pro-active, zendesk#3204
-- =============================================
CREATE PROCEDURE [dbo].[rptArDepositReceiptDetail] 

--DECLARE	
	@lcDateStart as smalldatetime = null
	,@lcDateEnd as smalldatetime = null
	,@lcCustNo varchar(max) = 'All'
	,@userId uniqueidentifier = null



AS
BEGIN


/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END

		--select * from @Customer

SELECT @lcDateStart=CASE WHEN @lcDateStart is null then @lcDateStart else cast(@lcDateStart as smalldatetime)  END,
			@lcDateEnd=CASE WHEN @lcDateEnd is null then @lcDateEnd else DATEADD(day,0,cast(@lcDateEnd as smalldatetime))  END	--11/18/16 DRP:  changed DATEADD(day,1,cast(@lcDateEnd as smalldatetime)...TO BE... DATEADD(day,0,cast(@lcDateEnd as smalldatetime)
--SELECT @lcDateStart,@lcDateEnd

-- 03/17/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN

	; 
	with ZDetail as 
		(
		select	cast (D.DATE as date) AS DepositDate,C.CUSTNAME,TOT_DEP,a.DEP_no,a.REC_ADVICE,a.uniquear
				,r.INVDATE InvDate,case when a.REC_TYPE = 'Other' then 'Other ~ ' + a.DESCRIPT else a.INVNO end as invno
				,isnull(r.INVTOTAL,0.00) as InvTotal,a.DISC_TAKEN ,a.REC_AMOUNT	
				-- 03/22/19 VL added due_date
				,r.DUE_DATE							
		from	ARCREDIT A
				LEFT OUTER JOIN ACCTSREC R  ON A.CUSTNO = R.CUSTNO AND A.INVNO = R.INVNO
				INNER JOIN CUSTOMER C ON A.CUSTNO = C.CUSTNO
				INNER JOIN DEPOSITS D ON A.DEP_NO = D.DEP_NO
		WHERE	exists (select 1 from @Customer C1  where a.custno = c1.custno) 
				and datediff(day,D.DATE,@lcDateStart)<=0 and datediff(day,D.date,@lcDateEnd)>=0
				--and d.date between @lcDateStart and @lcDateEnd	--11/18/16 DRP:  replaced with the above
		)
	


	select distinct	DepositDate,CUSTNAME,CASE WHEN ROW_NUMBER() OVER(Partition by D.Dep_no Order by D.Dep_no)=1 Then D.TOT_DEP ELSE CAST(0.00 as Numeric(20,2)) END AS TOT_DEP
			,D.DEP_no,D.REC_ADVICE,D.uniquear,D.INVDATE InvDate,D.invno,d.InvTotal,D.DISC_TAKEN,D.REC_AMOUNT
			-- 03/22/19 VL added due_date and DaysToPay
			,D.DUE_DATE, DATEDIFF(day,D.Due_date,DepositDate) AS DaysToPay
	from	ZDetail D 
	order by DepositDate,custname,REC_ADVICE
	END
ELSE
-- FC installed
	BEGIN
	; 
	with ZDetail as 
		(
		-- 01/13/17 VL:	Added functional currency fields
		select	cast (D.DATE as date) AS DepositDate,C.CUSTNAME,TOT_DEP,a.DEP_no,a.REC_ADVICE,a.uniquear
				,r.INVDATE InvDate,case when a.REC_TYPE = 'Other' then 'Other ~ ' + a.DESCRIPT else a.INVNO end as invno
				,isnull(r.INVTOTAL,0.00) as InvTotal,a.DISC_TAKEN ,a.REC_AMOUNT
				,TOT_DEPFC,isnull(r.INVTOTALFC,0.00) as InvTotalFC,a.DISC_TAKENFC ,a.REC_AMOUNTFC
				,TOT_DEPPR,isnull(r.INVTOTALPR,0.00) as InvTotalPR,a.DISC_TAKENPR ,a.REC_AMOUNTPR
				--Fcused.Symbol AS Currency
				,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol	
				-- 03/22/19 VL added due_date
				,r.DUE_DATE	
		from ARCREDIT A
			-- 01/13/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON A.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON A.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON A.Fcused_uniq = TF.Fcused_uniq								
				LEFT OUTER JOIN ACCTSREC R  ON A.CUSTNO = R.CUSTNO AND A.INVNO = R.INVNO
				INNER JOIN CUSTOMER C ON A.CUSTNO = C.CUSTNO
				INNER JOIN DEPOSITS D ON A.DEP_NO = D.DEP_NO
		WHERE	exists (select 1 from @Customer C1  where a.custno = c1.custno) 
				and datediff(day,D.DATE,@lcDateStart)<=0 and datediff(day,D.date,@lcDateEnd)>=0
				--and d.date between @lcDateStart and @lcDateEnd	--11/18/16 DRP:  replaced with the above
		)
	


	select distinct	DepositDate,CUSTNAME,CASE WHEN ROW_NUMBER() OVER(Partition by D.Dep_no Order by D.Dep_no)=1 Then D.TOT_DEP ELSE CAST(0.00 as Numeric(20,2)) END AS TOT_DEP
			,D.DEP_no,D.REC_ADVICE,D.uniquear,D.INVDATE InvDate,D.invno,d.InvTotal,D.DISC_TAKEN,D.REC_AMOUNT
			,CASE WHEN ROW_NUMBER() OVER(Partition by D.Dep_no Order by D.Dep_no)=1 Then D.TOT_DEPFC ELSE CAST(0.00 as Numeric(20,2)) END AS TOT_DEPFC
			,d.InvTotalFC,D.DISC_TAKENFC,D.REC_AMOUNTFC
			-- 01/13/17 VL:	Added functional currency fields
			,CASE WHEN ROW_NUMBER() OVER(Partition by D.Dep_no Order by D.Dep_no)=1 Then D.TOT_DEPPR ELSE CAST(0.00 as Numeric(20,2)) END AS TOT_DEPPR
			-- 10/04/17 VL added a missing , after D.REC_AMOUNTPR
			,d.InvTotalPR,D.DISC_TAKENPR,D.REC_AMOUNTPR,
			--, Currency
			TSymbol,PSymbol,FSymbol
			-- 03/22/19 VL added due_date and DaysToPay
			,D.DUE_DATE, DATEDIFF(day,D.Due_date,DepositDate) AS DaysToPay
	from	ZDetail D 
	order by TSymbol, DepositDate,custname,REC_ADVICE
	END
END-- end of IF FC installee

End