-- =============================================
-- Author:		Raviraj P
-- Create date: 12/15/2018
-- Description:	Update UDF setup require and list column
-- =============================================

CREATE PROCEDURE [dbo].[UpdateUDFSetupField] 
	@sectionName varchar(200),	
	@fieldName varchar(200),
	@isUdf bit = 1,
	@categoryName VARCHAR(100) =null, 
	@subSection VARCHAR(100) ='', 
	@nullable BIT = 1,
	@listString varchar(MAX)=null,
	@dynamicString varchar(MAX)=null,
	@udfId uniqueidentifier=null,
	@maxLength varchar(200)='0',
	@fieldType varchar(200),
	@decimalPrecision int = 0
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @tableName varchar(200),@section varchar(200)
	SELECT @tableName=mainTable FROM MnxUdfSections WHERE section=@sectionName

	SELECT @section=REPLACE(section,' ','_')FROM MnxUdfSections WHERE section=@sectionName
 

	DECLARE @udfTableName varchar(200),@SQL varchar(MAX),@udfTableKeyName varchar(200),@fieldDefault varchar(200)
	IF @isUdf = 1 AND @subSection IS NOT NULL AND  @subSection <>''  AND  @categoryName IS NOT NULL 
	
	 BEGIN
	    SET @udfTableName = @subSection  + '_' + REPLACE(@categoryName,' ','_')  
	 END
	ELSE If @isUdf = 1
		SET @udfTableName = 'udf'+@section   
	ELSE
		SET @udfTableName = 'udt'+@section   
	--MAKE SURE FIELD EXISTS
	DECLARE @fieldExists int = 0
	SELECT @fieldExists=COUNT(column_name) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @udfTableName AND COLUMN_NAME=@fieldName
	IF @fieldExists=0 
		RETURN 404
		
	IF @listString IS NOT NULL AND @listString <> ''
	BEGIN
		UPDATE UDFMeta SET listString = @listString WHERE metaId = @udfId
	END

	IF @dynamicString  IS NOT NULL AND @dynamicString <> ''
	UPDATE UDFMeta SET dynamicSQL = @dynamicString WHERE metaId = @udfId
	
	DECLARE @fieldlenght varchar(200),@keyTypeFinal VARCHAR(200)
	
	IF @fieldType='list' OR @fieldType='dynamicSql'
		SET @keyTypeFinal='varchar(MAX)'
	ELSE IF @fieldType='char' OR @fieldType='varchar' 
		SET @keyTypeFinal= @fieldType+'('+CAST(@maxLength as varchar(20))+')'
	ELSE IF @fieldType = 'decimal'		 
		SET @keyTypeFinal= @fieldType+'('+CAST(@maxLength AS VARCHAR(20))+ ','+CAST(@decimalPrecision AS VARCHAR(20))+')'
	ELSE  SET @keyTypeFinal=@fieldType

	SET @fieldlenght = case when (@listString <> '' OR @dynamicString <> '') then 'MAX' else CAST(@maxLength as varchar(20)) end

	IF @nullable = 0
	BEGIN
		SET @SQL='ALTER TABLE dbo.'+@udfTableName+' ALTER COLUMN '+@fieldName + ' '  + @keyTypeFinal + ' NOT NULL'
	END
	ELSE
	BEGIN
		SET @SQL='ALTER TABLE dbo.'+@udfTableName+' ALTER COLUMN '+@fieldName + ' ' + @keyTypeFinal + ' NULL'
	END
	EXEC (@SQL)	
END