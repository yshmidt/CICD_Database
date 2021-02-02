-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 02/02/2016
-- Description:	Subscribe/un-subscribe user to a trigger
-- this script is temporary untill we get UI to add triggers and subscribe to them
-- @action parameter can have 'Add' or 'Remove' value
-- =============================================
CREATE PROCEDURE [dbo].[SubscribeUserByEmailAddress] 
	-- Add the parameters for the stored procedure here
	 @triggerName varchar(50) = '', 
	 @emailaddress varchar(100)=null,
	 @action varchar(10)='Add'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @actTriggerId uniqueidentifier=null,
			@userid uniqueidentifier ; 

	select @actTriggerId=actTriggerId from MnxTriggersAction where triggername=@triggerName
	if @actTriggerId is null
	BEGIN
		print N'Trigger ' +@triggerName+N' was not setup'
	end 
	else --- @actTriggerId is null
	BEGIN 
		select TOP 1 @userid=Userid from aspnet_membership where EMAIL=@emailaddress order by userid
		if @userid is null
		BEGIN
			print N'User with e-mail address ' +@emailaddress+N' not found'
		end 
		else  --  @userid is null
		BEGIN
			if @action='Add' --- subscribe a user to get e-mail
			BEGIN
				IF NOT EXISTS (select 1 from wmTriggersActionSubsc where fkActTriggerId= @actTriggerId and fkUserId=@userid)
					INSERT INTO wmTriggersActionSubsc (fkActTriggerId ,fkUserId ,notificationType) 
					VALUES	(@actTriggerId,@userid,'E');
		
			END ---@action='Add'
			if @action='Remove' --- un-subscribe a user 
			BEGIN
				delete from wmTriggersActionSubsc where fkActTriggerId= @actTriggerId and fkUserId=@userid ;
			END ---@action='Remove'
	END --  @userid is null
	END -- -- --- @actTriggerId is null
END 