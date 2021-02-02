-- =============================================
-- Author:		
-- Create date: 
-- Description:	Add New mnxNote 
-- 6/19/2017 : Shripati : IsFlagged & IsSystemNote columns no longer in use
-- 03/05/2018 : Vijay G : Updated the stored procedure logic to insert note records into the wmNoteRelationship table 
-- 03/05/2018 : Vijay G : Insert RecordId,RecordType,CarNo into wmNotes table
-- 03/05/2018 : Vijay G : Insert note relationship into wmNoteRelationship table
-- 03/05/2018 : Vijay G : Added tWmNotes parameter for bulk insert of the PM and Item notes for BOM import
-- =============================================
CREATE PROCEDURE [dbo].[MnxNotesAdd]    
    @tempwmNote tWmNotes ReadOnly,
	@NoteId uniqueidentifier = NULL,
	@Description text = NUll,
	@CreatedUserID uniqueidentifier = NULL,
	@ReminderDate datetime =NULL,
	@RecordId varchar(100) = NULL,
	@RecordType varchar(50) = NULL,
	@NoteCategory int = NULL	
AS
BEGIN
	IF NOT EXISTS ( Select 1 from @tempwmNote)
		BEGIN
			INSERT INTO [dbo].[wmNotes]
			   ([NoteID]
			   ,[Description]
			   ,[fkCreatedUserID]
			   ,[CreatedDate]
			   ,[fkLastModifiedUserID]
			   ,[LastModifiedDate]
			   ,[DeletedDate]
			   ,[fkDeletedUserID]
			   ,[IsDeleted]
			   ,[ReminderDate]
			   ,[RecordId]     -- 03/05/2018 : Vijay G : Insert RecordId 
			   ,[RecordType]   -- 03/05/2018 : Vijay G : Insert RecordType 
			   ,[NoteCategory] 
			   ,[CarNo])       -- 03/05/2018 : Vijay G : Insert CarNo default as 0				   
		 VALUES
			   (@NoteId
			   ,@Description
			   ,@CreatedUserID
			   ,getdate()
			   ,null
			   ,null
			   ,null
			   ,null
			   ,0
			   ,@ReminderDate
			   ,@RecordId     -- 03/05/2018 : Vijay G : Insert RecordId 
			   ,@RecordType
			   ,@NoteCategory -- 03/05/2018 : Vijay G : Insert RecordType 
			   ,0);            -- 03/05/2018 : Vijay G : Insert CarNo default as 0 
			   

-- 03/05/2018 : Vijay G : Insert note relationship into wmNoteRelationship table  
			DECLARE @NoteRelationshipId uniqueidentifier = newid()  
			INSERT INTO [dbo].[wmNoteRelationship]
			   ([NoteRelationshipId]
			   ,[fkNoteID]
			   ,[CreatedUserID]
			   ,[Note]
			   ,[CreatedDate])
		 VALUES
			   (@NoteRelationshipId
			   ,@NoteId
			   ,@CreatedUserID
			   ,@Description
			   ,getdate())      
		END
	ELSE
	   -- 03/05/2018 : Vijay G : Bulk Insert of note
	   /*Insert Notes into wmNotes table*/		
		BEGIN
			INSERT INTO [dbo].[wmNotes] ([NoteID],[Description],[fkCreatedUserID],[CreatedDate],[fkLastModifiedUserID],[LastModifiedDate]
			   ,[DeletedDate],[fkDeletedUserID],[IsDeleted],[ReminderDate],[RecordId],[RecordType],[NoteCategory] ,[CarNo])       
			SELECT NoteID,Description,fkCreatedUserID,GETDATE(),NULL,NULL,NULL,NULL,0,ReminderDate,RecordId,RecordType,NoteCategory,0 
			FROM @tempwmNote
			
			/*Insert Notes into wmNoteRelationship table*/		
			INSERT INTO [dbo].[wmNoteRelationship] ([NoteRelationshipId],[fkNoteID],[CreatedUserID],[Note],[CreatedDate],[ImagePath])
			SELECT NEWID() AS NoteRelationshipId, NoteID AS fkNoteID, fkCreatedUserID as CreatedUserID,
				Description as Note, GETDATE() as CreatedDate, ImagePath
			FROM @tempwmNote
		END	     
END