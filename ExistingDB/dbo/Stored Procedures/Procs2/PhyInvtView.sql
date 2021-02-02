-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- Modified: 
-- 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- 05/28/17 VL added functional currency code
-- =============================================
CREATE PROC [dbo].[PhyInvtView] @lcUniqPiHead AS char(10) = ' '
AS
	--10/09/14 YS removed invtmfhd table and replaced with 2 new tables
	SELECT Part_class, Part_type, Part_no, Revision, Descript, U_of_meas, Stdcost, Part_sourc, Phyinvt.Uniqphyno,
		Phyinvt.Uniq_key, Phyinvt.W_key, Phyinvt.Lotcode, Phyinvt.Expdate, Phyinvt.Reference, Phyinvt.Qty_oh, Phyinvt.Sys_date, 
		Phyinvt.Phycount, Phyinvt.Init, Phyinvt.Phydate, Phyinvt.Invreason, Phyinvt.Invrecncl, Phyinvt.Tag_no, Warehous.Whno, 
		Invtmfgr.Location, M.Partmfgr, M.Mfgr_pt_no, Warehous.Warehouse, Invtmfgr.Instore, Inventor.Custno, 
		Warehous.Wh_gl_nbr, Phyinvt.Uniqpihead, Phyinvt.Ponum, Inventor.Custpartno, Inventor.Custrev, Invtmfgr.Countflag, 
		Phyinvt.Uniq_lot, Inventor.Serialyes, L.Uniqmfgrhd, StdcostPR
	FROM Inventor, Phyinvt, Invtmfgr, InvtMPNLink L, MfgrMaster M, Warehous
	WHERE Inventor.Uniq_key = Phyinvt.Uniq_key
	AND Phyinvt.W_key = Invtmfgr.W_key
	AND Invtmfgr.Uniqmfgrhd = L.Uniqmfgrhd
	and l.mfgrMasterId=M.MfgrMasterId
	AND Invtmfgr.Uniqwh = Warehous.Uniqwh
	AND Phyinvt.Uniqpihead = @lcUniqPiHead
	ORDER BY Uniqphyno