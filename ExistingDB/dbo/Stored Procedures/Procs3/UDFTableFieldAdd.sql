-- =============================================
-- Author:		David Sharp
-- Create date: 8/13/2012
-- Description:	Add a UDF table field
-- 7/17/2015 Anuj : Added isUdf check to make udf/udt table name based on section
-- 10/19/2015 Sachin s:Precision values can not save for decimal dataType
-- 05/12/2016 Satish B: there is no need to check again If condition if @keyTypeFinal variable already set in first if so Add Else If condition
-- 05/20/2016 Satish B : Added the return parameter to return value if the UDF name is already exist
-- 05/20/2016 Satish B : Added 'WITH VALUES' Used to Save Integer and Text Default Value 
-- e.g.exec UDFTableFieldAdd @sectionName=N'Inventory',@fieldName=N'StaticList',@fieldType=N'list',@fieldLength=N'50',@fieldDefault=N'2',@nullable=0,@listString=N'',@dynamicString=N'',@isUdf=1
-- 06/30/2016 Satish :Added  '@section' to creation of new UDF/UDT table from 'mainTable' to 'section' using mnxUdfSections table to maintain uniq table creation for UDF/UDT
-- 11/06/2017 Raviraj P : Added a new parameter @categoryName
-- 11/06/2017 Raviraj P : Set capa table name
-- 10/05/2018 Shivshankarp : Added a new parameter @subSection 
-- 04/17/2019 Shrikant B :  SET @keyNullable from @keyNullable= 'NOT NULL' to NULL 
-- 04/23/2019 Raviraj P :  change @nullable from 0 to 1
-- 06/18/2019 Nitesh B :  change @keyNullable from 'NULL' to 'NOT NULL'
-- UDFTableFieldAdd 'BOM Header','arjun', 'varchar', 78, 'a', 1, '','',1,  0,'', 'udfBOM Header'
-- =============================================
CREATE PROCEDURE [dbo].[UDFTableFieldAdd] 
	-- Add the parameters for the stored procedure here
	@sectionName varchar(200),
	@fieldName varchar(200),
	@fieldType varchar(200),
	@fieldLength varchar(200)='0',
	@fieldDefault varchar(200)=null,
	@nullable bit = 0,
	@listString varchar(MAX)=null,
	@dynamicString varchar(MAX)=null,
	@isUdf bit = 1,
	@decimalPrecision int = 0,
	@categoryName VARCHAR(100) = null , -- 06/11/2017 Raviraj P : Added a new parameter @categoryName
	@subSection VARCHAR(100) =''  -- 10/05/2018 Shivshankarp : Added a new parameter @subSection 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @tablekey VARCHAR(200),@keyType VARCHAR(200),@keyLength INT,@keyNull VARCHAR(4),@keyTypeFinal VARCHAR(200),@keyNullable VARCHAR(20) = 'NULL',
			@udfTableName VARCHAR(200),@SQL VARCHAR(MAX),@udfTableKeyName VARCHAR(200),@secureFieldName VARCHAR(MAX),@RETURN_VALUE NVARCHAR(200),@section VARCHAR(200)
	
	-- 06/30/2016 Satish : Change to create new UDF/UDT table creation from mainTable to section using mnxUdfSections table to maintain uniq table creation for UDF/UDT
	--SELECT @tableName=mainTable FROM MnxUdfSections WHERE section=@sectionName
	-- 06/30/2016 Satish :Added  '@section' to creation of new UDF/UDT table from 'mainTable' to 'section' using mnxUdfSections table to maintain uniq table creation for UDF/UDT
	SELECT @section=REPLACE(section,' ','_')FROM MnxUdfSections WHERE section=@sectionName

	-- 7/17/2015 Anuj : Added isUdf check to make udf/udt table name based on section
	IF @isUdf = 1   AND (@subSection IS NOT NULL AND @subSection != '') AND  (@categoryName IS NOT NULL AND @categoryName != '')-- 10/05/2018 Shivshankarp : Added a new parameter @subSection   
	-- 11/06/2017 Raviraj P :  Added custom CAPACategoryUDF condition
	BEGIN
		SET @udfTableName = @subSection + '_' + REPLACE(@categoryName,' ','_')    --11/06/2017 Raviraj P : Set capa table name
	END
	ELSE IF @isUdf = 1
	BEGIN
		SET @udfTableName = 'udf'+@section     --06-30-2016 Satish :Create new udf table using section name
	END
	ELSE
	BEGIN
		SET @udfTableName = 'udt'+@section     --06-30-2016 Satish :Create new udt table using section name
	END
	SET @secureFieldName = REPLACE(@fieldName,' ','_')

	IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = @udfTableName)
    BEGIN
		EXEC UDFTableAdd @sectionName, @isUdf, @categoryName,@subSection
    END
	IF EXISTS(SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS	WHERE TABLE_NAME = @udfTableName AND COLUMN_NAME=@fieldName)
		--5/20/2016 Satish B : Added the @RETURN_VALUE parameter to return error  if the UDF name is already exist
		BEGIN
			SELECT '403' AS msgCode,'Field Already Exists In The Table' AS msg
			SET @RETURN_VALUE = 'Field Already Exists In The Table'
			RAISERROR (@RETURN_VALUE, 11,1)
		END
	ELSE
	BEGIN
		--Set the datatype
		IF @fieldType='list' OR @fieldType='dynamicSql'
		BEGIN
			SET @keyTypeFinal='varchar(MAX)'
			--Clear any previously existing settings for the field and add it fresh
			DELETE FROM UDFMeta WHERE udfTable=@udfTableName AND udfField=@fieldName
			INSERT INTO UDFMeta (udfTable,udfField,listString,dynamicSQL)
			SELECT @udfTableName,@fieldName,@listString,@dynamicString
		END
		--Sachin s change the code code for decimal data type
		--ELSE IF @fieldType='char' OR @fieldType='varchar' OR @fieldType='decimal' 
		--	SET @keyTypeFinal= @fieldType+'('+CAST(@fieldLength as varchar(20))+')'

		ELSE IF @fieldType='char' OR @fieldType='varchar' 
			 SET @keyTypeFinal= @fieldType+'('+CAST(@fieldLength as varchar(20))+')'
			-- 10-19-2015 Sachin s:Precision values can not save for decimal dataType
			--05/12/2016 Satish B: there is no need to check again If condition if @keyTypeFinal variable already set in first if so Add Else If condition
		 ELSE IF @fieldType = 'decimal'		 
		     SET @keyTypeFinal= @fieldType+'('+CAST(@fieldLength AS VARCHAR(20))+ ','+CAST(@decimalPrecision AS VARCHAR(20))+')'
		ELSE  SET @keyTypeFinal=@fieldType
		  -- 04/17/2019 Shrikant B :  SET @keyNullable from @keyNullable= 'NOT NULL' to NULL 

		IF @nullable = 1 -- 04/23/2019 Raviraj P :  change @nullable from 0 to 1
			BEGIN
				SET @keyNullable = 'NOT NULL' -- 06/18/2019 Nitesh B :  change @keyNullable from 'NULL' to 'NOT NULL'
			END
		ELSE
			BEGIN
				SET @keyNullable = 'NULL'
			END

		BEGIN TRANSACTION
			--IF @fieldDefault is not set field MUST be nullable
			IF @fieldDefault IS NULL SET @SQL='ALTER TABLE dbo.'+@udfTableName+' ADD '+@secureFieldName+' '+@keyTypeFinal+' CONSTRAINT DF_'+@udfTableName+'_'+@secureFieldName+ ' DEFAULT NULL'                 
			 --05/20/2016 Satish B :Added 'WITH VALUES' Used to Save Integer and Text Default Value
			ELSE SET @SQL='ALTER TABLE dbo.'+@udfTableName+' ADD '+@secureFieldName+' '+@keyTypeFinal+' '+@keyNullable+'  CONSTRAINT DF_'+@udfTableName+'_'+@secureFieldName+' DEFAULT '''+@fieldDefault+''''+'WITH VALUES' 
			--ELSE SET @SQL='ALTER TABLE dbo.'+@udfTableName+' ADD '+@fieldName+' '+@keyTypeFinal+' '+@keyNullable+' DEFAULT '''+@fieldDefault+''''	
			EXEC (@SQL)
			SET @SQL='ALTER TABLE dbo.'+@udfTableName+' SET (LOCK_ESCALATION = TABLE) '
			EXEC (@SQL)		
		COMMIT
	END
END