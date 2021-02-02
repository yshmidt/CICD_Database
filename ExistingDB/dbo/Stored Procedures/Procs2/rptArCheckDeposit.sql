
-- =============================================
-- Author:		Debbie
-- Create date: 11/19/15
-- Description:	This Stored Procedure was created for the Check Deposit Summary
-- Reports:		ar_rep7
-- Modified:	03/18/16 VL:	Added FC code
--				04/08/16 VL:	Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				05/16/16 DRP:	needed to change the [DATE] field from smalldatetime to be cast(DEPOSITS.DATE as date)[DATE]
--				01/13/17 VL:	Added functional currency fields
-- 11/03/17 VL removed RunningDepTotalFC because it's diffent currency
-- =============================================
CREATE PROCEDURE [dbo].[rptArCheckDeposit]

--declare 

@lcDateStart smalldatetime = null
,@lcDateEnd smalldatetime = null
,@userId uniqueidentifier=null

as
begin

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it. 
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	


/*RECORD SELECTION SECTION*/

-- 03/17/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
BEGIN
IF @lFCInstalled = 0
	BEGIN
	;
	With zDep as 
	(
	select	cast(DEPOSITS.DATE as date)[DATE],BANKS.BK_ACCT_NO,BANKS.BANK,ARCREDIT.REC_ADVICE,sum(ARCREDIT.REC_AMOUNT) as REC_AMOUNT, DEPOSITS.DEP_NO
	from	DEPOSITS
			INNER JOIN BANKS ON DEPOSITS.BK_UNIQ = BANKS.BK_UNIQ
			INNER JOIN ARCREDIT ON DEPOSITS.DEP_NO = ARCREDIT.DEP_NO
			INNER JOIN CUSTOMER ON ARCREDIT.CUSTNO = CUSTOMER.CUSTNO
	where	DATEDIFF(day, @lcDateStart,deposits.date) >=0 AND DATEDIFF(day,deposits.date,@lcDateEnd )>=0
			and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)

	Group by DEPOSITS.DATE,BANKS.BK_ACCT_NO,BANKS.BANK,ARCREDIT.REC_ADVICE, DEPOSITS.DEP_NO

	)

	select *,sum(rec_amount) over (order by date,BK_ACCT_NO,BANK,REC_ADVICE rows unbounded preceding) as RunningDepTotal from zDep
	END
ELSE
	BEGIN
	;
	With zDep as 
	(
	select	cast(DEPOSITS.DATE as date)[DATE],BANKS.BK_ACCT_NO,BANKS.BANK,ARCREDIT.REC_ADVICE,sum(ARCREDIT.REC_AMOUNT) as REC_AMOUNT, DEPOSITS.DEP_NO
		-- 03/18/16 VL oadded FC fields
		,sum(ARCREDIT.REC_AMOUNTFC) as REC_AMOUNTFC
		-- 01/13/17 VL added functional currency fields
		,sum(ARCREDIT.REC_AMOUNTPR) as REC_AMOUNTPR
		--, Fcused.Symbol AS Currency
		,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	from	DEPOSITS
			-- 01/13/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON DEPOSITS.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON DEPOSITS.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON DEPOSITS.Fcused_uniq = TF.Fcused_uniq						
			INNER JOIN BANKS ON DEPOSITS.BK_UNIQ = BANKS.BK_UNIQ
			INNER JOIN ARCREDIT ON DEPOSITS.DEP_NO = ARCREDIT.DEP_NO
			--INNER JOIN Fcused ON ARCREDIT.FCUSED_UNIQ = Fcused.FcUsed_Uniq
			INNER JOIN CUSTOMER ON ARCREDIT.CUSTNO = CUSTOMER.CUSTNO
	where	DATEDIFF(day, @lcDateStart,deposits.date) >=0 AND DATEDIFF(day,deposits.date,@lcDateEnd )>=0
			and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)

	Group by TF.Symbol,PF.Symbol,FF.Symbol,DEPOSITS.DATE,BANKS.BK_ACCT_NO,BANKS.BANK,ARCREDIT.REC_ADVICE, DEPOSITS.DEP_NO
	)

	select *,sum(rec_amount) over (order by TSymbol,PSymbol,FSymbol,date,BK_ACCT_NO,BANK,REC_ADVICE rows unbounded preceding) as RunningDepTotal
		-- 11/03/17 VL removed RunningDepTotalFC because it's different currency
		--,sum(rec_amountFC) over (order by TSymbol,PSymbol,FSymbol,date,BK_ACCT_NO,BANK,REC_ADVICE rows unbounded preceding) as RunningDepTotalFC
		-- 01/13/17 VL added functional currency fields
		,sum(rec_amountPR) over (order by TSymbol,PSymbol,FSymbol,date,BK_ACCT_NO,BANK,REC_ADVICE rows unbounded preceding) as RunningDepTotalPR
		from zDep	
	ORDER BY TSymbol, Date, Bk_Acct_no, BANK, REC_ADVICE
	END
END
end