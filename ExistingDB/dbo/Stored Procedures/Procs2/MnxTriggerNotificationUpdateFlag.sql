-- =============================================
-- Author:		David Sharp
-- Create date: 11/7/2012
-- Description:	updates the flag on a message
-- =============================================
CREATE PROCEDURE [dbo].[MnxTriggerNotificationUpdateFlag] 
	-- Add the parameters for the stored procedure here
	@messageIds varchar(MAX), 
	@flagType varchar(10) = 'flagGray'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/* Load all message ids into @msgs table */
	DECLARE @msgs TABLE (msgId uniqueidentifier)
	INSERT INTO @msgs
	SELECT	CAST(id as uniqueidentifier)
		FROM	fn_simpleVarcharlistToTable(@messageIds,',')
	
	UPDATE wmTriggerNotification
	SET	flagType = @flagType
	WHERE messageId IN (SELECT msgId FROM @msgs)
		
	
END