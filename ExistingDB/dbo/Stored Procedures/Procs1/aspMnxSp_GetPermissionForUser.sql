
-- =============================================
-- Author:		Shripati	
-- Create date: 08/10/2017 
-- Description:	Get the Permissions of User  
-- =============================================

CREATE PROCEDURE [dbo].[aspMnxSp_GetPermissionForUser]  
	-- Add the parameters for the stored procedure here
	@UserId uniqueidentifier = null,
	@licenseTypeRoles varchar(MAX) = null
AS
BEGIN
	
	SET NOCOUNT ON;

    IF (@licenseTypeRoles IS NULL OR @licenseTypeRoles = '')
    BEGIN

        DECLARE @tblRolesLte TABLE (roleName varchar(50))
        DECLARE @RolesLte TABLE (ModuleName varchar(100),roleName varchar(100), ModuleId int)
		INSERT INTO @tblRolesLte SELECT CAST(roleName as varchar(50)) from fn_convertToRoleNames('')
	    INSERT INTO @RolesLte SELECT DISTINCT  ISNULL(m.ModuleName,r.Description) as ModuleName ,r.RoleName ,r.ModuleId
		FROM aspmnx_GroupRoles AS gr INNER JOIN aspnet_Roles AS r ON gr.fkRoleId =r.RoleId 
		INNER JOIN aspmnx_groupUsers AS gu ON gu.fkgroupid=gr.fkGroupId
		LEFT JOIN MnxModule m on m.ModuleId=r.ModuleId
		SELECT ModuleName, STUFF((SELECT DISTINCT ',' + RoleName FROM @RolesLte WHERE ModuleName = r.ModuleName
          FOR XML PATH ('')), 1, 1, '')  AS  Roles FROM  @RolesLte r group by ModuleName,ModuleId

	END
	ELSE
	-- 11/17/2011 Added functionality to limit displayed roles based on user license.
	BEGIN	
		DECLARE @tblRoles TABLE (roleName varchar(50))
        DECLARE @Roles TABLE (ModuleName varchar(100),roleName varchar(100), ModuleId int)

		INSERT INTO @tblRoles SELECT CAST(roleName as varchar(50)) from fn_convertToRoleNames(@licenseTypeRoles)
	    INSERT INTO @Roles SELECT DISTINCT  ISNULL(m.ModuleName,r.Description) as ModuleName ,r.RoleName ,r.ModuleId	
		FROM aspmnx_GroupRoles AS gr INNER JOIN aspnet_Roles AS r ON gr.fkRoleId =r.RoleId 
		INNER JOIN aspmnx_groupUsers AS gu ON gu.fkgroupid=gr.fkGroupId
		LEFT JOIN MnxModule m on m.ModuleId=r.ModuleId
		OUTER APPLY (SELECT roleName, CAST(1 as bit) as Permitted FROM @tblRoles WHERE roleName = r.RoleName)Z
		WHERE gu.fkuserid =  @UserId order by ISNULL(m.ModuleName,r.Description)

		SELECT ModuleName, STUFF((SELECT DISTINCT ',' + RoleName FROM @Roles WHERE ModuleName = r.ModuleName
          FOR XML PATH ('')), 1, 1, '')  AS  RoleName FROM  @Roles r group by ModuleName,ModuleId

	END
END

