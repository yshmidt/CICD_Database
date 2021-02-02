-- =============================================
-- Author:		David Sharp
-- Create date: 12/7/2011
-- Description:	gets info about internal part numbers
-- 08/27/13 DS added filter for full results, or any result
-- 10/25/13 DS added PATINDEX for performance and @activeMonthLimit (not used) for consistency in seach sp
-- 11/15/13 DS changed approach to return TOP 15 excluding previous results
-- 05/07/14 DS Added ExternalEmp param
-- =============================================
CREATE PROCEDURE [dbo].[MnxSearchViewInventorParts] 
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
	-- 15 = date
	/* TODO: add customer restrictions */
	IF @searchType = 15
    BEGIN 
		SET @searchTerm = cast(convert(date,@searchTerm) as varchar(20))
	END

    DECLARE @thisTerm varchar(MAX) = '%' + @searchTerm + '%'
    DECLARE @count int	
    /* colNames are the localizatoin keys for the column names returned in the results. */
	--DECLARE @table TABLE(searchProc varchar(MAX),id varchar(50),[group] nvarchar(255),[table] nvarchar(255),[link] varchar(255),  
	--	partNumberRev_m nvarchar(255), partClass_s nvarchar(255),description_f nvarchar(255),partSource_s nvarchar(255))
	/* Need to add filter by approved customer ids. */
	
	--INSERT INTO @table
	IF @ExternalEmp = 0
	BEGIN
		SELECT DISTINCT TOP 15 'MnxSearchViewInventorParts' AS searchProc,i.UNIQ_KEY AS id, 'PN_f' AS [group], 'itemMaster_f' AS [table],
				'/Inventory/' + CAST(i.UNIQ_KEY AS varchar(50)) AS [link],
				RTRIM(i.part_no) + CASE WHEN i.revision = ' ' THEN ' '  ELSE ' | ' + i.revision END AS partNumRev_m,
				i.PART_CLASS AS partClass_s,i.DESCRIPT AS description_f,i.PART_SOURC AS partSource_s
			FROM inventor i
			WHERE PATINDEX(@thisTerm,
				i.PART_NO+' '+
				i.REVISION+'  '+
				i.DESCRIPT+'  '+
				i.PART_CLASS+'  '+
				i.PART_TYPE+'  '+
				i.PART_SOURC+'  '+
				i.MATLTYPE)>0
			AND (i.CUSTNO ='')
			AND NOT i.UNIQ_KEY IN (SELECT id FROM @tSearchId)
		SET @count = @@ROWCOUNT
	END
	--IF @count > 0	SELECT * FROM @table
	
	
	
	---- 08/27/13 DS added filter for full results, or any result
	--IF @fullResult=1
	--BEGIN
	--	INSERT INTO @table
	--	SELECT DISTINCT 'MnxSearchViewInventorParts',i.UNIQ_KEY AS id, 'PN_f' AS [group], 'itemMaster_f' AS [table],'/Inventory/' + CAST(i.UNIQ_KEY AS varchar(50)) AS [link],
	--			RTRIM(i.part_no) + CASE WHEN i.revision = ' ' THEN ' '  ELSE ' | ' + i.revision END AS partNumRev,i.PART_CLASS AS partClass,i.DESCRIPT AS [description],i.PART_SOURC AS partSource
	--		FROM inventor i
	--		WHERE PATINDEX(@thisTerm,
	--			i.PART_NO+' '+
	--			i.REVISION+'  '+
	--			i.DESCRIPT+'  '+
	--			i.PART_CLASS+'  '+
	--			i.PART_TYPE+'  '+
	--			i.PART_SOURC+'  '+
	--			i.MATLTYPE)>0
	--		AND (i.CUSTNO ='')
	--	SET @count = @@ROWCOUNT
	--	IF @count > 0
	--	SELECT * FROM @table
	--END
	--ELSE
	--BEGIN
	--	DECLARE @countTble SearchCountType
	--	INSERT INTO @countTble
	--	SELECT TOP 1 'MnxSearchViewInventorParts','PN_f' [group], 'itemMaster_f' [table],'' [link]
	--		FROM inventor i
	--		WHERE PATINDEX(@thisTerm,
	--			i.PART_NO+' '+
	--			i.REVISION+'  '+
	--			i.DESCRIPT+'  '+
	--			i.PART_CLASS+'  '+
	--			i.PART_TYPE+'  '+
	--			i.PART_SOURC+'  '+
	--			i.MATLTYPE)>0
	--		AND (i.CUSTNO ='')
	--	SET @count = @@ROWCOUNT
	--	IF @count > 0
	--		SELECT * FROM @table
	--END
	RETURN @count
END