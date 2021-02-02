-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/12/2012
-- Description:	Find Bank Reconciliation for a given bank and status 
-- =============================================
CREATE PROCEDURE [dbo].[BkReconFindView]
	-- Add the parameters for the stored procedure here
	@lcBk_Uniq char(10)=NULL,@lcReconStatus char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT StmtDate, ReconStatus, ReconUniq 
	FROM bkrecon 
    WHERE Bkrecon.bk_uniq = @lcBk_Uniq
    AND BkRecon.RECONSTATUS =CASE WHEN @lcReconStatus=' ' THEN BkRecon.RECONSTATUS ELSE @lcReconStatus END
	
END
