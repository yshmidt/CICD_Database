create proc [dbo].[InvtSerUpDView] @gUniq_key as char(10)=null
as SELECT Invtser.serialuniq, Invtser.serialno, Invtser.uniq_key,
  Invtser.uniqmfgrhd, Invtser.uniq_lot, Invtser.id_key, Invtser.id_value,
  Invtser.savedttm, Invtser.saveinit, Invtser.lotcode, Invtser.expdate,
  Invtser.reference, Invtser.ponum, Invtser.isreserved, Invtser.actvkey,
  Invtser.oldwono, Invtser.wono, Invtser.reservedflag, Invtser.reservedno
 FROM invtser
 WHERE  Invtser.uniq_key =  @gUniq_key 
 ORDER BY Invtser.serialno