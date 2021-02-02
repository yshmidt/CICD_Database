
CREATE PROCEDURE [dbo].[MnxNoteReminderAdd]
	@fkUserId uniqueidentifier,
	@NoteReminderID uniqueidentifier,
	@ReminderDate datetime,
	@fkNoteRecordId uniqueidentifier
AS
BEGIN
	INSERT INTO [dbo].[wmNoteReminders]
           (NoteReminderID
           ,[fkUserID]
           ,[ReminderDate]
           ,[fkNoteRecordID])
     VALUES
           (@NoteReminderID
           ,@fkUserId
           ,@ReminderDate
           ,@fkNoteRecordId)
END

