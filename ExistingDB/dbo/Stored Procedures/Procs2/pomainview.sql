
CREATE proc [dbo].[pomainview] @gcPonum char(15) =''
AS
-- 01/19/15 VL added potaxfc, pototalfc, shipchgfc, recontodtfc, Fcused_uniq and Fchist_key for FC
-- 11/09/16 VL added Presentation currency fields: potaxPR, pototalPR, shipchgPR, recontodtPR, PRFcused_uniq, FuncFcused_uniq
SELECT Supinfo.supname, Supinfo.status, Pomain.ponum, Pomain.conum,
  Pomain.podate, Pomain.postatus, Pomain.verdate, Pomain.buyer, Pomain.potax,
  Pomain.pototal, Pomain.appvname, Pomain.finalname, Pomain.terms,
  Pomain.ponote, Pomain.pofooter, Pomain.closddate, Pomain.is_printed,
  Pomain.c_link, Pomain.r_link, Pomain.i_link, Pomain.b_link, Pomain.shipchg,
  Pomain.is_sctax, Pomain.sctaxpct, Pomain.confname, Supinfo.acctno,
  Pomain.confirmby, Pomain.shipcharge, Pomain.fob, Pomain.shipvia,
  Pomain.deltime, Pomain.isinbatch, Pomain.popriority, Pomain.poackndoc,
  Pomain.verinit, Pomain.uniqsupno, Pomain.pochanges, Supinfo.supid,
  Pomain.lfreightinclude,POMAIN.POUNIQUE, Pomain.CurrChange, PoMain.acknowledged, POMAIN.RecVer,
  Pomain.potaxfc, Pomain.pototalfc, Pomain.shipchgfc, Pomain.recontodtfc, Pomain.Fcused_uniq, Pomain.FcHist_key, 
  potaxPR, pototalPR, shipchgPR, recontodtPR, PRFcused_uniq, FuncFcused_uniq  
  FROM pomain  INNER JOIN supinfo  ON  Pomain.uniqsupno = Supinfo.uniqsupno 
 WHERE  Pomain.ponum = @gcPoNum 