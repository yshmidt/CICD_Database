CREATE PROCEDURE [dbo].[MnxNotesRemoveFromDatabase]
	@NoteId uniqueidentifier,
	@RecordId varchar(100),
	@RecordType varchar(50),
	@fkDeletedUserID uniqueidentifier
AS
BEGIN
	
    DECLARE @NoteRecordID uniqueidentifier
    SET @NoteRecordID = (select NoteRecordID from wmNoteToRecord where fkNoteId= @NoteId)
    BEGIN
		DELETE wmNoteReminders where fkNoteRecordID=@NoteRecordID
		DELETE wmNoteToRecord where NoteRecordID=@NoteRecordID
		Delete from RecordTags where fkRecordID = @NoteId and RecordType = @RecordType
		DELETE wmNotes where NoteID=@NoteId		
	END
END