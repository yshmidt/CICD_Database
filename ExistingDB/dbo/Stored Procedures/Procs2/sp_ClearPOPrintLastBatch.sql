CREATE PROCEDURE [dbo].[sp_ClearPOPrintLastBatch] 
AS

-- @ltTableFieldname: The table that contain Tablename and Fieldname
-- @lcValue: the value that will update
-- @lcCriteria: the WHERE clause

BEGIN

SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;

	-- 05/14/13 VL added WHERE IsInBatch = 1, so it won't update all records, just update those has in batch before
	UPDATE POMAIN	
		SET ISINBATCH = 0
		WHERE ISINBATCH = 1
		
END TRY

BEGIN CATCH
	RAISERROR('Error occurred in globally updating values. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END			