
-- =============================================
-- Author:		Debbie
-- Create date: 05/21/2012
-- Description:	Created for the GL Trial Balance report
-- Reports Using Stored Procedure:  gltbal.rpt \\  gltbwk1.rpt  \\  gltbwk2.rpt
-- Modified:  01/15/2014 DRP:  added the @userid parameter for WebManex
-- 12/01/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter
-- 05/04/2015 DPR:  Added  [or @lcDiv = ''] to the below where statements so if the user leaves the parameter blank on the Cloud it will then return all Division. 
-- 06/23/15 YS optimize the "where" and remove "*"
-- 05/03/17 DRP:  Added Functional Currency Changes.
-- ============================================= 
CREATE PROCEDURE [dbo].[rptGlTrialBalance]

--declare
		@lcFy as char(4) = ''
		,@lcPer as numeric(2) = ''
		,@lcShowAll as char(3) = 'No'
		,@lcDiv as char(2) = ''		--12/01/2014 DRP:  added the Division Paramater.   Null then it will show all Division.  
	    ,@userId uniqueidentifier=null
	 
as
begin

declare @GLBal as table (gltype char(3),lo_limit char(13),hi_limit char(13),glTypeDesc char(20),gl_descr char(30),gl_nbr char(13),gl_class char(7)
						,FiscalYear char(4),Period numeric(2),BegBal numeric(14,2),DEBIT numeric(14,2), CREDIT numeric (14,2),EndBal numeric(14,2)
						,FSymbol char(3),EndDate smalldatetime,BegBalPR numeric(14,2),DEBITPR numeric(14,2), CREDITPR numeric (14,2),EndBalPR numeric(14,2)
						,PSymbol char(3))	--05/03/17 DRP:  ADDED THIS TO HELP WITH THE FUNCTIONAL CURRENCY IMPLEMENTATION


-- 05/03/17 DRP added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()


INSERT INTO @GLBal
select	GL_NBRS.GLTYPE,gltypes.lo_limit,gltypes.hi_limit,gltypes.GLTYPEDESC,GL_NBRS.GL_DESCR, gl_acct.GL_NBR,GL_NBRS.gl_class,glfiscalyrs.FISCALYR
		,glfyrsdetl.period,gl_acct.BEG_BAL as BegBal,gl_acct.DEBIT,gl_acct.CREDIT,gl_acct.BEG_BAL+GL_ACCT.DEBIT-gl_acct.CREDIT as EndBal
		,ISNULL(FF.Symbol,'') AS FSymbol,GLFYRSDETL.EndDate,gl_acct.BEG_BALPR as BegBalPR,gl_acct.DEBITPR,gl_acct.CREDITPR,gl_acct.BEG_BALPR+GL_ACCT.DEBITPR-gl_acct.CREDITPR as EndBalPR
		,ISNULL(PF.Symbol,'') AS PSymbol	
from	GL_ACCT		
		left outer join GL_NBRS on gl_acct.GL_NBR = GL_NBRS.GL_NBR
		left outer join GLTYPES on GL_NBRS.GLTYPE = gltypes.GLTYPE
		inner join GLFYRSDETL on gl_acct.FK_FYDTLUNIQ = glfyrsdetl.FYDTLUNIQ
		inner join glfiscalyrs on  glfyrsdetl.FK_FY_UNIQ = GLFISCALYRS.FY_UNIQ
		left outer JOIN Fcused PF ON GL_ACCT.PrFcused_uniq = PF.Fcused_uniq		--05/03/17 DRP:  added
		left outer JOIN Fcused FF ON GL_ACCT.FuncFcused_uniq = FF.Fcused_uniq	--05/03/17DRP:  added

where	@lcPer = glfyrsdetl.period
		and @lcFy = glfiscalyrs.FISCALYR
		---06/23/15 YS optimize the "where" and remove "*"
		and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
		--and 1 = case when @lcDiv is null OR @lcDiv = '*'or @lcDiv = '' then 1 else  
		--			 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/01/2014 DRP:  Added this filter to work with the Division parameter. 

		
order by GL_NBR

--select * from @GLBal

BEGIN
IF @lFCInstalled = 0
	BEGIN
		if (@lcShowAll = 'No')
		begin
			select gltype,lo_limit,hi_limit,glTypeDesc,gl_descr,gl_nbr,gl_class,FiscalYear,Period,BegBal,DEBIT,CREDIT,EndBal,EndDate 
			from @GLBal where BEGBAL <> 0.00 or DEBIT <> 0.00 or CREDIT <> 0.00 
			order by gl_nbr
			end 

			else if (@lcShowAll = 'Yes')
			select gltype,lo_limit,hi_limit,glTypeDesc,gl_descr,gl_nbr,gl_class,FiscalYear,Period,BegBal,DEBIT,CREDIT,EndBal,EndDate 
			from @GLBal 
			order by gl_nbr
		END

ELSE

/**************************/
/*FOREIGN CURRENCY SECTION*/
/**************************/
	BEGIN
		if (@lcShowAll = 'No')
		begin
			select gltype,lo_limit,hi_limit,glTypeDesc,gl_descr,gl_nbr,gl_class,FiscalYear,Period,BegBal,DEBIT,CREDIT,EndBal,EndDate,FSymbol,EndDate
				   ,BegBalPR,DEBITPR,CREDITPR,EndBalPR,PSymbol 
			from @GLBal where BEGBAL <> 0.00 or DEBIT <> 0.00 or CREDIT <> 0.00 
			order by gl_nbr
			end 

			else if (@lcShowAll = 'Yes')
			select gltype,lo_limit,hi_limit,glTypeDesc,gl_descr,gl_nbr,gl_class,FiscalYear,Period,BegBal,DEBIT,CREDIT,EndBal,FSymbol,EndDate
				   ,BegBalPR,DEBITPR,CREDITPR,EndBalPR,PSymbol
			from @GLBal 
			order by gl_nbr
		END 
	end	
END