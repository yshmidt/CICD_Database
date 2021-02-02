
-- =============================================
-- Author : Shrikant B
-- Created date : 12/08/2018
-- Description : GET UDF Record to check udf has data (Checks bom Item level or header level UDF)
-- 05/09/2019  : Shrikant fixed the issue of when table exists then only select udf data
-- CheckBomIOrHLevelUdf 'BOM Details', 'SRBLHZODCW'
-- CheckBomIOrHLevelUdf 'BOM Header', 'HF663J1Y2J'
-- =============================================
CREATE PROC [dbo].[CheckBomIOrHLevelUdf]
	@sectionName varchar(200),  
	@fkValue varchar(200)
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
	DECLARE @udfTableName varchar(200),@SQL nvarchar(MAX), @tableKey varchar(50), @tableName varchar(200), @section varchar(200)  
   
	SELECT @tableName=mainTable FROM MnxUdfSections WHERE section=@sectionName  
	IF(@tableName IS NULL) SET @tableName=@sectionName  
	SELECT @section=REPLACE(section,' ','_')FROM MnxUdfSections WHERE section=@sectionName
  
	BEGIN  
		--Get Primary Key  
		SELECT @tableKey=COLUMN_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME=@tableName  
		--SET @udfTableName =  @subSection +'_'+ REPLACE(REPLACE(@categoryName,'-','_'),' ','_') --10/15/2018 Nitesh B : Replced above statement   
		--SET @SQL = 'IF EXISTS (SELECT udfid FROM dbo.udf'+@section+' WHERE fk'+@tableKey+'='''+@fkValue+''')
-- 05/09/2019  : Shrikant fixed the issue of when table exists then only select udf data
		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'udf'+@section+'')
		 SET @SQL =  'SELECT * FROM dbo.udf'+@section+' WHERE fk'+@tableKey+'='''+@fkValue+''''
	END

	EXEC(@SQL)  
END  