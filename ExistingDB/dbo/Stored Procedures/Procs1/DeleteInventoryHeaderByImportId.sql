-- =============================================
-- Author:		Shivshankar P
-- Create date: 02/21/2018
-- Description:	this procedure will Used for delete Imported Invt Record
-- Nitesh B 1/18/2019: Delete ImportUdfFields records
-- Nitesh B 5/27/2019: Change parameter @invtImportId UNIQUEIDENTIFIER to @invtImportId tUniqueIdentifier READONLY
-- =============================================
CREATE PROCEDURE [dbo].[DeleteInventoryHeaderByImportId]
	-- Add the parameters for the stored procedure here
	@invtImportId tUniqueIdentifier READONLY -- Nitesh B 5/27/2019: Change parameter @invtImportId UNIQUEIDENTIFIER to @invtImportId tUniqueIdentifier READONLY
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

	DELETE FROM ImportInvtSerialFields WHERE FkRowId IN (SELECT RowId FROM ImportInvtFields WHERE FkImportId IN (select UniqueIdentifierId from @invtImportId))
	DELETE FROM ImportInvtFields WHERE FkImportId IN (select UniqueIdentifierId from @invtImportId)
	DELETE FROM InvtImportHeader WHERE InvtImportId IN (select UniqueIdentifierId from @invtImportId)
	 -- Nitesh B 1/18/2019: Delete ImportUdfFields records
	DELETE FROM ImportUdfFields WHERE FkImportId IN (select UniqueIdentifierId from @invtImportId) 
	

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