-- =============================================
-- Author:		David Sharp
-- Create date: 10/29/2012
-- Description:	get a message detail
-- =============================================
CREATE PROCEDURE [dbo].[MnxTriggerNotificationGet]
	-- Add the parameters for the stored procedure here
	@msgId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @root varchar(MAX)
	SELECT @root=CUSTOMROOTURL FROM GENERALSETUP

    -- Insert statements for procedure here
    SELECT tm.*, COALESCE(u.UserName,'')SenderName, ta.bodyTemplate,ta.subjectTemplate,ta.summaryTemplate,tm.notificationValues,@root rootUrl
		FROM wmTriggerNotification tm LEFT OUTER JOIN aspnet_Users u ON tm.senderId=u.UserId
			LEFT OUTER JOIN MnxTriggersAction ta ON tm.triggerId=ta.actTriggerId
		WHERE messageId=@msgId 
		
	UPDATE wmTriggerNotification
		SET dateRead=GETDATE(),dateFirstRead=GETDATE()
		WHERE messageId=@msgId AND dateFirstRead IS NULL
END