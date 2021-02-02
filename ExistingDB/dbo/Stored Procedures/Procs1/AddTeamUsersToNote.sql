-- =============================================
-- Author:	Raviraj P
-- Create date: 10/13/2017
-- Description:	Add the delete team user to its respected chat or issue then delete team from WmNoteUser 
-- exec [dbo].[AddTeamUsersToNote] 'EB694BF1-79DB-496B-B330-227D8682BD4D'
-- =============================================
CREATE PROCEDURE [dbo].[AddTeamUsersToNote] 
	-- Add the parameters for the stored procedure here
	@fkWmNoteGroupId uniqueidentifier 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO WmNoteUser(WmNoteUserId,UserId,NoteId,IsGroup,GroupId)
	SELECT NEWID(),wmNoteGroupUser.UserId,NoteId,CAST(0 AS BIT),CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER)
	FROM WmNoteGroupUsers wmNoteGroupUser
	INNER JOIN WmNoteGroup wmNoteGroup ON wmNoteGroupUser.FkWmNoteGroupId = wmNoteGroup.WmNoteGroupId
	INNER JOIN  WmNoteUser wmNoteUser  ON wmNoteUser.GroupId = wmNoteGroupUser.FkWmNoteGroupId AND wmNoteUser.IsGroup = 1
	WHERE wmNoteGroupUser.FkWmNoteGroupId = @fkWmNoteGroupId
	AND NOT EXISTS(SELECT 1 FROM WmNoteUser w1
	WHERE w1.UserId = wmNoteGroupUser.UserId and WmNoteUser.NoteId = NoteId and w1.IsGroup = 0)

	 -- delete team from WmNoteUser 
	 DELETE FROM WmNoteUser WHERE GroupId = @fkWmNoteGroupId
END