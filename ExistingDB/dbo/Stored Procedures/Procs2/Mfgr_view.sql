

CREATE proc [dbo].[Mfgr_view] @gUniq_key as CHAR(10) ='' 
AS
SELECT DISTINCT Invtmfgr.uniq_key,Invtmfgr.w_key, Invtmfgr.location, Invtmfgr.netable, Invtmfgr.qty_oh,
  Invtmfgr.reserved, Invtmfgr.qty_oh - Invtmfgr. reserved as QtyAvail, Invtmfgr.count_init,
  Invtmfgr.count_dt, Warehous.warehouse, Warehous.whno, Invtmfgr.rstk_ord,
  Warehous.wh_gl_nbr, Invtmfgr.instore,
  Invtmfgr.UniqSupno, Invtmfgr.reordpoint,
  Invtmfgr.reorderqty, Invtmfgr.countflag, Invtmfgr.is_deleted,
  Invtmfgr.is_validated, Invtmfgr.uniqmfgrhd, Invtmfgr.uniqwh
 FROM warehous INNER JOIN invtmfgr 
   ON  Warehous.UniqWh = Invtmfgr.Uniqwh
 WHERE  Invtmfgr.uniq_key =  @guniq_key

