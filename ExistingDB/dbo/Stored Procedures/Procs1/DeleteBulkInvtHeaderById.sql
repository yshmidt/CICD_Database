-- =============================================
-- Author:		Mahesh B.	
-- Create date: 04/24/2019 
-- Description:	Delete Imported item by imported id 
-- =============================================
CREATE PROCEDURE [dbo].[DeleteBulkInvtHeaderById]
	-- Add the parameters for the stored procedure here
		@invtImportId UNIQUEIDENTIFIER
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- get ready to handle any errors
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	
	BEGIN TRY
	BEGIN TRANSACTION
    
	DELETE FROM ImportBulkInvtFields WHERE FkInvtImportId =@invtImportId
	DELETE FROM ImportBulkInvtHeader WHERE InvtImportId =@invtImportId
	
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK
			SELECT @ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );

	END CATCH	
	IF @@TRANCOUNT>0
		COMMIT 
END