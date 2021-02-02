-- =============================================
-- Author:		David Sharp
-- Create date: 12/30/2013
-- Description:	clear a user's subscription
-- =============================================
CREATE PROCEDURE dbo.MnxTriggerNotificationSubscriptionDelete 
	-- Add the parameters for the stored procedure here
	@userId uniqueidentifier, 
	@triggerId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DELETE FROM dbo.wmTriggersActionSubsc WHERE [fkActTriggerId] = @triggerId AND
      [fkUserId] = @userId
END
