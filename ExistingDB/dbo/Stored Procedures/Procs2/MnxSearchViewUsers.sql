-- =============================================
-- Author:		David Sharp
-- Create date: 11/22/2011
-- Description:	search users
-- 08/27/13 DS added filter for full results, or any result
-- 10/25/13 DS added PATINDEX for performance and @activeMonthLimit (not used) for consistency in seach sp
-- 11/15/13 DS changed approach to return TOP 15 excluding previous results
-- 05/07/14 DS Added ExternalEmp param
-- 12/10/14 DS modified the search term
-- 03/07/2017 Raviraj P Rename workcenter columns to Department
-- =============================================
CREATE PROCEDURE [dbo].[MnxSearchViewUsers]
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
    DECLARE @thisTerm varchar(MAX) = '%' + @searchTerm + '%'
    DECLARE @count int
    --colNames are the localizatoin keys for the column names returned in the results.
    --DECLARE @table SearchUsersType

	--INSERT INTO @table
	IF @ExternalEmp = 0
	BEGIN
		SELECT	'MnxSearchViewUsers' as searchProc,CAST(m.UserId AS varchar(50))AS id,'Users' AS [group], 'contacts_f' AS [table], 
				'/Admin/Users/' + CAST(m.UserId AS varchar(50)) AS [link], 
				p.FirstName + ' ' + p.LastName AS fullName,p.workPhone AS phone_f,p.Initials AS INIT_f, p.Department AS WC_a -- 03/07/2017 Raviraj P Rename workcenter columns to Department
			FROM	aspnet_Profile AS p INNER JOIN aspnet_Membership AS m ON p.UserId = m.UserId
			WHERE PATINDEX(@thisTerm,
					m.Email+'  '+
					p.FirstName+'  '+
					p.LastName)>0
				AND NOT m.UserId IN (SELECT id FROM @tSearchId)
	END
	SET @count = @@ROWCOUNT
	--IF @count > 0 SELECT * FROM @table
			
			
	---- 08/27/13 DS added filter for full results, or any result
	--IF @fullResult=1
	--BEGIN
	--	INSERT INTO @table
	--	SELECT	'MnxSearchViewUsers',CAST(m.UserId AS varchar(50))AS id,'Users' AS [group], 'contacts_f' AS [table], '/Admin/Users/' + CAST(m.UserId AS varchar(50)) AS [link], 
	--			p.FirstName + ' ' + p.LastName AS f1,p.workPhone,p.Initials, p.workcenter
	--		FROM	aspnet_Profile AS p INNER JOIN aspnet_Membership AS m ON p.UserId = m.UserId
	--		WHERE PATINDEX(@searchTerm,
	--				m.Email+'  '+
	--				p.FirstName+'  '+
	--				p.LastName)>0
	--	SET @count = @@ROWCOUNT
	--	IF @count > 0
	--		SELECT * FROM @table	
	--END
	--ELSE
	--BEGIN
	--	DECLARE @countTble SearchCountType
	--	INSERT INTO @countTble
	--	SELECT TOP 1 'MnxSearchViewUsers','Users' [table], 'contacts_f' [table], '' [link]
	--		FROM aspnet_Profile AS p INNER JOIN aspnet_Membership AS m ON p.UserId = m.UserId
	--		WHERE PATINDEX(@searchTerm,
	--				m.Email+'  '+
	--				p.FirstName+'  '+
	--				p.LastName)>0
	--	SELECT @count =count(*) FROM @countTble
	--	IF @count > 0
	--		SELECT * FROM @countTble
	--END	
	RETURN @count
END