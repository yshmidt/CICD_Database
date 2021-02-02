-- =============================================
-- Author:		Shripati
-- Create date: 07/06/2017 
-- Description:	update Group Role
-- =============================================
CREATE PROCEDURE [dbo].[aspmnx_GroupRoleUpdate] 
	-- Add the parameters for the stored procedure here
	@Groupid uniqueidentifier , 
	@Roles varchar(MAX) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --If @Suppliers is provided, clear existing records not in the list and add new records
    IF NOT (@Roles IS NULL)
	BEGIN
		DECLARE @tRoles Table (RoleId uniqueidentifier)
		
		INSERT INTO @tRoles
		SELECT	CAST(id as uniqueidentifier)
		FROM	fn_simpleVarcharlistToTable(@Roles,',')
		
		BEGIN TRY
		
			BEGIN TRANSACTION
			BEGIN TRY
				DELETE FROM [dbo].[aspmnx_GroupRoles] 
				WHERE	fkGroupId = @Groupid AND fkRoleId NOT IN (SELECT RoleId FROM @tRoles)
			END TRY
			BEGIN CATCH	
				RAISERROR('Probelm during removeing records from aspmnx_GroupRoles table. 
				Please contact ManEx with detailed information of the action prior to this message.',11,1)
			END CATCH
			BEGIN TRY
				INSERT INTO [dbo].[aspmnx_GroupRoles](fkGroupId,fkRoleId)
				SELECT	@Groupid, RoleId
				FROM	@tRoles 
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
				
		--DROP TABLE #temp
	
END