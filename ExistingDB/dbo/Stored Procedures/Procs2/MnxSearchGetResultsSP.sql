-- =============================================
-- Author:		David Sharp
-- Create date: 11/22/2011
-- Description:	process search query
-- 08/27/13 DS Modifications to improves performance by doing the full search only on the first sp, or the provided sp 
--             while returning only the first row of the others to verify a result exists.
-- 10/25/13 DS Added handling for a standard limit on the years included in the search
-- 11/15/13 DS changed approach to return TOP 15 excluding previous results
-- 05/07/14 DS Added external employee check to search process
-- 12/12/14 DS Added supplier status filter
-- 01/06/2015 DRP:  Added @customerStatus Filter
-- =============================================
CREATE PROCEDURE [dbo].[MnxSearchGetResultsSP] 
	-- Add the parameters for the stored procedure here
	@searchType int,
	@searchTerm varchar(MAX),
	@userId uniqueidentifier,
	@defaultSearch varchar(500)='',
	@activeMonthLimit int = 0,
	@idList varchar(MAX)=''
		,@supplierStatus varchar(20) = 'All'
		,@customerStatus varchar (20) = 'All'

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	
	-- To be enabled later to filter search results based on users allowed customers and suppliers
	DECLARE @ExternalEmp bit
  	SELECT @ExternalEmp = ExternalEmp FROM aspnet_Profile WHERE UserId=@UserId

    DECLARE @tCustomers UserCompanyPermissions
    INSERT INTO @tCustomers	EXEC aspmnxSP_GetCustomers4User @userId, @ExternalEmp,@customerStatus
    
    DECLARE @tSupplier UserCompanyPermissions
    INSERT INTO @tSupplier	EXEC aspmnxSP_GetSuppliers4User @userId, @ExternalEmp, @supplierStatus
    
    DECLARE @tSearchId tSearchId
    INSERT INTO @tSearchId
    SELECT id FROM dbo.fn_simpleVarcharlistToTable (@idList,',')
	
	DECLARE @ErrTable TABLE (ErrNumber int,ErrSeverity int,ErrProc varchar(MAX),ErrLine int,ErrMsg varchar(MAX))
	
    DECLARE @sproc varchar(100)
    DECLARE @rCount int
    DECLARE @i int = 0
    IF @defaultSearch<>'' SET @i=1 --if a default search is provided, return only those results, otherwise return only the first
    
	BEGIN    
		DECLARE rt_cursor CURSOR LOCAL FAST_FORWARD
		FOR
		SELECT		p.storedProcedure
		FROM		[MnxSearchProcedureList] p INNER JOIN [MnxSearchType2Procedure] tp ON p.procedureId = tp.fkProcedureId
		WHERE		tp.fkTypeId = @searchType AND p.isActive = 1
		ORDER BY	tp.resultOrder
		OPEN		rt_cursor;
	END
	
	FETCH NEXT FROM rt_cursor INTO @sproc
	
    WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
		--08/27/13 DS If the default search is provided, or no results found yet, request the full results from the sproc, otherwise, just check if results exist.
		--IF @i = 0 OR @sproc = @defaultSearch
			EXEC @rCount = @sproc @searchTerm, @searchType, @userId, @tCustomers, @tSupplier,1,@activeMonthLimit,@tSearchId, @ExternalEmp
		--ELSE
			--EXEC @rCount = @sproc @searchTerm, @searchType, @userId, @tCustomers, @tSupplier,0,@activeMonthLimit
			
		--IF @rCount>0 SET @i = 1
		END TRY
		BEGIN CATCH
			INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)
			SELECT
				ERROR_NUMBER() AS ErrorNumber
				,ERROR_SEVERITY() AS ErrorSeverity
				--,ERROR_STATE() AS ErrorState
				,ERROR_PROCEDURE() AS ErrorProcedure
				,ERROR_LINE() AS ErrorLine
				,ERROR_MESSAGE() AS ErrorMessage;
				
			SELECT * FROM @ErrTable
		END CATCH
		FETCH NEXT FROM rt_cursor INTO @sproc
	END
	 
	CLOSE rt_cursor
	DEALLOCATE rt_cursor
END