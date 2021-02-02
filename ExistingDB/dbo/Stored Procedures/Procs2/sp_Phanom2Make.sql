-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/09/19
-- Description:	Obsolete all BOM items for an inactive BOM assembly
-- =============================================
CREATE PROCEDURE [dbo].[sp_Phanom2Make] @lcUniq_key char(10) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;		


	DECLARE @lcPart_Sourc char(10)

	SELECT @lcPart_Sourc = Part_Sourc
		FROM INVENTOR
		WHERE UNIQ_KEY = @lcUniq_key
		AND PART_SOURC <> 'CONSG'

	IF (@@ROWCOUNT=0) OR @lcPart_Sourc <> 'PHANTOM'
	BEGIN
		RAISERROR('Part number entered is not a Phaantom part.',1,1)
		ROLLBACK TRANSACTION
		RETURN	
	END 

	UPDATE Inventor 
		SET Part_sourc = 'MAKE', 
			Bom_lastdt = GETDATE()
	WHERE Uniq_key = @lcUniq_key
	
END TRY

BEGIN CATCH
	RAISERROR('Error occurred in changing PHANTOM part to MAKE part. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END