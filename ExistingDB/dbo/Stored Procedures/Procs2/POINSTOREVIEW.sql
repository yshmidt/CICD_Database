

CREATE proc [dbo].[POINSTOREVIEW] @gcPonum char(15) =null
AS
SELECT Postore.uniq_key, Postore.qty_isu, Postore.partmfgr,
  Postore.mfgr_pt_no, Postore.ponum, Postore.date_isu,
  Postore.contr_uniq, Postore.uniqrecord, Postore.lotcode, Postore.expdate,
  Postore.reference, Postore.uniqlnno, Postore.usedby, Postore.uniqmfgrhd, 
  Postore.uniqsupno, Postore.uniqwh,
  Postore.location,Postore.serialno,POSTORE.serialuniq,  POSTORE.RecVer 
 FROM postore
 WHERE  Postore.ponum =  @gcPoNum 