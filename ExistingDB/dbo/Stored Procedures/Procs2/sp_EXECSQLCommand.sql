create PROCEDURE [dbo].[sp_EXECSQLCommand] @ltUpdateTableCommandLine AS tUpdateTableCommandLine READONLY
AS

BEGIN

SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;	


DECLARE @ZUpdTable TABLE (nrecno int identity, lcUpdateCommand nvarchar(4000))
DECLARE @lnTotalNo int, @lnCount int, @lcSQLString nvarchar(4000)

INSERT @ZUpdTable (lcUpdateCommand)
SELECT lcUpdateCommand
	FROM @ltUpdateTableCommandLine

SET @lnTotalNo = @@ROWCOUNT;

IF (@lnTotalNo>0)
BEGIN	
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @lcSQLString = lcUpdateCommand
			FROM @ZUpdTable WHERE nrecno = @lnCount
		IF (@@ROWCOUNT<>0)
		BEGIN
			EXECUTE sp_executesql @lcSQLString
		END
	END
END
			
END TRY

BEGIN CATCH
	RAISERROR('Error occurred in running SQL updating commands. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END		
