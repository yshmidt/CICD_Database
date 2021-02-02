

CREATE proc [dbo].[InvtMfsuppliersInfoView] (@lcUniqMfgrhd char(10) ='')
AS
SELECT Supinfo.supname, Invtmfsp.uniqmfsp, Supinfo.supid,
  Supinfo.uniqsupno, Invtmfsp.uniqmfgrhd, Invtmfsp.suplpartno,
  Invtmfsp.uniq_key
 FROM invtmfsp 
    INNER JOIN supinfo 
   ON  Invtmfsp.UniqSupno = Supinfo.UniqSupno
 WHERE  Invtmfsp.uniqmfgrhd = @lcUniqmfgrhd 


