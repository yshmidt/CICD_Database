-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/01/2009>
-- Description:	<View for the GL_ACCT table to gather related information>
-- modified: 06/22/15 added new column sequenceNumber. That way we do not have to rely on the data entered into FY column
-- this SP is used by glview form in the desktop only
-- 02/04/16 YS added cashFlow column to gl_nbrs table 
--04/22/16 ys added  remove cashFlow column from gl_nbrs table, added cashFlowActCode associated with the type
-- =============================================
CREATE PROCEDURE [dbo].[GL_ACCTVIEW]
--06/22/15 YS changed properties used
	@StartSequenceNumber int=0,
	@lnStartPeriod Numeric(2,0)=0,
	@EndSequenceNumber int=0,
	@lnEndPeriod Numeric(2,0)=0,
	--@lcStartFy char(4)=' ',
	--@lcStartPeriod Numeric(2,0)=0,
	--@lcEndFy char(4)=' ',
	--@lcEndPeriod Numeric(2,0)=0,
	@lcgl_class char(7)=' '
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 06/22/15 added new column sequenceNumber and changed properties
	-- 02/04/16 YS added cashFlow column to gl_nbrs table 
   	select gl_acct.gl_nbr,fk_FyDtlUniq,glfiscalyrs.FiscalYr,glFyrsDetl.Period,Beg_bal,Debit,Credit,End_bal,
			gl_acct.gl_nbr+glfiscalyrs.FiscalYr+convert(char(2),glFyrsDetl.Period) as NBR_PERIOD,
			Gl_nbrs.GLTYPE,gl_nbrs.GL_CLASS,Gl_nbrs.GL_DESCR ,gltypes.GLTYPEDESC,isnull(c.cashActName,cast('' as nvarchar(50))) as cashActName
			from gl_acct INNER JOIN glFyrsDetl ON gl_acct.fk_fydtluniq=glFyrsDetl.FyDtlUniq 
			INNER JOIN glFiscalyrs ON  glFyrsDetl.fk_fy_uniq=glFiscalyrs.Fy_uniq
			INNER JOIN GL_NBRS ON Gl_acct.gl_nbr=Gl_nbrs.gl_nbr
			INNER JOIN GLTYPES ON GL_NBRS.GLTYPE =GLTYPEs.GLTYPE 
			--04/22/16 ys added  cashFlow associated with the type
			LEFT OUTER JOIN mnxcashFlowActivities C on gltypes.cashFlowActCode=c.cashFlowActCode
			--06/22/15 YS changes in parameters. Need covert int to char otherwise between doesn't work need to find a better solution
			--WHERE GLFISCALYRS.SequenceNumber+glfyrsdetl.Period BETWEEN @StartSequenceNumber+@lnStartPeriod and @EndSequenceNumber+@lnEndPeriod
			where dbo.padl(rtrim(cast(SequenceNumber as char(4))),4,'0')+ dbo.padl(RTRIM(CAST(Period as CHAR(2))),2,'0')
			between dbo.padl(rtrim(cast(@startSequenceNumber as char(4))),4,'0')+ dbo.padl(RTRIM(CAST(@lnStartPeriod as CHAR(2))),2,'0')
			and dbo.padl(rtrim(cast(@endSequenceNumber as char(4))),4,'0')+ dbo.padl(RTRIM(CAST(@lnEndPeriod as CHAR(2))),2,'0')
			AND (@lcgl_class =' ' OR  Gl_nbrs.GL_CLASS = @lcgl_class );
																
END