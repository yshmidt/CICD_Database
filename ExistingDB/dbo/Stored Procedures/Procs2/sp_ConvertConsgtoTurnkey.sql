-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/09/18
-- Description:	Globally deactive old part (with terminate date), add new replaced part number for selected product number (in system utility)
-- =============================================
CREATE PROCEDURE [dbo].[sp_ConvertConsgtoTurnkey] @lcUniq_key char(10) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;		

DECLARE @lcBomCustno char(10)

SELECT @lcBomCustno = BomCustno 
	FROM INVENTOR
	WHERE UNIQ_KEY = @lcUniq_key

UPDATE Bom_det
	SET UNIQ_KEY = Inventor.INT_UNIQ
	FROM BOM_DET, INVENTOR
	WHERE Bom_det.UNIQ_KEY = Inventor.UNIQ_KEY
	AND Inventor.CUSTNO = @lcBomCustno
	AND Bom_det.BomParent = @lcUniq_key
	

END TRY

BEGIN CATCH
	RAISERROR('Error occurred in converting consigned to turnkey process. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END