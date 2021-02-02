-- =============================================
-- Author:		<Vicky Lu>
-- Create date: ??
-- Description:	Get information for autokit
-- Modified: 
----  03/08/15 YS use left outer join for the parttype table. Parts are not required to have a type
----  05/01/15 VL Changed in 2 places to speed up code
----  07/01/15 VL Change the last SQL code to filter out dupicate AVL records and speed up in LEFT OUTER JOIN code
----  08/27/15 VL Changed @ZKitReq1.Qty, ShortQty and @KitReq.Qty from numeric(9,2) to numeric(12,2)
-- Modified: 10/09/14 YS removed invtmfhd table and replace with 2 new tables
-- 10/29/14    move orderpref to invtmpnlink
----  10/01/15 VL Filter out antiavl records in SP instead of in form, the BOMparent field is removed in last SQL result and caused problem to check antiavl in form level
----  11/05/15 VL Changed Revision from char(4) to char(8)
--- 05/17/16 YS added qty_each to kamain table (qty column has total to build all build qty w/o the scrap)
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 07/10/17 YS remove qty_each from kamain. Qty coulmn is populated with qty from bom
 --03/01/18 YS lotcode size change to 25
-- =============================================
CREATE PROCEDURE [dbo].[KitAutoKitView] @gWono AS char(10) = ''
AS
BEGIN

-- 09/27/13 VL added LotDetail to first SQL return, it decides which index to use in form auto kit

SET NOCOUNT ON;
--- 05/17/16 YS added qty_each to kamain table (qty column has total to build all build qty w/o the scrap)

DECLARE @ZKitReq1 TABLE (Dept_id char(4), Uniq_key char(10), BomParent char(10), Qty numeric(12,2), ShortQty numeric(12,2),
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		Used_inKit char(1), Part_Sourc char(8), Part_no char(35), Revision char(8), Descript char(45), Part_class char(8), 
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		Part_type char(8), U_of_meas char(4), Scrap numeric(6,2), SetupScrap numeric(4,0), CustPartNo char(35), SerialYes bit,Qty_Each numeric(12,2))
--- 05/17/16 YS added qty_each to kamain table (qty column has total to build all build qty w/o the scrap)
-- 07/10/17 YS remove qty_each from kamain. Qty coulmn is populated with qty from bom
DECLARE @KitReq TABLE (Wono char(10), Dept_id char(4), Dept_name char(25), Uniq_key char(10), BomParent char(10), 
--- 03/28/17 YS changed length of the part_no column from 25 to 35
	Used_inkit char(1), ReqQty numeric(12,2), Part_sourc char(8), Act_qty numeric(12,2), Part_no char(35), 
	Revision char(8), Descript char(45), Part_class char(8), Part_type char(8), U_of_meas char(4), Qty numeric(12,2), SerialYes bit)

DECLARE	@KitInvtView TABLE (QtyNotReserved numeric(12,2), LotQtyNotReserved numeric(12,2), QtyOh numeric(12,2), 
	LotQtyOh numeric(12,2), QtyReserved numeric(12,2), LotQtyReserved numeric(12,2), Uniq_key char(10), Partmfgr char(8), 
	InStore bit, UniqSupno char(10), Mfgr_pt_no char(30), Wh_gl_nbr char(13), UniqWh char(10), Location char(17), 
	 --03/01/18 YS lotcode size change to 25
	W_key char(10), OrderPref numeric(2,0), Lotcode char(25), Expdate smalldatetime, Ponum char(15), Reference char(12), 
	Warehouse char(6), UniqMfgrhd char(10), Bomparent char(10))
				
DECLARE @llKitAllowNonNettable bit, @BomCustno char(10);

SELECT @llKitAllowNonNettable = isnull(lKitAllowNonNettable,0) FROM KitDef
SELECT @BomCustno = BomCustno FROM INVENTOR WHERE Uniq_key = (SELECT UNIQ_KEY FROM WOENTRY WHERE WONO = @gWono)

INSERT @ZKitReq1 EXEC [KitBomInfoView] @gWono;

--- 05/17/16 YS added qty_each to kamain table (qty column has total to build all build qty w/o the scrap)

INSERT @KitReq SELECT @gWono AS Wono, ZKitReq1.Dept_id, Dept_name, ZKitReq1.Uniq_key, ZKitReq1.Bomparent,
	ZKitReq1.Used_inKit, ZKitReq1.ShortQty AS ReqQty, ZKitReq1.Part_sourc, 0 AS Act_qty, 
	CASE WHEN ZKitReq1.Part_sourc = 'CONSG' THEN ZKitReq1.CustPartNo ELSE ZKitReq1.Part_no END AS Part_no,
	ZKitReq1.Revision, ZKitReq1.Descript, ZKitReq1.Part_class, ZKitReq1.Part_type, ZKitReq1.U_of_meas, ZKitReq1.Qty_each, 
	ZKitReq1.SerialYes
	--,ZKitReq1.Qty_each
	FROM @ZKitReq1 ZKitReq1 LEFT OUTER JOIN Depts
	ON ZKitReq1.Dept_id = DEPTS.Dept_id

-- SQL result 
-- 09/27/13 VL added LotDetail, it decides which index to use in form auto kit
--SELECT * FROM @KitReq;
--  03/08/15 YS use left outer join for the parttype table. Parts are not required to have a type
--SELECT KitReq.*, LotDetail
--	FROM @KitReq KitReq, PARTTYPE 
--	WHERE KitReq.Part_class = Parttype.PART_CLASS
--	AND KitReq.Part_type = Parttype.Part_type
--;

SELECT KitReq.*, ISNULL(LotDetail,CAST(0 as bit)) as LotDetail
	FROM @KitReq KitReq LEFT OUTER JOIN PARTTYPE ON KitReq.Part_class = Parttype.PART_CLASS
	AND KitReq.Part_type = Parttype.Part_type ;
	


--10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- 10/29/14    move orderpref to invtmpnlink
;
WITH ZKitInvt1 AS
(
	SELECT DISTINCT Invtmfgr.qty_oh-Invtmfgr.reserved AS QtyNotReserved,
		Invtmfgr.qty_oh AS QtyOh, Invtmfgr.reserved AS QtyReserved, Invtmfgr.Uniq_key,
		M.Partmfgr, Invtmfgr.InStore, InvtMfgr.UniqSupNo,
		M.Mfgr_pt_no, Warehous.Wh_gl_nbr, Invtmfgr.UniqWh,
		Invtmfgr.Location, Invtmfgr.W_key, L.OrderPref, Warehous.Warehouse, 
		L.UniqMfgrHd, Invtmfgr.NetAble, M.lDisallowKit, Invtmfgr.CountFlag, Bomparent
	FROM Warehous, @KitReq KitReq, Invtmfgr, InvtMPNLink L,MfgrMaster M
	WHERE KitReq.Uniq_key = Invtmfgr.Uniq_key 
	AND Invtmfgr.UniqWh = Warehous.UniqWh
	AND L.UniqMfgrHd = Invtmfgr.UniqMfgrHd 
	AND L.mfgrMasterId=M.MfgrMasterId
	AND M.lDisallowKit = 0
	--AND 1 = (CASE WHEN @llKitAllowNonNettable = 1 THEN 1 ELSE Invtmfgr.NetAble END)
	AND ((@llKitAllowNonNettable = 1) OR (@llKitAllowNonNettable = 0 AND Invtmfgr.NetAble = 1))
	AND Warehouse<>'MRB' AND Warehouse <> 'WIP' AND Warehouse <>'WO-WIP'
	AND Warehous.lNotAutoKit = 0
	AND Invtmfgr.CountFlag= SPACE(1)
	AND L.Is_deleted = 0 and M.IS_DELETED=0
	AND Invtmfgr.Is_Deleted = 0
)

-- KitInvtView
INSERT @KitInvtView 
SELECT DISTINCT CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN QtyNotReserved ELSE Invtlot.Lotqty-Invtlot.Lotresqty END AS QtyNotReserved,
	CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN 000000000.00 ELSE Invtlot.Lotqty-Invtlot.Lotresqty END AS lotQtyNotReserved,
	CASE WHEN Invtlot.Lotqty IS NULL THEN ZKitInvt1.QtyOh ELSE Invtlot.lotqty END AS QtyOh, Invtlot.Lotqty AS LotQtyOh, 
	CASE WHEN Invtlot.Lotqty IS NULL THEN ZKitInvt1.QtyReserved ELSE Invtlot.Lotresqty END AS QtyReserved,
	CASE WHEN Invtlot.Lotqty IS NULL THEN Invtlot.Lotqty ELSE Invtlot.Lotresqty END AS LotQtyReserved,
	ZKitInvt1.Uniq_key, ZKitInvt1.Partmfgr, ZKitInvt1.InStore, ZKitInvt1.UniqSupno,
	ZKitInvt1.Mfgr_pt_no, ZKitInvt1.wh_gl_nbr,ZKitInvt1.UniqWh, 
	ZKitInvt1.Location, ZKitInvt1.W_key, ZKitInvt1.OrderPref, Invtlot.Lotcode, Invtlot.Expdate, Invtlot.Ponum,
	Invtlot.Reference,  ZKitInvt1.Warehouse, ZKitInvt1.UniqMfgrhd, ZKitInvt1.Bomparent
	FROM ZKitInvt1 LEFT OUTER JOIN Invtlot
	ON ZKitInvt1.W_key = Invtlot.W_key
	ORDER BY ZKitInvt1.Uniq_key, ZKitInvt1.W_key


-- SQL result 1
SELECT * FROM @KitInvtView

-- SQL result 2
-- ZForAvl
-- 05/01/15 VL chande the code to speed up
-- 07/01/15 VL found if a part is used several times in the BOM (with phantom part), the duplicate AVL records will appear in the SQL result 2 (also in result 1) 
-- with different Bomparent.  It caused problems in inserting invt_isu records becaue it might issue more qty then qty_oh in that w_key, will add DISTINCT
-- in next select command and don't include Bompart to filter out dupliate
--SELECT KitInvt.*, Inventor.Uniq_key AS cUniqkey
--	FROM @KitInvtView KitInvt LEFT OUTER JOIN Inventor 
--	--ON KitInvt.Uniq_key+@BomCustno=Inventor.Int_uniq+Inventor.CustNo;
--	ON KitInvt.Uniq_key = Inventor.Int_uniq 
--	AND Inventor.CustNo = @BomCustno
-- 10/01/15 VL found a problem that the bomparent is removed from the data, and the field is used later in form to filter out not approved mfgr,
-- decided just do it here to remove those not avl mfgr, then return the last SQL result 2
--SELECT DISTINCT K.QtyNotReserved, K.lotQtyNotReserved, K.QtyOh, K.LotQtyOh, K.QtyReserved, K.LotQtyReserved, K.Uniq_key, K.Partmfgr, K.InStore, K.UniqSupno,
--	K.Mfgr_pt_no, K.wh_gl_nbr, K.UniqWh, K.Location, K.W_key, K.OrderPref, K.Lotcode, K.Expdate, K.Ponum, K.Reference, K.Warehouse, K.UniqMfgrhd, I.Uniq_key AS cUniqKey
--FROM @KitInvtView K LEFT OUTER JOIN Inventor I
--ON K.Uniq_key = I.Int_uniq 
--AND @BomCustno = I.Custno

-- Try to use separate SQL to avoid taking long time all in one big SQL statement
;WITH ZPrepareAVL AS -- try to get cUniq_key here
(
SELECT K.QtyNotReserved, K.lotQtyNotReserved, K.QtyOh, K.LotQtyOh, K.QtyReserved, K.LotQtyReserved, K.Uniq_key, K.Partmfgr, K.InStore, K.UniqSupno,
	K.Mfgr_pt_no, K.wh_gl_nbr, K.UniqWh, K.Location, K.W_key, K.OrderPref, K.Lotcode, K.Expdate, K.Ponum, K.Reference, K.Warehouse, K.UniqMfgrhd, ISNULL(I.Uniq_key,K.Uniq_key) AS cUniqKey, Bomparent
FROM @KitInvtView K LEFT OUTER JOIN Inventor I
ON K.Uniq_key = I.Int_uniq 
AND @BomCustno = I.Custno
),
ZFilterOutAntiAvl AS -- What will be filter out later
(
SELECT ZPrepareAVL.*
	FROM ZPrepareAVL INNER JOIN Antiavl 
	ON Antiavl.Bomparent = ZPrepareAVL.Bomparent
	AND ANTIAVL.Uniq_key = ZPrepareAVL.cUniqKey
	AND Antiavl.Partmfgr = ZPrepareAVL.Partmfgr
	AND Antiavl.Mfgr_pt_no = ZPrepareAVL.Mfgr_pt_no)
-- Get distinct record and remove Bomparent here
SELECT DISTINCT K.QtyNotReserved, K.lotQtyNotReserved, K.QtyOh, K.LotQtyOh, K.QtyReserved, K.LotQtyReserved, K.Uniq_key, K.Partmfgr, K.InStore, K.UniqSupno,
	K.Mfgr_pt_no, K.wh_gl_nbr, K.UniqWh, K.Location, K.W_key, K.OrderPref, K.Lotcode, K.Expdate, K.Ponum, K.Reference, K.Warehouse, K.UniqMfgrhd, K.cUniqKey
	FROM ZPrepareAVL K
	WHERE Bomparent+Uniq_key+Partmfgr+Mfgr_pt_no NOT IN 
		(SELECT Bomparent+Uniq_key+Partmfgr+Mfgr_pt_no 
			FROM ZFilterOutAntiAvl)

	
END	