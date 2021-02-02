-- =============================================
-- Author:		??
-- Create date: ??
-- Description:	Delete Note
-- Modified: 07/22/15 YS changed to use @RecordId parameter when removing from RecordTags table
--			 07/22/15 YS added begin transaction and begin try/catch block
-- 06/13/18 YS structure changes created an error
-- =============================================
CREATE PROCEDURE [dbo].[MnxNotesDelete]
	@NoteId uniqueidentifier,
	@RecordId varchar(100),
	@RecordType varchar(50),
	@fkDeletedUserID uniqueidentifier
AS
BEGIN
	--07/22/15 YS declare to collect error information
	DECLARE @ErrorNumber INT, @ErrorMessage   NVARCHAR(4000),@ErrorProcedure NVARCHAR(4000),@ErrorLine INT

    DECLARE @NoteRecordCount int
    SELECT @NoteRecordCount = COUNT(*) FROM wmNoteTORecord where fkNoteId= @NoteId;
   --07/22/15 YS added begin transaction and begin try/catch block
    BEGIN TRANSACTION
		BEGIN TRY
			if(@NoteRecordCount > 1)
			BEGIN
				UPDATE [wmNoteToRecord]
				SET IsDeleted = 1,
				DeletedDate = GETDATE(),
				fkDeletedUserID = @fkDeletedUserID
				WHERE fkNoteId= @NoteId AND RecordId = @RecordId AND RecordType = @RecordType;
			END
			ELSE
			BEGIN
				---07/22/15 YS changed to use @RecordId parameter when removing from RecordTags table
				--DELETE FROM [dbo].[RecordTags]
				--WHERE fkRecordID= @NoteId;
	    
				DELETE FROM [dbo].[RecordTags]
				WHERE fkRecordID= @RecordId;
	    
				UPDATE [wmNoteToRecord]
				SET IsDeleted = 1,
				DeletedDate = GETDATE(),
				fkDeletedUserID = @fkDeletedUserID
				WHERE fkNoteId= @NoteId;
		
				UPDATE [wmNotes]
				SET IsDeleted = 1,
				DeletedDate = GETDATE(),
				fkDeletedUserID = @fkDeletedUserID
				WHERE NoteId= @NoteId;		
			END  
		END TRY
		BEGIN CATCH
			SELECT @ErrorNumber = ERROR_NUMBER(),
			   @ErrorMessage = ERROR_MESSAGE(),
			   @ErrorProcedure= ERROR_PROCEDURE(),
			   @ErrorLine= ERROR_LINE()

			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION 
			
			 RAISERROR ('An error occurred within [MnxNotesDelete] SP. 
                  Error Number        : %d
                  Error Message       : %s  
                  Affected Procedure  : %s
                  Affected Line Number: %d'
                  , 16, 1
                  , @ErrorNumber, @ErrorMessage, @ErrorProcedure,@ErrorLine);
       
			
		END CATCH
		IF @@TRANCOUNT > 0
		  COMMIT		 

END