-- =============================================
-- Author:		Satish B
-- Create date: 10/06/2018
-- Description:	Add po import Header details
-- =============================================
CREATE PROCEDURE [dbo].DeletePOUploadScheduleRecord
-- Add the parameters for the stored procedure here
	@importId UNIQUEIDENTIFIER 
	,@importRowId UNIQUEIDENTIFIER
	,@importScheduleRowId UNIQUEIDENTIFIER
AS
BEGIN                   
	SET NOCOUNT ON;
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	
	BEGIN TRY
		BEGIN TRANSACTION
			DELETE FROM ImportPOSchedule WHERE  fkPOImportId  =@importId AND fkRowId=@importRowId AND ScheduleRowId=@importScheduleRowId
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