
CREATE PROCEDURE [dbo].[MnxNoteReminderDelete]
@fkUserId uniqueidentifier,	
@fkNoteRecordId uniqueidentifier
AS
BEGIN
	UPDATE wmNoteReminders
    SET IsDeleted = 1
    WHERE fkUserID=@fkUserId
		AND fkNoteRecordId=@fkNoteRecordId
END

