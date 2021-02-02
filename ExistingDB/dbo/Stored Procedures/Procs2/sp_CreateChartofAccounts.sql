-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/05/2009>
-- Description:	<Create chart of accounts table GL_ACCT>
-- 06/22/15 YS added sequencenumber column to use for sorting instead of fiscalyrs
-- =============================================
CREATE PROCEDURE [dbo].[sp_CreateChartofAccounts] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Delete all records from GL_ACCT
	DELETE FROM GL_ACCT
	-- create new records
	-- 06/22/15 YS added sequencenumber column to use for sorting instead of fiscalyrs
	--INSERT INTO GL_ACCT (GL_NBR,fk_FyDtlUniq) select GL_NBRS.GL_NBR,GlFyrsDetl.FyDtlUniq from gl_nbrs CROSS JOIN glFiscalYrs INNER JOIN GlFyrsDetl on glFiscalyrs.Fy_uniq=GlFyrsDetl.fk_fy_uniq order by GL_NBRS.GL_NBR,FiscalYr,Period
    INSERT INTO GL_ACCT (GL_NBR,fk_FyDtlUniq) select GL_NBRS.GL_NBR,GlFyrsDetl.FyDtlUniq from gl_nbrs CROSS JOIN glFiscalYrs INNER JOIN GlFyrsDetl on glFiscalyrs.Fy_uniq=GlFyrsDetl.fk_fy_uniq order by GL_NBRS.GL_NBR,sequenceNumber,Period
	-- call to calculate TB
	EXEC sp_RecalculateTB 
END