
-- =============================================
-- Author:		Shripati
-- Create date: 07/06/2017 
-- Description:	Get modules roles for user
-- =============================================
CREATE procedure [dbo].[aspmnxSP_GetModuleRole]
-- Add the parameters for the stored procedure here
@Userid uniqueidentifier , 
@ModuleName VARCHAR(50),
@RoleName   VARCHAR(30)

As
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
BEGIN
SELECT RoleName,
    isnull(Z.Assigned,cast(0 as bit)) as Assigned	  
	from aspnet_Roles ar
	INNER join aspnet_Users u on u.UserId= @Userid
	LEFT join aspmnx_groupUsers gu on gu.fkuserid = u.UserId  
	OUTER APPLY (SELECT CAST(1 as bit) as Assigned from aspmnx_GroupRoles gr where fkGroupId = gu.fkGroupId AND fkRoleId =ar.roleId  ) as Z 
	where ar.ModuleId =(select ModuleId from MnxModule where ModuleName=@moduleName) and RoleName=@RoleName
END
