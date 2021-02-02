-- =============================================
-- Author:		David Sharp
-- Create date: 04/05/2012
-- Description:	search modules
-- 08/27/13 DS added filter for full results, or any result
-- 10/25/13 DS added PATINDEX for performance and @activeMonthLimit (not used) for consistency in seach sp
-- 11/15/13 DS changed approach to return TOP 15 excluding previous results
-- 05/07/14 DS Added ExternalEmp param
-- =============================================
CREATE PROCEDURE [dbo].[MnxSearchViewModules]
	-- Add the parameters for the stored procedure here
	@searchTerm varchar(MAX),
	@searchType int,
	@userId uniqueidentifier,
	@tCustomers UserCompanyPermissions READONLY,
	@tSupplier UserCompanyPermissions READONLY,
	@fullResult bit = 0,
	@activeMonthLimit int = 0,
	@tSearchId tSearchId READONLY,
	@ExternalEmp bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --colNames are the localizatoin keys for the column names returned in the results.
    DECLARE @thisTerm varchar(MAX) = '%' + @searchTerm + '%'
    DECLARE @count int	
    --DECLARE @table TABLE(searchProc varchar(MAX),id varchar(50),[group] nvarchar(255),[table] nvarchar(255),[link] varchar(255),  
	--	moduleCode_f nvarchar(255), description_f nvarchar(255))

	--INSERT INTO @table
	IF @ExternalEmp = 0
	BEGIN
		SELECT DISTINCT TOP 15 'MnxSearchViewModules' AS searchProc,i.UNIQUENUM AS id, 'module_f' AS [group], 'module_f' AS [table],
				CAST(i.WebAddress AS varchar(50)) AS [link],i.SCREENNAME AS moduleCode_f,i.SCREENDESC AS description_f
			FROM ITEMS i
			WHERE PATINDEX(@thisTerm,
					i.SCREENNAME+'  '+
					i.SCREENDESC+'  '+
					i.APP)>0
				AND NOT i.UNIQUENUM IN (SELECT id FROM @tSearchId)
		SET @count = @@ROWCOUNT
	END
	--IF @count > 0	SELECT * FROM @table
		
		
	---- 08/27/13 DS added filter for full results, or any result
	--IF @fullResult=1
	--BEGIN
	--	INSERT INTO @table
	--	SELECT DISTINCT 'MnxSearchViewModules',NULL AS id, 'module_f' AS [group], 'module_f' AS [table],CAST(i.WebAddress AS varchar(50)) AS [link],
	--			i.SCREENNAME,i.SCREENDESC
	--		FROM ITEMS i
	--		WHERE PATINDEX(@thisTerm,
	--			i.SCREENNAME+'  '+
	--			i.SCREENDESC+'  '+
	--			i.APP)>0
	--	SET @count = @@ROWCOUNT
	--	IF @count > 0
	--	SELECT * FROM @table
	--END
	--ELSE
	--BEGIN
	--	DECLARE @countTble SearchCountType
	--	INSERT INTO @countTble
	--	SELECT TOP 1 'MnxSearchViewModules', 'module_f' [group], 'module_f' [table],''[link]
	--		FROM ITEMS i
	--		WHERE PATINDEX(@thisTerm,
	--			i.SCREENNAME+'  '+
	--			i.SCREENDESC+'  '+
	--			i.APP)>0
	--	SET @count = @@ROWCOUNT
	--	IF @count > 0
	--		SELECT * FROM @countTble
	--END
	RETURN @count
	
END