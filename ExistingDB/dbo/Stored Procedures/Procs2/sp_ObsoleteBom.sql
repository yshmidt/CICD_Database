-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/09/19
-- Description:	Obsolete all BOM items for an inactive BOM assembly
-- Modification:
-- 01/04/18 VL changed to only update Term_dt if it's not empty, user might already obsolete some items, so keep those dates for BOM history purpose
-- =============================================
CREATE PROCEDURE [dbo].[sp_ObsoleteBom] @lcUniq_key char(10) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

-- 12/05/12 VL changed to update Bom_det.Term_dt to only get date part, no time, otherwise in BOM, it might not show correctly due to th4e time part might affect the bom to display or not
SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;		

	DECLARE @lcPart_Sourc char(10), @lcBom_Status char(10), @ldBomInactdt smalldatetime

	SELECT @lcPart_Sourc = Part_Sourc, @lcBom_Status = Bom_Status, @ldBomInactdt = BomInactdt
		FROM INVENTOR
		WHERE UNIQ_KEY = @lcUniq_key
		AND PART_SOURC <> 'CONSG'

	IF (@@ROWCOUNT=0) OR @lcPart_Sourc <> 'MAKE'
	BEGIN
		RAISERROR('Part number entered is not a MAKE part.',1,1)
		ROLLBACK TRANSACTION
		RETURN	
	END 

	IF @lcBom_Status <> 'Inactive'
	BEGIN
		RAISERROR('Part number entered is not an INACTIVE BOM.',1,1)
		ROLLBACK TRANSACTION
		RETURN	
	END

	UPDATE BOM_DET	
		SET TERM_DT = CONVERT(varchar(10),@ldBomInactdt,110)
		WHERE BOMPARENT = @lcUniq_key
		-- 01/04/18 VL changed to only update Term_dt if it's not empty, user might already obsolete some items, so keep those dates for BOM history purpose
		AND TERM_DT IS NULL
		
	UPDATE INVENTOR 
		SET BOM_LASTDT = GETDATE()
		WHERE UNIQ_KEY = @lcUniq_key	

END TRY

BEGIN CATCH
	RAISERROR('Error occurred in obsoleting all BOM items. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END