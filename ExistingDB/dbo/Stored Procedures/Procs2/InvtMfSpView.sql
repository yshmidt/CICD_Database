

CREATE proc [dbo].[InvtMfSpView]  @gUniq_Key char(10) =''
AS
SELECT Invtmfsp.uniqmfsp, Invtmfsp.uniqmfgrhd, Invtmfsp.uniqsupno,
  Invtmfsp.suplpartno, Invtmfsp.uniq_key, Supinfo.supname,Supinfo.Supid,
  Invtmfsp.pfdsupl, Invtmfsp.is_deleted
 FROM invtmfsp 
    INNER JOIN supinfo 
   ON  Invtmfsp.uniqsupno = Supinfo.uniqsupno
 WHERE  Invtmfsp.uniq_key = @gUniq_Key 

