-- =============================================
-- Author:	Shripati	
-- Create date: 07/06/2017 
-- Description:	update group name
-- 05/10/19 Shrikant remove parameter @GroupDescription to fix the issue of SYS > User Access Info > Group Setup > Group name does not retain changes if I edit the name of the group.
-- 07/06/2017 Shripati for Remove GroupDescr column 
-- aspmnx_GroupUpdate '8dd813b9-c057-4962-a416-b8fa8a4d4dcb', 'woModuletest'
-- =============================================

CREATE PROCEDURE [dbo].[aspmnx_GroupUpdate] 
	-- Add the parameters for the stored procedure here
	@Groupid uniqueidentifier , 
	@GroupName varchar(250),
	-- 07/06/2017 Shripati for Remove GroupDescr column 
   --- 06/13/18 YS the description is removed  
   -- 05/10/19 Shrikant remove parameter @GroupDescription to fix the issue of SYS > User Access Info > Group Setup > Group name does not retain changes if I edit the name of the group.
	--@GroupDescription varchar(250),
	@Roles varchar(MAX) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/06/2017 Shripati for Remove GroupDescr column 
        UPDATE aspmnx_Groups SET GroupName = @GroupName  
   --- 06/13/18 YS the description is removed  
   --GroupDescr = @GroupDescription   
   WHERE GroupId=@groupId;  
	
    --If @Suppliers is provided, clear existing records not in the list and add new records  
    IF NOT (@Roles IS NULL)  
 BEGIN  
  DECLARE @tRoles Table (RoleId uniqueidentifier)  
  --CREATE TABLE #temp(id varchar(40))  
    
  --INSERT INTO #temp  
  --SELECT id  
  --FROM fn_simpleVarcharlistToTable(@Roles)  
  INSERT INTO @tRoles  
  SELECT CAST(id as uniqueidentifier)  
  FROM fn_simpleVarcharlistToTable(@Roles,',')  
    
  BEGIN TRY  
    
   BEGIN TRANSACTION  
   BEGIN TRY  
    DELETE FROM [dbo].[aspmnx_GroupRoles]   
    WHERE fkGroupId = @Groupid AND fkRoleId NOT IN (SELECT RoleId FROM @tRoles)  
   END TRY  
   BEGIN CATCH   
    RAISERROR('Probelm during removeing records from aspmnx_GroupRoles table.   
    Please contact ManEx with detailed information of the action prior to this message.',11,1)  
   END CATCH  
   BEGIN TRY  
    INSERT INTO [dbo].[aspmnx_GroupRoles](fkGroupId,fkRoleId)  
    SELECT @Groupid, RoleId  
    FROM @tRoles   
    WHERE RoleId NOT IN (SELECT fkRoleId FROM [dbo].[aspmnx_GroupRoles] WHERE fkGroupId = @Groupid)  
   END TRY  
   BEGIN CATCH   
    RAISERROR('Probelm during inserting records into aspmnx_GroupRoles table.   
    Please contact ManEx with detailed information of the action prior to this message.',11,1)  
   END CATCH  
   commit   
  END TRY  
  BEGIN CATCH  
   ROLLBACK TRANSACTION  
   RETURN -1  
  END CATCH   
END


END