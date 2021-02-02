CREATE PROCEDURE [dbo].[InvtQtyStatus4WoView] @lcUniq_key char(10) = ' ', @gWono char(10) = ' '

AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
DECLARE @lcWono char(10);

WITH ZInvt_res AS
(
	SELECT W_key, ISNULL(SUM(Qtyalloc),0.00) AS Available_qty
		FROM Invt_res
		WHERE Invt_res.Wono = @gWono
		GROUP BY W_key 
),

ZInvtMfgr AS
(
	SELECT Warehouse, Partmfgr, Mfgr_pt_no, Location, 
		Qty_oh,Reserved, W_key, ISNULL(Invtmfgr.Qty_oh-Invtmfgr.Reserved,0) AS Available_qty 
		FROM Warehous, Invtmfhd LEFT OUTER JOIN Invtmfgr
		ON Invtmfhd.UniqMfgrHd = Invtmfgr.UniqMfgrHd
		WHERE Warehous.UniqWh = Invtmfgr.UniqWh
		AND Invtmfhd.Uniq_key = @lcUniq_key
		AND (Invtmfgr.Is_Deleted IS NULL
		OR Invtmfgr.Is_Deleted = 0)
		AND Invtmfhd.Is_deleted = 0
)

SELECT Warehouse,Location,Qty_oh,Reserved, Partmfgr,Mfgr_pt_no,
		CASE WHEN ZInvt_res.Available_qty IS NULL THEN Qty_oh-Reserved ELSE Qty_oh-Reserved+ZInvt_res.Available_qty END AS Available_Qty
		FROM ZInvtMfgr LEFT OUTER JOIN ZInvt_res
		ON ZInvtMfgr.W_key = ZInvt_res.W_key 

END




