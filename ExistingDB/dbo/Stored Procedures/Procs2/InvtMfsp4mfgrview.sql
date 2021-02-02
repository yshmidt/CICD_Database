

CREATE proc [dbo].[InvtMfsp4mfgrview] (@lcuniqsupno char(10) ='', @lcUniqMfgrhd char(10) ='')
AS
SELECT Invtmfsp.uniqmfgrhd, Invtmfsp.uniqmfsp, Invtmfsp.uniqsupno,
  Invtmfsp.suplpartno, Invtmfsp.uniq_key, Invtmfsp.pfdsupl,
  Invtmfsp.is_deleted
 FROM invtmfsp
 WHERE  Invtmfsp.uniqsupno = @lcuniqsupno
   AND  Invtmfsp.uniqmfgrhd = @lcUniqMfgrHd
   AND  Invtmfsp.is_deleted =0



