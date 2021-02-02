---06/13/18 YS structure changed. Probably need to remove SP
CREATE PROCEDURE [dbo].[MnxNoteUpdate] 
	@NoteId uniqueidentifier,
	@Description text,
	@LastModifiedUserID uniqueidentifier
	--,@IsFlagged bit
AS
BEGIN
	UPDATE wmNotes
	SET Description = @Description,
	LastModifiedDate = getdate(),
	fkLastModifiedUserID = @LastModifiedUserID
	--,IsFlagged = @IsFlagged
	WHERE NoteId = @NoteId
		
END