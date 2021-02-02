-- =============================================
-- Author:		Yelena
-- Create date: 12/01/2012
-- Description:	Return aspnet user id based on the webauth
-- 07/10/13 DS Modified to allow for additional methods of getting the userId
-- 01/02/13 SL Added apikey to the user profile
-- =============================================
CREATE FUNCTION [dbo].[fn_GetAspNetUserID]
(
	-- Add the parameters for the function here
	@checkCode varchar(100),
	@codeType varchar(50)
)
RETURNS uniqueidentifier
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar uniqueidentifier=null

	-- Add the T-SQL statements to compute the return value here
	IF @codeType = 'webAuth'
		SELECT @ResultVar= fk_aspnetUsers FROM Users where webauth = @checkCode
	ELSE IF @codeType = 'badgecode'
		SELECT @ResultVar= UserId FROM aspnet_Profile where badgeCode = @checkCode
	-- 07/10/13 DS added session option
	ELSE IF @codeType = 'session'
		SELECT @ResultVar= fkuserId FROM aspmnx_ActiveUsers where sessionId = @checkCode
    -- 12/12/13 Santosh L added for apikey
    ELSE IF @codeType = 'apikey'
		SELECT @ResultVar= UserId FROM aspnet_Profile where ApiKey = @checkCode
	-- Return the result of the function
	RETURN @ResultVar

END