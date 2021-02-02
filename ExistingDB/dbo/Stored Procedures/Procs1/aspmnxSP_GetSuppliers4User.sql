-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <10/03/2011>
-- Description:	Get Supplier List assigned to a user
-- All Active Suppliers assigned to a given user
-- 05/07/14 DS Added external employee param
-- 05/13/14 DS Added ability to not pass the ExternalEmp and have it get it from the userid
-- 05/27/14 YS added ability to show inactive suppliers. New parameter showStatus can have the following values
-- 12/12/14 DS Added supplier status to allow for filtering the suppliers by status
--- showStatus = 'Active' (default) - show only Active customers
--- showStatus = 'Inactive' - show only Inactive customers
--- showStatus = 'All' - show all customers
--- supllier couls have the following status that is hard coded by manEx
/*APPROVED  =   Active     
PREFERED    =	Active      
DISQUALIFIED =  Inactive     
INACTIVE   = Inactive         
PROBATION   = Active        
UNDER EVALUATION   = Active  
*/
--- 07/11/18 YS supname increased from 30 to 50
-- =============================================
CREATE PROCEDURE [dbo].[aspmnxSP_GetSuppliers4User]
	-- Add the parameters for the stored procedure here
	@UserId uniqueidentifier=NULL,
	@ExternalEmp bit = NULL,
	@supplierStatus char(8)='Active'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
   	 -- Insert statements for procedure here
    -- 2. show only assigned customers if users is external
    -- 3. show all the customers if user is internal and no customers has been assigned  
  	-- check if the users is internal or external
	--- 07/11/18 YS supname increased from 30 to 50
  	DECLARE @tSupplier Table (UniqSupno char(10),SUPNAME char(50))
	IF @ExternalEmp IS NULL
		--06/10/14 YS if userid is null (not provided), we need to make sure that we do not return all the customers
		-- will assign 1 to @externalEmp that way no customers will be returned. if userid=null, the select below return no records, so no value assigned to
		-- @externalEmp. To work around assign 1 prior to running the select
		set @ExternalEmp =1
  		SELECT @ExternalEmp = ExternalEmp FROM aspnet_Profile WHERE UserId=@UserId
  	

  	IF (@ExternalEmp =1) -- outside employee select only assigned customer
  		INSERT INTO @tSupplier SELECT Supinfo.UniqSupno,Supinfo.SUPNAME 	
			FROm Supinfo INNER JOIN aspmnx_UserSuppliers  ON  aspmnx_UserSuppliers.fkUniqSupNo =Supinfo.UNIQSUPNO  
			WHERE fkUserId = @UserId 
			-- 05/27/14 YS added ability to show inactive suppliers. New parameter showStatus can have the following values
			AND 1 = CASE WHEN @supplierStatus='Active' and (Supinfo.[Status]<>'INACTIVE' and Supinfo.[Status]<>'DISQUALIFIED') THEN 1
						WHEN @supplierStatus='Inactive' and (Supinfo.[Status]='INACTIVE' OR Supinfo.[Status]='DISQUALIFIED')  THEN 1
						WHEN @supplierStatus = 'All' THEN 1 ELSE 0 END
	ELSE -- (@ExternalEmp <>1)
	BEGIN
		INSERT INTO @tSupplier SELECT Supinfo.UniqSupno,Supinfo.SUPNAME 	
			FROm Supinfo INNER JOIN aspmnx_UserSuppliers  ON  aspmnx_UserSuppliers.fkUniqSupNo =Supinfo.UNIQSUPNO  
			WHERE fkUserId = @UserId 
		IF @@ROWCOUNT = 0 
		BEGIN
			-- get all the customers
			INSERT INTO  @tSupplier SELECT Supinfo.UniqSupno,Supinfo.SUPNAME 
				FROM Supinfo
				-- 05/27/14 YS added ability to show inactive suppliers. New parameter showStatus can have the following values
				WHERE 1 = CASE WHEN @supplierStatus='Active' and (Supinfo.[Status]<>'INACTIVE' and Supinfo.[Status]<>'DISQUALIFIED') THEN 1
						WHEN @supplierStatus='Inactive' and (Supinfo.[Status]='INACTIVE' OR Supinfo.[Status]='DISQUALIFIED')  THEN 1
						WHEN @supplierStatus = 'All' THEN 1 ELSE 0 END
			--WHERE Status<>'INACTIVE'
			--AND Status<>'DISQUALIFIED'
		END	-- @@ROWCOUNT=0
	END -- (@ExternalEmp =1)
	SELECT * FROM @tSupplier
	
END