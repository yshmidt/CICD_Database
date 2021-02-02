
CREATE PROCEDURE [dbo].[MnxNoteReminderGetByUserIdAndNoteRecordId]
	@fkUserId uniqueidentifier,		
	@fkNoteRecordId uniqueidentifier
AS
BEGIN
	SELECT [NoteReminderID]
      ,[fkUserID]
      ,[ReminderDate]
      ,[fkNoteRecordID]
      ,[IsDeleted]
  FROM [wmNoteReminders] nr
  WHERE  nr.fkUserID=@fkUserId	
		AND nr.fkNoteRecordId	= @fkNoteRecordId	
		AND IsDeleted = 0

END

