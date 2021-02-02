-- =============================================
-- Author:		David Sharp
-- Create date: 2/6/2013
-- Description:	Get Notes By Tag
-- =============================================
CREATE PROCEDURE [dbo].[DEMO_NoteByTagGet] 
	-- Add the parameters for the stored procedure here
	@tagName varchar(100)=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    IF @tagName IS NULL
    select p.Initials, at.[Description]Tag,nr.RecordType,nr.RecordID,n.[Description]Descript ,rt.CreatedDate,r.ReminderDate
	from RecordTags rt 
		inner join aspnet_Profile p on p.UserId=rt.fkCreatedUserId
		inner join MnxAdminTags at on at.AdminTagId = rt.fkAdminTagId
		inner join wmNoteToRecord nr on rt.fkRecordId=nr.fkNoteID
		inner join wmNotes n on n.NoteID=rt.fkRecordId
		left outer join wmNoteReminders r on r.fkNoteRecordID=n.NoteID
    ELSE
	select p.Initials, at.[Description]Tag,nr.RecordType,nr.RecordID,n.[Description]Descript ,rt.CreatedDate ,r.ReminderDate
	from RecordTags rt 
		inner join aspnet_Profile p on p.UserId=rt.fkCreatedUserId
		inner join MnxAdminTags at on at.AdminTagId = rt.fkAdminTagId
		inner join wmNoteToRecord nr on rt.fkRecordId=nr.fkNoteID
		inner join wmNotes n on n.NoteID=rt.fkRecordId
		left outer join wmNoteReminders r on r.fkNoteRecordID=n.NoteID
	where at.[Description]=@tagName
END