-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- Modified: 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[PhyInvtNotReconcileView] @lcUniqPiHead AS char(10) = ''
AS
BEGIN

SET NOCOUNT ON;

-- 06/05/12 VL changed InvtSer.SerialUniq NOT IN to InvtSer.Serialno NOT IN, and added parameter for this view, should only select for passed UniqPhyNo
--10/09/04 YS use one sql and not exists instead of 2 below.
-- SqlResult
SELECT Part_no, Revision, SerialNo, SerialUniq, Inventor.UNIQ_KEY, UniqPhyNo
	FROM INVENTOR, INVTSER, PhyInvt
	WHERE Inventor.UNIQ_KEY = InvtSer.UNIQ_KEY
	AND Invtser.UNIQ_KEY = PhyInvt.UNIQ_KEY
	AND PhyInvt.W_KEY = Invtser.ID_VALUE
	AND Invtser.ID_KEY = 'W_KEY'
	AND Invtser.ISRESERVED = 1
	AND InvtSer.LOTCODE = PhyInvt.LOTCODE
	AND InvtSer.REFERENCE = PhyInvt.REFERENCE
	AND ISNULL(InvtSer.Expdate,1) = ISNULL(PhyInvt.Expdate,1)
	AND InvtSer.PONUM = PhyInvt.Ponum
	AND UniqPiHead = @lcUniqPiHead
	AND (InvRecncl = 0
			AND INIT <> ''
			AND (PhyDATE <> ''
			OR PhyDATE IS NOT NULL))	
	AND NOT EXISTS
	(SELECT 1 from PhyInvtSer Where UniqPiHead = @lcUniqPiHead and UniqPhyNo=PhyInvt.UNIQPHYNO and Serialno=InvtSer.Serialno)
	ORDER BY 1,2,3;

--WITH ZPhyInvtSer AS
--(
--SELECT Serialno, UniqPhyNo 
--	FROM PhyInvtSer
--	WHERE PhyInvtSer.UniqPhyNo IN
--		(SELECT UniqPhyNo 
--			FROM PhyInvt
--			WHERE InvRecncl = 0
--			AND INIT <> ''
--			AND (PhyDATE <> ''
--			OR PhyDATE IS NOT NULL))
--	AND UniqPiHead = @lcUniqPiHead
--)
---- SQL result -- all the SN that are reserved but not in PhyInvtser table
---- 06/05/12 VL changed InvtSer.SerialUniq NOT IN to InvtSer.Serialno NOT IN
--SELECT Part_no, Revision, SerialNo, SerialUniq, Inventor.UNIQ_KEY, UniqPhyNo
--	FROM INVENTOR, INVTSER, PhyInvt
--	WHERE Inventor.UNIQ_KEY = InvtSer.UNIQ_KEY
--	AND Invtser.UNIQ_KEY = PhyInvt.UNIQ_KEY
--	AND PhyInvt.W_KEY = Invtser.ID_VALUE
--	AND Invtser.ID_KEY = 'W_KEY'
--	AND Invtser.ISRESERVED = 1
--	AND InvtSer.LOTCODE = PhyInvt.LOTCODE
--	AND InvtSer.REFERENCE = PhyInvt.REFERENCE
--	AND ISNULL(InvtSer.Expdate,1) = ISNULL(PhyInvt.Expdate,1)
--	AND InvtSer.PONUM = PhyInvt.Ponum
--	AND UniqPiHead = @lcUniqPiHead
--	AND (InvRecncl = 0
--			AND INIT <> ''
--			AND (PhyDATE <> ''
--			OR PhyDATE IS NOT NULL))	
--	AND InvtSer.Serialno NOT IN 
--		(SELECT Serialno
--			FROM ZPhyInvtSer)
--	ORDER BY 1,2,3;

-- Prepare to select records which
-- 1.) Invtmfgr.QTY_OH < PhyInvt.QTY_OH - PhyInvt.PhyCount
-- 2.) Invtmfgr.Reserved > PhyInvt.PhyCount
--10/09/14 YS removed invtmfhd table and replace with 2 new tables
-- also combine 2 sql in 1

--;WITH ZInvtmfgr AS
--(SELECT PhyInvt.Uniq_key, INVTMFGR.W_key, Invtmfgr.QTY_OH AS Qty_Oh, PhyInvt.QTY_OH - PhyInvt.PhyCount AS Reduced_Qty, 
--	Invtmfgr.RESERVED AS ReservedQty, PhyInvt.Phycount, UniqPhyNo
--	FROM INVTMFGR, PhyInvt
--	WHERE Invtmfgr.W_KEY = PhyInvt.W_KEY
--	AND (Invtmfgr.QTY_OH < PhyInvt.QTY_OH - PhyInvt.PHYCOUNT
--	OR Reserved > PhyInvt.PhyCount)
--	AND (InvRecncl = 0
--			AND INIT <> ''
--			AND (PhyDATE <> ''
--			OR PhyDATE IS NOT NULL))	
--	AND PhyInvt.Qty_oh > Phycount
--	AND PhyInvt.LOTCODE = ''
--	AND UniqPiHead = @lcUniqPiHead
--UNION
--SELECT PhyInvt.Uniq_key, InvtLot.W_KEY, Invtlot.LOTQTY AS Qty_Oh, PhyInvt.QTY_OH - PhyInvt.PhyCOUNT AS Reduced_Qty, 
--	Invtlot.LOTRESQTY AS ReservedQty, PhyInvt.Phycount, UniqPhyNo
--	FROM INVTLOT, PhyInvt
--	WHERE Invtlot.W_key = PhyInvt.W_KEY
--	AND Invtlot.LOTCODE = PhyInvt.LOTCODE
--	AND Invtlot.REFERENCE = PhyInvt.REFERENCE
--	AND ISNULL(Invtlot.EXPDATE,1) = ISNULL(PhyInvt.Expdate,1)
--	ANd Invtlot.PONUM = PhyInvt.PONUM
--	AND (LotQty < PhyInvt.Qty_Oh - PhyInvt.PhyCount
--	OR LotResQty > PhyInvt.PhyCount)	
--	AND (InvRecncl = 0
--			AND INIT <> ''
--			AND (PhyDATE <> ''
--			OR PhyDATE IS NOT NULL))	
--	AND PhyInvt.Qty_oh > Phycount
--	AND PhyInvt.LOTCODE <> ''
--	AND UniqPiHead = @lcUniqPiHead
--)		
---- SQL result 1
--SELECT DISTINCT Part_no, Revision, ZInvtmfgr.*, Invtmfhd.PARTMFGR, Invtmfhd.Mfgr_pt_no
--	FROM INVENTOR, ZInvtmfgr, Invtmfgr, Invtmfhd
--	WHERE Inventor.UNIQ_KEY = ZInvtmfgr.Uniq_key
--	AND ZInvtmfgr.W_KEY = Invtmfgr.W_key
--	AND Invtmfgr.UniqMfgrhd = Invtmfhd.UniqMfgrhd
--	ORDER BY 1,2

-- SqlResult1
SELECT PhyInvt.Uniq_key, INVTMFGR.W_key, Invtmfgr.QTY_OH AS Qty_Oh, PhyInvt.QTY_OH - PhyInvt.PhyCount AS Reduced_Qty, 
	Invtmfgr.RESERVED AS ReservedQty, PhyInvt.Phycount, UniqPhyNo,M.PartMfgr,M.mfgr_pt_no
	FROM INVTMFGR INNER JOIN PhyInvt ON Invtmfgr.W_KEY = PhyInvt.W_KEY
	INNER JOIN InvtMPNLink L ON Invtmfgr.UNIQMFGRHD=L.uniqmfgrhd
	INNER JOIN MfgrMaster M ON L.mfgrMasterid=M.MfgrMasterId
	WHERE (Invtmfgr.QTY_OH < PhyInvt.QTY_OH - PhyInvt.PHYCOUNT
	OR Reserved > PhyInvt.PhyCount)
	AND (InvRecncl = 0
			AND INIT <> ''
			AND (PhyDATE <> ''
			OR PhyDATE IS NOT NULL))	
	AND PhyInvt.Qty_oh > Phycount
	AND PhyInvt.LOTCODE = ' '
	AND UniqPiHead = @lcUniqPiHead
UNION
SELECT PhyInvt.Uniq_key, InvtLot.W_KEY, Invtlot.LOTQTY AS Qty_Oh, PhyInvt.QTY_OH - PhyInvt.PhyCOUNT AS Reduced_Qty, 
	Invtlot.LOTRESQTY AS ReservedQty, PhyInvt.Phycount, UniqPhyNo,M.PartMfgr,M.mfgr_pt_no
	FROM INVTLOT INNER JOIN PhyInvt ON Invtlot.W_key = PhyInvt.W_KEY
	AND Invtlot.LOTCODE = PhyInvt.LOTCODE
	AND Invtlot.REFERENCE = PhyInvt.REFERENCE
	AND ISNULL(Invtlot.EXPDATE,1) = ISNULL(PhyInvt.Expdate,1)
	ANd Invtlot.PONUM = PhyInvt.PONUM
	INNER JOIN InvtMfgr ON Invtmfgr.W_key=PhyInvt.W_KEY
	INNER JOIN InvtMPNLink L ON Invtmfgr.UNIQMFGRHD=L.uniqmfgrhd
	INNER JOIN MfgrMaster M on L.mfgrMasterId=M.MfgrMasterId
	WHERE
	(LotQty < PhyInvt.Qty_Oh - PhyInvt.PhyCount
	OR LotResQty > PhyInvt.PhyCount)	
	AND (InvRecncl = 0
			AND INIT <> ''
			AND (PhyDATE <> ''
			OR PhyDATE IS NOT NULL))	
	AND PhyInvt.Qty_oh > Phycount
	AND PhyInvt.LOTCODE <> ''
	AND UniqPiHead = @lcUniqPiHead
	ORDER BY 1,2

END