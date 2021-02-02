
-- =============================================
-- Author:		<Vicky Lu> 
-- Create date: <01/05/18>
-- Description:	<Clear out all CC records>
-- =============================================
CREATE PROCEDURE [dbo].[sp_ClearAllCC] 
AS

BEGIN
BEGIN TRANSACTION
BEGIN TRY;	

DELETE FROM CCRECORD WHERE CCRECNCL = 0
UPDATE INVTMFGR SET COUNTFLAG = '' WHERE COUNTFLAG = 'C'

EXEC spMntUpdLogScript 'Clear CC','Fix Data'

END TRY

BEGIN CATCH
	RAISERROR('Error occurred in clearing CC records. This operation will be cancelled.',11,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END	            	