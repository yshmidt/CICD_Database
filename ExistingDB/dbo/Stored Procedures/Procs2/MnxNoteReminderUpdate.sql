
CREATE PROCEDURE [dbo].[MnxNoteReminderUpdate]
	-- Add the parameters for the stored procedure here	
	@fkUserId uniqueidentifier,	
	@ReminderDate datetime,
	@fkNoteRecordId uniqueidentifier
AS
BEGIN
	UPDATE wmNoteReminders
    SET ReminderDate = @ReminderDate
    WHERE  fkUserID=@fkUserId	
		AND fkNoteRecordId	= @fkNoteRecordId	
END

