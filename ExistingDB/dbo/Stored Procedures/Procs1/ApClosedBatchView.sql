CREATE PROCEDURE [dbo].[ApClosedBatchView] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT BatchDescr,DatePaid,Bank,Batch_tot,BatchUniq, Bk_Acct_No, ApBatch.Bk_Uniq, BANKS.ACCTTITLE, lReprinted 
		FROM ApBatch, Banks 
		WHERE ApBatch.Is_Closed = 1 
			AND Banks.Bk_Uniq = ApBatch.Bk_Uniq 
END