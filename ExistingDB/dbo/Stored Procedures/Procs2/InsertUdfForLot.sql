-- =============================================
-- Author:	Rajendra k
-- Create Date: 04/23/2019
-- Description:	To insert udf lot copy into udf table. 
-- EXEC [dbo].[InsertUdfForLot]  '_1ZH0JLRML','B46AMERBI7','OYKCSXMU4Z'
-- =============================================															
CREATE PROCEDURE [dbo].[InsertUdfForLot] 
(  
@uniqKey AS CHAR(10),  
@oldUniqLot AS CHAR(10),
@newUniqLot AS CHAR(10)
)  
AS  
BEGIN  
	SET NOCOUNT ON;  
	DECLARE @udfTableName VARCHAR(20),@Part_class VARCHAR (20),@uniqlotcode VARCHAR(MAX)
	DECLARE @SQl VARCHAR(MAX)
	IF OBJECT_ID(N'tempdb..##TEMP') IS NOT NULL
    DROP TABLE ##TEMP;
	IF OBJECT_ID(N'tempdb..##TEMPTABLE') IS NOT NULL
    DROP TABLE ##TEMPTABLE;

	
	SET @Part_class = (SELECT RTRIM(PART_CLASS) FROM INVENTOR WHERE UNIQ_KEY = @uniqKey)
	SET @udfTableName =  'udfinvtlot' +'_'+ REPLACE(@Part_class,'-','_') 
	
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @udfTableName)
	BEGIN 
	SET @SQl = 'SELECT * INTO ##TEMPTABLE FROM  '+ @udfTableName +' WHERE fkUNIQ_LOT LIKE ''%' + @newUniqLot + '%'''	
	EXEC(@SQl);
		IF NOT EXISTS(SELECT 1 FROM ##TEMPTABLE)
			BEGIN
			SET @uniqlotcode = N'SELECT * INTO  ##TEMP FROM  '+ @udfTableName +' WHERE fkUNIQ_LOT LIKE ''%' + @oldUniqLot + '%'''
			EXEC(@uniqlotcode);	  
				IF EXISTS(SELECT 1 FROM  ##TEMP WHERE fkUNIQ_LOT = @oldUniqLot)
				BEGIN
					UPDATE  ##TEMP SET fkUNIQ_LOT = @newUniqLot,udfId = NEWID() WHERE fkUNIQ_LOT = @oldUniqLot;
					SET @uniqlotcode = N'INSERT INTO ' + @udfTableName +' SELECT * FROM ##TEMP WHERE fkUNIQ_LOT LIKE ''%' + @newUniqLot + '%'''
					EXEC(@uniqlotcode);	
				END
				DROP TABLE ##TEMP;
			END
			DROP TABLE ##TEMPTABLE;
	END	
END	