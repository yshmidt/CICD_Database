-- =============================================
-- Author:		Vicky Lu
-- Create date: ???
-- Description:	???
-- Modified: 08/29/14 VL
--			10/09/14 YS replaced invtmfhd table with 2 new tables
--	02/17/15 VL added to filter out inactive part by passing 10 parameter to fn_phantomSubSelect()
-- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected
--- 04/14/15 YS change "location" column length to 256
-- 08/27/15 VL increase @ZKitReq1.qty length from numeric(9,2) to numeric(12,2) like Kamain.Qty
-- 03/28/16 YS removed serial number from invt_res table. This procedure may not work anymore, will have to check if we need to use it in the new _a_design
--- 03/28/17 YS changed length of the part_no column from 25 to 35
--02/09/18 YS changed size of the lotcode column to 25 char
-- =============================================
CREATE PROCEDURE [dbo].[InvAllocEditbyWOView] @gWono AS char(10) = ' '
AS
BEGIN

SET NOCOUNT ON;

-- 08/29/14 VL Changed @ZInvAllocD from  TO ON Invt_res.W_key+Invt_res.Lotcode+CONVERT(char,Invt_res.expdate,20)+Invt_res.reference+Invt_res.Ponum = Invtlot.W_key+Invtlot.lotcode+CONVERT(char,Invtlot.expdate,20)+Invtlot.reference+Invtlot.Ponum 
--  TO ON Invt_res.W_key = Invtlot.W_key
--	AND Invt_res.Lotcode = Invtlot.lotcode
--	AND ISNULL(Invt_res.Expdate,1) = ISNULL(Invtlot.Expdate,1)
--	AND Invt_res.Reference = Invtlot.Reference
--	AND Invt_res.Ponum = Invtlot.Ponum 

DECLARE @ZKitReq1 TABLE (Dept_id char(4), Uniq_key char(10), BomParent char(10), Qty numeric(12,2), ShortQty numeric(9,2),
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
--- 04/14/15 YS change "location" column length to 256
-- 03/28/16 YS removed serial number from invt_res table
--02/09/18 YS changed size of the lotcode column to 25 char
DECLARE	@ZInvAllocD TABLE (QtyAlloc numeric(12,2), Uniq_key char(10), DateTime smalldatetime, SaveInit char(8), Invtres_no char(10), 
		Partmfgr char(8), Mfgr_pt_no char(30), UniqWh char(10), Location varchar(256), W_key char(10), AvailQty numeric(12,2), AvailBalance numeric(12,2),
		Lotcode nvarchar(25), Expdate smalldatetime, 
		Ponum char(15), Reference char(12), LotResQty numeric(12,2), Warehouse char(6), Refinvtres char(10), 
		OldQtyAlloc numeric(12,2))
				
DECLARE @BomCustno char(10), @lnTotalNo int, @lnCount int, @lnAct_qty numeric(12,2), @lcUniq_key char(10),
		@lnQtyalloc numeric(12,2), @WODue_date smalldatetime, @WOBldQty numeric(7,0), @WOUniq_key char(10);

SELECT @BomCustno = BomCustno FROM INVENTOR WHERE Uniq_key = (SELECT UNIQ_KEY FROM WOENTRY WHERE WONO = @gWono)
SELECT @WOuniq_key = Uniq_key, @WODue_date = Due_date, @WOBldQty = BldQty FROM WOENTRY WHERE WONO = @gWono

-- 02/17/15 VL added 10th parameter to filter out inactive part
INSERT @ZKitReq1 
SELECT Dept_id, Uniq_key, BomParent, Qty, ReqQty AS ShortQty, Used_inKit, Part_Sourc, Part_no, Revision, Descript, 
		Part_class, Part_type, U_of_meas, Scrap, SetupScrap, CustPartNo, SerialYes
		FROM [dbo].[fn_PhantomSubSelect] (@WOuniq_key, @WOBldQty, 'F', NULL, 'F', 'T', 'F', 0,0,0);
-- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected
INSERT @ZInvAllocH SELECT KitReq.Part_no, KitReq.Revision, KitReq.Descript, KitReq.Part_Sourc, KitReq.Part_class, 
	KitReq.Part_type, ISNULL(SUM(ShortQty),0) AS OriginalReqQty, 000000000.00 AS QtyKit2Request, 
	000000000.00 AS QtyAlloc2Request, 000000000.00 AS BalanceReqQty, KitReq.Uniq_key, KitReq.U_of_meas, 
	WO.BldQty, WO.Due_date, Cust.CustName, BomParent, WO.OpenClos, KitReq.SerialYes, WO.Custno, 
	INVTH.Part_no AS TopPartNo, INVTH.Revision AS TopRevision, INVTH.Descript AS TopDescript, 
	INVTH.Part_Class AS TopPart_class, INVTH.Part_type AS TopPart_Type, isnull(Lotdetail,cast(0 as bit)) as LotDetail, @gWono AS Wono
	FROM WOENTRY WO, CUSTOMER Cust, INVENTOR InvtH, 
	@ZKitReq1 KitReq LEFT OUTER JOIN PARTTYPE
		ON KitReq.Part_class = PARTTYPE.PART_CLASS
		AND KitReq.Part_type = PARTTYPE.PART_TYPE 
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
	SELECT * FROM @ZInvAllocH WHERE QtyAlloc2Request <> 0;


	-- Prepare detail
	-------------------------------------------------------------------------------------	
-- 08/29/14 VL changed left outer join	
-- 03/28/16 YS removed serial number from invt_res table
--02/09/18 YS changed size of the lotcode column to 25 char
	INSERT @ZInvAllocD
			SELECT Invt_res.Qtyalloc, Invt_res.Uniq_key, Invt_res.DateTime, Invt_res.Saveinit, Invt_res.Invtres_no, 
			M.Partmfgr,M.Mfgr_pt_no, Invtmfgr.UniqWh, Invtmfgr.Location, Invtmfgr.W_key, 
			CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN Invtmfgr.Qty_oh-Invtmfgr.Reserved ELSE Invtlot.Lotqty-Invtlot.Lotresqty END AS AvailQty,
			CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN Invtmfgr.Qty_oh-Invtmfgr.Reserved ELSE Invtlot.Lotqty-Invtlot.Lotresqty END AS AvailBalance,
			ISNULL(Invtlot.Lotcode, SPACE(25)) AS LotCode, Invtlot.Expdate, ISNULL(Invtlot.Ponum,SPACE(15)) AS Ponum, 
			ISNULL(Invtlot.Reference,SPACE(12)) AS Reference, 
  			CASE WHEN (Invtlot.Lotqty IS NULL OR Invtlot.Lotresqty IS NULL) THEN 0 ELSE Invtlot.Lotresqty END AS Lotresqty, 
			Warehous.warehouse, Invt_Res.RefInvtRes, Invt_res.QtyAlloc AS OldQtyAlloc 
			---10/09/14 YS replaced invtmfhd table with 2 new tables
			FROM Warehous,InvtMPNLink L,MfgrMaster M,Invtmfgr,Invt_res LEFT OUTER JOIN invtlot 
				ON Invt_res.W_key = Invtlot.W_key
				AND Invt_res.Lotcode = Invtlot.lotcode
				AND ISNULL(Invt_res.Expdate,1) = ISNULL(Invtlot.Expdate,1)
				AND Invt_res.Reference = Invtlot.Reference
				AND Invt_res.Ponum = Invtlot.Ponum 	  			 
			WHERE  Invtmfgr.UniqWh = Warehous.UniqWh
				AND Invt_res.wono = @gWono
				AND Invtmfgr.w_key = Invt_res.w_key
				AND L.UniqMfgrHd=Invtmfgr.UniqMfgrHd
				AND L.mfgrMasterId=M.MfgrMasterId
-- 03/28/16 YS removed serial number from invt_res table
	--UPDATE @ZInvAllocD SET AvailQty = CASE WHEN InvtSer.ISReserved = 1 OR InvtSer.Id_Key<>'W_KEY' OR InvtSer.Id_Value<>ZInvAllocD.W_key THEN 0 ELSE 1 END 
	--	FROM @ZInvAllocD ZInvAllocD, INVTSER
	--	WHERE ZInvAllocD.SerialUniq <> ''
	--	AND ZInvAllocD.SerialUniq = InvtSer.SerialUniq
		
	-- Detail
	-- Also filter out if it has unallocated records or is unallocated records of others
	SELECT *, @gWono AS Wono
		FROM @ZInvAllocD
		WHERE InvtRes_No NOT IN (SELECT RefInvtRes FROM @ZinvAllocD) 
				AND RefInvtRes NOT IN (SELECT InvtRes_No FROM @ZinvAllocD)
	
END