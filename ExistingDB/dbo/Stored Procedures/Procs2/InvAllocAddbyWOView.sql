-- =============================================
-- Create date:
-- Description: Used in inventory allocation module
-- Modification:
-- 04/04/2013 VL added WHERE IS_DELETED = 0 to filter out if it's deleted
-- 09/03/14 VL changed code to speed up
-- 10/29/14    move orderpref to invtmpnlink
-- 02/17/15 VL added to filter out inactive part by passing 10 parameter to fn_phantomSubSelect()
-- Modified: 10/09/14 YS replaced invtmfhd with 2 new files
-- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected
--- 04/14/15 YS change "location" column length to 256
-- 08/27/15 VL increase @ZKitReq1.qty length from numeric(9,2) to numeric(12,2) like Kamain.Qty
--- 03/28/17 YS changed length of the part_no column from 25 to 35
--02/09/18 YS changed size of the lotcode column to 25 char
-- =============================================
CREATE PROCEDURE [dbo].[InvAllocAddbyWOView] @gWono AS char(10) = ' '
AS
BEGIN

SET NOCOUNT ON;

DECLARE @ZKitReq1 TABLE (Dept_id char(4), Uniq_key char(10), BomParent char(10), Qty numeric(9,2), ShortQty numeric(12,2),
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		Used_inKit char(1), Part_Sourc char(8), Part_no char(35), Revision char(8), Descript char(45), Part_class char(8),
		--- 03/28/17 YS changed length of the part_no column from 25 to 35 
		Part_type char(8), U_of_meas char(4), Scrap numeric(6,2), SetupScrap numeric(4,0), CustPartNo char(35), SerialYes bit)
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @ZInvAllocH TABLE (nrecno int identity, Part_no char(35), Revision char(8), Descript char(45), Part_Sourc char(8),
		Part_class char(8), Part_type char(8), OriginalReqQty numeric(12,2), QtyKit2Request numeric(12,2), 
		QtyAlloc2Request numeric(12,2), BalanceReqQty numeric(12,2), Uniq_key char(10), U_of_meas char(4),
		BldQty numeric(7,0), Due_date smalldatetime, Custname char(35), Bomparent char(10), OpenClos char(10),
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		SerialYes bit, Custno char(10), TopPart_No char(35), TopRevision char(8), TopDescript char(45), 
		TopPart_Class char(8), TopPart_Type char(8), LotDetail bit, Wono char(10))
-- 10/29/14    move orderpref to invtmpnlink and changed type to INT
--- 04/14/15 YS change "location" column length to 256
DECLARE	@ZInvAllocD TABLE (Uniq_key char(10), Partmfgr char(8), Mfgr_pt_no char(30), UniqWh char(10), 
	Location varchar(256), W_key char(10), UniqMfgrhd char(10), SerialYes bit, AvailQty numeric(12,2),
	--02/09/18 YS changed size of the lotcode column to 25 char
	QtyAlloc numeric(12,2), AvailBalance numeric(12,2),  Lotcode nvarchar(25), Expdate smalldatetime, 
	Ponum char(15), Reference char(12), Serialno char(30), SerialUniq char(30), Warehouse char(6), 
	OrderPref int);
				
DECLARE @BomCustno char(10), @lnTotalNo int, @lnCount int, @lnAct_qty numeric(12,2), @lcUniq_key char(10),
		@lnQtyalloc numeric(12,2), @WODue_date smalldatetime, @WOBldQty numeric(7,0), @WOUniq_key char(10);

SELECT @BomCustno = BomCustno FROM INVENTOR WHERE Uniq_key = (SELECT UNIQ_KEY FROM WOENTRY WHERE WONO = @gWono)
SELECT @WOuniq_key = Uniq_key, @WODue_date = Due_date, @WOBldQty = BldQty FROM WOENTRY WHERE WONO = @gWono
-- 02/17/15 VL added 10th parameter to filter out inactive part
INSERT @ZKitReq1 
SELECT Dept_id, Uniq_key, BomParent, Qty, ReqQty AS ShortQty, Used_inKit, Part_Sourc, Part_no, Revision, Descript, 
		Part_class, Part_type, U_of_meas, Scrap, SetupScrap, CustPartNo, SerialYes
		FROM [dbo].[fn_PhantomSubSelect] (@WOuniq_key, @WOBldQty, 'T', @WODue_date, 'F', 'T', 'F', 0,0,0);

		--FROM [dbo].[fn_PhantomSubSelect] (@WOuniq_key, @WOBldQty, 'T', @WODue_date, 'F', 'T', 'F', 0,0);
-- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected
INSERT @ZInvAllocH SELECT KitReq.Part_no, KitReq.Revision, KitReq.Descript, KitReq.Part_Sourc, KitReq.Part_class, 
	KitReq.Part_type, ISNULL(SUM(ShortQty),0) AS OriginalReqQty, 000000000.00 AS QtyKit2Request, 
	000000000.00 AS QtyAlloc2Request, 000000000.00 AS BalanceReqQty, KitReq.Uniq_key, KitReq.U_of_meas, 
	WO.BldQty, WO.Due_date, Cust.CustName, BomParent, WO.OpenClos, KitReq.SerialYes, WO.Custno, 
	INVTH.Part_no AS TopPartNo, INVTH.Revision AS TopRevision, INVTH.Descript AS TopDescript, 
	INVTH.Part_Class AS TopPart_class, INVTH.Part_type AS TopPart_Type, 
	ISNULL(Lotdetail,cast(0 as bit)) as LotDetail, @gWono AS Wono
	FROM  WOENTRY WO, CUSTOMER Cust, INVENTOR InvtH, 
	@ZKitReq1 KitReq LEFT OUTER JOIN Parttype  ON KitReq.Part_class = PARTTYPE.PART_CLASS AND KitReq.Part_type = PARTTYPE.PART_TYPE
	WHERE WO.UNIQ_KEY = InvtH.Uniq_key
	AND WO.CUSTNO = Cust.CUSTNO
	AND (KitReq.Part_class = PARTTYPE.PART_CLASS 
	AND KitReq.Part_type = PARTTYPE.PART_TYPE)
	AND WO.WONO = @gWono
	GROUP BY KitReq.Part_no, KitReq.Revision, KitReq.Descript, KitReq.Part_Sourc, KitReq.Part_class, 
	KitReq.Part_type, KitReq.Uniq_key, KitReq.U_of_meas, 
	WO.BldQty, WO.Due_date, Cust.CustName, BomParent, WO.OpenClos, KitReq.SerialYes, WO.Custno, 
	INVTH.Part_no, INVTH.Revision, INVTH.Descript, INVTH.Part_class, INVTH.Part_type, Lotdetail, WO.Wono

SET @lnTotalNo = @@ROWCOUNT
SET @lnCount=0;
WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @lcUniq_key = Uniq_key FROM @ZInvAllocH WHERE nrecno = @lnCount
		SELECT @lnAct_qty = ISNULL(SUM(Act_qty),0) FROM KAMAIN WHERE WONO = @gWono AND UNIQ_KEY = @lcUniq_key
		SELECT @lnQtyalloc = ISNULL(SUM(Qtyalloc),0) FROM INVT_RES WHERE WONO = @gWono AND UNIQ_KEY = @lcUniq_key
			
		UPDATE @ZInvAllocH SET	QtyKit2Request = @lnAct_qty,
								QtyAlloc2Request = @lnQtyalloc,
								BalanceReqQty = CASE WHEN OriginalReqQty - @lnAct_qty - @lnQtyalloc >= 0
												THEN OriginalReqQty - @lnAct_qty - @lnQtyalloc
												ELSE 0 END
							WHERE nrecno = @lnCount

	
	END
	-- Header information
	SELECT * FROM @ZInvAllocH;
	--10/09/14 YS replace invtmfhd table with 2 new tables
	-- 10/29/14    move orderpref to invtmpnlink
	WITH ZInvt1D AS
	(
	--02/09/18 YS changed size of the lotcode column to 25 char
		SELECT Invtmfgr.Uniq_key, m.Partmfgr,m.Mfgr_pt_no,Invtmfgr.UniqWh,
			Invtmfgr.Location, Invtmfgr.W_key, l.UniqMfgrHd, Inventor.SerialYes,
			CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN Invtmfgr.qty_oh-Invtmfgr.reserved ELSE Invtlot.Lotqty-Invtlot.Lotresqty END AS AvailQty,
			CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN Invtlot.Lotqty ELSE Invtlot.Lotqty-Invtlot.Lotresqty END AS lotQtyNotReserved,
  			CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN Invtmfgr.qty_oh-Invtmfgr.reserved ELSE Invtlot.Lotqty-Invtlot.Lotresqty END AS AvailQtyNow,
  			ISNULL(Invtlot.Lotcode, SPACE(25)) AS LotCode, Invtlot.Expdate, ISNULL(Invtlot.Reference,SPACE(12)) AS Reference, 
  			ISNULL(Invtlot.Ponum,SPACE(15)) AS Ponum, Warehous.Warehouse,l.Orderpref
		 FROM @ZInvAllocH ZInvAllocH INNER JOIN InvtMfgr ON ZInvAllocH.uniq_key = Invtmfgr.uniq_key
		INNER JOIN  Warehous ON Invtmfgr.UniqWh = Warehous.UniqWh
		INNER JOIN Inventor ON Inventor.Uniq_key = Invtmfgr.uniq_key
		INNER JOIN InvtMPNLink L ON INVTMFGR.UNIQMFGRHD=L.uniqmfgrhd
		INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
		LEFT OUTER JOIN Invtlot 
		 ON Invtmfgr.w_key = Invtlot.w_key
 		 WHERE Invtmfgr.Netable = 1
   			AND Warehous.Warehouse <> 'MRB' 
   			AND Invtmfgr.CountFlag = SPACE(1)
			AND Invtmfgr.Is_Deleted = 0
			AND L.Is_Deleted = 0 AND M.IS_DELETED=0
			AND 0 < CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN Invtmfgr.qty_oh-Invtmfgr.reserved ELSE Invtlot.Lotqty-Invtlot.Lotresqty END 
	),
	ZInvtD2 AS 
	(--Prepare cUniqkey and gUniq_key to use later
		SELECT ZInvt1D.*, ISNULL(Invt.Uniq_key,ZInvt1D.Uniq_key) AS cUniqKey, @WOuniq_key AS gUniq_key, @gWono AS Wono	
			FROM ZInvt1D LEFT OUTER JOIN Inventor Invt
			ON ZInvt1D.Uniq_key = Invt.INT_UNIQ
			AND @BomCustno = Invt.CUSTNO
	),
	ZInvt1 AS
	(-- Filter out deleted invtmfhd and antiaval records
	-- 03/28/16 YS restore overwritten code for the new tables in place of invtmfhd table
		SELECT ZInvtD2.*
			FROM ZInvtD2 
			WHERE 
			exists
			(select 1 from invtmpnlink L inner join mfgrmaster M on l.MfgrMasterId=m.MfgrMasterId
			where l.uniq_key=ZInvtD2.cUniqKey and m.PartMfgr=ZInvtD2.PartMfgr and m.mfgr_pt_no=ZInvtD2.mfgr_pt_no and l.is_deleted=0 and m.is_deleted=0)
			--cUniqKey+Partmfgr+Mfgr_pt_no 
			--	IN (SELECT Uniq_key+Partmfgr+Mfgr_pt_no FROM INVTMFHD 
			--		WHERE IS_DELETED = 0)
			-- 03/28/16 YS remove concatenated "where"
			--AND gUniq_key+cUniqKey+Partmfgr+Mfgr_pt_no 
			--	NOT IN (SELECT Bomparent+Uniq_Key+Partmfgr+Mfgr_pt_no FROM ANTIAVL)	
			and not exists (select 1 from ANTIAVL where bomparent=ZInvtD2.gUniq_key and antiavl.UNIQ_KEY=ZInvtD2.cUniqKey and ANTIAVL.PARTMFGR=ZInvtD2.PartMfgr and ANTIAVL.MFGR_PT_NO=ZInvtD2.mfgr_pt_no) 
	)
			
			
	-- 09/03/14 VL tried to speed up the SP			
	--INSERT @ZInvAllocD
	SELECT ZInvt1.Uniq_key, Partmfgr, Mfgr_pt_no, UniqWh, Location, W_key, ZInvt1.UniqMfgrhd, 
		SerialYes, ZInvt1.AvailQty-ZInvt1.AvailQty+1 AS AvailQty, 0.00 AS QtyAlloc,
		ZInvt1.AvailQty-ZInvt1.AvailQty+1 AS AvailBalance, ZInvt1.Lotcode, ZInvt1.Expdate, 
		ZInvt1.Ponum, ZInvt1.Reference, InvtSer.Serialno, InvtSer.SerialUniq, ZInvt1.Warehouse, ZInvt1.OrderPref, 
		0.00 AS OldQtyAlloc, cUniqkey, gUniq_key, ZInvt1.Wono
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
		SerialYes, ZInvt1.AvailQty, 0.00 AS QtyAlloc, ZInvt1.AvailQtyNow AS AvailBalance, ZInvt1.Lotcode, 
		ZInvt1.Expdate, ZInvt1.Ponum, ZInvt1.Reference, SPACE(30) AS Serialno, 
		SPACE(10) AS SerialUniq, ZInvt1.Warehouse AS Warehouse, ZInvt1.OrderPref,
		0.00 AS OldQtyAlloc, cUniqkey, gUniq_key, ZInvt1.Wono 
	FROM ZInvt1
	WHERE SerialYes = 0

	-- 09/03/14 the code took long time
	-- Detail
	-- also filter out if no invtmfhd records found, and if has records in antiavl
	-- 04/04/2013 VL added WHERE IS_DELETED = 0 to filter out if it's deleted
	--SELECT ZD.*, ZD.QtyAlloc AS OldQtyAlloc, ISNULL(Invt.Uniq_key,ZD.Uniq_key) AS cUniqKey, 
	--	@WOuniq_key AS gUniq_key, @gWono AS Wono
	--	FROM @ZInvAllocD ZD LEFT OUTER JOIN Inventor Invt
	--	ON ZD.Uniq_key+@BomCustno = Invt.INT_UNIQ+Invt.CUSTNO
	--	WHERE ISNULL(Invt.Uniq_key,ZD.Uniq_key)+Partmfgr+Mfgr_pt_no 
	--		IN (SELECT Uniq_key+Partmfgr+Mfgr_pt_no FROM INVTMFHD 
	--			WHERE IS_DELETED = 0)
	--	AND @WOuniq_key+ISNULL(Invt.Uniq_key,ZD.Uniq_key)+Partmfgr+Mfgr_pt_no 
	--		NOT IN (SELECT Bomparent+Uniq_Key+Partmfgr+Mfgr_pt_no FROM ANTIAVL)

	
END