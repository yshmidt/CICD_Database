-- =============================================
-- Author:		David Sharp
-- Create date: 10/29/2012
-- Description:	get a user new message count
-- =============================================
CREATE PROCEDURE [dbo].[MnxTriggerNotificationCountGet] 
	-- Add the parameters for the stored procedure here
	@recipientId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT count(*)[count] FROM wmTriggerNotification WHERE dateRead is null AND recipientId=@recipientId AND (dateRemind IS NULL OR dateRemind<=GETDATE())
END