-- =============================================
-- Author:		David Sharp
-- Create date: 11/22/2011
-- Description:	search users
-- 08/27/13 DS added filter for full results, or any result
-- 10/25/13 DS added PATINDEX for performance and @activeMonthLimit (not used) for consistency in seach sp
-- 11/15/13 DS changed approach to return TOP 15 excluding previous results
-- 05/07/14 DS added ExternalEmp param
-- 03/07/2017 Raviraj P Rename workcenter columns to Department
-- 09/29/17 YS this SP is not working with the new structure . Comment out for now
-- =============================================
CREATE PROCEDURE [dbo].[MnxSearchViewGroups]
	-- Add the parameters for the stored procedure here
	@searchTerm varchar(MAX),
	@searchType int,
	@userId uniqueidentifier,
	@tCustomers UserCompanyPermissions READONLY,
	@tSupplier UserCompanyPermissions READONLY,
	@fullResult bit = 0,
	@activeMonthLimit int = 0,
	@tSearchId tSearchId READONLY,
	@ExternalEmp bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --colNames are the localizatoin keys for the column names returned in the results.
    DECLARE @thisTerm varchar(MAX) = '%' + @searchTerm + '%'
    DECLARE @count int--, @count2 int	
   -- 09/29/17 YS this SP is not working with the new structure . Comment out for now
   /*
    DECLARE @groupTable SearchGroupType
	--DECLARE @userTable SearchUsersType
		
	IF @ExternalEmp = 0
	BEGIN
		INSERT INTO @groupTable	
		SELECT DISTINCT TOP 15 'MnxSearchViewGroups' AS searchProc,groupId AS id, 'Groups' AS [group], 'group' AS [table], 
				'/Admin/Groups/' + CAST(groupId AS varchar(50)) AS [link], groupName, groupDescr
			FROM aspmnx_Groups
			WHERE PATINDEX(@thisTerm,groupName+'  '+groupDescr)>0
				AND NOT groupId IN (SELECT id FROM @tSearchId)
		SET @count = @@ROWCOUNT
		--IF @count > 0 
		SELECT * FROM @groupTable		
		
		--INSERT INTO @userTable
		SELECT DISTINCT TOP 15 'MnxSearchViewGroups' AS searchProc,p.userId AS id, 'Groups' AS [group], 'users' AS [table], 
				'/Admin/Users/' + CAST(p.userId AS varchar(50)) AS [link], p.FirstName + ' ' + p.LastName AS fullName,
				p.workPhone AS phone_f,p.Initials AS INIT_f,p.Department AS WC_a -- 03/07/2017 Raviraj P Rename workcenter columns to Department
			FROM aspnet_Profile p INNER JOIN aspmnx_groupUsers g ON p.UserId = g.fkuserid
			WHERE (g.fkgroupid IN (SELECT id FROM @groupTable))
				AND NOT p.userId IN (SELECT id FROM @tSearchId)
			
		SET @count = @count+@@ROWCOUNT
	END
	--IF @count2 > 0 SELECT * FROM @userTable
	--SET @count = @count + @count2
		
		
		
	---- 08/27/13 DS added filter for full results, or any result
	--IF @fullResult=1
	--BEGIN
	--	INSERT INTO @groupTable	
	--	SELECT	DISTINCT 'MnxSearchViewGroups',groupId AS id, 'Groups' AS [group], 'group' AS [table], '/Admin/Groups/' + CAST(groupId AS varchar(50)) AS [link], groupName, groupDescr
	--		FROM aspmnx_Groups
	--		WHERE PATINDEX(@thisTerm,groupName+'  '+groupDescr)>0
	--	SET @count = @@ROWCOUNT
	--	IF @count > 0
	--		SELECT * FROM @groupTable		
			
	--	INSERT INTO @userTable
	--	SELECT DISTINCT 'MnxSearchViewGroups',p.userId AS id, 'Groups' AS [group], 'users' AS [table], '/Admin/Users/' + CAST(p.userId AS varchar(50)) AS [link], p.FirstName + ' ' + p.LastName AS fullName,p.workPhone,p.Initials,p.workcenter
	--		FROM aspnet_Profile p INNER JOIN aspmnx_groupUsers g ON p.UserId = g.fkuserid
	--		WHERE (g.fkgroupid IN (SELECT id FROM @groupTable))
	--	SET @count2 = @@ROWCOUNT
	--	IF @count2 > 0
	--		SELECT * FROM @userTable
	--	SET @count = @count + @count2
	--END
	--ELSE
	--BEGIN
	--	DECLARE @countTble SearchCountType
	--	INSERT INTO @countTble
	--	SELECT TOP 1 'MnxSearchViewGroups', 'Groups' [group], 'group' [table], '' [link]
	--		FROM aspmnx_Groups
	--		WHERE PATINDEX(@thisTerm,groupName + '  ' + groupDescr)>0
			
	--	INSERT INTO @countTble
	--	SELECT TOP 1 'MnxSearchViewGroups', 'Groups' [group], 'users' [table], '' [link]
	--		FROM aspnet_Profile p INNER JOIN aspmnx_groupUsers g ON p.UserId = g.fkuserid
	--		WHERE (g.fkgroupid IN (SELECT id FROM @groupTable))
	--	SELECT @count = COUNT(*) FROM @countTble
	--	IF @count > 0
	--		SELECT * FROM @countTble
	--END
	*/
	RETURN @count
END