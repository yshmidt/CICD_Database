-- =============================================
-- Author:		David Sharp
-- Create date: 3/19/2012
-- Description:	Gets a list of Messages to send
--- Modifications:
--07/30/2013 YS modified update for the table
-- =============================================
CREATE PROCEDURE [dbo].[MnxNoticeUpdateMessages] 
	-- Add the parameters for the stored procedure here
	@sessionId uniqueidentifier = null,
	@messageId uniqueidentifier,
	@dateOpened smalldatetime = null,
	--07/30/13 YS use new type datetime2 
	--@dateSent smalldatetime = null,
	@dateSent datetime2 = null,
	@errorCode varchar(MAX)= null,
	@errorMessage varchar(MAX) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- 1. Check to see if an error was returned, if so switch the flag
    -- 2. Check to see if date first open is already set, if so, skip it
    -- 3. Check to see if date sent is already set, if so, skip it
    
    --07/30/13 YS no need for this code
    --DECLARE @hasError bit = 0
    --IF NOT(@errorCode IS NULL) SET @hasError = 1
    --07/30/13 YS use date2(0) smalldatetime is not going to be used in the future and the seconds are missing from the value of the date
    -- using datetime2(0) will remove miliseconds but show seconds
    --DECLARE @lastDate as smalldatetime
    -- also we can work w/o @lastDate varibale
  --  DECLARE @lastDate as datetime2(0)
  --  SELECT @lastDate = dateFirstOpened FROM MnxTriggerEmails
		--WHERE messageid = @messageId
  --  IF NOT(@lastDate IS NULL) SET @dateOpened = @lastDate
    --07/30/13 YS I am confused as to what is going on here
    -- I will leave the code untill I have an understanding
 --   IF @dateSent = '' SET @dateSent = GETDATE()
 --   DECLARE @sendDate smalldatetime
 --   SELECT @sendDate = dateSent FROM MnxTriggerEmails
	--	WHERE messageid = @messageId
	--IF NOT(@sendDate IS NULL) SET @dateSent = @sendDate
    
	UPDATE wmTriggerEmails
    SET dateFirstOpened = ISNULL(dateFirstOpened,@dateOpened), 
			hasError = CASE WHEN @errorCode IS NOT NULL THEN 1 ELSE 0 END , 
			errorCode = @errorCode, 
			errorMessage = @errorMessage, 
			dateSent = ISNULL(dateSent,CASE WHEN @errorCode IS NOT NULL THEN NULL ELSE @dateSent END)
	WHERE messageid = @messageId
    
    --UPDATE MnxTriggerEmails
    
    --SET dateFirstOpened = @dateOpened, hasError = @hasError, errorCode = @errorCode, errorMessage = @errorMessage, dateSent = @dateSent
	--WHERE messageid = @messageId
END