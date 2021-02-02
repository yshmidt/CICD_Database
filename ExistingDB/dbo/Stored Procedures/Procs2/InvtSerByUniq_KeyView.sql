
CREATE PROC [dbo].[InvtSerByUniq_KeyView] @gUniq_Key AS char(10)=null
AS
BEGIN
SELECT Invtser.serialuniq, Invtser.serialno, Invtser.uniq_key,
  Invtser.uniqmfgrhd, Invtser.uniq_lot, Invtser.id_key, Invtser.id_value,
  Invtser.savedttm, Invtser.saveinit, Invtser.lotcode, Invtser.expdate,
  Invtser.reference, Invtser.ponum, Invtser.isreserved, Invtser.actvkey,
  Invtser.oldwono, Invtser.wono, Invtser.reservedflag, Invtser.reservedno
 FROM InvtSer
 WHERE Invtser.Uniq_key = @gUniq_key 

END