CREATE PROC [dbo].[AlloctedWOWIP4WonoView] @gWono AS char(10) = ' '
AS
--------------------------------------------------------------------------------------------
-- Modification
-- 12/15/2014 VL found has to filter out this work order WO-WIP allocation and the PJ WO-WIP allocation, should only get allocation 
--				from other WO and PJ.  [Allocted4PJ4WonoView] [Allocted4WonoView] already get allocation for this WO and PJ
--------------------------------------------------------------------------------------------

;WITH ZWo AS
(
SELECT Wono, PrjUnique 
	FROM WOENTRY
	WHERE WONO = @gWono
),
ZGetAllocatedtoWOWIP AS
(
SELECT Invt_res.*, UniqMfgrhd, Instore, UniqSupno
	FROM Invt_res, Invtmfgr, ZWo
	WHERE Invt_res.W_key = Invtmfgr.W_key
	AND Invtmfgr.Location = 'WO' + @gWono
	AND Invt_res.WONO <> @gWono 
	AND Invt_res.Fk_Prjunique <> ZWo.PrjUnique 
	AND Invtres_no NOT IN 
		(SELECT Refinvtres
			FROM Invt_res)
	AND qtyAlloc > 0
)

SELECT ZGetAllocatedtoWOWIP.*, Part_no, Revision, Part_class, Part_type, Wono AS Issuedto_Wo, 
CASE WHEN PJCTMAIN.PRJNUMBER IS NULL THEN SPACE(10) ELSE PJCTMAIN.PRJNUMBER END AS Issuedto_Prj
	FROM Inventor, ZGetAllocatedtoWOWIP LEFT OUTER JOIN PjctMain
	ON ZGetAllocatedtoWOWIP.Fk_PrjUnique = Pjctmain.Prjunique
	WHERE Inventor.Uniq_key = ZGetAllocatedtoWOWIP.Uniq_key



