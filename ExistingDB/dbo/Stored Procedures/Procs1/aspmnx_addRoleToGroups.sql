-- =============================================
-- Author:		David Sharp
-- Create date: 12/13/2011
-- Description:	adds role to list of groups
-- =============================================
CREATE PROCEDURE [dbo].[aspmnx_addRoleToGroups] 
	-- Add the parameters for the stored procedure here
	@roleName varchar(50),
	@Groups varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here	
	DECLARE @tGroups TABLE (groupid uniqueidentifier)
    DECLARE @lRollback bit=0
    DECLARE @roleId uniqueidentifier
 
	-- validate Role Name
	SELECT @roleId = roleId from aspnet_Roles where RoleName=@roleName
	IF @roleId IS NULL
		BEGIN
		RAISERROR('Invalid Role Name. This operation will be cancelled.',11,1)
		RETURN -1
		END

	BEGIN TRY  -- outside begin try
		--BEGIN TRANSACTION -- wrap transaction
			INSERT INTO @tGroups SELECT CAST(id as uniqueidentifier) from fn_simpleVarcharlistToTable(@Groups,',')

			BEGIN TRY -- inside begin try
				DELETE FROM [dbo].[aspmnx_GroupRoles] 
				WHERE	fkRoleId = @roleId AND fkgroupid NOT IN (SELECT GroupId FROM @tGroups)
							
			END TRY
			BEGIN CATCH	
				RAISERROR('Probelm during removeing records from aspmnx_GroupRoles table. 
				Please contact ManEx with detailed information of the action prior to this message.',11,1)
			END CATCH
			-- check if @Groups was empty
			IF (@Groups<>'')
			BEGIN
				BEGIN TRY		
					INSERT INTO [dbo].[aspmnx_GroupRoles] (fkRoleId,fkgroupid)
						SELECT	DISTINCT @roleId, GroupId
							FROM	@tGroups 
							WHERE GroupId NOT IN (SELECT fkgroupid FROM [dbo].[aspmnx_GroupRoles] WHERE fkRoleId = @roleId)
				END TRY
				BEGIN CATCH
					RAISERROR('Probelm during inserting records into aspmnx_GroupRoles table. 
					Please contact ManEx with detailed information of the action prior to this message.',11,1)
				END CATCH	
			END
		--COMMIT
	END TRY
	BEGIN CATCH
		SET @lRollback=1
		ROLLBACK
		RETURN -1
	END CATCH
END