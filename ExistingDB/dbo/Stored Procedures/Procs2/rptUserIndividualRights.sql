
-- =============================================
-- Author:		Debbie
-- Create date: 11/20/15
-- Description:	Created for the users Rights Report
-- Reports:		rights
-- Modified:	
-- 03/25/20 VL: Re-create user rights reports for cube version
-- =============================================

CREATE PROCEDURE  [dbo].[rptUserIndividualRights]
 

--declare 

@lcUser varchar(max) = 'All'
,@userId uniqueidentifier=null	

AS
BEGIN

/*USER LIST*/		
	DECLARE @User AS TABLE(UserId uniqueidentifier )

	IF @lcUser IS NOT NULL AND @lcUser <>'' AND @lcUser<>'All'
			INSERT INTO @User select * from dbo.[fn_simpleVarcharlistToTable](@lcUser,',')
					
	ELSE
		IF  @lcUser='All'	
		BEGIN
			INSERT INTO @User SELECT userid FROM aspnet_Profile
		END	

		--select * from @user



	/*RECORD SELECTION SECTION*/
	DECLARE @UserRight TABLE(UserId uniqueidentifier, UserName varchar(100), Description nvarchar(256), RoleName nvarchar(256), Checked char(1), ModuleId int)
	DECLARE @UserRightPivot TABLE (UserId uniqueidentifier, UserName varchar(100), Description nvarchar(256), [View] char(1), [Add] char(1), [Edit] char(1), [Delete] char(2), [Setup] char(1), 
		[Reports] char(1), [Tools] char(1), [Other] char(1), [SuperUser] char(1), ModuleId int, [Sort] varchar(256), ModulePath varchar(250))

	INSERT INTO @UserRight
	SELECT DISTINCT UserID, LTRIM(RTRIM(P.Firstname))+ ' ' + LTRIM(RTRIM(P.Lastname)) AS UserName, 
			CASE WHEN IsSpecial = 1 THEN r.Description ELSE ModuleName END AS Description, CASE WHEN IsSpecial = 1 THEN 'Other' ELSE r.RoleName END AS RoleName, 'Y' AS Checked, MnxModule.ModuleId
			FROM aspmnx_GroupRoles AS gr INNER JOIN aspnet_Roles AS r ON gr.fkRoleId =r.RoleId 
			INNER JOIN aspmnx_groupUsers AS gu ON gu.fkgroupid=gr.fkGroupId
			LEFT OUTER JOIN MnxModule ON MnxModule.ModuleId = r.ModuleId
			INNER JOIN aspnet_Profile P ON P.UserId = gu.fkuserid 
			WHERE EXISTS(SELECT 1 FROM @User U WHERE U.UserId = gu.fkuserid)

	INSERT INTO @UserRightPivot 
	SELECT UserId, UserName, Description, ISNULL([View],' ') AS [View],ISNULL([Add],' ') AS [Add],ISNULL([Edit],' ') AS [Edit],ISNULL([Delete],' ') AS [Delete],ISNULL([Setup],' ') AS [Setup],ISNULL([Reports],' ') AS [Reports],
		ISNULL([Tools],' ') AS [Tools],ISNULL([Other],' ') AS [Other],'' AS SuperUser, ModuleId, '' AS Sort, '' AS ModulePath
		FROM @UserRight
		pivot(MAX(Checked) FOR RoleName IN([View],[Add],[Edit],[Delete],[Setup],[Reports],[Tools],[Other])
		) as p

	INSERT INTO @UserRightPivot 
	SELECT UserId, LTRIM(RTRIM(P.Firstname))+ ' ' + LTRIM(RTRIM(P.Lastname)) AS UserName, 'SCM Super User' AS Description, '' AS [View], '' AS [Add], '' AS [Edit], '' AS [Delete], '' AS Setup, '' AS Reports, '' AS Tools, '' AS Other, 'Y' AS SuperUser, 0 AS ModuleId, '' AS Sort, '' AS ModulePath
		FROM aspnet_Profile P
		WHERE ScmAdmin = 1
		AND EXISTS(SELECT 1 FROM @User U WHERE U.UserId = P.UserId)
	UNION ALL
	SELECT UserId, LTRIM(RTRIM(P.Firstname))+ ' ' + LTRIM(RTRIM(P.Lastname)) AS UserName, 'MFG Super User' AS Description, '' AS [View], '' AS [Add], '' AS [Edit], '' AS [Delete], '' AS Setup, '' AS Reports, '' AS Tools, '' AS Other, 'Y' AS SuperUser, 0 AS ModuleId, '' AS Sort, '' AS ModulePath
		FROM aspnet_Profile P
		WHERE ProdAdmin = 1
		AND EXISTS(SELECT 1 FROM @User U WHERE U.UserId = P.UserId)
	UNION ALL
	SELECT UserId, LTRIM(RTRIM(P.Firstname))+ ' ' + LTRIM(RTRIM(P.Lastname)) AS UserName, 'ENG Super User' AS Description, '' AS [View], '' AS [Add], '' AS [Edit], '' AS [Delete], '' AS Setup, '' AS Reports, '' AS Tools, '' AS Other, 'Y' AS SuperUser, 0 AS ModuleId, '' AS Sort, '' AS ModulePath
		FROM aspnet_Profile P
		WHERE EngAdmin = 1
		AND EXISTS(SELECT 1 FROM @User U WHERE U.UserId = P.UserId)
	UNION ALL
	SELECT UserId, LTRIM(RTRIM(P.Firstname))+ ' ' + LTRIM(RTRIM(P.Lastname)) AS UserName, 'S,G&A Super User' AS Description, '' AS [View], '' AS [Add], '' AS [Edit], '' AS [Delete], '' AS Setup, '' AS Reports, '' AS Tools, '' AS Other, 'Y' AS SuperUser, 0 AS ModuleId, '' AS Sort, '' AS ModulePath
		FROM aspnet_Profile P
		WHERE AcctAdmin = 1
		AND EXISTS(SELECT 1 FROM @User U WHERE U.UserId = P.UserId)
	UNION ALL
	SELECT UserId, LTRIM(RTRIM(P.Firstname))+ ' ' + LTRIM(RTRIM(P.Lastname)) AS UserName, 'Admin Super User' AS Description, '' AS [View], '' AS [Add], '' AS [Edit], '' AS [Delete], '' AS Setup, '' AS Reports, '' AS Tools, '' AS Other, 'Y' AS SuperUser, 0 AS ModuleId, '' AS Sort, '' AS ModulePath
		FROM aspnet_Profile P
		WHERE CompanyAdmin = 1
		AND EXISTS(SELECT 1 FROM @User U WHERE U.UserId = P.UserId)
	UNION ALL
	SELECT UserId, LTRIM(RTRIM(P.Firstname))+ ' ' + LTRIM(RTRIM(P.Lastname)) AS UserName, 'Corrective & Preventative Action (CAPA) Super User' AS Description, '' AS [View], '' AS [Add], '' AS [Edit], '' AS [Delete], '' AS Setup, '' AS Reports, '' AS Tools, '' AS Other, 'Y' AS SuperUser, 0 AS ModuleId, '' AS Sort, '' AS ModulePath
		FROM aspnet_Profile P
		WHERE CAPAAdmin = 1
		AND EXISTS(SELECT 1 FROM @User U WHERE U.UserId = P.UserId)
	UNION ALL
	SELECT UserId, LTRIM(RTRIM(P.Firstname))+ ' ' + LTRIM(RTRIM(P.Lastname)) AS UserName, 'Project/Tasks Super User' AS Description, '' AS [View], '' AS [Add], '' AS [Edit], '' AS [Delete], '' AS Setup, '' AS Reports, '' AS Tools, '' AS Other, 'Y' AS SuperUser, 0 AS ModuleId, '' AS Sort, '' AS ModulePath
		FROM aspnet_Profile P
		WHERE ProjectsTasks = 1
		AND EXISTS(SELECT 1 FROM @User U WHERE U.UserId = P.UserId)

	;WITH modules AS
	(
			SELECT 0  AS ParentModule ,ModuleId,ModuleName,ModuleDesc,FileType,IsPermission,
			CAST(ModuleName AS VARCHAR(MAX)) AS ModulePath,
			CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY moduleid) AS VARCHAR(MAX))),4,'0') AS VARCHAR(MAX)) AS Sort
   FROM MnxModule WHERE filetype=1  and (IsModuleShow = 1 OR IsModuleShow IS NULL) --04/08/2019 Raviraj P Get role for special permission and available module
		UNION ALL
			SELECT m.ModuleId AS ParentModule,msub.ModuleId,msub.ModuleName,msub.ModuleDesc,msub.FileType,msub.IsPermission,
			RTRIM(m.ModulePath)+'>'+CAST(msub.ModuleName AS VARCHAR(MAX)) AS ModulePath ,
			CAST(RTRIM(m.Sort)+'-'+	dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY r.ModuleOrder) AS VARCHAR(4))),4,'0') AS VARCHAR(MAX)) AS Sort
			FROM modules m 
			INNER JOIN  MnxModuleRelationship R ON M.ModuleId=R.ParentId
			INNER JOIN MnxModule msub ON msub.ModuleId=r.ChildId
  WHERE msub.IsModuleShow = 1 OR msub.IsModuleShow IS NULL --04/08/2019 Raviraj P Get role for special permission and available module
	)
	UPDATE @UserRightPivot SET Sort = m.Sort, ModulePath = m.ModulePath FROM modules m WHERE [@UserRightPivot].ModuleId = m.ModuleId

	SELECT UserName, ModulePath, Description, [View],[Add],[Edit],[Delete],[Setup],[Reports],[Tools],[Other],[SuperUser],[UserId],[Sort] from @UserRightPivot ORDER BY UserName,SuperUser DESC, Sort

END