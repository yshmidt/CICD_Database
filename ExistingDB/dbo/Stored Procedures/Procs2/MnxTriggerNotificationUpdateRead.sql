-- =============================================
-- Author:		David Sharp
-- Create date: 10/29/2012
-- Description:	updates the read date on a message
-- =============================================
CREATE PROCEDURE [dbo].[MnxTriggerNotificationUpdateRead] 
	-- Add the parameters for the stored procedure here
	@messageIds varchar(MAX), 
	@markAsRead bit,
	@dateRead smalldatetime = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/* Check to see if the dateRead has already been set.  If so, don't change that value. */
	DECLARE @dteRead smalldatetime, @firstRead smalldatetime
	DECLARE @msgs TABLE (msgId uniqueidentifier)
	INSERT INTO @msgs
	SELECT	CAST(id as uniqueidentifier)
		FROM	fn_simpleVarcharlistToTable(@messageIds,',')
	
	SET @dateRead=GETDATE()
	
	IF @markAsRead = 1
	BEGIN
	
		UPDATE wmTriggerNotification
		SET	dateRead = @dateRead
			,dateFirstRead=@dateRead
		WHERE messageId IN (SELECT msgId FROM @msgs) AND dateRead IS NULL
		
		/* If the notice was also sent via email, mark the email as read when read via system message */
		UPDATE wmTriggerEmails
		SET dateFirstOpened = @dateRead
		WHERE messageid IN (SELECT msgId FROM @msgs) AND dateFirstOpened IS NULL
	
	END
	ELSE
	BEGIN
		UPDATE wmTriggerNotification
		SET	dateRead = NULL
		WHERE messageId IN (SELECT msgId FROM @msgs) 
	END
	
END