-- =============================================
-- Author:		Vicky Lu	
-- Create date: <07/19/12>
-- Description:	<Get all pars that belong to selected inactive customers, will update SO, PO, WO, BOM, qtyoh fields, so later
--				can be used to created XL files and for sp_DeactivateParts4InactiveCustomer sp>
-- 11/30/17 VL Paramit complained that some PO keeps OPEN while all items were received, so we changed to check PO items if all received instead of checking POmain.Postatus
-- =============================================
CREATE PROCEDURE [dbo].[GetParts4Customer] 
	-- Add the parameters for the stored procedure here
	@ltCustList AS tCustno READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @ZTempConsgPT TABLE (Uniq_key char(10), Int_Uniq char(10));
DECLARE @ZTempInternalPT TABLE (Uniq_key char(10), Custno char(10));
-- 01/16/13 VL added HasConsg field to indicate the internal part has consigned part associated with it
DECLARE @FinalParts TABLE (Uniq_key char(10), BOM char(35), PO char(15), SO char(10), WO char(10), TotQtyOH numeric(12,2), 
							HasConsg char(1), Int_Uniq char(10), Ok char(1))

-- First get all internal parts and consg parts for selected customers, but filter out those parts if the internal parts have other CONSG part
INSERT @ZTempConsgPt
	SELECT Uniq_key, Int_Uniq
		FROM Inventor 
		WHERE Status = 'Active'
		AND Custno IN (SELECT Custno FROM @ltCustList)

INSERT @ZTempInternalPT
	SELECT I1.Uniq_key, I2.Custno
		FROM Inventor AS I1,Inventor AS I2
		WHERE I1.Status = 'Active'
		AND I1.Uniq_key = I2.Int_uniq
		AND I1.Uniq_key IN (SELECT Int_uniq FROM @ZTempConsgPt);

-- 01/16/13 VL moved this part to bottom
---- This parts have to be excluded, because the internal part has other CONSG parts associated with it
--WITH ZExcludedPt
--AS
--(
--SELECT Uniq_key
--	FROM @ZTempInternalPT
--	WHERE Custno NOT IN
--		(SELECT Custno FROM @ltCustList)
--)

-- 01/16/13 VL decide not to exclude parts in (ZExcludedPt) now, will just mark it as NotInactive, so user still can know those parts exist, just not de-activate
-- Now join internal part (filter out those have other CONSG internal part) with consg parts
--INSERT @FinalParts (Uniq_key) 
--SELECT ZI.Uniq_key
--	FROM @ZTempInternalPT ZI
--	WHERE Uniq_key NOT IN (SELECT Uniq_key FROM ZExcludedPt)
--UNION 
--SELECT ZC.Uniq_key
--	FROM @ZTempConsgPT ZC

INSERT @FinalParts (Uniq_key, Int_Uniq) 
SELECT ZI.Uniq_key, SPACE(10)
	FROM @ZTempInternalPT ZI
UNION 
SELECT ZC.Uniq_key, Int_Uniq
	FROM @ZTempConsgPT ZC
	

-- Update BOM field if the part is in a bom of an active product
UPDATE @FinalParts
	SET BOM = Inventor.PART_NO+'/'+Inventor.REVISION
	FROM @FinalParts F, BOM_DET, Inventor
	WHERE F.Uniq_key = Bom_det.UNIQ_KEY
	AND Bom_det.BOMPARENT = Inventor.UNIQ_KEY
	AND Inventor.STATUS = 'Active'

-- Update PO field if the part has OPEN PO items
-- 11/30/17 VL Paramit complained that some PO keeps OPEN while all items were received, so we changed to check PO items if all received instead of checking POmain.Postatus
UPDATE @FinalParts
	SET PO = PM.Ponum
	FROM @FinalParts F, POMAIN PM, POITEMS PI
	WHERE F.Uniq_key = PI.UNIQ_KEY
	AND PM.PONUM = PI.Ponum
	AND (PM.POSTATUS <> 'CANCEL'
	AND PM.POSTATUS <> 'CLOSED')

	UPDATE @FinalParts
	SET PO = Poitems.Ponum
	FROM @FinalParts F INNER JOIN POITEMS
	ON F.Uniq_key = POitems.UNIQ_KEY
	WHERE Poitems.Ord_qty <> Poitems.Acpt_qty
	AND lCancel = 0
-- 11/30/17 VL End

-- Update SO field if the part has OPEN SO status
UPDATE @FinalParts
	SET SO = SM.Sono
	FROM @FinalParts F, Somain SM, SODETAIL SD
	WHERE F.Uniq_key = SD.UNIQ_KEY
	AND SM.SONO = SD.SONO
	AND SM.ORD_TYPE = 'Open'

-- Update WO field if the part has OPEN WO status
UPDATE @FinalParts
	SET WO = WO.Wono
	FROM @FinalParts F, WOENTRY WO
	WHERE F.Uniq_key = WO.UNIQ_KEY
	AND (WO.OPENCLOS <> 'Cancel'
	AND WO.OPENCLOS <> 'Closed');

-- Check if the parts have qty_oh > 0
WITH ZQtyOH AS
(
SELECT Uniq_key, SUM(Qty_OH) AS TotalQtyOH
	FROM INVTMFGR 
	WHERE UNIQ_KEY IN 
		(SELECT UNIQ_KEY 
			FROM @FinalParts)
	GROUP BY Uniq_key
)	
	
UPDATE @FinalParts
	SET TotQtyOH = I.TotalQtyOH
	FROM @FinalParts F, ZQtyOH I
	WHERE F.Uniq_key = I.UNIQ_KEY

-- This parts have to be excluded, because the internal part has other CONSG parts associated with it
;
WITH ZExcludedPt
AS
(
SELECT Uniq_key
	FROM @ZTempInternalPT
	WHERE Custno NOT IN
		(SELECT Custno FROM @ltCustList)
)
-- 01/16/13 VL added code to update HasConsg field
UPDATE @FinalParts
	SET HasConsg = 'Y'
	WHERE Uniq_key IN 
		(SELECT Uniq_key FROM ZExcludedPt)

-- 01/17/13 VL found a situation that a CONSG has qty_oh, can not be deactivated, but the INTERNAL part has no qty_oh,
-- this internal part would be deactivated and leave the CONSG not deactivated, here will mark INTERNAL can not be deactivated too
UPDATE @FinalParts
	SET HasConsg = 'Y'
	WHERE Int_Uniq = ''
	AND Uniq_key IN 
		(SELECT Int_Uniq
			FROM @FinalParts 
			WHERE Int_Uniq <> ''
			AND TotQtyOH <> 0)

-- Final update OK field if xall fields are empty and no qty_oh
UPDATE @FinalParts
	SET Ok = 'Y'
	WHERE BOM IS NULL
	AND PO IS NULL
	AND SO IS NULL
	AND WO IS NULL
	AND TotQtyOH = 0.00	
	AND HasConsg IS NULL

SELECT PART_NO, Revision, Part_Sourc, ISNULL(F.Uniq_key, SPACE(10)) AS Uniq_key, ISNULL(F.BOM, SPACE(35)) AS BOM,
	ISNULL(F.PO, SPACE(15)) AS PO, ISNULL(F.SO, SPACE(10)) AS SO, ISNULL(F.WO, SPACE(10)) AS WO, ISNULL(F.TotQtyOH, 0.00) AS TotQtyOH,
	ISNULL(F.HasCONSG, ' ') AS HasConsg, ISNULL(F.Int_Uniq, SPACE(10)) AS Int_Uniq, ISNULL(F.Ok, ' ') AS Ok
	FROM Inventor, @FinalParts F
	WHERE Inventor.UNIQ_KEY = F.Uniq_key
	ORDER BY 1,2 
		
END