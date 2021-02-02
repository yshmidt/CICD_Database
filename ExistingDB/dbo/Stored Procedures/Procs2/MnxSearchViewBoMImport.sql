-- =============================================
-- Author:		David Sharp
-- Create date: 5/3/2012
-- Description:	search imports
-- 08/27/13 DS added filter for full results, or any result
-- 11/15/13 DS changed approach to return TOP 15 excluding previous results
-- 04/16/14 DS removed customer and date filters TODO:Add these back later once search is fully upgraded
-- 11/06/14 DS change date format
--04/08/15 YS customer settings saved in wmsettings
-- =============================================
CREATE PROCEDURE [dbo].[MnxSearchViewBoMImport]
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
    /* colNames are the localizatoin keys for the column names returned in the results. */
    /* TODO: filter results by permitted companies for the user */
    DECLARE @thisTerm varchar(MAX) = '%' + @searchTerm + '%'
    DECLARE @count int,@count2 int
    DECLARE @bomTable TABLE (searchProc varchar(MAX),id varchar(max),[group] varchar(20),[table] varchar(20),link varchar(max),partNumber_f varchar(50),revision_f varchar(4),description_f varchar(50),date_f varchar(50),user_f varchar(5))
    DECLARE @bomItemTable TABLE (searchProc varchar(MAX),id varchar(max),[group] varchar(20),[table] varchar(20),link varchar(max),partNumber_f varchar(50),revision_f varchar(4),description_f varchar(50),date_f varchar(50),user_f varchar(5))
	
	-- If not specified, restrict the months to standard search limit
    IF @activeMonthLimit = 0 
		--04/08/15 YS customer settings saved in wmsettings
		--SELECT @activeMonthLimit = settingValue FROM MnxSettingsManagement WHERE settingId='40efabbe-7643-4bb7-ad1e-258ece817c30'
		SELECT @activeMonthLimit = COALESCE(s.settingValue,w.settingvalue) 
				FROM MnxSettingsManagement s left outer join wmSettingsManagement w 
					ON s.settingid=w.settingid
				WHERE settingName='searchMonthLimit'
				
	INSERT INTO @bomTable (searchProc,id,[group],[table],link,partNumber_f,revision_f,description_f,date_f,user_f)
		SELECT DISTINCT TOP 15 'MnxSearchViewBoMImport',ih.importId AS id, 'importBom' AS [table], 'importBOM_f' AS [group], '/Bom/Import/Process/' + CAST(ih.importId AS varchar(50)) AS [link], 
				ih.assyNum AS AssyNumber, ih.assyRev AS revision_f, ih.assyDesc AS description_f,CONVERT(varchar(10),ih.startDate,101)startDate,ih.startedBy
			FROM importBOMHeader ih  LEFT OUTER JOIN CUSTOMER c ON ih.custno = c.CUSTNO
			WHERE (PATINDEX(@thisTerm,
					ih.assyNum+' '+
					ih.assyRev+' '+
					ih.assyDesc+' '+
					COALESCE(c.CUSTNAME,''))>0)
				--AND ih.custNo IN (SELECT id FROM @tCustomers)
				AND  1=CASE WHEN ih.startDate>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1 ELSE 0 END
			ORDER BY CONVERT(varchar(10),ih.startDate,101)
				--AND NOT ih.importId  IN (SELECT id FROM @tSearchId)
				
		SET @count = @@ROWCOUNT
		IF @count > 0
		SELECT * FROM @bomTable
	
		INSERT INTO @bomItemTable (searchProc,id,[group],[table],link,partNumber_f,revision_f,description_f,date_f,user_f)
		SELECT DISTINCT TOP 15 'MnxSearchViewBoMImport',i.fkImportId AS id, 'importParts' AS [table], 'importPart_f' AS [group], '/Bom/Import/Process/' + CAST(bh.importId AS varchar(50)) AS [link], 
			bh.assyNum AS AssyNumber,bh.assyRev AS revision_f,bh.assyDesc AS description_f,CONVERT(varchar(10),bh.startDate,101)startDate,bh.startedBy
			FROM	importBOMFields AS i INNER JOIN  importBOMHeader AS bh ON i.fkImportId = bh.importId 
				INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId=fd.fieldDefId
			WHERE PATINDEX(@thisTerm,i.adjusted)>0 
				AND (fd.fieldName='partMfg' OR fd.fieldName='partNo')
				--AND bh.custNo IN (SELECT id FROM @tCustomers)
				AND  1=CASE WHEN bh.startDate>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1 ELSE 0 END
				--AND NOT i.fkImportId  IN (SELECT id FROM @tSearchId)
			ORDER BY CONVERT(varchar(10),bh.startDate,101)
		SET @count2 = @@ROWCOUNT
		IF @count2 > 0
		SELECT * FROM @bomItemTable
		SET @count = @count + @count2
		
		
	---- 08/27/13 DS added filter for full results, or any result
	--IF @fullResult=1
	--BEGIN
	--	INSERT INTO @bomTable (searchProc,id,[group],[table],link,partNumber_f,revision_f,description_f,date_f,user_f)
	--	SELECT	DISTINCT 'MnxSearchViewBoMImport',ih.importId AS id, 'importBom' AS [table], 'importBOM_f' AS [group], '/Bom/Import/Process/' + CAST(ih.importId AS varchar(50)) AS [link], 
	--			ih.assyNum AS AssyNumber, ih.assyRev AS revision_f, ih.assyDesc AS description_f,ih.startDate,ih.startedBy
	--		FROM importBOMHeader ih  LEFT OUTER JOIN CUSTOMER c ON ih.custno = c.CUSTNO
	--		WHERE (PATINDEX(@thisTerm,
	--				ih.assyNum+' '+
	--				ih.assyRev+' '+
	--				ih.assyDesc+' '+
	--				COALESCE(c.CUSTNAME,''))>0)
	--			AND ih.custNo IN (SELECT id FROM @tCustomers)
	--			AND  1=CASE WHEN ih.startDate>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1 ELSE 0 END
	--	SET @count = @@ROWCOUNT
	--	IF @count > 0
	--	SELECT * FROM @bomTable		
	
	--	INSERT INTO @bomItemTable (searchProc,id,[group],[table],link,partNumber_f,revision_f,description_f,date_f,user_f)
	--	SELECT DISTINCT 'MnxSearchViewBoMImport',i.fkImportId AS id, 'Groups' AS [table], 'importPart_f' AS [group], '/Bom/Import/Process/' + CAST(bh.importId AS varchar(50)) AS [link], 
	--		bh.assyNum AS AssyNumber,bh.assyRev AS revision_f,bh.assyDesc AS description_f,bh.startDate,bh.startedBy
	--		FROM	importBOMFields AS i INNER JOIN  importBOMHeader AS bh ON i.fkImportId = bh.importId 
	--			INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId=fd.fieldDefId
	--		WHERE PATINDEX(@thisTerm,i.adjusted)>0 
	--			AND (fd.fieldName='partMfg' OR fd.fieldName='partNo')
	--			AND bh.custNo IN (SELECT id FROM @tCustomers)
	--			AND  1=CASE WHEN bh.startDate>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1 ELSE 0 END
	--	SET @count2 = @@ROWCOUNT
	--	IF @count2 > 0
	--	SELECT * FROM @bomItemTable
	--	SET @count = @count + @count2
	--END
	--ELSE
	--BEGIN
	--	DECLARE @countTble SearchCountType
	--	INSERT INTO @countTble
	--	SELECT TOP 1 'MnxSearchViewBoMImport', 'importBom' AS [group], 'importBOM_f' AS [table], '' [link]
	--		FROM importBOMHeader ih  LEFT OUTER JOIN CUSTOMER c ON ih.custno = c.CUSTNO
	--		WHERE (PATINDEX(@thisTerm,
	--				ih.assyNum+' '+
	--				ih.assyRev+' '+
	--				ih.assyDesc+' '+
	--				COALESCE(c.CUSTNAME,''))>0)
	--			AND ih.custNo IN (SELECT id FROM @tCustomers)
	--			AND  1=CASE WHEN ih.startDate>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1 ELSE 0 END
		
	--	INSERT INTO @countTble
	--	SELECT TOP 1 'MnxSearchViewBoMImport', 'Groups' AS [group], 'importPart_f' AS [table], '' [link]
	--		FROM importBOMFields AS i INNER JOIN importBOMHeader AS bh ON i.fkImportId = bh.importId 
	--			INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId=fd.fieldDefId
	--		WHERE (PATINDEX(@thisTerm,LTRIM(RTRIM(i.adjusted)))>0)
	--			AND (fd.fieldName='partMfg' OR fd.fieldName='partNo') 
	--			AND bh.custNo IN (SELECT id FROM @tCustomers)
	--			AND 1=CASE WHEN bh.startDate>DATEADD(MONTH,-@activeMonthLimit,GETDATE()) THEN 1 ELSE 0 END
	--	SET @count = @@ROWCOUNT
	--	IF @count > 0
	--		SELECT * FROM @countTble
	--END
	RETURN @count
	
END