

CREATE PROCEDURE [dbo].[spManExNotesDelete]
	@NoteId uniqueidentifier,
	@RecordId varchar(100),
	@RecordType varchar(50),
	@fkDeletedUserID uniqueidentifier
AS
BEGIN

    DECLARE @NoteRecordCount int
    SELECT @NoteRecordCount = COUNT(*) FROM wmNoteTORecord where fkNoteId= @NoteId;
    
    if(@NoteRecordCount > 1)
    BEGIN
		UPDATE [wmNoteToRecord]
		SET IsDeleted = 1,
		DeletedDate = GETDATE(),
		fkDeletedUserID = @fkDeletedUserID
		WHERE fkNoteId= @NoteId AND [wmNoteToRecord].RecordId = @RecordId AND [wmNoteToRecord].RecordType = @RecordType;
    END
    ELSE
    BEGIN
		DELETE FROM [dbo].[wmNotes]
		WHERE NoteId= @NoteId;
	     
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

END