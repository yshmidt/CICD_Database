-- =============================================
-- Author:		Vicky Lu
-- Create date: ???
-- Description:	Cycle Count
-- Modified:	10/08/14 YS replace invtmfhd with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[CycleNotReconcileView]
AS
BEGIN

SET NOCOUNT ON;

-- 06/05/12 VL changed InvtSer.SerialUniq NOT IN to InvtSer.Serialno NOT IN

WITH ZCycleSer AS
(
SELECT Serialno, UniqCcno 
	FROM CYCLESER
	WHERE CycleSer.UNIQCCNO IN
		(SELECT UNIQCCNO 
			FROM CCRECORD
			WHERE CCRECNCL = 0
			AND CCINIT <> ''
			AND (CCDATE <> ''
			OR CCDATE IS NOT NULL))
)
-- 05/10/12 VL added lot code criteria
-- 06/05/12 VL changed InvtSer.SerialUniq NOT IN to InvtSer.Serialno NOT IN
-- SQL result -- all the SN that are reserved but not in CycleSer table
SELECT Part_no, Revision, SerialNo, SerialUniq, Inventor.UNIQ_KEY, UniqCcno
	FROM INVENTOR, INVTSER, Ccrecord
	WHERE Inventor.UNIQ_KEY = InvtSer.UNIQ_KEY
	AND Invtser.UNIQ_KEY = Ccrecord.UNIQ_KEY
	AND Ccrecord.W_KEY = Invtser.ID_VALUE
	AND Invtser.ID_KEY = 'W_KEY'
	AND Invtser.ISRESERVED = 1
	AND InvtSer.LOTCODE = Ccrecord.LOTCODE
	AND InvtSer.REFERENCE = Ccrecord.REFERENCE
	AND ISNULL(InvtSer.Expdate,1) = ISNULL(Ccrecord.Expdate,1)
	AND InvtSer.PONUM = Ccrecord.Ponum	
	AND (CCRECNCL = 0
			AND CCINIT <> ''
			AND (CCDATE <> ''
			OR CCDATE IS NOT NULL))	
	AND InvtSer.Serialno NOT IN 
		(SELECT Serialno
			FROM ZCycleSer)
	ORDER BY 1,2,3;

-- Prepare to select records which
-- 1.) Invtmfgr.QTY_OH < Ccrecord.QTY_OH - Ccrecord.CCOUNT
-- 2.) Invtmfgr.Reserved > Ccrecord.CCount

WITH ZInvtmfgr AS
(SELECT Ccrecord.Uniq_key, INVTMFGR.W_key, Invtmfgr.QTY_OH AS Qty_Oh, Ccrecord.QTY_OH - Ccrecord.CCOUNT AS Reduced_Qty, 
	Invtmfgr.RESERVED AS ReservedQty, Ccrecord.Ccount, UniqCcno, CCRECORD.UniqMfgrhd
	FROM INVTMFGR, CCRECORD
	WHERE Invtmfgr.W_KEY = Ccrecord.W_KEY
	AND (Invtmfgr.QTY_OH < Ccrecord.QTY_OH - Ccrecord.CCOUNT
	OR Reserved > Ccrecord.CCount)
	AND (CCRECNCL = 0
		AND CCINIT <> ''
		AND (CCDATE <> ''
		OR CCDATE IS NOT NULL))	
	AND Ccrecord.Qty_oh > Ccount
	AND Ccrecord.LOTCODE = ''
UNION
SELECT Ccrecord.Uniq_key, InvtLot.W_KEY, Invtlot.LOTQTY AS Qty_Oh, Ccrecord.QTY_OH - Ccrecord.CCOUNT AS Reduced_Qty, 
	Invtlot.LOTRESQTY AS ReservedQty, Ccrecord.Ccount, UniqCcno, CCRECORD.UniqMfgrhd
	FROM INVTLOT, CCRECORD
	WHERE Invtlot.W_key = Ccrecord.W_KEY
	AND Invtlot.LOTCODE = Ccrecord.LOTCODE
	AND Invtlot.REFERENCE = Ccrecord.REFERENCE
	AND ISNULL(Invtlot.EXPDATE,1) = ISNULL(Ccrecord.Expdate,1)
	ANd Invtlot.PONUM = Ccrecord.PONUM
	AND (LotQty < Ccrecord.Qty_Oh - Ccrecord.CCount
	OR LotResQty > Ccrecord.CCount)	
	AND (CCRECNCL = 0
		AND CCINIT <> ''
		AND (CCDATE <> ''
		OR CCDATE IS NOT NULL))	
	AND Ccrecord.Qty_oh > Ccount
	AND Ccrecord.LOTCODE <> ''
)		
-- SQL result 1
--10/08/14 YS replace invtmfhd with 2 new tables
--SELECT DISTINCT Part_no, Revision, ZInvtmfgr.*, Invtmfhd.PARTMFGR, Invtmfhd.Mfgr_pt_no
--	FROM INVENTOR, ZInvtmfgr, Invtmfhd
--	WHERE Inventor.UNIQ_KEY = ZInvtmfgr.Uniq_key
--	AND ZInvtmfgr.UniqMfgrhd = Invtmfhd.UniqMfgrhd
--	ORDER BY 1,2
SELECT DISTINCT Part_no, Revision, ZInvtmfgr.*, M.PARTMFGR, M.Mfgr_pt_no
	FROM INVENTOR INNER JOIN  ZInvtmfgr ON Inventor.UNIQ_KEY = ZInvtmfgr.Uniq_key
	INNER JOIN  InvtMPNLink L ON ZInvtmfgr.UniqMfgrhd = L.UniqMfgrhd
	INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
	ORDER BY Part_no, Revision


	
END	