CREATE PROC [dbo].[CracteamView] @lcCarno  AS char(10) = ' '
AS
BEGIN
	SELECT LTRIM(RTRIM(Users.name))+', '+LTRIM(RTRIM(Users.firstname)) AS Name, CRACTEAM.*
		FROM CRACTEAM, Users
		WHERE Cracteam.CRMEMBER = Users.USERID
		AND TMCARNO = @lcCarno
		ORDER BY Name, users.FIRSTNAME
END
