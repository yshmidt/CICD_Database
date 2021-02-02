-- =============================================
-- Author: David Sharp
-- Create date: 1/31/2012
-- Description: search boms
-- 08/27/13 DS added filter for full results, or any result
-- 10/25/13 DS added @activeMonthLimit param (not used now) and PATINDEX for improved performance
-- 11/14/13 DS added @recordLimit to allow companies to specify how many records to return with the results
-- 11/15/13 DS changed approach to return TOP 15 excluding previous results
-- 02/14/14 DS Added DISTINCT to select to produce better results
-- 05/07/14 DS Add ExternalEmp param
-- =============================================
CREATE PROCEDURE [dbo].[MnxSearchViewBoM]
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
	DECLARE @count int,@count2 int
	--DECLARE @bomTable SearchBoMType
	--DECLARE @bomItemTable SearchBoMType

	--SET ROWCOUNT @recordLimit
	--INSERT INTO @bomTable (searchProc,id,[group],[table],link,partNumber_f,revision_f,description_f)
	SELECT DISTINCT TOP 15 'MnxSearchViewBoM' AS searchProc,Bomparent as id, 'BOMs' AS [group], 'BOM_f' AS [table], 
			'/bom/' + CAST(Bomparent AS varchar(50)) AS [link],Inventor.PART_NO as partNumber_f,Inventor.Revision as revision_f,DESCRIPT as description_f  
		from Bom_det INNER JOIN INVENTOR ON Inventor.UNIQ_KEY=Bom_det.BOMPARENT 
		WHERE (PATINDEX(@thisTerm,
				PART_NO+' '+ 
				REVISION+'  '+
				DESCRIPT)>0) 
			AND (Inventor.BOMCUSTNO IN (SELECT id from @tCustomers) OR 1 = CASE WHEN @ExternalEmp = 0 AND Inventor.BOMCUSTNO = '' THEN 1 ELSE 0 END) 
			AND NOT Bomparent IN (SELECT id FROM @tSearchId)

	--SET ROWCOUNT @recordLimit
	--INSERT INTO @bomTable (searchProc,id,[group],[table],link,partNumber_f,revision_f,description_f)
	UNION
	SELECT DISTINCT TOP 15 'MnxSearchViewBoM',Bomparent as id, 'BOMs' AS [group], 'BOM_f' AS [table], '/bom/' + CAST(Bomparent AS varchar(50)) AS [link],C.PART_NO as AssyNumber,C.Revision as revision_f,C.DESCRIPT as description_f  
		from Bom_det INNER JOIN INVENTOR C ON C.Int_uniq=Bom_det.BOMPARENT 
		WHERE (PATINDEX(@thisTerm,
				C.CustPARTNO+' '+
				C.CUSTREV+'  '+
				C.DESCRIPT)>0) 
			AND C.Custno IN (SELECT id from @tCustomers)
			AND NOT Bomparent IN (SELECT id FROM @tSearchId)

	SET @count = @@ROWCOUNT
	--IF @count > 0 SELECT * FROM @bomTable
	
	--SET ROWCOUNT @recordLimit
	--INSERT INTO @bomItemTable (searchProc,id,[group],[table],link,partNumber_f,revision_f,description_f)
	SELECT DISTINCT TOP 15 'MnxSearchViewBoM' AS searchProc,bh.UNIQ_KEY AS id, 'BOMParts' AS [group], 'partNumber_f' AS [table], 
			'/bom/' + CAST(bd.BOMPARENT AS varchar(50)) AS [link],
			bh.PART_NO AS partNumber_f,bh.REVISION AS revision_f,bh.DESCRIPT AS description_f
		FROM dbo.INVENTOR AS bi INNER JOIN dbo.BOM_DET AS bd ON bi.UNIQ_KEY = bd.UNIQ_KEY 
			INNER JOIN dbo.INVENTOR AS bh ON bd.BOMPARENT = bh.UNIQ_KEY
		WHERE (PATINDEX(@thisTerm,
				bi.PART_NO+' '+ 
				bi.REVISION+'  '+ 
				bi.DESCRIPT)>0)
			AND NOT bh.UNIQ_KEY  IN (SELECT id FROM @tSearchId)
			
	SET @count = @count+@@ROWCOUNT
	--IF @count2 > 0 SELECT * FROM @bomItemTable
	
	--SET @count = @count + @count2
		
		
	---- 08/27/13 DS added filter for full results, or any result
	--IF @fullResult=1
	--BEGIN
	--	--SET ROWCOUNT @recordLimit
	--	INSERT INTO @bomTable (searchProc,id,[group],[table],link,partNumber_f,revision_f,description_f)
	--	select 'MnxSearchViewBoM',Bomparent as id, 'BOMs' AS [group], 'BOM_f' AS [table], '/bom/' + CAST(Bomparent AS varchar(50)) AS [link],Inventor.PART_NO as AssyNumber,Inventor.Revision as revision_f,DESCRIPT as description_f  
	--		from Bom_det INNER JOIN INVENTOR ON Inventor.UNIQ_KEY=Bom_det.BOMPARENT 
	--		WHERE (PATINDEX(@thisTerm,
	--				PART_NO+' '+ 
	--				REVISION+'  '+
	--				DESCRIPT)>0) 
	--			AND Inventor.BOMCUSTNO IN (SELECT id from @tCustomers)

	--	--SET ROWCOUNT @recordLimit
	--	--INSERT INTO @bomTable (searchProc,id,[group],[table],link,partNumber_f,revision_f,description_f)
	--	union
	--	select 'MnxSearchViewBoM',Bomparent as id, 'BOMs' AS [group], 'BOM_f' AS [table], '/bom/' + CAST(Bomparent AS varchar(50)) AS [link],C.PART_NO as AssyNumber,C.Revision as revision_f,C.DESCRIPT as description_f  
	--		from Bom_det INNER JOIN INVENTOR C ON C.Int_uniq=Bom_det.BOMPARENT 
	--		WHERE (PATINDEX(@thisTerm,
	--				C.CustPARTNO+' '+
	--				C.CUSTREV+'  '+
	--				C.DESCRIPT)>0) 
	--			AND C.Custno IN (SELECT id from @tCustomers)
	
	--	SET @count = @@ROWCOUNT
	--	IF @count > 0 SELECT * FROM @bomTable
		
	--	--SET ROWCOUNT @recordLimit
	--	INSERT INTO @bomItemTable (searchProc,id,[group],[table],link,partNumber_f,revision_f,description_f)
	--	SELECT DISTINCT 'MnxSearchViewBoM',bh.UNIQ_KEY AS id, 'Groups' AS [group], 'partNumber_f' AS [table], '/bom/' + CAST(bd.BOMPARENT AS varchar(50)) AS [link],
	--			bh.PART_NO AS AssyNumber,bh.REVISION AS revision_f,bh.DESCRIPT AS description_f
	--		FROM dbo.INVENTOR AS bi INNER JOIN dbo.BOM_DET AS bd ON bi.UNIQ_KEY = bd.UNIQ_KEY 
	--			INNER JOIN dbo.INVENTOR AS bh ON bd.BOMPARENT = bh.UNIQ_KEY
	--		WHERE (PATINDEX(@thisTerm,
	--				bi.PART_NO+' '+ 
	--				bi.REVISION+'  '+ 
	--				bi.DESCRIPT)>0)
	--	SET @count2 = @@ROWCOUNT
	--	IF @count2 > 0 SELECT * FROM @bomItemTable
		
	--	SET @count = @count + @count2
	--END
	--ELSE
	--BEGIN
	--	DECLARE @countTble SearchCountType
	--	INSERT INTO @countTble
	--	select  TOP 1 'MnxSearchViewBoM','BOM_f' AS [table],'BOM_f' AS [group],''
	--		from Bom_det INNER JOIN INVENTOR ON Inventor.UNIQ_KEY=Bom_det.BOMPARENT 
	--		WHERE (PATINDEX(@thisTerm,
	--				PART_NO+' '+
	--				REVISION+'  '+
	--				DESCRIPT)>0)
	--			AND Inventor.BOMCUSTNO IN (SELECT id from @tCustomers)
		
	--	INSERT INTO @countTble
	--	select TOP 1 'MnxSearchViewBoM','BOM_f' AS [table],'BOM_f' AS [group],''
	--		from Bom_det INNER JOIN INVENTOR C ON C.Int_uniq=Bom_det.BOMPARENT 
	--		WHERE (PATINDEX(@thisTerm,
	--				C.CustPARTNO+' '+
	--				C.CustRev+'  '+
	--				C.DESCRIPT)>0) 
	--			AND C.Custno IN (SELECT id FROM @tCustomers)
		
	--	INSERT INTO @countTble
	--	SELECT TOP 1 'MnxSearchViewBoM','partNumber_f' AS [table],'partNumber_f' AS [group],''
	--		FROM dbo.INVENTOR AS bi INNER JOIN
	--		dbo.BOM_DET AS bd ON bi.UNIQ_KEY = bd.UNIQ_KEY INNER JOIN
	--		dbo.INVENTOR AS bh ON bd.BOMPARENT = bh.UNIQ_KEY
	--		WHERE (PATINDEX(@thisTerm,
	--				bi.PART_NO+' '+
	--				bi.REVISION+'  '+
	--				bi.DESCRIPT)>0)
		
	--	SELECT @count = COUNT(*) FROM @countTble
	--	IF @count>0
	--		SELECT * FROM @countTble
	--END
	RETURN @count
END