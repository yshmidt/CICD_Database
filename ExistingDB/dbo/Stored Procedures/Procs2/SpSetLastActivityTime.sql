-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/19/2013 
-- Description:	Set LastActivityTime from the desktop
-- 08/26/13 YS save module and workstation id
-- =============================================
CREATE PROCEDURE [dbo].[SpSetLastActivityTime]
	-- Add the parameters for the stored procedure here
	@SessionId varchar(50),
	@UserId uniqueidentifier,
	@Module varchar(50)='',
	@WorkStationId varchar(50)='',
	@newSessionId varchar(50) ='' OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--09/10/13 YS create a table variable and outpur new session id
	DECLARE @tSessionId table (sessionId varchar(50))
	
    -- Insert statements for procedure here
    -- 07/10/13 YS update last activity for user check both sessionid and oldsessionid
    --09/11/13 YS trying to use UPDLOCK hint to prevent deadlock
    --09/12/13 YS add begin transaction/commit
    
  --  SELECT aspmnx_ActiveUsers.pkActiveUsers  from  aspmnx_ActiveUsers (UPDLOCK)
		--WHERE (sessionId=@SessionId or oldsessionId=@SessionId) and fkuserId =@userId 
		-- 09/12/13 YS split check for sessionid and oldsessionid
	--10/30/13 YS added check if record was found
	declare @lFound bit =0 	
	IF exists (SELECT 1 from aspmnx_ActiveUsers where  fkuserId =@userId and sessionId=@SessionId)
	BEGIN
		set @lFound=1
		BEGIN TRANSACTION
		UPDATE aspmnx_ActiveUsers SET lastActivityDate=GETDATE(),
							lastModule = @Module ,
							workstationId =@WorkStationId  OUTPUT Inserted.sessionId into @tSessionId  
		WHERE fkuserId =@userId and sessionId=@SessionId   
		COMMIT
	END	
	IF exists (SELECT 1 from aspmnx_ActiveUsers where  fkuserId =@userId and oldsessionId=@SessionId)
	BEGIN	
		set @lFound=1
		BEGIN TRANSACTION
		UPDATE aspmnx_ActiveUsers SET lastActivityDate=GETDATE(),
							lastModule = @Module ,
							workstationId =@WorkStationId  OUTPUT Inserted.sessionId into @tSessionId  
		WHERE fkuserId =@userId and oldsessionId=@SessionId 
		COMMIT 
	END	
 --   ;WITH
 --   Upd
 --   as(
 --   SELECT aspmnx_ActiveUsers.pkActiveUsers  from  aspmnx_ActiveUsers (UPDLOCK)
	--	WHERE (sessionId=@SessionId or oldsessionId=@SessionId) and fkuserId =@userId 
	--)	
	--UPDATE aspmnx_ActiveUsers SET lastActivityDate=GETDATE(),
	--						lastModule = @Module ,
	--						workstationId =@WorkStationId  OUTPUT Inserted.sessionId into @tSessionId  
	--	WHERE pkActiveUsers in (SELECT pkActiveUsers from upd)
		
	
	
	--UPDATE aspmnx_ActiveUsers SET lastActivityDate=GETDATE(),
	--						lastModule = @Module ,
	--						workstationId =@WorkStationId  OUTPUT Inserted.sessionId into @tSessionId  WHERE (sessionId=@SessionId or oldsessionId=@SessionId) and fkuserId =@userId
	---- return new information if any
	--select @newSessionId=sessionId 
	--	 FROM aspmnx_ActiveUsers WHERE (sessionId=@SessionId or oldsessionId=@SessionId ) and fkuserId = @UserId
	
	select @newSessionId=sessionId 
		 FROM @tSessionId 
	--10/30/13 log record if not found or @newSessionId is empty
	if @lFound=0 OR @newSessionId =''
		INSERT INTO [ActiveUsers_Delete_Log]
           ([sessionId]
           ,[fkuserId]
           ,[lastActivityDate]
           ,[workstationId]
           ,[lastModule]
           ,[oldsessionId]
           ,[deleteDate]
           ,[pkDeleteLog])
		VALUES
           (@newSessionId 
           ,@UserId
           ,GETDATE()
           ,@WorkStationId
           ,@Module 
           ,@sessionId
           ,GETDATE()
           ,NEWID())

END
-------
