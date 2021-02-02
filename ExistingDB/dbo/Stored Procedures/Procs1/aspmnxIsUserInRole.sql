
CREATE PROCEDURE [dbo].[aspmnxIsUserInRole]
    @UserId    uniqueidentifier=null,
    @RoleId    uniqueidentifier=null,
    @SuperUserCode int = 1
AS
BEGIN
   DECLARE @SuperAccountUser bit =0,@SuperUser bit =0,@SuperProdUser bit=0
   
   -- if @SuperUserCode =1 then superuser, if = 2 then SuperAccountUser, default to 1
   --- check if the user has any super power
		
	SELECT @SuperAccountUser=AcctAdmin,@SuperUser=CompanyAdmin,@SuperProdUser=ProdAdmin FROM aspnet_Profile where aspnet_Profile.UserId = @UserId 
	IF (@UserId IS NULL)
		RETURN (0)
	IF (@RoleId IS NULL)
		RETURN (0)	
	IF @SuperUserCode=1 and @SuperUser=1-- Super company
		RETURN (1)
	IF 	@SuperUserCode=2 and @SuperAccountUser=1
		RETURN (1)	
   	IF (EXISTS (SELECT aspmnx_GroupRoles.fkRoleId 
			FROM aspmnx_GroupRoles inner join aspmnx_groupUsers on aspmnx_GroupRoles.fkGroupId=aspmnx_groupUsers.fkgroupid
			WHERE aspmnx_groupUsers.fkuserid =@UserId 
			and aspmnx_GroupRoles.fkRoleId =@RoleId))
		RETURN (1)
	ELSE
   		RETURN (0)
   
   
	
END