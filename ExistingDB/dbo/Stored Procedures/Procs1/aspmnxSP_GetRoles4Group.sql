
-- =============================================
-- Author:		Shripati U
-- Create date: 05/27/2016
-- Description:	Get Ordered Roles for group 
-- 09/02/2017 Shripati updated query to get roles by sort order
-- 12/18/2017 Shripati updated query to Special Roles
-- 04/10/2018 Sachin B get the IsSpecial field
-- 04/10/2018 Sachin B Add Temp table PermissionData and Update Code for the grouping of permission
-- 04/08/2019 Raviraj P Get role for special permission and available module
-- 05/16/2019 Shrikant added parameter @Filter to filter grid data 
-- aspmnxSP_GetRoles4Group   '8486e2d0-0dcc-4252-83de-28861626d603','[Description] LIKE ''%Packing List%'' ' 
-- =============================================
CREATE PROCEDURE [dbo].[aspmnxSP_GetRoles4Group] 
	-- Add the parameters for the stored procedure here
	@GroupId UNIQUEIDENTIFIER,
	-- 05/16/2019 Shrikant added parameter @Filter to filter grid data
    @Filter nvarchar(1000) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	-- 09/02/2017 Shripati updated query to get roles by sort order
	SET NOCOUNT ON;
	DECLARE @SQL nvarchar(max);  
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
	--04/10/2018 Sachin B Add Temp table PermissionData and Update Code for the grouping of permission
	,PermissionData AS
	(
		SELECT aspnet_Roles.ModuleId,RoleId,RoleName,
		CASE WHEN IsSpecial=1  AND ModulePath IS NOT NULL THEN [Description] ELSE modules.ModuleName END as [Description],
		ModulePath AS Modules,
		-- 04/10/2018 Sachin B get the IsSpecial field
		ISNULL(Z.Assigned,CAST(0 AS BIT)) AS Assigned ,Sort,IsSpecial 
		FROM aspnet_Roles 
		LEFT JOIN modules ON modules.ModuleId=aspnet_Roles.ModuleId 
		OUTER APPLY (SELECT CAST(1 AS BIT) AS Assigned FROM aspmnx_GroupRoles WHERE fkGroupId = @GroupId AND fkRoleId =aspnet_Roles.roleId ) as Z 
		WHERE IsPermission=1 and IsSpecial=0
	UNION  
		-- 12/18/2017 Shripati updated query to Special Roles
		-- 04/10/2018 Sachin B get the IsSpecial field 
		SELECT modules.ModuleId,RoleId,RoleName,
		CASE WHEN IsSpecial=1 AND ModulePath IS NULL THEN [Description] ELSE aspnet_Roles.Description END AS [Description],
		CASE WHEN IsSpecial=1 AND ModulePath IS NOT NULL THEN ModulePath ELSE [Description] END AS Modules,
		ISNULL(Z.Assigned,CAST(0 AS BIT)) AS Assigned,
		CASE WHEN  modules.ModuleId IS NOT NULL THEN Sort ELSE 'ZZ' END AS Sort
		--'ZZ' as Sort
		,IsSpecial 
		FROM aspnet_Roles
		LEFT JOIN modules on modules.ModuleId=aspnet_Roles.ModuleId 
		OUTER APPLY (SELECT CAST(1 AS BIT) as Assigned FROM aspmnx_GroupRoles WHERE fkGroupId = @GroupId AND fkRoleId =aspnet_Roles.roleId ) AS Z
		WHERE IsSpecial=1 
		--ORDER BY Sort
	)

  SELECT IDENTITY(INT,1,1) AS RowNumber,* INTO #TEMP FROM PermissionData
  
IF @filter <> ''
 BEGIN  
     SET @SQL=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP t WHERE  '+@filter+' order by Sort'  
 END  
ELSE  
 BEGIN  
     SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP t order by Sort ' 
 END  

 EXEC SP_EXECUTESQL @SQL  
END