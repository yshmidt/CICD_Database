-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/12/2012
-- Description:	Find last Statemnt date fo a bank reconciliation 
-- =============================================
CREATE PROCEDURE [dbo].[LastReconView]
	-- Add the parameters for the stored procedure here
	@lcBk_Uniq char(10)=' ' 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT BkRecon.ThisStmtBalance  AS LastStmBal, L.LastStmtDt,BKRECON.RECONUNIQ ,bkRecon.RECONSTATUS  
	from BkRecon INNER JOIN (SELECT MAX(StmtDate) as LastStmtDt FROM BkRecon B WHERE  B.Bk_Uniq = @lcBk_Uniq) L
		ON L.LastStmtDt=BkRecon.StmtDate
	where Bk_Uniq = @lcBk_Uniq
	
END
