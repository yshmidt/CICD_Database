-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/09/18
-- Description:	Globally deactive old part (with terminate date), add new replaced part number for selected product number (in system utility)
---10/07/15 YS need to list all the columns in the insert part
-- =============================================
CREATE PROCEDURE [dbo].[sp_GlobalBOMReplacement] @ltUniqBomno AS tUniqBomno READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

-- 12/04/12 VL changed all GETDAT() to CONVERT(varchar(10),GETDATE(),110), so when in BOM showing bom_det, the time section of GETDATE() won't affect
SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;		

DECLARE @lcNewPartUniq_key char(10)
DECLARE @tZUniqBomno TABLE (OldUniqBomno char(10), NewUniqBomno char(10))

-- Connect old and new uniqbomno
INSERT @tZUniqBomno (OldUniqBomno, NewUniqBomno)
	SELECT UniqBomno AS OldUniqBomno, dbo.fn_GenerateUniqueNumber() AS NewUniqBomno
		FROM @ltUniqBomno
		
SELECT @lcNewPartUniq_key = Uniq_key 
	FROM @ltUniqBomno
	
-- Insert new part number as new bom item
INSERT BOM_DET (UNIQBOMNO, ITEM_NO, BOMPARENT, UNIQ_KEY, DEPT_ID, QTY, OFFSET, TERM_DT, EFF_DT, USED_INKIT)
	SELECT tZUniqBomno.NewUniqBomno AS UniqBomno, ITEM_NO, BOMPARENT, @lcNewPartUniq_key AS UNIQ_KEY, DEPT_ID, QTY, OFFSET, NULL AS TERM_DT, 
		CONVERT(varchar(10),GETDATE(),110) AS EFF_DT, USED_INKIT
		FROM Bom_det, @tZUniqBomno tZUniqBomno
		WHERE Bom_det.UNIQBOMNO = tZUniqBomno.OldUniqBomno
			
-- Now update old Uniqbomno with term_dt 
UPDATE BOM_DET	
	SET TERM_DT = CONVERT(varchar(10),GETDATE(),110)
	WHERE UNIQBOMNO IN
		(SELECT UNIQBOMNO FROM @ltUniqBomno)

-- Update Bom_ref
---10/07/15 YS need to list all the columns in the insert part
INSERT INTO BOM_REF (UniqBomno,Ref_des, Nbr, Assign, Body, Xor, Yor, Orient,  UniqueRef)
	SELECT tZUniqBomno.NewUniqBomno AS UniqBomno, Ref_des, Nbr, Assign, Body, Xor, Yor, Orient, dbo.fn_GenerateUniqueNumber() AS UniqueRef
		FROM BOM_REF, @tZUniqBomno tZUniqBomno
		WHERE BOM_REF.UNIQBOMNO = tZUniqBomno.OldUniqBomno
	

END TRY

BEGIN CATCH
	RAISERROR('Error occurred in updating inactive part number records. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END		