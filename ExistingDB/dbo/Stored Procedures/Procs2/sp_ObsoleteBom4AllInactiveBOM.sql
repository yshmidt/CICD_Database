-- =============================================
-- Author:		Vicky Lu
-- Create date: 2016/10/04
-- Description:	Obsolete all BOM items for ALL inactive BOM assembly
-- Modification:
-- 01/04/18 VL changed to only update Term_dt if it's not empty, user might already obsolete some items, so keep those dates for BOM history purpose
-- =============================================
CREATE PROCEDURE [dbo].[sp_ObsoleteBom4AllInactiveBOM]
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;		

-- Assembly has to be 'MAKE' part
-- Assembly Bom Status = 'Inactive'

DECLARE @ZAllInactiveBOM TABLE (Uniq_key char(10), BomInactdt smalldatetime)
INSERT @ZAllInactiveBOM SELECT Uniq_key, BomInactdt FROM Inventor WHERE Part_Sourc = 'MAKE' AND Bom_Status = 'Inactive'

UPDATE BOM_DET	
	SET TERM_DT = CONVERT(varchar(10),ZAllInactiveBOM.BomInactdt,110) 
	FROM @ZAllInactiveBOM ZAllInactiveBOM
	WHERE BOMPARENT = ZAllInactiveBOM.Uniq_Key
	-- 01/04/18 VL changed to only update Term_dt if it's not empty, user might already obsolete some items, so keep those dates for BOM history purpose
	AND TERM_DT IS NULL

UPDATE INVENTOR 
	SET BOM_LASTDT = GETDATE()
	FROM @ZAllInactiveBOM ZAllInactiveBOM
	WHERE INVENTOR.Uniq_key = ZAllInactiveBOM.Uniq_Key

END TRY

BEGIN CATCH
	RAISERROR('Error occurred in obsoleting all BOM items for all inactive BOM assemblies. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END