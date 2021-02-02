-- =============================================
-- Author:		Vicky Lu
-- Create date: 10/17/2013
-- Description:	Mark WO-WIP location with 0 qty_oh as deleted in Invtmfgr
-- =============================================

CREATE PROCEDURE [dbo].[sp_ClearWOWIP]
AS
BEGIN

SET NOCOUNT ON;
BEGIN TRANSACTION
BEGIN TRY;		

UPDATE Invtmfgr 
	SET Is_Deleted = 1 
	WHERE LEFT(Location,2) = 'WO' 
	AND Qty_oh = 0 
	AND UniqWh IN 
		(SELECT UniqWh 
			FROM Warehous 
			WHERE Warehouse = 'WO-WIP')

END TRY

BEGIN CATCH
	RAISERROR('Error occurred in clearing WO-WIP locations with zero quantity OH. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
BEGIN
    COMMIT TRANSACTION;
   -- 10/17/2013 using new procedure / table to log scripts
    exec [spMntUpdLogScript] 'sp_ClearWOWIP','Stored Procedure';
   END
END	