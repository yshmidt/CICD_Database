CREATE PROCEDURE [dbo].[aspmnx_UpdateUserPermissions] 
	-- Add the parameters for the stored procedure here
	@UserId uniqueidentifier , 
	@Suppliers varchar(MAX) = null,
	@Customers varchar(MAX) = null,
	@Groups varchar(MAX) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- validate UserId
	IF @UserId IS NULL OR NOT EXISTS(SELECT Userid from aspnet_Users where UserId=@UserId)
		BEGIN
		RAISERROR('Invalid User Id. This operation will be cancelled.',11,1)
		RETURN -1
		END
	
    -- Insert statements for procedure here
    --CREATE TABLE #temp(id varchar(40))
    -- YS craete table variable for each of the possible values (e.g. suppliers, customers, groups)
    -- 
    DECLARE @tSupplier Table (uniqsupno char(10))
    DECLARE @tCustomer Table (custno char(10))
    DECLARE @tGroups TABLE (groupid uniqueidentifier)
    DECLARE @lRollback bit=0
    
    --If @Suppliers is provided, clear existing records not in the list and add new records
    BEGIN TRY  -- outside begin try
    BEGIN TRANSACTION -- wrap transaction
	IF NOT (@Suppliers IS NULL)
	BEGIN
		--INSERT INTO #temp
		--INSERT INTO @t
		--SELECT	id
		--FROM	fn_simpleVarcharlistToTable(@Suppliers)
		INSERT INTO @tSupplier SELECT CAST(id as CHAR(10)) from fn_simpleVarcharlistToTable(@Suppliers,',')
		
		BEGIN TRY -- inside begin try
			DELETE FROM [dbo].[aspmnx_UserSuppliers] 
			WHERE	fkUserId = @UserId AND fkUniqSupNo NOT IN (SELECT UniqSupno FROM @tSupplier)
		END TRY
		BEGIN CATCH	
			RAISERROR('Probelm during removeing records from aspmnx_UserSuppliers table. 
			Please contact ManEx with detailed information of the action prior to this message.',11,1)
		END CATCH
		-- check if @Suppliers was empty
		IF (@Suppliers<>'')
		BEGIN
		BEGIN TRY		
			INSERT INTO [dbo].[aspmnx_UserSuppliers](fkUserId,fkUniqSupNo)
			SELECT	@UserId, s.UniqSupno
				FROM	@tSupplier as S
				WHERE	S.uniqsupno  NOT IN (SELECT fkUniqSupNo FROM [dbo].[aspmnx_UserSuppliers] WHERE fkUserId = @UserId)
		END TRY
		BEGIN CATCH
			RAISERROR('Probelm during inserting records into aspmnx_UserSuppliers table. 
			Please contact ManEx with detailed information of the action prior to this message.',11,1)
		END CATCH	
		END -- 	IF (@Suppliers<>'')	
		--TRUNCATE TABLE #temp
	END
	
	--If @Customers is provided, clear existing records not in the list and add new records as needed
	IF NOT (@Customers IS NULL)
	BEGIN
		--INSERT INTO #temp
		--INSERT @t
		--SELECT	id
		--FROM	fn_simpleVarcharlistToTable(@Customers)
		
		--DELETE FROM [dbo].[aspmnx_UserCustomers] 
		--WHERE	fkUserId = @UserId AND NOT fkCustno IN (SELECT id FROM @t)
		
		--INSERT INTO [dbo].[aspmnx_UserCustomers](fkUserId,fkCustno)
		--SELECT	DISTINCT @UserId, id
		--FROM	@t
		--WHERE	NOT id IN (SELECT fkCustno FROM [dbo].[aspmnx_UserCustomers] WHERE fkUserId = @UserId)
		INSERT INTO @tCustomer SELECT CAST(id as CHAR(10)) from fn_simpleVarcharlistToTable(@Customers,',')
		BEGIN TRY -- inside begin try
			DELETE FROM [dbo].[aspmnx_UserCustomers] 
			WHERE	fkUserId = @UserId AND fkCustno NOT IN (SELECT custno FROM @tCustomer)
		END TRY
		BEGIN CATCH	
			RAISERROR('Probelm during removeing records from aspmnx_UserCustomers table. 
			Please contact ManEx with detailed information of the action prior to this message.',11,1)
		END CATCH
		-- check if @Customers was empty
		IF (@Customers<>'')
		BEGIN
		BEGIN TRY		
			INSERT INTO [dbo].[aspmnx_UserCustomers](fkUserId,fkCustno)
			SELECT	@UserId, C.Custno
				FROM	@tCustomer C
				WHERE C.custno NOT IN (SELECT fkCustno FROM [dbo].[aspmnx_UserCustomers] WHERE fkUserId = @UserId)
		END TRY
		BEGIN CATCH
			RAISERROR('Probelm during inserting records into aspmnx_UserCustomers table. 
			Please contact ManEx with detailed information of the action prior to this message.',11,1)
		END CATCH		
		END -- IF (@Customers<>'')			
		--TRUNCATE TABLE #temp
	END
	
	--If @Groups is provided, clear existing records not in the list and add new records as needed
	IF NOT (@Groups IS NULL)
	BEGIN
		--INSERT INTO #temp
		--INSERT INTO @t
		--SELECT	CAST(id AS uniqueidentifier)
		--FROM	fn_simpleVarcharlistToTable(@Groups)
					
		--DELETE FROM [dbo].[aspmnx_groupUsers] 
		--WHERE	fkUserId = @UserId AND NOT fkgroupid IN (SELECT id FROM @t)
		
		--INSERT INTO [dbo].[aspmnx_groupUsers] (fkuserid,fkgroupid)
		--SELECT	DISTINCT @UserId, id
		--FROM	@t
		--WHERE	NOT id IN (SELECT fkgroupid FROM [dbo].[aspmnx_groupUsers] WHERE fkUserId = @UserId)
		INSERT INTO @tGroups SELECT CAST(id as uniqueidentifier) from fn_simpleVarcharlistToTable(@Groups,',')
					
		----Get all Roles for current groups
		--CREATE TABLE #groupRoles(id uniqueidentifier)
		--INSERT INTO #groupRoles
		--SELECT fkRoleId
		--FROM aspmnx_GroupRoles
		--WHERE fkGroupId IN (SELECT id FROM #temp)
		
		----Get Role Ids for protected roles
		--CREATE TABLE #superRoles(id uniqueidentifier)	
		--INSERT INTO #superRoles
		--SELECT RoleId
		--FROM aspnet_Roles
		--WHERE RoleName IN ('CompanyAdmin','Super')
		
		
		
		--TRUNCATE TABLE #temp
		--DROP TABLE #groupRoles
		BEGIN TRY -- inside begin try
			DELETE FROM [dbo].[aspmnx_groupUsers] 
			WHERE	fkUserId = @UserId AND fkgroupid NOT IN (SELECT GroupId FROM @tGroups)
						
		END TRY
		BEGIN CATCH	
			RAISERROR('Probelm during removeing records from aspmnx_groupUsers table. 
			Please contact ManEx with detailed information of the action prior to this message.',11,1)
		END CATCH
		-- check if @Groups was empty
		IF (@Groups<>'')
		BEGIN
		BEGIN TRY		
			INSERT INTO [dbo].[aspmnx_groupUsers] (fkuserid,fkgroupid)
				SELECT	DISTINCT @UserId, GroupId
					FROM	@tGroups 
					WHERE GroupId NOT IN (SELECT fkgroupid FROM [dbo].[aspmnx_groupUsers] WHERE fkUserId = @UserId)
		END TRY
		BEGIN CATCH
			RAISERROR('Probelm during inserting records into aspmnx_groupUsers table. 
			Please contact ManEx with detailed information of the action prior to this message.',11,1)
		END CATCH	
		END -- IF (@Groups<>'')	
	END
	COMMIT
	
	END TRY
	BEGIN CATCH
		SET @lRollback=1
		ROLLBACK
		RETURN -1
	END CATCH
	--DROP TABLE #temp		
END
