-- Author:	Rajendra K
-- Create date: 10/15/2018
-- Description:	get Lot udf table values
-- 11/01/2018 Nitesh B : Added COLUMN m.NUMERIC_SCALE  in select list
-- 11/05/2018 Raviraj : Remove space if part class having space
CREATE PROCEDURE GetUdfInventorLotGridColumns
(
@uniqKey CHAR(10)
)
AS
BEGIN
   SET NOCOUNT ON
   DECLARE @SQL nvarchar(max) ;DECLARE @SQL1 nvarchar(max) 
   SET @SQL  = (SELECT TOP 1 'UdfInvtlot_'+(REPLACE(REPLACE(RTRIM(I.Part_Class),'-','_'), ' ', '_')) AS ColumnName FROM INVENTOR I WHERE UNIQ_KEY = @UniqKey)
   IF OBJECT_ID (N''+@SQL+'', N'U') IS NOT NULL
   BEGIN
    SELECT m.ORDINAL_POSITION,m.COLUMN_NAME,m.COLUMN_DEFAULT,CASE WHEN m.IS_NULLABLE='NO' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END IS_NULLABLE,m.DATA_TYPE,
	--m.CHARACTER_MAXIMUM_LENGTH,
	--Sachin s 10-15-2015 CHARACTER_MAXIMUM_LENGTH value get the null value so replace from NUMERIC_PRECISION
	CASE WHEN (m.CHARACTER_MAXIMUM_LENGTH IS NULL )
							 THEN  m.NUMERIC_PRECISION 
                  ELSE m.CHARACTER_MAXIMUM_LENGTH 
             END  AS CHARACTER_MAXIMUM_LENGTH,
	
	um.listString,um.dynamicSQL,
	m.NUMERIC_SCALE -- 11/01/2018 Nitesh B : Added COLUMN m.NUMERIC_SCALE  in select list
		FROM INFORMATION_SCHEMA.COLUMNS m LEFT OUTER JOIN UDFMeta um 
		ON m.COLUMN_NAME=um.udfField and um.udfTable = @SQL -- 9/30/2016 Raviraj :Join the udfmeta with udftable name to avoid duplicate entries with same name
		WHERE TABLE_NAME = @SQL ORDER BY ORDINAL_POSITION ASC;
   END
END		