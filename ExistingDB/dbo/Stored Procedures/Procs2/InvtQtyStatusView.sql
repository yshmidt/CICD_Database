/****** Object:  StoredProcedure [dbo].[InvtQtyStatusView]    Script Date: 10/9/2014 11:17:55 AM ******/
-- =============================================
-- Author:		Vicky lu
-- Create date: ???
-- Description:	used in KIT desktop module
-- Modified: 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[InvtQtyStatusView] @gUniq_key char(10)=' '

AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

-- 09/10/12 VL added Qty_oh and Reserved, so can be used in more places
SET NOCOUNT ON;
--10/09/14 YS removed Invtmfhd table
--SELECT Warehouse, Partmfgr, Mfgr_pt_no AS Manufacture_Part_No, Location, 
--	ISNULL(Qty_oh-Reserved,0) AS Available_qty, QTY_OH, Reserved 
--	FROM Warehous, Invtmfhd LEFT OUTER JOIN Invtmfgr
--	ON Invtmfhd.UniqMfgrHd = Invtmfgr.UniqMfgrHd
--	WHERE Warehous.UniqWh = Invtmfgr.UniqWh
--	AND Invtmfhd.Uniq_key = @gUniq_key
--	AND (Invtmfgr.Is_Deleted IS NULL
--	OR Invtmfgr.Is_Deleted = 0)
--	AND Invtmfhd.Is_deleted = 0

SELECT ISNULL(Warehouse,space(8)) as Warehouse, m.Partmfgr, m.Mfgr_pt_no AS Manufacture_Part_No, Location, 
	ISNULL(Qty_oh-Reserved,0) AS Available_qty, QTY_OH, Reserved 
	FROM InvtMPNLink L INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId 
	LEFT OUTER JOIN Invtmfgr ON L.uniqmfgrhd=Invtmfgr.UNIQMFGRHD
	LEFT OUTER JOIN warehous ON Invtmfgr.UNIQWH=Warehous.UNIQWH
	WHERE L.Uniq_key = @gUniq_key
	AND (Invtmfgr.Is_Deleted IS NULL
	OR Invtmfgr.Is_Deleted = 0)
	AND L.Is_deleted = 0 and M.IS_DELETED=0

END