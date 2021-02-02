-- =============================================
-- Author:		David Sharp
-- Create date: 8/13/2012
-- Description:	Drop a UDF table field
-- 7/17/2015 Anuj : Added isUdf check to make udf/udt table name based on section
-- 11/06/2017 Raviraj P : Added a new parameter @categoryName
-- 11/06/2017 Raviraj P :  Added custom CAPACategoryUDF condition
-- 10/11/2018 Shivshankarp : Added a new parameter @subSection 
-- 02/01/2019 Shrikant Fixed the issue of UDF has not been deleted if categoryName is blank
-- UDFTableFieldDrop 'BOM Details', 'gfdfghdjhgf', 1, '', 'udfBOM Details'
-- =============================================
CREATE PROCEDURE [dbo].[UDFTableFieldDrop] 
	-- Add the parameters for the stored procedure here
	@sectionName varchar(200),	
	@fieldName varchar(200),
	@isUdf bit = 1,
	@categoryName VARCHAR(100) ='', -- 11/06/2017 Raviraj P : Added a new parameter @categoryName
	@subSection VARCHAR(100) ='' -- 10/04/2018 Shivshankarp : Added a new parameter @subSection 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --USERS CANNOT DELETE THE KEY TO THE MAIN TABLE
    DECLARE @fkLink varchar(200),@tableName varchar(200),@section varchar(200)
	SELECT @tableName=mainTable FROM MnxUdfSections WHERE section=@sectionName
	-- 06/30/2016 Satish : Added Get UDF/UDT table record which is created based on sectionName
	SELECT @section=REPLACE(section,' ','_')FROM MnxUdfSections WHERE section=@sectionName
    SELECT @fkLink=COLUMN_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME=@tableName
    IF @fieldName = 'fk'+@fkLink
		RETURN 400
	
	-- 7/17/2015 Anuj : Added isUdf check to make udf/udt table name based on section
	DECLARE @udfTableName varchar(200),@SQL varchar(MAX),@udfTableKeyName varchar(200),@fieldDefault varchar(200)
	-- 02/01/2019 Shrikant Fixed the issue of UDF has not been deleted if categoryName is blank
	IF @isUdf = 1 AND @subSection IS NOT NULL AND  @subSection <>''  AND  @categoryName IS NOT NULL AND @categoryName<>'' -- 10/11/2018 Shivshankarp : Added a new parameter @subSection 
	-- 11/06/2017 Raviraj P :  Added custom CAPACategoryUDF condition
	 BEGIN
	     SET @udfTableName = @subSection  + '_' + REPLACE(@categoryName,' ','_')  
	 END
	ELSE If @isUdf = 1
		SET @udfTableName = 'udf'+@section   -- 06/30/2016 Satish : Added to get UDF table name which is created based on sectionName
	ELSE
		SET @udfTableName = 'udt'+@section   -- 06/30/2016 Satish : Added to get UDT table name which is created based on sectionName
	--MAKE SURE FIELD EXISTS
	DECLARE @fieldExists int = 0
	SELECT @fieldExists=COUNT(column_name) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @udfTableName AND COLUMN_NAME=@fieldName
	IF @fieldExists=0 
		RETURN 404
		
	SELECT @fieldDefault=COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @udfTableName AND COLUMN_NAME=@fieldName
	BEGIN TRANSACTION
		IF NOT @fieldDefault IS NULL
		BEGIN
			SET @SQL='ALTER TABLE dbo.'+@udfTableName+'	DROP CONSTRAINT DF_'+@udfTableName+'_'+@fieldName
			EXEC (@SQL)
		END
		SET @SQL='ALTER TABLE dbo.'+@udfTableName+'	DROP COLUMN '+@fieldName
		EXEC (@SQL)
		SET @SQL='ALTER TABLE dbo.'+@udfTableName+' SET (LOCK_ESCALATION = TABLE) '
		EXEC (@SQL)		
	COMMIT
END