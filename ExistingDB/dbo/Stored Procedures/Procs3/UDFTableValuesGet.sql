
---- =============================================    
-- Author:  David Sharp    
-- Create date: 8/13/2012    
-- Description: get udf table values    
-- 12/04/14 DS added a record if not found, but will delete it right after in case the user does not save the record in the view.    
-- 13/07/15 Anuj Added UdfId to make it workable for UDT    
-- 13/07/15 Anuj Added IsUdfId to Check UDF or UDT    
-- 06/30/2016 Satish : Added to get UDF/UDT table value which is created based on sectionName    
-- 11/06/2017 Raviraj P : Added a new parameter @categoryName    
-- 04/12/2018 Vijay G: Modified the incorrect syntax at  SET @newRecord = 1 END'    
-- 06/06/2018 Vijay G: Get UDF record is new or existing    
-- 09/24/2018 Nitesh B: Added Condition @sectionName = 'INVENTOR'    
-- 10/15/2018 Nitesh B: Added Parameter  @subSection    
-- 10/15/2018 Nitesh B: Modified condition to get UdfTable name and table Key    
-- 10/16/2018 Nitesh B : Added condition to check udf table exists or not    
-- 10/25/2019 Nitesh B : Replaced REPLACE(@categoryName,'-','_') by REPLACE(REPLACE(@categoryName,'-','_'),' ','_') for Category having '-'    
-- 01/14/2018 Shrikant  B  formating stored procedure 
-- UDFTableValuesGet  'BOM Details', '_2BK0I3O2E', '018dd7e3-690d-1f94-6351-b4e71cb8bd55', 0, '', ''
-- =============================================    
CREATE PROCEDURE [dbo].[UDFTableValuesGet]     
 -- Add the parameters for the stored procedure here    
 @sectionName varchar(200),    
 @fkValue varchar(200),    
 @udfId uniqueidentifier,    
 @isUdf bit = 1,    
 @categoryName VARCHAR(100) = '', -- 11/06/2017 Raviraj P : Added a new parameter @categoryName    
 @subSection VARCHAR(100)=NULL -- 10/15/2018 Nitesh B: Added Parameter  @subSection    
AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
    
    -- Insert statements for procedure here    
 DECLARE @udfTableName varchar(200),@SQL nvarchar(MAX),@udfTableKeyName varchar(200),@tableKey varchar(50),@tableName varchar(200),@section varchar(200)    
 DECLARE @newRecord bit = 0    
    
 SELECT @tableName=mainTable FROM MnxUdfSections WHERE section=@sectionName    
 IF(@tableName IS NULL) SET @tableName=@sectionName    
 -- 06/30/2016 Satish : Added to get UDF/UDT table value which is created based on sectionName    
 SELECT @section=REPLACE(section,' ','_')FROM MnxUdfSections WHERE section=@sectionName    
    
 --Get Primary Key    
 SELECT @tableKey=COLUMN_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME=@tableName    
 -- 09/24/2018 Nitesh B: Added Condition @sectionName = 'INVENTOR'    
 --IF @isUdf = 1 AND (@sectionName = 'CAPACategoryUDF' OR @sectionName = 'INVENTOR') AND @categoryName IS NOT NULL -- 11/06/2017 Raviraj P :  Added custom CAPACategoryUDF condition    
           -- 09/27/2018 Nitesh B : Modified condition for Inventor    
    --IF @isUdf = 1 AND (@sectionName IS NOT NULL AND @sectionName != '') AND (@subSection IS NOT NULL AND @subSection != '')  AND @categoryName IS NOT NULL -- 11/06/2017 Raviraj P :  Added custom CAPACategoryUDF condition    
 IF @isUdf = 1 AND @subSection  IS NOT NULL AND @subSection <> ''  AND @categoryName IS NOT NULL    
 BEGIN    
     --SET @udfTableName =  (CASE WHEN @sectionName = 'CAPACategoryUDF' THEN 'udfWmnotes_' ELSE 'udfInventor_' END)+ REPLACE(@categoryName,' ','_')    --11/06/2017 Raviraj P : Set capa table name -- 09/27/2018 Nitesh B : Modified condition for Inventor   
  SET @udfTableName =  @subSection +'_'+ REPLACE(REPLACE(@categoryName,'-','_'),' ','_') --10/15/2018 Nitesh B : Replced above statement     
  -- 10/04/2018 Nitesh B : Replaced REPLACE(@categoryName,'-','_') by REPLACE(REPLACE(@categoryName,'-','_'),' ','_') for Category having '-'    
  --SET @tableKey = (CASE WHEN @sectionName = 'CAPACategoryUDF' THEN 'noteID' ELSE 'Uniq_Key' END) -- 09/27/2018 Nitesh B : Modified condition for Inventor -- 10/15/2018 Nitesh B: Removed condition to make it generic    
  SET @SQL = 'IF NOT EXISTS (SELECT udfid FROM dbo.'+@udfTableName+' WHERE fk'+@tableKey+'='''+@fkValue+''')
				BEGIN 
					INSERT INTO dbo.'+@udfTableName+' (fk'+@tableKey+') SELECT '''+@fkValue+''' SET @newRecord = 1 
				END'     
 END    
 -- 13/07/15 Anuj Added UdfId to make it workable for UDT    
 -- 13/07/15 Anuj Added IsUdfId to Check UDF or UDT    
 ELSE IF @isUdf = 1    
 BEGIN    
  SET @udfTableName = 'udf'+@section    
  SET @SQL = 'IF NOT EXISTS (SELECT udfid FROM dbo.'+@udfTableName+' WHERE fk'+@tableKey+'='''+@fkValue+''')
					BEGIN 
						INSERT INTO dbo.'+@udfTableName+' (fk'+@tableKey+') SELECT '''+@fkValue+''' SET @newRecord = 1 
					END'     
 END    
 ELSE    
 BEGIN    
  SET @udfTableName = 'udt'+@section    
  -- 04/12/2018 Vijay G: Modified the incorrect syntax at  SET @newRecord = 1 END'    
  SET @SQL = 'IF NOT EXISTS (SELECT udfid FROM dbo.'+@udfTableName+' WHERE udfid='''+convert(nvarchar(36), @udfId)+''')
				BEGIN 
					INSERT INTO dbo.'+@udfTableName+' (fk'+@tableKey+',udfId) 
							VALUES ('''+@fkValue+''','''+convert(nvarchar(36), @udfId)+''')
					SET @newRecord = 1 
				END'    
 END    
    
 --10/16/2018 Rajendra K : Added condition to check udf table exists or not    
 IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = @udfTableName))    
 BEGIN    
 -- 13/07/15 Anuj Added IsUdfId to Check UDF or UDT    
 EXECUTE sp_executesql @SQL, N'@newRecord bit OUTPUT',@newRecord=@newRecord OUTPUT     
 IF @isUdf = 1 AND (@sectionName IS NOT NULL AND @sectionName != '') AND (@subSection IS NOT NULL AND @subSection != '') AND @categoryName IS NOT NULL -- 11/06/2017 Raviraj P :  Added custom CAPACategoryUDF condition    
                   -- 09/27/2018 Nitesh B : Modified condition for Inventor    
 BEGIN    
  SET @SQL='SELECT * FROM dbo.'+@udfTableName+' WHERE fk'+@tableKey+'='''+@fkValue + ''''    
 END    
 ELSE IF @isUdf = 1    
 BEGIN    
  SET @SQL='SELECT * FROM dbo.'+@udfTableName+' WHERE fk'+@tableKey+'='''+@fkValue + ''''    
 END    
 ELSE    
 BEGIN    
  SET @SQL='SELECT * FROM dbo.'+@udfTableName+' WHERE udfid='''+convert(nvarchar(36), @udfId)+''''    
 END    
  EXEC (@SQL)    
  --10/15/2018 Nitesh B : Added parameter @newSubSection    
  DECLARE @newSubSection VARCHAR(200)= 
		CASE 
			WHEN  @sectionName = 'CAPACategoryUDF' 
			THEN  @subSection ELSE 'udf' + @sectionName 
		END    
  EXEC UDFTableConfigGet @sectionName, @isUdf,@categoryName,@newSubSection    
  --EXEC UDFTableConfigGet @sectionName, @isUdf,@categoryName    
 IF @newRecord = 1    
 BEGIN    
 IF @isUdf = 1    
 BEGIN    
  SET @SQL='DELETE FROM dbo.'+@udfTableName+' WHERE fk'+@tableKey+'='''+@fkValue+''''    
 END    
 ELSE    
 BEGIN    
   SET @SQL='DELETE FROM dbo.'+@udfTableName+' WHERE udfid='''+convert(nvarchar(36), @udfId)+''''    
 END    
 EXEC(@SQL)    
 END    
 -- 06/06/2018 Vijay G: Get UDF record is new or existing    
 SELECT @newRecord AS isNewRecord    
 END    
END  