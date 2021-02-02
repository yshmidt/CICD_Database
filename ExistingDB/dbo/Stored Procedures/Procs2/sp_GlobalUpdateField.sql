-- 03/25/13 VL changed the length of @lcValue from char(10) to varchar(max)
--ALTER PROCEDURE [dbo].[sp_GlobalUpdateField] @ltTableFieldname AS tTableFieldname READONLY, @lcValue AS char(10) = ' ', @lcCriteria AS nvarchar(2000) = ' '
CREATE PROCEDURE [dbo].[sp_GlobalUpdateField] @ltTableFieldname AS tTableFieldname READONLY, @lcValue AS varchar(max) = ' ', @lcCriteria AS nvarchar(2000) = ' '
AS

-- @ltTableFieldname: The table that contain Tablename and Fieldname
-- @lcValue: the value that will update
-- @lcCriteria: the WHERE clause

BEGIN

SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;	

DECLARE @ZUpdTable TABLE (nrecno int identity, TableName nvarchar(128), FieldName nvarchar(128))
DECLARE @lnTotalNo int, @lnCount int, @lcTableName nvarchar(128), @lcFieldName nvarchar(128), @lcSQLString nvarchar(4000)

INSERT @ZUpdTable (TableName, FieldName)
SELECT TableName, FieldName
	FROM @ltTableFieldName
	ORDER BY Tablename, FieldName

SET @lnTotalNo = @@ROWCOUNT;
	
IF (@lnTotalNo>0)
BEGIN	
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @lcTableName = TableName, @lcFieldName = FieldName
			FROM @ZUpdTable WHERE nrecno = @lnCount
		IF (@@ROWCOUNT<>0)
		BEGIN
			SELECT @lcSQLString = 'UPDATE '+ LTRIM(RTRIM(@lcTableName)) + ' SET ' + LTRIM(RTRIM(@lcFieldName)) + ' = '''
							+LTRIM(RTRIM(@lcValue)) + ''' WHERE ' + LTRIM(RTRIM(@lcCriteria))  
			EXECUTE sp_executesql @lcSQLString
		END
	END
END
			
END TRY

BEGIN CATCH
	RAISERROR('Error occurred in globally updating values. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END		