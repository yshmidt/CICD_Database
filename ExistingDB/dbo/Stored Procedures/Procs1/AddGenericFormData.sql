-- =============================================
-- Author: Shivshankar Patil	
-- Create date: <02/25/16>
-- Description:	<For adding generic form data> 
-- =============================================
CREATE PROCEDURE [dbo].[AddGenericFormData]
	-- Add the parameters for the stored procedure here
	@tableName varchar(Max), --Generic add form name
	@fieldName varchar(Max) = null,--Table Column Names
	@fieldValue varchar(Max) = null,--Table Column values
	@uniqueColName varchar(200) = null,--Table unique Column name
	@uniqueColType varchar(200) = null--Table unique Column Type
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SQL nvarchar(MAX), @tableMaxValue varchar(200),@dynamicTableSQL nvarchar(MAX),@addValue int, @colUniqueKeyValue VARCHAR(200)=''
	DECLARE @isAutoGenerateId varchar(30),@uniqueKeyValue varchar(200)='', @ColLength nvarchar(Max),@numDefaultColValue varchar(200)='0'
	DECLARE @uniqueKey nvarchar(10),@tableFieldName nvarchar(max),@tableFieldValue nvarchar(max)
	DECLARE @uniqueGuid uniqueidentifier


	     IF (@fieldName  IS NOT NULL AND @fieldName != '' AND  @fieldValue  IS NOT NULL  AND @fieldValue != '') 
		   BEGIN
					 --Used To Check the table unique column contains auto increment OR Not
					 SELECT @isAutoGenerateId=  is_identity FROM sys.columns WHERE object_id = object_id(''+ @tableName +'')  AND name =  ''+@uniqueColName+''
					 --Used to Get Column Length
					 SELECT  @ColLength = CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS IC where TABLE_NAME = ''+ @tableName +'' and COLUMN_NAME =  ''+@uniqueColName+''

			  --IF Table column does not contain auto increment 
			  IF (@isAutoGenerateId =0)
			      BEGIN
					  --Get table Max unique Number
				      SET  @dynamicTableSQL  = N'SELECT TOP 1 @uniqueKey = '  +@uniqueColName+ ' + 1 FROM '+@tableName+' order by '+ @uniqueColName +' DESC'
				      exec sp_executesql @dynamicTableSQL, N'@uniqueKey varchar(100) out', @uniqueKey out
            
			
				--Check table column Type         
				IF(@uniqueColType = '''CHAR''')
				     BEGIN
						 -- Used to formate the column value dynamically
						 SET @colUniqueKeyValue =  dbo.padl(@uniqueKey,@ColLength ,@numDefaultColValue);   
						 --PRINT @colUniqueKeyValue
						 select @colUniqueKeyValue
						 SET @tableFieldName = @fieldName + ',' + @uniqueColName
						 SET @tableFieldValue = @fieldValue + ','''+ @colUniqueKeyValue +''''
				      END

				 ELSE IF (@uniqueColType = '''uniqueidentifier''')
				    BEGIN
						SET @uniqueGuid = NEWID()
					    SET @tableFieldName = @fieldName + ',' + @uniqueColName
					    SET @tableFieldValue = @fieldValue + ','''+ CONVERT(varchar(255),@uniqueGuid) +''''
						
			         END

			   ELSE IF (@uniqueColType = '''uniqueKey''')
				
				    BEGIN
						 SET @colUniqueKeyValue =  dbo.fn_GenerateUniqueNumber();   
					     SET @tableFieldName = @fieldName + ',' + @uniqueColName
						 SET @tableFieldValue = @fieldValue + ','''+ @colUniqueKeyValue +''''
					    
			      END
				  ELSE
				  BEGIN
					 SET @tableFieldName = @fieldName 
					 SET @tableFieldValue = @fieldValue 
					
				  END
				   SET @SQL='INSERT INTO dbo.'+@tableName+'(' + @tableFieldName +') VALUES ('+ @tableFieldValue +')'
				   EXEC(@SQL)
				  END
		          END
			  --Used to update the table
		     ELSE
		        BEGIN
		             SET @SQL=@tableName
					 EXEC(@SQL)
		         END


END