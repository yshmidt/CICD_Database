

CREATE proc [dbo].[MfgrConsgnView] @guniq_key as char(10)=null

as SELECT Invtmfgr.uniq_key, Invtmfgr.qty_oh, Invtmfgr.reserved,
  Invtmfgr.netable, Invtmfgr.count_dt, Invtmfgr.count_type,
  Invtmfgr.rstk_ord, Invtmfgr.count_init, Invtmfgr.location,
  Invtmfgr.w_key, Invtmfgr.instore, Invtmfgr.UniqSupno, Invtmfgr.reordpoint,
  Invtmfgr.reorderqty, Invtmfgr.safetystk, Invtmfgr.countflag,
  Invtmfgr.is_deleted, Invtmfgr.is_validated, Invtmfgr.uniqmfgrhd,
  Invtmfgr.uniqwh
 FROM 
     invtmfgr 
    INNER JOIN inventor 
   ON  Invtmfgr.uniq_key = Inventor.uniq_key
 WHERE   Inventor.int_uniq =  @guniq_key 
   AND  Inventor.int_uniq <> SPACE(10) 
   AND  Inventor.part_sourc = 'CONSG'