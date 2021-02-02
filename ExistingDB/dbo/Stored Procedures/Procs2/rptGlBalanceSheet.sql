
-- =============================================
-- Author:		Debbie
-- Create date: 05/24/2012
-- Description:	Created for the Balance Sheet Report
-- Reports Using Stored Procedure:  glbalsh.rpt
-- Modified:  01/15/2014 DRP:  added the @userid parameter for WebManex
-- 12/10/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter
-- 05/05/2015 DPR:  Added  [or @lcDiv = ''] to the below where statements so if the user leaves the parameter blank on the Cloud it will then return all Division.
-- replaced the @lcShowAll = 'No' and @lcShowAll = 'Yes' sections with a different select statement so I could reflect the correct positive or negative value the the End_Bal fields.  Prior to this change I was doing this on the CR, but in Cloud we need the Quickview to also be accurate.
-- 05/02/17 DRP:  Added Functional Currency Changes.
-- =============================================
CREATE PROCEDURE [dbo].[rptGlBalanceSheet]

--declare
		@lcFy as char(4) = ''
		,@lcPer as int = ''
		,@lcShowAll as char(3) = 'No'
		,@lcDiv as char(2) = null		--12/10/2014 DRP:  added the Division Paramater.   Null then it will show all Division.  
		,@userId uniqueidentifier=null

as
begin

declare @GLBal as table (Tot_Start char(13),Tot_End char(13),Norm_Bal char(2),GlType char(3),gl_descr char(30),gl_class char(7),gl_nbr char(13),Beg_Bal numeric(14,2)
						,Debit numeric(14,2), credit numeric (14,2),End_Bal numeric(14,2),FSymbol char(3)
						,LONG_DESCR char(52),glTypeDesc char(20),FiscalYear char(4),Period numeric(2),EndDate smalldatetime,IsClosed bit
						,Beg_BalPR numeric(14,2),DebitPR numeric(14,2), creditPR numeric (14,2),End_BalPR numeric(14,2),PSymbol char(3)
						)	--05/02/17 DRP:  added FSymbol,Beg_BalPR,DebitPR,creditPR,End_BalPR,PSymbol

-- 05/02/17 DRP added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

--This section will gather all of the detailed information for the GL Balance sheet and insert it into the above declared table
Insert @GLBal
select	TOT_START,TOT_END,NORM_BAL,gl_nbrs.GLTYPE,GL_DESCR,gl_nbrs.GL_CLASS,GL_NBRS.GL_NBR,gl_Acct.Beg_Bal,gl_acct.DEBIT,gl_acct.credit,gl_Acct.End_Bal,isnull(FF.Symbol,'') AS FSymbol
		,GL_NBRS.LONG_DESCR,GLTYPEDESC
		,glfiscalyrs.FISCALYR,glfyrsdetl.period,GLFYRSDETL.EndDate,GLFYRSDETL.lClosed
		,gl_Acct.BEG_BALPR,gl_acct.DEBITPR,gl_acct.CREDITPR,gl_Acct.END_BALPR,isnull(PF.Symbol,'') AS PSymbol

		
from	GL_ACCT		
		left outer join GL_NBRS on gl_acct.GL_NBR = GL_NBRS.GL_NBR
		left outer join GLTYPES on GL_NBRS.GLTYPE = gltypes.GLTYPE
		inner join GLFYRSDETL on gl_acct.FK_FYDTLUNIQ = glfyrsdetl.FYDTLUNIQ
		inner join glfiscalyrs on  glfyrsdetl.FK_FY_UNIQ = GLFISCALYRS.FY_UNIQ
		left outer JOIN Fcused PF ON GL_ACCT.PrFcused_uniq = PF.Fcused_uniq		--05/02/17 DRP:  added
		left outer JOIN Fcused FF ON GL_ACCT.FuncFcused_uniq = FF.Fcused_uniq	--05/02/17DRP:  added

where	@lcFy = glfiscalyrs.FISCALYR
		and @lcPer = glfyrsdetl.period
		and gl_nbrs.STMT = 'BAL'
		and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
				 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter. 
--select * from @GLBal

--The below section should calculate the Ending Balance for the Closing Account
;
with zbstotdr as
			(
			SELECT	SUM(END_BAL) AS TotAmt,SUM(END_BALPR) AS TotAmtPR
			from	@GLBal as A  
			where	Norm_Bal = 'DR'
			)
,
zbstotcr as
			(			
			Select	SUM(end_bal) as TotAmt,SUM(End_BalPR) as TotAmtPR
			from	@GLBal as B
			where Norm_Bal = 'CR'	
			)
			
--This section is taking the calculated Ending Balance for the Closing Account and updating it into the Delcared table above
--note that if the Norm_Bal = CR then the value will be reversed on the Balance Sheet report			
update @GLBal set End_Bal = -(isnull(zbstotdr.totAmt,0.00) + isnull(zbstotcr.totamt,0.00)),End_BalPR = -(isnull(zbstotdr.totAmtPR,0.00) + isnull(zbstotcr.totamtPR,0.00)) from zbstotdr,zbstotcr,glsys where gl_class = 'Closing' and gl_nbr = glsys.CUR_EARN

--select * from @GLBal
--This section below is calculating the total by gltype
;
with
ZGlTotalNbrs as
			(				
			select	GL_NBR,tot_start,Tot_end
			from	@GLBal as C 
			where	gl_class = 'Total'
			)
,
Zbstotdr2 as
			(
			select	ZGlTotalNbrs.gl_nbr,SUM(end_bal) as TotAmtDr,SUM(end_balPR) as TotAmtDrPR
			from	@GLBal as D,ZGlTotalNbrs
			where	Norm_Bal = 'DR'
					and D.gl_nbr between ZGlTotalNbrs.tot_start and ZGlTotalNbrs.tot_end
					and gl_class <> 'Total'
			GROUP BY ZGlTotalNbrs.gl_nbr		
			)	
			
	
			,
Zbstotcr2 as
			(
			select	ZGlTotalNbrs.gl_nbr,SUM(end_bal) as TotAmtCr,SUM(end_balPR) as TotAmtCrPR
			from	@GLBal as E,ZGlTotalNbrs
			where	Norm_Bal = 'CR'
					and E.gl_nbr between ZGlTotalNbrs.Tot_Start and ZGlTotalNbrs.Tot_End
					and gl_class <> 'Total'
			GROUP BY ZGlTotalNbrs.gl_nbr		
			)
	 

--This section is taking the calculated Ending Balance per the GLType			
-- Note that if the Norm_bal = CR the value will be reversed on the Balance Sheet report.
update @GLBal set End_bal = ISNULL(zbstotdr2.totamtdr,0.00)+ISNULL(zbstotcr2.totamtcr,0.00),End_balPR = ISNULL(zbstotdr2.totamtdrPR,0.00)+ISNULL(zbstotcr2.totamtcrPR,0.00)   FROM ZGlTotalNbrs LEFT OUTER JOIN  zbstotdr2 ON ZGlTotalNbrs.gl_nbr=zbstotdr2.gl_nbr
LEFT OUTER JOIN zbstotcr2 on ZGlTotalNbrs.gl_nbr=zbstotcr2.gl_nbr 
INNER JOIN @GLBal as F on ZGlTotalNbrs.GL_NBR=F.gl_nbr 

--select * from @GLBal
/*05/05/2015 DRP: replaced this section with the following, so I could reflect the correct positive or negative value the the End_Bal fields.  Prior to this change I was doing this on the CR, but in Cloud we need the Quickview to also be accurate.
--if (@lcShowAll = 'No')
--begin
--select * from @GLBal where End_Bal <> 0.00 or gl_class ='Title' or gl_class = 'Heading'
--order by gl_nbr
--end 

--else if (@lcShowAll = 'Yes')
--select * from @GLBal
--order by gl_nbr
*/

BEGIN
IF @lFCInstalled = 0
	BEGIN
		if (@lcShowAll = 'No')
		begin
		select	Tot_Start,Tot_End, Norm_Bal,GlType,gl_descr,gl_class,gl_nbr,Beg_Bal,Debit, credit,case when Norm_Bal = 'DR' then End_Bal else -End_Bal end as  End_Bal,LONG_DESCR,glTypeDesc,FiscalYear,Period ,EndDate ,IsClosed
		from	@GLBal where End_Bal <> 0.00 or gl_class ='Title' or gl_class = 'Heading'
		order by gl_nbr
		end 

		else if (@lcShowAll = 'Yes')
		select	Tot_Start,Tot_End, Norm_Bal,GlType,gl_descr,gl_class,gl_nbr,Beg_Bal,Debit, credit,case when Norm_Bal = 'DR' then End_Bal else -End_Bal end as  End_Bal,LONG_DESCR,glTypeDesc,FiscalYear,Period ,EndDate ,IsClosed
		from	@GLBal
		order by gl_nbr

	END

ELSE

/**************************/
/*FOREIGN CURRENCY SECTION*/
/**************************/
	BEGIN 
		if (@lcShowAll = 'No')
		begin
		select	Tot_Start,Tot_End, Norm_Bal,GlType,gl_descr,gl_class,gl_nbr,Beg_Bal,Debit, credit,case when Norm_Bal = 'DR' then End_Bal else -End_Bal end as End_Bal,FSymbol
				,LONG_DESCR,glTypeDesc,FiscalYear,Period ,EndDate ,IsClosed,Beg_BalPR,DebitPR, creditPR,case when Norm_Bal = 'DR' then End_BalPR else -End_BalPR end as End_BalPR,PSymbol
		from	@GLBal where End_Bal <> 0.00 or gl_class ='Title' or gl_class = 'Heading'
		order by gl_nbr
		end 

		else if (@lcShowAll = 'Yes')
		select	Tot_Start,Tot_End, Norm_Bal,GlType,gl_descr,gl_class,gl_nbr,Beg_Bal,Debit, credit,case when Norm_Bal = 'DR' then End_Bal else -End_Bal end as  End_Bal
				,FSymbol,LONG_DESCR,glTypeDesc,FiscalYear,Period ,EndDate ,IsClosed,Beg_BalPR,DebitPR, creditPR,case when Norm_Bal = 'DR' then End_BalPR else -End_BalPR end as End_BalPR,PSymbol
		from	@GLBal
		order by gl_nbr
	END
END
end