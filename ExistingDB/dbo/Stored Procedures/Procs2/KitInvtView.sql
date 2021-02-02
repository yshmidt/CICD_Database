-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- 10/09/14 YS replaced invtmfhd table with 2 new tables
-- 10/29/14    move orderpref to invtmpnlink
--- 04/14/15 YS change "location" column length to 256
--- 03/28/17 YS changed length of the part_no column from 25 to 35
 --03/01/18 YS lotcode size change to 25
-- =============================================
CREATE PROCEDURE [dbo].[KitInvtView] @gWono AS char(10) = ''
AS
BEGIN

-- 03/14/13 VL changed the SQL result 1, the LEFT OUTER JOIN criteria caused it runs too long, Smart reported the issue.
-- 09/02/14 VL added ZKitPick1 in front of * for SQL Result2 so it won't all from two tables

SET NOCOUNT ON;
--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @ZKitMainView TABLE (DispPart_no char(35), Req_Qty numeric(12,2), Phantom char(1), DispRevision char(8),
	Part_class char(8), Part_type char(8), Kaseqnum char(10), Entrydate smalldatetime, Initials char(8), 
	Rej_qty numeric(12,2), Rej_date smalldatetime, Rej_reson char(10), Kitclosed bit, Act_qty numeric(12,2), 
	Uniq_key char(10), Dept_id char(4), Dept_name char(25), Wono char(10), Scrap numeric(6,2), Setupscrap numeric(4,0), 
	Bomparent char(10), Shortqty numeric(12,2), Lineshort bit, Part_sourc char(10), Qty numeric(12,2), 
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	Descript char(45), Inv_note text, U_of_meas char(4), Pur_uofm char(4), Ref_des char(15), Part_no char(35), 
	Custpartno char(35), Ignorekit bit, Phant_make bit, Revision char(8), Serialyes bit, Matltype char(10),	CustRev char(8))
-- 10/29/14    move orderpref to invtmpnlink and changed type to int	
--- 04/14/15 YS change "location" column length to 256
DECLARE	@KitInvtView TABLE (QtyNotReserved numeric(12,2), LotQtyNotReserved numeric(12,2), Kaseqnum char(10), 
	Uniq_key char(10), BomParent char(10), Part_sourc char(10), Partmfgr char(8), Mfgr_pt_no char(30), 
	Wh_gl_nbr char(13), UniqWh char(10), Location varchar(256), W_key char(10), InStore bit, UniqSupno char(10), 
	 --03/01/18 YS lotcode size change to 25
	Lotcode char(25), Expdate smalldatetime, Reference char(12), Ponum char(15), Warehouse char(6), 
	CountFlag char(1), OrderPref int, UniqMfgrhd char(10));
	
DECLARE @llKitAllowNonNettable bit, @WOuniq_key char(10), @BomCustno char(10);

SELECT @llKitAllowNonNettable = lKitAllowNonNettable FROM KitDef
SELECT @WOuniq_key = Uniq_key FROM WOENTRY WHERE WONO = @gWono
SELECT @BomCustno = BomCustno FROM INVENTOR WHERE Uniq_key = @WOuniq_key

INSERT @ZKitMainView EXEC [KitMainView] @gWono;
-- 10/09/14 YS replaced invtmfhd table with 2 new tables
WITH ZKitInvt1 AS
(
-- 10/29/14    move orderpref to invtmpnlink
	SELECT DISTINCT Invtmfgr.qty_oh-Invtmfgr.reserved AS QtyNotReserved,
		Kitmainview.Kaseqnum, Kitmainview.uniq_key, Kitmainview.BomParent, Kitmainview.Part_sourc,
		M.Partmfgr, M.Mfgr_pt_no, Warehous.Wh_gl_nbr, Invtmfgr.UniqWh,
		Invtmfgr.Location, Invtmfgr.W_key, Invtmfgr.InStore, InvtMfgr.UniqSupNo, Invtmfgr.CountFlag,
		Warehous.Warehouse, l.OrderPref, L.UniqMfgrHd, Invtmfgr.NetAble, M.lDisallowKit
	FROM Warehous, @ZKitMainView KitMainView, Invtmfgr, InvtMPNLink L, MfgrMaster M
	WHERE Kitmainview.Uniq_key = Invtmfgr.uniq_key 
	AND L.UniqMfgrHd = Invtmfgr.UniqMfgrHd 
	AND l.mfgrMasterId=M.MfgrMasterId
	AND M.lDisallowKit = 0
	AND 1 = (CASE WHEN @llKitAllowNonNettable = 1 THEN 1 ELSE Invtmfgr.NetAble END)
	AND L.Is_deleted = 0 and M.is_deleted =0 
	AND Invtmfgr.UniqWh = Warehous.UniqWh
	AND  Warehouse<>'MRB'
	AND Invtmfgr.Is_Deleted = 0
)
-- KitInvtView
INSERT @KitInvtView 
-- 02/03/12 VL remove ISNULL() function for Lotcode records
--SELECT DISTINCT CASE WHEN (Invtlot.lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN QtyNotReserved ELSE Invtlot.lotqty-Invtlot.lotresqty END AS QtyNotReserved,
--	CASE WHEN (Invtlot.lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN 000000000.00 ELSE Invtlot.lotqty-Invtlot.lotresqty END AS lotQtyNotReserved,
--	ZKitInvt1.Kaseqnum, ZKitInvt1.Uniq_key, ZKitInvt1.BomParent, ZKitInvt1.Part_sourc, ZKitInvt1.Partmfgr,
--	ZKitInvt1.Mfgr_pt_no, ZKitInvt1.wh_gl_nbr,ZKitInvt1.UniqWh,	ZKitInvt1.Location, ZKitInvt1.W_key, 
--	ZKitInvt1.InStore, ZKitInvt1.UniqSupno, ISNULL(Invtlot.Lotcode,SPACE(15)), Invtlot.Expdate,
--	ISNULL(Invtlot.Reference,SPACE(12)), ISNULL(Invtlot.Ponum, SPACE(15)), ZKitInvt1.Warehouse, 
--	ZKitInvt1.CountFlag, ZKitInvt1.OrderPref, ZKitInvt1.UniqMfgrhd 
--	FROM ZKitInvt1 LEFT OUTER JOIN Invtlot
--	ON ZKitInvt1.W_key = Invtlot.W_key
--	ORDER BY Partmfgr, ISNULL(Invtlot.Lotcode, SPACE(15)), Warehouse, Location
SELECT DISTINCT CASE WHEN (Invtlot.lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN QtyNotReserved ELSE Invtlot.lotqty-Invtlot.lotresqty END AS QtyNotReserved,
	CASE WHEN (Invtlot.lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN 000000000.00 ELSE Invtlot.lotqty-Invtlot.lotresqty END AS lotQtyNotReserved,
	ZKitInvt1.Kaseqnum, ZKitInvt1.Uniq_key, ZKitInvt1.BomParent, ZKitInvt1.Part_sourc, ZKitInvt1.Partmfgr,
	ZKitInvt1.Mfgr_pt_no, ZKitInvt1.wh_gl_nbr,ZKitInvt1.UniqWh,	ZKitInvt1.Location, ZKitInvt1.W_key, 
	ZKitInvt1.InStore, ZKitInvt1.UniqSupno, Invtlot.Lotcode, Invtlot.Expdate,
	Invtlot.Reference, Invtlot.Ponum, ZKitInvt1.Warehouse, 
	ZKitInvt1.CountFlag, ZKitInvt1.OrderPref, ZKitInvt1.UniqMfgrhd 
	FROM ZKitInvt1 LEFT OUTER JOIN Invtlot
	ON ZKitInvt1.W_key = Invtlot.W_key
	ORDER BY Partmfgr, Invtlot.Lotcode, Warehouse, Location


-- SQL result 
SELECT * FROM @KitInvtView

-- SQL result 1
-- ZForAvl
-- 03/14/13 VL changed the SQL code because it's too slow, Smart reported it
--SELECT KitInvt.*, Inventor.Uniq_key AS cUniqkey
--	FROM @KitInvtView KitInvt LEFT OUTER JOIN Inventor 
--	ON KitInvt.Uniq_key+@BomCustno=Inventor.Int_uniq+Inventor.CustNo;
SELECT KitInvt.*, Inventor.Uniq_key AS cUniqkey
	FROM @KitInvtView KitInvt LEFT OUTER JOIN Inventor 
	ON (KitInvt.Uniq_key=Inventor.Int_uniq
	AND @BomCustno=Inventor.CustNo);

-- PRE KitPick
-- 10/09/14 YS replaced invtmfhd table with 2 new tables
--- Replace two SQL into one 
--WITH ZKitPick1 AS
--(
--SELECT Kalocate.Kaseqnum, Kalocate.w_key, Kalocate.pick_qty, Kalocate.lotcode, Kalocate.expdate, 
--	Kalocate.Reference, Kalocate.Ponum, Kalocate.UniqMfgrHd, 
--	ISNULL(Invtmfhd.Uniq_key,SPACE(10)) AS Uniq_key, ISNULL(Invtmfhd.partmfgr,'Deleted') AS Partmfgr,
--	ISNULL(Invtmfhd.Mfgr_pt_no,SPACE(30)) AS Mfgr_pt_no, Kalocate.OverIssQty, Kalocate.Overw_key, '1' AS UpdFlg,
--	ISNULL(Invtmfhd.OrderPref,00) AS OrderPref, Kalocate.UniqKalocate 
--	FROM @ZKitMainView KitMainView, Kalocate LEFT OUTER JOIN Invtmfhd 
--	ON Kalocate.Uniqmfgrhd = Invtmfhd.UniqMfgrhd
--	WHERE Kalocate.KaseqNum = KitMainView.KaseqNum
--)
---- SQL result 2
---- 09/02/14 VL added ZKitPick1 in front of *
--SELECT ZKitPick1.*, ISNULL(Invtmfgr.InStore,0) AS Instore, ISNULL(Invtmfgr.UniqSupno,SPACE(10)) AS UniqSupno,
--	ISNULL(INVTMFGR.COUNTFLAG,SPACE(1)) AS CountFlag
--	FROM ZKitPick1 LEFT OUTER JOIN INVTMFGR
--	ON ZKitPick1.W_KEY = INVTMFGR.W_key
--	ORDER BY Kaseqnum, ZKitPick1.W_key, Lotcode, Expdate, Reference
---- SQL result 2
-- 10/29/14    move orderpref to invtmpnlink
SELECT Kalocate.Kaseqnum, Kalocate.w_key, Kalocate.pick_qty, Kalocate.lotcode, Kalocate.expdate, 
	Kalocate.Reference, Kalocate.Ponum, Kalocate.UniqMfgrHd, 
	ISNULL(L.Uniq_key,SPACE(10)) AS Uniq_key, ISNULL(M.partmfgr,'Deleted') AS Partmfgr,
	ISNULL(M.Mfgr_pt_no,SPACE(30)) AS Mfgr_pt_no, Kalocate.OverIssQty, Kalocate.Overw_key, '1' AS UpdFlg,
	ISNULL(l.OrderPref,00) AS OrderPref, Kalocate.UniqKalocate ,
	ISNULL(Invtmfgr.InStore,0) AS Instore, ISNULL(Invtmfgr.UniqSupno,SPACE(10)) AS UniqSupno,
	ISNULL(INVTMFGR.COUNTFLAG,SPACE(1)) AS CountFlag
	FROM @ZKitMainView KitMainView, Kalocate LEFT OUTER JOIN InvtMpnLink L ON Kalocate.Uniqmfgrhd = L.UniqMfgrhd
	LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
	LEFT OUTER JOIN INVTMFGR ON Kalocate.w_key=Invtmfgr.w_key
	WHERE Kalocate.KaseqNum = KitMainView.KaseqNum
	
END	