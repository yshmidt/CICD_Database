-- =============================================
-- Author:		David Sharp
-- Create date: 8/13/2012
-- Description:	Add a UDF table
-- 7/17/2015 Anuj : Added isUdf check to make udf/udt table name based on section
-- 06/30/2016 Satish :Added  '@section' to creation of new UDF/UDT table from 'mainTable' to 'section' using mnxUdfSections table to maintain uniq table creation for UDF/UDT
-- 10/24/2017 Raviraj P :  Handle for the table with key type as uniqueidentifier
-- 11/06/2017 Raviraj P :  Added custom CAPACategoryUDF condition
-- 10/02/2018 Shivshankarp : Added a new parameter @subSection 
-- 12/03/2018 Satish B : Added a new filter  @subSection != '' And @categoryName != ''
-- =============================================
CREATE PROCEDURE [dbo].[UDFTableAdd] 
	-- Add the parameters for the stored procedure here
	@sectionName VARCHAR(200),
	@isUdf BIT = 1,
	@categoryName VARCHAR(100) = NULL,
	@subSection VARCHAR(100) = NULL -- 10/02/2018 Shivshankarp : Added a new parameter @subSection 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @tablekey VARCHAR(200),@keyType VARCHAR(200),@keyLength INT,@keyNull VARCHAR(4),@keyTypeFinal VARCHAR(200),@keyNullable VARCHAR(20) = 'NULL',
			@udfTableName VARCHAR(200),@SQL VARCHAR(MAX),@udfTableKeyName VARCHAR(200),@tableName VARCHAR(200),@section VARCHAR(200)
	
	SELECT @tableName=mainTable FROM MnxUdfSections WHERE section=@sectionName
	-- 06/30/2016 Satish :Added  '@section' to creation of new UDF/UDT table from 'mainTable' to 'section' using mnxUdfSections table to maintain uniq table creation for UDF/UDT
	SELECT @section=REPLACE(section,' ','_') FROM MnxUdfSections WHERE section=@sectionName

	--Get Primary Key
	SELECT @tableKey=COLUMN_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME=@tableName
	SELECT @keyType=DATA_TYPE,@keyLength=CHARACTER_MAXIMUM_LENGTH,@keyNull=IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tableName AND COLUMN_NAME=@tableKey ORDER BY ORDINAL_POSITION ASC;
	--IF @isUdf = 1 AND @sectionName IS NOT NULL AND @subSection IS NOT NULL  AND @categoryName IS NOT NULL-- 10/02/2018 Shivshankarp : Added a new parameter @subSection  
	-- 12/03/2018 Satish B : Added a new filter  @subSection != '' And @categoryName != ''
	IF @isUdf = 1 AND @sectionName IS NOT NULL AND  (@subSection IS NOT NULL AND @subSection != '')  AND  (@categoryName IS NOT NULL AND @categoryName != '')
	-- 11/06/2017 Raviraj P :  Added custom CAPACategoryUDF condition
	BEGIN
		SET @udfTableName =  @subSection + '_' + REPLACE(@categoryName,' ','_')
		--SET @keyType=CASE WHEN @sectionName = 'INVENTOR' THEN  'CHAR' ELSE 'uniqueidentifier' END
	END
	--7/17/2015 Anuj : Added isUdf check to make udf/udt table name based on section
	ELSE IF @isUdf = 1 AND @sectionName IS NOT NULL 
	BEGIN
		SET @udfTableName = 'udf'+@section
	END
	ELSE
	BEGIN
		SET @udfTableName = 'udt'+@section
	END

	IF @sectionName = 'CAPACategoryUDF'  AND @categoryName IS NOT NULL -- 11/06/2017 Raviraj P :  Added custom CAPACategoryUDF condition
	 BEGIN
			SET @udfTableKeyName = 'fkNoteID'
	 END	
    ELSE
	 BEGIN
	   SET @udfTableKeyName = 'fk'+@tableKey
     END 
	--Set the datatype
	IF @keyType='char' OR @keyType='varchar'  
	BEGIN
		SET @keyTypeFinal= @keyType+'('+CAST(@keyLength AS VARCHAR(20))+')'
	END
	IF @keyType='char' OR @keyType='varchar'  
	BEGIN
		SET @keyTypeFinal= @keyType+'('+CAST(@keyLength AS VARCHAR(20))+')'
	END

	IF @keyType='uniqueidentifier'  -- 10/24/2017 Raviraj P :  Handle for the table with key type as uniqueidentifier
	BEGIN
		SET @keyTypeFinal= 'uniqueidentifier'
	END
	IF @keyNull = 'NO' SET @keyNullable = 'NOT NULL'
	BEGIN TRANSACTION
		SET @SQL= 'CREATE TABLE dbo.'+@udfTableName+'(udfId uniqueidentifier NOT NULL,'+@udfTableKeyName+' '+@keyTypeFinal+' '+@keyNullable+')  ON [PRIMARY]'
		EXEC (@SQL)
		SET @SQL='ALTER TABLE dbo.'+@udfTableName+' ADD CONSTRAINT DF_'+@udfTableName+'_udfId DEFAULT newid() FOR udfId'
		EXEC (@SQL)
		SET @SQL='ALTER TABLE dbo.'+@udfTableName+' ADD CONSTRAINT DF_'+@udfTableName+'_'+@udfTableKeyName+' DEFAULT '''' FOR '+@udfTableKeyName
		EXEC (@SQL)
		SET @SQL='ALTER TABLE dbo.'+@udfTableName+' ADD CONSTRAINT PK_'+@udfTableName+' PRIMARY KEY CLUSTERED (udfId) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
		EXEC (@SQL)
		SET @SQL='ALTER TABLE dbo.'+@udfTableName+' SET (LOCK_ESCALATION = TABLE) '
		EXEC (@SQL)
	COMMIT
END