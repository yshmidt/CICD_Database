-- =============================================
-- Author:		???
-- Create date: ???
-- Description:	???
-- Modified: 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- =============================================

CREATE PROCEDURE [dbo].[InvtSer4KitPickView] @gWono AS char(10)=' ', @lcUniq_key char(10) = ' ', @lcW_key AS char(10)=' '
AS

DECLARE @llKitAllowNonNettable bit

SELECT @llKitAllowNonNettable = lKitAllowNonNettable FROM KITDEF;

WITH ZWOWIPMfgr AS
 (
	SELECT W_key 
		FROM Invtmfgr, Warehous
		WHERE Invtmfgr.UniqWh = Warehous.UniqWh 
		AND Invtmfgr.Is_Deleted = 0
		AND Warehous.Is_Deleted = 0
		AND Invtmfgr.Uniq_key = @lcUniq_key
		AND Warehouse = 'WO-WIP'
		AND Invtmfgr.Location = 'WO'+@gWono
)
--10/09/14 YS removed invtmfhd table and replaced with 2 new tables
SELECT InvtSer.Serialno, SerialUniq, IsReserved, ReservedFlag, ReservedNo, Id_Value, LotCode, ExpDate, Reference, Ponum 
	FROM InvtSer, Invtmfgr, Warehous, InvtMPNLink L, MfgrMaster M
	WHERE InvtSer.Uniq_key = @lcUniq_key
	AND InvtSer.Uniq_key = Invtmfgr.Uniq_key
	AND Invtmfgr.Uniq_key = L.Uniq_key
	AND Invtmfgr.Uniqmfgrhd = L.Uniqmfgrhd
	AND L.mfgrMasterId=M.MfgrMasterId
	AND Invtmfgr.UniqWh = Warehous.UniqWh
	AND (InvtSer.Id_key = 'W_KEY' AND InvtSer.Id_Value = Invtmfgr.W_key)
	AND NOT (InvtSer.Id_key = 'WONO' AND InvtSer.Id_Value = @gWono)
	AND (InvtSer.Id_key = 'W_KEY' AND InvtSer.Id_Value NOT IN (SELECT W_key FROM ZWOWIPMfgr))
	AND M.lDisallowKit = 0
	AND 1 = (CASE WHEN @llKitAllowNonNettable = 1 THEN 1 ELSE Invtmfgr.NetAble END)
	AND Invtmfgr.Is_Deleted = 0
	AND Warehouse <> 'MRB'
	AND Invtmfgr.W_key = @lcW_key	
