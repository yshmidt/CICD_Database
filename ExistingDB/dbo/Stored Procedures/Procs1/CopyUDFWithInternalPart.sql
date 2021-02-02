
-- ==========================================================================================    
-- Author:  <Sanjay B>    
-- Create date: <04/23/2019>    
-- Description: Copy UDF With Internal Part 
-- exec [CopyUDFWithInternalPart] '2T06HF3J4N','_1LR0NALAL'
-- ==========================================================================================    
CREATE PROCEDURE [dbo].[CopyUDFWithInternalPart]
(  
	@uniqKey AS CHAR(10),  
	@oldUniqKey AS CHAR(10)
)  
AS  
BEGIN  

	SET NOCOUNT ON;  
	DECLARE @udfTableName varchar(20),@Part_class varchar (20),@sql varchar(MAX),@sequal VARCHAR(MAX);

	SELECT @Part_class = PART_CLASS FROM INVENTOR WHERE UNIQ_KEY = @oldUniqKey;
	SET @udfTableName =  'udfInventor_' +(@Part_class);
	
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @udfTableName)
	BEGIN 


		SET @sql = N'SELECT * INTO  ##TEMP FROM  '+ RTRIM(@udfTableName) +' WHERE fkUNIQ_KEY LIKE ''%' + @oldUniqKey + '%''';
		
		EXEC(@sql);
			  
		IF EXISTS(SELECT * FROM ##TEMP WHERE fkUNIQ_KEY = @oldUniqKey)
		BEGIN
			UPDATE ##TEMP SET fkUNIQ_KEY = @uniqKey,udfId = NEWID() WHERE fkUNIQ_KEY = @oldUniqKey;
			SET @sql = N'INSERT INTO ' + RTRIM(@udfTableName) +' SELECT * FROM ##TEMP WHERE fkUNIQ_KEY LIKE ''%' + @uniqKey + '%'''
			EXEC(@sql);
			
			IF OBJECT_ID(N'tempdb..##TEMP') IS NOT NULL
            DROP TABLE ##TEMP;	
		END
	END	
END	