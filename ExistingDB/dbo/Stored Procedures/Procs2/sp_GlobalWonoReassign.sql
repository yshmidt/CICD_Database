create PROCEDURE [dbo].[sp_GlobalWonoReassign] @lcOldWono AS char(10) = ' ', @lcNewWono AS char(10) = ' '
AS

BEGIN

SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;	

DECLARE @ZUpdWo TABLE (nrecno int identity, TableName nvarchar(128), FieldName nvarchar(128))
DECLARE @lnTotalNo int, @lnCount int, @lcTableName nvarchar(128), @lcFieldName nvarchar(128), @lcSQLString nvarchar(4000)

INSERT @ZUpdWo
SELECT O.Name AS TableName, C.Name AS FieldName 
	FROM sys.all_objects O, sys.all_columns C
	WHERE O.Object_id = C.Object_id
	AND (LTRIM(RTRIM(C.Name)) = 'wono'
	OR LTRIM(RTRIM(C.Name)) = 'oldwono')
	AND Type = 'U'
	ORDER BY Tablename

SET @lnTotalNo = @@ROWCOUNT;
	
IF (@lnTotalNo>0)
BEGIN	
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @lcTableName = TableName, @lcFieldName = FieldName
			FROM @ZUpdWo WHERE nrecno = @lnCount
		IF (@@ROWCOUNT<>0)
		BEGIN
			SELECT @lcSQLString = 'UPDATE '+ LTRIM(RTRIM(@lcTableName)) + ' SET ' + LTRIM(RTRIM(@lcFieldName)) + ' = ''' 
							+@lcNewWono + ''' WHERE ' + LTRIM(RTRIM(@lcFieldName)) + ' = ''' + @lcOldWono + ''''
							
			EXECUTE sp_executesql @lcSQLString
		END
	END
END
			
END TRY

BEGIN CATCH
	RAISERROR('Error occurred in re-assigning work order number. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END		
