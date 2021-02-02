
-- =============================================
-- Author:		Debbie
-- Create date: 11/19/15
-- Description:	This Stored Procedure was created for the Returned Checks Info
-- Reports:		ar_rep22
-- Modified:	08/09/17 YS added currencies
-- 06/12/20 VL Added Rec_Advice column to show check number
-- =============================================
CREATE PROCEDURE [dbo].[rptArReturnChk]

--declare
	@lcDateStart smalldatetime = null
	,@lcDateEnd smalldatetime = null
	,@userId uniqueidentifier = null

as 
begin

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it. 
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	
---08/09/17 YS follow Debbie's suggestion to create a result table and use it at the end to select appropriate columns
--- use temp table 
if OBJECT_ID('tempdb..#tResult') is not null
	drop table #tResult;
/*RECORD SELECTION SECTION*/
---08/09/17 YS insert into #tResult and add currency columns
select	CUSTNAME,BANKS.BK_ACCT_NO,BANK,isnull(bf.symbol,space(3)) as bkCurr,
isnull(tf.symbol,space(3)) as trCurr, TOT_DEP,REC_AMOUNT,
isnull(pf.symbol,space(3)) as prCurr,TOT_DEPPR ,REC_AMOUNTPR,
isnull(ff.symbol,space(3)) as funcCurr,TOT_DEPFC ,REC_AMOUNTFC,
[DATE],arretck.RET_DATE,RET_NOTE
-- 06/12/20 VL Added Rec_Advice column to show check number
, ARRETCK.REC_ADVICE
INTO #tResult
from	ARRETCK
		INNER JOIN DEPOSITS ON ARRETCK.DEP_NO = DEPOSITS.DEP_NO
		INNER JOIN CUSTOMER ON ARRETCK.CUSTNO = CUSTOMER.CUSTNO
		INNER JOIN BANKS ON DEPOSITS.BK_UNIQ = BANKS.BK_UNIQ
		left outer join fcused ff on ARRETCK.FUNCFCUSED_UNIQ=ff.FcUsed_Uniq
		left outer join fcused pf on ARRETCK.PRFCUSED_UNIQ=pf.FcUsed_Uniq
		left outer join fcused tf on ARRETCK.FCUSED_UNIQ=tf.FcUsed_Uniq
		left outer join fcused bf on Banks.Fcused_Uniq=bf.FcUsed_Uniq
where	exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)
		and DATEDIFF(day, @lcDateStart,arretck.RET_DATE) >=0 AND DATEDIFF(day,arretck.RET_DATE,@lcDateEnd )>=0
order by custname,date
/*
None FC installation
*/
IF dbo.fn_IsFCInstalled() = 0
select	CUSTNAME,BK_ACCT_NO,BANK,
	TOT_DEP,REC_AMOUNT,
	[DATE],RET_DATE,RET_NOTE
	-- 06/12/20 VL Added Rec_Advice column to show check number
	,REC_ADVICE
	FROM #tResult
else
/*
 FC installation
*/
	select	CUSTNAME,BK_ACCT_NO,BANK,bkCurr,
	trCurr, TOT_DEP,REC_AMOUNT,
	prCurr,TOT_DEPPR ,REC_AMOUNTPR,
	funcCurr,TOT_DEPFC ,REC_AMOUNTFC,
	[DATE],RET_DATE,RET_NOTE
	-- 06/12/20 VL Added Rec_Advice column to show check number
	,REC_ADVICE
	FROM #tResult
-- drop the temp table
if OBJECT_ID('tempdb..#tResult') is not null
	drop table #tResult;
end