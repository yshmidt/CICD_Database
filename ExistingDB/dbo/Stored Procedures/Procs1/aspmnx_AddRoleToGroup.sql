-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/06/2011
-- Description:	Assign Role to a group
-- =============================================
CREATE PROCEDURE [dbo].[aspmnx_AddRoleToGroup] 
	-- Add the parameters for the stored procedure here
	@Groupid uniqueidentifier , 
	@RoleId uniqueidentifier
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --GroupRoleId will be auto generated
	INSERT INTO aspmnx_GroupRoles (fkGroupId,fkRoleId) VALUES (@groupId,@RoleId);
	
END