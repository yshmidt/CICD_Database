-- =============================================
-- Author:		Anuj Kumar
-- Create date: 13/07/15
-- Description:	get udt table values
-- 06/30/2016 Satish : Added to get UDT table value which is created based on sectionName      
-- 06/25/2019 Shrikant : Added The if exists code to avoid error thrown by sp if cutsheet setup not exists or table not exists in Database.  
-- UDTTableValuesGet 'BOM Details', 'U6EX9GPLWH'   
-- =============================================
CREATE PROCEDURE [dbo].[UDTTableValuesGet] 
	-- Add the parameters for the stored procedure here
	@sectionName varchar(200),
	@fkValue varchar(200)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @udfTableName varchar(200),@SQL nvarchar(MAX),@udfTableKeyName varchar(200),@tableKey varchar(50)
 ,@tableName varchar(200),@section varchar(200)      
	DECLARE @newRecord bit = 0
	
	SELECT @tableName=mainTable FROM MnxUdfSections WHERE section=@sectionName
	IF(@tableName IS NULL) SET @tableName=@sectionName
 -- 06/30/2016 Satish : Added to get UDT table value which is created based on sectionName      
 SELECT @section=REPLACE(section,' ','_')FROM MnxUdfSections WHERE section=@sectionName      

	--Get Primary Key
	SELECT @tableKey=COLUMN_NAME FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_NAME=@tableName
	
	--Create the udf table name
 SET @udfTableName = 'udt'+@section  -- 06/30/2016 Satish : Added to get UDT table value which is created based on sectionName      

	--Select all items related to foreign key
-- 06/25/2019 Shrikant : Added The if exists code to avoid error thrown by sp if cutsheet setup not exists or table not exists in Database.  
 IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @udfTableName) 
 BEGIN 
	SET @SQL='SELECT * FROM dbo.'+@udfTableName+' WHERE fk'+@tableKey+'='''+@fkValue+''''
	EXEC (@SQL)
	EXEC UDFTableConfigGet @sectionName, 0
END

END