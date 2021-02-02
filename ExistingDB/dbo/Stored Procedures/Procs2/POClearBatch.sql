
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/22/2013
-- Description:	Procedure to clear the batch prior to printing new batch
-- =============================================
CREATE PROCEDURE [dbo].[POClearBatch] 
	-- Add the parameters for the stored procedure here
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	UPDATE POMAIN SET ISINBATCH =0 where ISINBATCH =1
	COMMIT
END