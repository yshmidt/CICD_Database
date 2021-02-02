
------------------------------------------------------------
-- Modification
-- 03/19/14 VL remove CoungFlag = '' criteria and changed to catch in form level, otherwise this sp will rebutn 0 record and form 
--				would try to find deleted record
--  10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- 12/10/14 VL found the criteria LTRIM(RTRIM(InvtLot.Lotcode)) = @gWono only work for regular wono, for rework wono, the lotcode field saves the original wono, so the sql 
--				will not find records, has to use woentry.cmpricelnk and find cmdetail.wono to link
-- 04/27/15 VL added CountFlag field
-- 11/18/16 Sachin b Set Qty used 0 to 0.0
------------------------------------------------------------

CREATE PROCEDURE [dbo].[ShopFloorReturnFromFGILotView] -- ShopFloorReturnFromFGILotView '_4500UQ3EM','0000000458'
	-- Add the parameters for the stored procedure here
	@gUniq_key char(10)=' ', @gWono char(10) = ' '
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
--  10/09/14 YS removed invtmfhd table and replaced with 2 new tables
SET NOCOUNT ON;
DECLARE @lllis_Rwk bit, @lcCmpriceLnk char(10)
SELECT @lllis_Rwk = lIs_Rwk, @lcCmpriceLnk = CmpriceLnk FROM WOENTRY WHERE WONO = @gWono
IF @lllis_Rwk = 0
	BEGIN
	--  10/09/14 YS removed invtmfhd table and replaced with 2 new tables
	-- 11/18/16 Sachin b Set Qty used 0 to 0.0
	SELECT Partmfgr, Warehouse, Location, Whno, Invtmfgr.W_key, (LotQTY-LotResQty) AS QtyOh, LotCode, 0.0 as QtyUsed,
		ExpDate, Reference, Uniq_lot, L.UniqMfgrHd, Invtmfgr.CountFlag
		--  10/09/14 YS removed invtmfhd table and replaced with 2 new tables
		FROM InvtMPNLink L,MfgrMaster M,  Invtmfgr, Warehous, InvtLot
		WHERE L.Uniq_key = @gUniq_Key
		AND Invtmfgr.UniqMfgrHd = L.UniqMfgrHd
		AND l.mfgrMasterId=M.MfgrMasterId
		AND Warehous.UniqWh = Invtmfgr.UniqWh	
		AND WAREHOUSE <> 'WIP   ' 
		AND WAREHOUSE <> 'WO-WIP'	
		AND Warehouse <> 'MRB   '
		AND LotQTY-LotResQty > 0
		AND Netable = 1
		AND InvtLot.W_key = InvtMfgr.W_key
		AND LTRIM(RTRIM(InvtLot.Lotcode)) = @gWono
		AND Invtmfgr.Is_Deleted = 0
		AND Invtmfgr.InStore = 0
		--AND Invtmfhd.Is_Deleted = 0
		AND L.Is_Deleted = 0 and M.IS_DELETED=0
		--AND Invtmfgr.CountFlag = ''
	END
ELSE
	BEGIN
	-- This is a rework work order the lot code should have original work order number, so link back to CM to find old wono, not the new rework wono
	--  10/09/14 YS removed invtmfhd table and replaced with 2 new tables
	;WITH ZCM AS (SELECT LTRIM(RTRIM(Cminvlot.Lotcode)) AS Wono 
		FROM Cminvlot 
		WHERE Uniq_Alloc IN 
			(SELECT Uniq_Alloc 
				FROM Cmalloc 
				WHERE Uniqueln+CmUnique IN 
					(SELECT Uniqueln+CmUnique 
						FROM Cmdetail WHERE Cmpricelnk = @lcCmpriceLnk)))
	-- 11/18/16 Sachin b Set Qty used 0 to 0.0					
	SELECT Partmfgr, Warehouse, Location, Whno, Invtmfgr.W_key, (LotQTY-LotResQty) AS QtyOh, LotCode, 0.0 as QtyUsed,
		ExpDate, Reference, Uniq_lot, L.UniqMfgrHd, Invtmfgr.CountFlag
		--  10/09/14 YS removed invtmfhd table and replaced with 2 new tables
		FROM InvtMPNLink L,MfgrMaster M, Invtmfgr, Warehous, InvtLot
		WHERE L.Uniq_key = @gUniq_Key
		AND Invtmfgr.UniqMfgrHd = L.UniqMfgrHd
		AND l.mfgrMasterId=M.MfgrMasterId
		AND Warehous.UniqWh = Invtmfgr.UniqWh	
		AND WAREHOUSE <> 'WIP   ' 
		AND WAREHOUSE <> 'WO-WIP'	
		AND Warehouse <> 'MRB   '
		AND LotQTY-LotResQty > 0
		AND Netable = 1
		AND InvtLot.W_key = InvtMfgr.W_key
		AND LTRIM(RTRIM(InvtLot.Lotcode)) IN (SELECT Wono FROM ZCM)
		AND Invtmfgr.Is_Deleted = 0
		AND Invtmfgr.InStore = 0
		--AND Invtmfhd.Is_Deleted = 0
		AND L.Is_Deleted = 0 and M.IS_DELETED=0
		--AND Invtmfgr.CountFlag = ''
	END
END