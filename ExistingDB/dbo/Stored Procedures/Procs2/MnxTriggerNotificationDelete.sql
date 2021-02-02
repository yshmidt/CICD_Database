-- =============================================
-- Author:		David Sharp
-- Create date: 10/29/2012
-- Description:	delete the trigger message
-- =============================================
CREATE PROCEDURE [dbo].[MnxTriggerNotificationDelete] 
	-- Add the parameters for the stored procedure here
	@messageIds varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/* Check to see if more than one message is to be deleted */	
    DECLARE @tMessage TABLE (messageId uniqueidentifier)
    DECLARE @lRollback bit=0
    
    BEGIN TRY  -- outside begin try
    BEGIN TRANSACTION -- wrap transaction
	IF NOT (@messageIds IS NULL)
	BEGIN
		INSERT INTO @tMessage SELECT CAST(id as uniqueidentifier) from fn_simpleVarcharlistToTable(@messageIds,',')
		DELETE FROM wmTriggerNotification
			WHERE messageId IN (SELECT messageId FROM @tMessage)
	END
	COMMIT
	END TRY
	BEGIN CATCH
		SET @lRollback=1
		ROLLBACK
		RETURN -1
	END CATCH
END