-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/05/2011
-- Description:	Get list of the roles for a given
-- =============================================
CREATE PROCEDURE [dbo].[aspMnxSp_GetRoles4User]  
	-- Add the parameters for the stored procedure here
	@UserId uniqueidentifier = null,
	@licenseTypeRoles varchar(MAX) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    IF (@licenseTypeRoles IS NULL OR @licenseTypeRoles = '')
    BEGIN
		SELECT DISTINCT r.RoleId,r.RoleName,r.Description	
		FROM aspmnx_GroupRoles AS gr INNER JOIN aspnet_Roles AS r ON gr.fkRoleId =r.RoleId 
		INNER JOIN aspmnx_groupUsers AS gu ON gu.fkgroupid=gr.fkGroupId
		WHERE  (gu.fkuserid =@UserId)
	END
	ELSE
	-- 11/17/2011 Added functionality to limit displayed roles based on user license.
	BEGIN	
		DECLARE @tblRoles TABLE (roleName varchar(50))

		INSERT INTO @tblRoles SELECT CAST(roleName as varchar(50)) from fn_convertToRoleNames(@licenseTypeRoles)

		--I added DISTINCT because it was duplicating assigned Roles
		SELECT DISTINCT r.RoleId,r.RoleName,r.Description,isnull(Z.Permitted,cast(0 as bit)) as Permitted	
		FROM aspmnx_GroupRoles AS gr INNER JOIN aspnet_Roles AS r ON gr.fkRoleId =r.RoleId 
		INNER JOIN aspmnx_groupUsers AS gu ON gu.fkgroupid=gr.fkGroupId
		OUTER APPLY (SELECT roleName, CAST(1 as bit) as Permitted FROM @tblRoles WHERE roleName = r.RoleName)Z
		WHERE gu.fkuserid = @UserId
		
		----This shows only assigned roles
		--SELECT r.RoleId,r.RoleName,r.Description	
		--FROM aspmnx_GroupRoles AS gr INNER JOIN aspnet_Roles AS r ON gr.fkRoleId =r.RoleId 
		--INNER JOIN aspmnx_groupUsers AS gu ON gu.fkgroupid=gr.fkGroupId
		--WHERE  (gu.fkuserid =@UserId) AND (r.RoleName IN (SELECT RoleName FROM @tblRoles))
		
		
			--SELECT Groupid,groupName,groupDescr ,isnull(Z.Assigned,cast(0 as bit)) as Assigned	  
	--from aspmnx_Groups OUTER APPLY (SELECT CAST(1 as bit) as Assigned from aspmnx_groupUsers where fkUserId = @UserId and fkgroupid =aspmnx_Groups.groupId ) as Z  

	END
	   
END