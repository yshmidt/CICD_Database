
-- =============================================
-- Author:		
-- Create date: 
-- Description:	Get list of the Groups
-- 07/06/2017 Shripati for Remove GroupDescr column 
-- =============================================
CREATE PROCEDURE [dbo].[aspmnxSP_GetGroups4Role]
	-- Add the parameters for the stored procedure here
	@roleName varchar(255)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @roleId uniqueidentifier
	SELECT @roleId = roleId FROM aspnet_Roles WHERE RoleName = @roleName
		
	--I tried to copy the format you used in the user sp
	-- 07/06/2017 Shripati for Remove GroupDescr column 
	SELECT groupId, groupName,isnull(Z.Assigned,cast(0 as bit)) as Assigned	
	FROM aspmnx_Groups OUTER APPLY (SELECT CAST(1 as bit) as Assigned from aspmnx_GroupRoles where fkGroupId = aspmnx_Groups.groupId AND fkRoleId =@roleId ) as Z  
	 
END