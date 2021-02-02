-- =============================================
-- Author:		David Sharp
-- Create date: 8/13/2012
-- Description:	get udf table values
-- 07/12/13 DS Added provision for if the sectionName IS the tableName
-- 12/09/14 DS Condensed UDF update to a single statement
-- 13/07/15 Anuj Added UdfId to make it workable for UDT
-- 13/07/15 Anuj Added IsUdfId to Check UDF or UDT
-- 06/30/2016 Satish : Added to update UDF/UDT table value which is created based on sectionName
-- 11/06/2017 Raviraj P : Added a new parameter @categoryName
-- 10/04/2018 Shivshankarp : Added a new parameter @subSection 
-- 10/12/2018 Rajendra K : Added condition for PartClass
-- 10/24/2018 Rajendra K : Set Default value 0/0.0 for Decimal and Interger values if it is empty
-- 10/25/2018 Nitesh B : Replaced REPLACE(@categoryName,'-','_') by REPLACE(REPLACE(@categoryName,'-','_'),' ','_') for Category having '-'
-- 12/20/2018 Shrikant B : Added a new parameter @isAddNew   
-- 12/20/18 Shrikant B handle add update @udfTableName conditionally to fix the issue of new cut sheet not saved updating previous one 
-- 01/14/2019 Shrikant B CHANGE WHERE fk'+@tableKey+'='''+ @fkValue +''' OR udfId='''+@udfId+''''  TO udfId='''+@udfId+''''
-- 04/23/2019 Raviraj P change @fieldValue size from 200 to 8000
-- UDFTableValueAdd  'BOM Details', 'Cut_Length', '328', '9CJHUO7SR4', 'ac2efeb0-8535-a5b5-1bce-07557da17be4', 0, '', '', 1
-- =============================================
CREATE PROCEDURE [dbo].[UDFTableValueAdd] 
	-- Add the parameters for the stored procedure here
 @sectionName VARCHAR(200),  
 @fieldName VARCHAR(200),  
 @fieldValue VARCHAR(8000),  -- 04/23/2019 Raviraj P change @fieldValue size from 200 to 8000
 @fkValue VARCHAR(200),  
 @udfId VARCHAR(200),  
 @isUdf BIT = 1,  
	@categoryName VARCHAR(MAX) = '',  -- 11/06/2017 Raviraj P : Added a new parameter @categoryName
 @subSection VARCHAR(100) ='', -- 10/03/2018 Shivshankarp : Added a new parameter @subSection   
 @isAddNew BIT = 0 -- 12/20/2018 Shrikant B : Added a new parameter @isAddNew   
   
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @udfTableName varchar(200),@SQL nvarchar(MAX),@udfTableKeyName varchar(200),@tableKey varchar(50),@rowCount int,@tableName varchar(200),@section varchar(200)
	DECLARE @recCount TABLE (recordCount int)
	
	SELECT @tableName=mainTable FROM MnxUdfSections WHERE section=@sectionName
	-- 07/12/13 DS reset table name to section if not found
	IF @tableName IS NULL SET @tableName=@sectionName
	-- 06/30/2016 Satish : Added to update UDF/UDT table value which is created based on sectionName
	SELECT @section=REPLACE(section,' ','_')FROM MnxUdfSections WHERE section=@sectionName
	--Get Primary Key
	SELECT @tableKey=COLUMN_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME=@tableName
	
	--IF @isUdf = 1 AND (@sectionName IS NOT NULL AND @sectionName != '') AND (@subSection IS NOT NULL AND @subSection != '')  AND (@categoryName IS NOT NULL AND @categoryName != '')
	IF @isUdf = 1 AND @subSection  IS NOT NULL AND @subSection <> ''  AND (@categoryName IS NOT NULL AND @categoryName != '')  -- 10/04/2018 Shivshankarp : Added a new parameter @subSection 
	-- 11/06/2017 Raviraj P :  Added custom CAPACategoryUDF condition
	BEGIN
	    -- 10/04/2018 Nitesh B : Replaced REPLACE(@categoryName,'-','_') by REPLACE(REPLACE(@categoryName,'-','_'),' ','_') for Category having '-'
		SET @udfTableName =  @subSection +'_'+ REPLACE(REPLACE(@categoryName,'-','_'),' ','_')      --11/06/2017 Raviraj P : Set capa table name
		--SET @tableKey = CASE WHEN @sectionName = 'INVENTOR' THEN 'UNIQ_KEY' ELSE 'NoteID' END -- 10/12/2018 Rajendra K : Added condition for PartClass
		
		-- 10/12/2018 Rajendra K : Added condition for PartClass
		
		if(@fieldValue = '')
		BEGIN
		DECLARE @fieldDataType VARCHAR(20)=(SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = @udfTableName AND COLUMN_NAME = @fieldName)
		IF (@fieldDataType ='decimal')
		BEGIN
		SET @fieldValue = 0.0
		END
		ELSE IF (@fieldDataType ='int')
		BEGIN
		SET @fieldValue = 0
		END
		END

	END
	-- 7/17/2015 Anuj : Added isUdf check to make udf/udt table name based on section
	ELSE IF @isUdf = 1
	BEGIN
		SET @udfTableName = 'udf'+@section
	END
	ELSE
	BEGIN
		SET @udfTableName = 'udt'+@section
	END

	-- 13/07/15 Anuj Added UdfId to make it workable for UDT
	-- 13/07/15 Anuj Added IsUdfId to Check UDF or UDT
	--SET @SQL='SELECT COUNT(*) FROM dbo.'+@udfTableName+' WHERE fk'+@tableKey+'='''+@fkValue+''''
 -- 12/20/18 Shrikant B handle add update @udfTableName conditionally to fix the issue of new cut sheet not saved updating previous one
 IF @isAddNew = 1
   BEGIN  
 SET @SQL='IF NOT EXISTS (SELECT 1 FROM dbo.'+@udfTableName+' WHERE  udfid='''+@udfId+''') '  
    + 'INSERT INTO dbo.'+@udfTableName+' ('+@fieldName+',fk'+@tableKey+',udfId) VALUES ('''+@fieldValue+''','''+@fkValue+''','''+@udfId+''') '  
    + 'ELSE '  
	-- 01/14/2019 Shrikant B CHANGE WHERE fk'+@tableKey+'='''+ @fkValue +''' OR udfId='''+@udfId+''''  TO udfId='''+@udfId+''''
    + 'UPDATE dbo.'+@udfTableName+' SET '+@fieldName+'='''+@fieldValue+''' WHERE udfId='''+@udfId+''''
   
  END  
  ELSE
    BEGIN 
	SET @SQL='IF NOT EXISTS (SELECT 1 FROM dbo.'+@udfTableName+' WHERE fk'+@tableKey+'='''+ @fkValue +''' OR udfid='''+@udfId+''') '
				+ 'INSERT INTO dbo.'+@udfTableName+' ('+@fieldName+',fk'+@tableKey+',udfId) VALUES ('''+@fieldValue+''','''+@fkValue+''','''+@udfId+''') '
				+ 'ELSE '
				+ 'UPDATE dbo.'+@udfTableName+' SET '+@fieldName+'='''+@fieldValue+''' WHERE fk'+@tableKey+'='''+ @fkValue +''' OR udfId='''+@udfId+''''
	 END 
	--INSERT INTO @recCount
	EXEC(@SQL)
	--SELECT top (1) @rowCount=recordCount FROM @recCount
	--IF @rowCount>=1
	--	SET @SQL='UPDATE dbo.'+@udfTableName+' SET '+@fieldName+'='''+@fieldValue+''' WHERE fk'+@tableKey+'='''+@fkValue+''''
	--ELSE
	--	SET @SQL='INSERT INTO dbo.'+@udfTableName+' ('+@fieldName+',fk'+@tableKey+') VALUES ('''+@fieldValue+''','''+@fkValue+''')'
	----PRINT @SQL
	--EXEC (@SQL)
END