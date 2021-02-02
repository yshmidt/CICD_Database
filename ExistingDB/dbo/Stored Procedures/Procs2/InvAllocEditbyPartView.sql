-- =============================================
-- Author:		Vicky Lu
-- Create date: ???
-- Description:	???
-- Modified: 10/09/14 YS replaced invtmfhd table with 2 new tables
-- 03/28/16 YS removed serial number from invt_res table . Whne working on the allocation we may need to dump this procedure or modify it 
-- =============================================
CREATE PROCEDURE [dbo].[InvAllocEditbyPartView] @lcUniq_key AS char(10) = ' '
AS
BEGIN

SET NOCOUNT ON;

WITH ZInvAllocD AS
(
-- 03/28/16 YS removed serial number from invt_res table . Whne working on the allocation we may need to dump this procedure or modify it 
SELECT Qtyalloc, Invt_Res.Uniq_Key, Invt_res.DateTime, Invt_res.Saveinit, Invt_res.Invtres_no, 
		m.Partmfgr, m.Mfgr_pt_no, Invtmfgr.UniqWh, Invtmfgr.Location, Invtmfgr.W_key,
		Invtmfgr.Qty_oh-Invtmfgr.Reserved AS AvailQty, Invtmfgr.Qty_oh-Invtmfgr.Reserved AS AvailBalance,
		LotCode, Expdate, Ponum, Reference,
		Warehous.warehouse, Invt_Res.RefInvtRes,  Invt_Res.QtyAlloc AS OldQtyAlloc,
		Invt_Res.Fk_PrjUnique, Invt_res.wono, Sono, Uniqueln
-- 10/09/14 YS replaced invtmfhd table with 2 new tables
FROM Warehous, InvtMPNLink L,MfgrMaster M, Invtmfgr, Invt_res
WHERE Invtmfgr.UniqWh = Warehous.UniqWh
	AND Invtmfgr.w_key = Invt_res.w_key
	AND L.UniqMfgrHd=Invtmfgr.UniqMfgrHd
	and l.mfgrMasterId=m.MfgrMasterId
	AND Invt_res.Uniq_key = @lcUniq_key
)
SELECT ZInvAllocD.*, ISNULL(PjctMain.PrjNumber,SPACE(10)) AS PrjNumber
	FROM ZInvAllocD LEFT OUTER JOIN PjctMain
	ON ZInvAllocD.FK_PRJUNIQUE = PjctMain.PrjUnique
	WHERE InvtRes_No NOT IN (SELECT RefInvtRes FROM ZinvAllocD) 
	AND RefInvtRes NOT IN (SELECT InvtRes_No FROM ZinvAllocD)
	ORDER BY Wono

END