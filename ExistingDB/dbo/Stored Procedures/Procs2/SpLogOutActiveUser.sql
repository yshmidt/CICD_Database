-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/09/13 
-- Description:	Remove users when log out. Also can be used to remove all users
--	@SessionId uniqueidentifier - session id of the session that has to be removed, 
--	@UserId uniqueidentifier - user id of the user that has to be removed in combination with session id
--	@lRemoveAll bit  - lRemoveAll=0 ignore this parameter , if = 1 - remove all users and ignore sessionid ad userid
-- 07/16/13 YS search for sesionid or olsessionid
-- 07/18/13 YS make @UserID as varch(36) instead of uniqueidentifier
-- 09/24/13 YS accept @sessionid and @userid as  CSV. also if only @sessionid or @userid is provided remove all records for given @sessionid or all records for given @userid
-- 10/24/13 DS changed @sessionId and @userId to @sessionIds and @userIds, added @keepLast, and @sessionId to allow the preservation of an active session 
-- =============================================
CREATE PROCEDURE [dbo].[SpLogOutActiveUser]
	-- Add the parameters for the stored procedure here
	@SessionIds varchar(max) = null,
	@UserIds  varchar(max)= null,
	@lRemoveAll bit = 0,
	@keepLast bit = 0,
	@sessionId varchar(36)='' 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	if (@lRemoveAll =1)
		BEGIN
		-- remove all users
		
		BEGIN TRY
			DELETE FROM aspmnx_ActiveUsers
		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK
		END CATCH
	END	  --- if (@lRemoveAll =1)
	ELSE
	BEGIN	 --- else for if (@lRemoveAll =1)
		--09/24/13 YS allow CSV. if one of the parameter null remove all records based on the none null parameter
		DECLARE @tSessions table (sessionid varchar(36)) ;
		DECLARE @tUsers table (Userid uniqueidentifier) ;
		IF @SessionIds is not null and @SessionIds <> ''
			INSERT INTO @tSessions SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@SessionIds,',')
		IF @UserIds is not null and @UserIds<>''
			INSERT INTO @tUsers SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@UserIds,',')
			
		BEGIN TRY
		-- 07/16/13 YS search for sesionid or olsessionid
		-- 10/24/13 DS added handling for clearning all users by passing empty strings for users and sessions
		--10/25/13/ YS trying a liitle different and or logic
		DELETE FROM aspmnx_ActiveUsers WHERE 
		1=CASE WHEN (@SessionIds is null or @SessionIds = '') and @UserIds is not null and @UserIds <> ''
				and fkuserId IN (SELECT Userid from  @tUsers) and sessionId<>@sessionId THEN 1
			when (@UserIds is null or @UserIds = '') and @SessionIds is not null and @SessionIds <> ''
				and (sessionId in (SELECT sessionid from @tSessions) or oldsessionId in (SELECT sessionid from @tSessions)) THEN 1
			when @UserIds is not null and @UserIds <>'' and @SessionIds is not null and @SessionIds <>''
				and fkuserId IN (SELECT Userid from  @tUsers) 
				and (sessionId in (SELECT sessionid from @tSessions) or oldsessionId in (SELECT sessionid from @tSessions)) THEN 1 
			when (@userIds = '' or @userIds IS null) and (@sessionIds = '' OR @sessionIds IS null) and sessionId<>@sessionId THEN 1 ELSE 0 END 
		
		
		--DELETE FROM aspmnx_ActiveUsers WHERE 
		--1=CASE WHEN (@SessionIds is null or @SessionIds = '') and (@UserIds is not null or @UserIds <> '')
		--		and fkuserId IN (SELECT Userid from  @tUsers) and sessionId<>@sessionId THEN 1
		--	when (@UserIds is null or @UserIds = '') and (@SessionIds is not null or @SessionIds <> '')
		--		and (sessionId in (SELECT sessionid from @tSessions) or oldsessionId in (SELECT sessionid from @tSessions)) THEN 1
		--	when @UserIds is not null and @UserIds <>'' and @SessionIds is not null and @SessionIds <>''
		--		and fkuserId IN (SELECT Userid from  @tUsers) 
		--		and (sessionId in (SELECT sessionid from @tSessions) or oldsessionId in (SELECT sessionid from @tSessions)) THEN 1 
		--	when @userIds = '' and @sessionIds = '' and sessionId<>@sessionId THEN 1 ELSE 0 END 
			 
		END TRY
		BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK
		END CATCH
	END  --- if (@lRemoveAll =1)
		
	IF @@TRANCOUNT>0
			COMMIT	
		
	
END
