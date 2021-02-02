-- =============================================
-- Author:		???
-- Create date: ???
-- Description: ???
-- Modified: 10/09/14 YS remove invtmfhd table and replace with 2 new tables
-- =============================================
CREATE proc [dbo].[invt_ware_view]
@gUniq_key char(10) = null
AS 

-- 10/09/14 YS remove invtmfhd table and replace with 2 new tables
SELECT Invtmfgr.uniq_key, m.partmfgr, m.mfgr_pt_no,
  Invtmfgr.qty_oh, Invtmfgr.reserved,  Invtmfgr.netable,
  Invtmfgr.count_dt, Invtmfgr.count_type, Invtmfgr.rstk_ord,
  Invtmfgr.count_init, Invtmfgr.UniqWh, Invtmfgr.location, Invtmfgr.w_key,
  Invtmfgr.instore, Warehous.warehouse, Warehous.wh_descr,
  Warehous.wh_gl_nbr, Warehous.wh_note,
  Warehous.[default], Invtmfgr.UniqSupno, Invtmfgr.is_deleted,
  Invtmfgr.uniqmfgrhd 
 FROM invtmfgr,InvtMPNLink L, MfgrMaster M ,warehous
 WHERE  Invtmfgr.UniqWh = Warehous.UniqWh
   AND  L.uniqmfgrhd = Invtmfgr.uniqmfgrhd
   AND L.MfgrMasterid=M.MfgrMasterId
and Invtmfgr.Uniq_key=@gUniq_key