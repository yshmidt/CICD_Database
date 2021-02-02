-- =============================================
-- Author:		Vicky Lu
-- Create date: ???
-- Description:	???
-- Modified: 10/09/14 YS replace invtmfhd table with 2 new tables
-- 10/29/14    move orderpref to invtmpnlink
-- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected
--02/09/18 YS changed size of the lotcode column to 25 char
-- =============================================
CREATE PROCEDURE [dbo].[InvAllocAddbyPjPartView] @lcUniq_key AS char(10) = ''
AS
BEGIN

SET NOCOUNT ON;
-- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected
--SELECT Part_no, Revision, Descript, Part_Sourc, Inventor.Part_Class, Inventor.Part_type, Uniq_key, Inventor.U_of_meas,SerialYes, LotDetail
--	FROM INVENTOR, PARTTYPE
--	WHERE Inventor.Part_class = PartType.Part_class
--	AND Inventor.Part_type = Parttype.Part_type 
--	AND INVENTOR.UNIQ_KEY = @lcUniq_key;

SELECT Part_no, Revision, Descript, Part_Sourc, Inventor.Part_Class, Inventor.Part_type, Uniq_key, 
	Inventor.U_of_meas,SerialYes, ISNULL(LotDetail,cast(0 as bit)) as LotDetail
FROM INVENTOR LEFT OUTER JOIN PARTTYPE
ON Inventor.Part_class = PartType.Part_class
AND Inventor.Part_type = Parttype.Part_type
WHERE INVENTOR.UNIQ_KEY = @lcUniq_key;
		
WITH ZInvt1 AS
(
	--10/09/14 YS replace invtmfhd table with 2 new tables
	-- 10/29/14    move orderpref to invtmpnlink
	--02/09/18 YS changed size of the lotcode column to 25 char
	SELECT Invtmfgr.Uniq_key, m.Partmfgr, m.Mfgr_pt_no,Invtmfgr.UniqWh,
		Invtmfgr.Location, Invtmfgr.W_key, l.UniqMfgrHd, Inventor.SerialYes,
		CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN Invtmfgr.qty_oh-Invtmfgr.reserved ELSE Invtlot.Lotqty-Invtlot.Lotresqty END AS AvailQty,
		CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN Invtlot.Lotqty ELSE Invtlot.Lotqty-Invtlot.Lotresqty END AS LotQtyNotReserved,
		CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN Invtmfgr.qty_oh-Invtmfgr.reserved ELSE Invtlot.Lotqty-Invtlot.Lotresqty END AS AvailQtyNow,
		ISNULL(Invtlot.Lotcode, SPACE(25)) AS LotCode, Invtlot.Expdate, ISNULL(Invtlot.Reference,SPACE(12)) AS Reference, 
		ISNULL(Invtlot.Ponum,SPACE(15)) AS Ponum, Warehous.Warehouse, l.Orderpref, 0.00 AS QtyAlloc
	 FROM Inventor INNER JOIN InvtMfgr ON Inventor.uniq_key = Invtmfgr.uniq_key
	 INNER JOIN  Warehous ON Invtmfgr.UniqWh = Warehous.UniqWh 
	 INNER JOIN InvtMPNLink L on Invtmfgr.UNIQMFGRHD=l.uniqmfgrhd
	 INNER JOIN MfgrMaster M on l.mfgrMasterId=m.MfgrMasterId
	 LEFT OUTER JOIN Invtlot 
	 ON Invtmfgr.w_key = Invtlot.w_key
	 WHERE INVENTOR.UNIQ_KEY = @lcUniq_key
		AND Invtmfgr.Netable = 1
		AND Warehous.Warehouse <> 'MRB' 
		AND Invtmfgr.CountFlag = SPACE(1)
		AND Invtmfgr.Is_Deleted = 0
		AND L.Is_Deleted = 0
		AND M.IS_DELETED=0
		AND 0 < CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN Invtmfgr.qty_oh-Invtmfgr.reserved ELSE Invtlot.Lotqty-Invtlot.Lotresqty END 
)	

SELECT ZInvt1.Uniq_key, Partmfgr, Mfgr_pt_no, UniqWh, Location, W_key, ZInvt1.UniqMfgrhd, 
	SerialYes, ZInvt1.AvailQty-ZInvt1.AvailQty+1 AS AvailQty, 
	LotQtyNotReserved - LotQtyNotReserved+1 AS LotQtyNotReserved, 0.00 AS QtyAlloc,
	ZInvt1.AvailQty-ZInvt1.AvailQty+1 AS AvailBalance, ZInvt1.Lotcode, ZInvt1.Expdate, 
	ZInvt1.Ponum, ZInvt1.Reference, InvtSer.Serialno, InvtSer.SerialUniq, ZInvt1.Warehouse, ZInvt1.OrderPref
FROM ZInvt1, INVTSER
WHERE ZInvt1.UniqMfgrHd = INVTSER.UniqMfgrhd
AND ZInvt1.LotCode = INVTSER.LOTCODE
AND ISNULL(ZInvt1.EXPDATE,1) = ISNULL(INVTSER.Expdate,1)
AND ZInvt1.Reference = INVTSER.Reference
AND ZInvt1.Ponum = INVTSER.Ponum
AND InvtSer.IsReserved = 0
AND InvtSer.ID_Key = 'W_KEY'
AND ZInvt1.W_key = InvtSer.Id_value
AND ZInvt1.SerialYes = 1
UNION 
	SELECT ZInvt1.Uniq_key, Partmfgr, Mfgr_pt_no, UniqWh, Location, W_key, ZInvt1.UniqMfgrhd, 
	SerialYes, ZInvt1.AvailQty, LotQtyNotReserved - LotQtyNotReserved+1 AS LotQtyNotReserved, 
	0.00 AS QtyAlloc, ZInvt1.AvailQtyNow AS AvailBalance, ZInvt1.Lotcode, 
	ZInvt1.Expdate, ZInvt1.Ponum, ZInvt1.Reference, SPACE(30) AS Serialno, 
	SPACE(10) AS SerialUniq, ZInvt1.Warehouse AS Warehouse, ZInvt1.OrderPref 
FROM ZInvt1
WHERE SerialYes = 0
	
	
END