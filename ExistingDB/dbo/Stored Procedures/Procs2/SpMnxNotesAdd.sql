
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/12/13
-- Description:	Add New mnxNote with possible multiple child records
-- 02/22/2017 : Vijay G : IsFlagged & IsSystemNote columns no longer in used
-- 03/08/2018 : Vijay G : Insert the notes into wmNotes and wmNoteRelationship table
-- 03/08/2018 : Vijay G : MnxNoteToRecord table is not in use
-- =============================================
CREATE PROCEDURE [dbo].[SpMnxNotesAdd] 
	-- Add the parameters for the stored procedure here		
	@tempwmNote tWmNotes READONLY, -- UDF table type for the child table wmNoteRelationship
	@tempwmNoteRelationship tWmNotes READONLY
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	
	DECLARE @ErrorNumber INT, @ErrorMessage   NVARCHAR(4000),@ErrorProcedure NVARCHAR(4000),@ErrorLine INT
	BEGIN TRANSACTION
	BEGIN TRY
		IF EXISTS ( Select 1 from @tempwmNote) AND EXISTS ( Select 1 from @tempwmNoteRelationship)
			BEGIN
				INSERT INTO [dbo].[wmNotes] ([NoteID],[Description],[fkCreatedUserID],[CreatedDate],[fkLastModifiedUserID],[LastModifiedDate]
			   ,[DeletedDate],[fkDeletedUserID],[IsDeleted],[ReminderDate],[RecordId],[RecordType],[NoteCategory] ,[CarNo])       
				SELECT NoteID,Description,fkCreatedUserID,GETDATE(),NULL,NULL,NULL,NULL,0,ReminderDate,RecordId,RecordType,NoteCategory,0 
				FROM @tempwmNote   
			  

			/*Insert Notes into wmNoteRelationship table*/		
				INSERT INTO [dbo].[wmNoteRelationship] ([NoteRelationshipId],[fkNoteID],[CreatedUserID],[Note],[CreatedDate],[ImagePath])
				SELECT NEWID() AS NoteRelationshipId, n.NoteID, r.fkCreatedUserID,
					r.Description, GETDATE() as CreatedDate, r.ImagePath
					-- 03/08/2018 : Vijay G : oldNoteId used for join to insert child note.
				FROM @tempwmNote n inner join @tempwmNoteRelationship r on n.OldNoteID = r.OldNoteID
			END      
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		SELECT @ErrorNumber = ERROR_NUMBER(),
			   @ErrorMessage = ERROR_MESSAGE(),
			   @ErrorProcedure= ERROR_PROCEDURE(),
			   @ErrorLine= ERROR_LINE()

      RAISERROR ('An error occurred within mnxNotes or wmNoteRelationship insert transaction. 
                  Error Number        : %d
                  Error Message       : %s  
                  Affected Procedure  : %s
                  Affected Line Number: %d'
                  , 16, 1
                  , @ErrorNumber, @ErrorMessage, @ErrorProcedure,@ErrorLine)
       
      IF @@TRANCOUNT > 0
         ROLLBACK TRANSACTION 
	
	END CATCH
END