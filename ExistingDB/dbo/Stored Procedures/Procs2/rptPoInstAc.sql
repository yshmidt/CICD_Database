  
-- =============================================  
-- Author:  Vicky Lu  
-- Create date: 03/27/19  
-- Description: PO Instore report printed right after the instore POs are created  
-- Reports:  PoInstAc.mrt  
-- Modify : Nitesh B 10/1/2019 : Added new parameter @lcPoNum
--		  : Nitesh B 10/15/2019 : Get 'ALL' supplier for In-Plant PO
  --- 01/30/20 YS take package information from mfgrmaster table 
-- =============================================  
CREATE PROCEDURE [dbo].[rptPoInstAc]   
  
 @userId uniqueidentifier = null,
 @lcPoNum nvarchar(MAX) = '' -- Nitesh B 10/1/2019 : Added new parameter @lcPoNum
AS  
BEGIN    

-- get list of approved suppliers for this user  
DECLARE @tSupplier tSupplier  
INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, 'ALL';  -- Nitesh B 10/15/2019 : Get 'ALL' supplier for In-Plant PO
DECLARE @zPostore TABLE (UniqRecord char(10))  
INSERT INTO @zPostore   
 SELECT UniqRecord  
  FROM Postore INNER JOIN [Contract] C ON postore.UNIQ_KEY=C.UNIQ_KEY   
 inner join supinfo  on postore.uniqsupno= supinfo.uniqsupno  
 inner join ContractHeader H on h.contractH_unique=c.contractH_unique  
 and h.uniqSupno=Supinfo.uniqsupno  
 inner join Contmfgr on Contmfgr.Contr_uniq=C.Contr_uniq  
 AND Contmfgr.Partmfgr=Postore.PartMfgr  
 AND Contmfgr.Mfgr_pt_no=Postore.Mfgr_pt_no  
 INNER JOIN Inventor ON Inventor.Uniq_key=Postore.Uniq_key  
 inner join warehous on  Warehous.UniqWh=Postore.UniqWh  
 INNER JOIN Poitems ON POSTORE.UNIQLNNO = Poitems.Uniqlnno  
 WHERE 1= case WHEN H.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupplier) THEN 1 ELSE 0  END  
 AND --Postore.lPrinted = 0 AND 
 Postore.PONUM IN (SELECT TRIM(id) PONUM FROM [dbo].[fn_orderedVarcharlistToTable] (@lcPoNum,',')) -- Nitesh B 10/1/2019 : Added new parameter @lcPoNum
   
  --- 01/30/20 YS take package information from mfgrmaster table  
SELECT DISTINCT Supinfo.supname, Inventor.part_no,Inventor.revision,Inventor.part_class,Inventor.part_type,  
 Inventor.descript, Inventor.u_of_meas, Inventor.pur_uofm,  
 m.part_pkg, Inventor.buyer_type, Inventor.stdcost,  
 Postore.qty_isu,Postore.partmfgr,Postore.mfgr_pt_no,Postore.UniqWh,  
 Postore.date_isu, Poitems.CostEach, Poitems.CostEachFC,   
 ROUND(Poitems.CostEach*Postore.Qty_isu,2) AS ExtAmt, ROUND(Poitems.CostEachFC*Postore.Qty_isu,2) AS ExtAmtFC,  
 Postore.uniq_key, Postore.UniqSupno,Postore.ponum,  
 Postore.UniqMfgrHd, Supinfo.r_link, Supinfo.c_link,  
 Postore.uniqrecord,Supinfo.Terms,  
 PoStore.LotCode,PoStore.ExpDate,PoStore.Reference,  
 Postore.UsedBy,Warehous.whno, Postore.location,  
 C.contr_uniq,H.contr_no, H.quote_no,Contmfgr.Mfgr_uniq,  
 POSTORE.serialno ,POSTORE.serialuniq,PoStore.UNIQLNNO,POSTORE.RecVer ,  
 Inventor.Taxable, H.Fcused_uniq, H.Fchist_key,  
 Inventor.stdcostPR   
FROM POSTORE INNER JOIN [Contract] C ON postore.UNIQ_KEY=C.UNIQ_KEY  
inner join supinfo  on postore.uniqsupno= supinfo.uniqsupno  
 inner join ContractHeader H on h.contractH_unique=c.contractH_unique  
 and h.uniqSupno=Supinfo.uniqsupno  
 inner join Contmfgr on Contmfgr.Contr_uniq=C.Contr_uniq  
 AND Contmfgr.Partmfgr=Postore.PartMfgr  
 AND Contmfgr.Mfgr_pt_no=Postore.Mfgr_pt_no  
  --- 01/30/20 YS take package information from mfgrmaster table 
 inner join mfgrmaster m on postore.PARTMFGR=m.PartMfgr
 and postore.MFGR_PT_NO=m.mfgr_pt_no
 INNER JOIN Inventor ON Inventor.Uniq_key=Postore.Uniq_key  
 inner join warehous on  Warehous.UniqWh=Postore.UniqWh  
 INNER JOIN Poitems ON POSTORE.UNIQLNNO = Poitems.Uniqlnno  
 WHERE 1= case WHEN H.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupplier) THEN 1 ELSE 0  END  
 AND --Postore.lPrinted = 0 AND 
 Postore.PONUM IN (SELECT TRIM(id) PONUM FROM [dbo].[fn_orderedVarcharlistToTable] (@lcPoNum,',')) -- Nitesh B 10/1/2019 : Added new parameter @lcPoNum
 ORDER BY ponum, part_no, revision  
   
-- Update lPrinted = 1 after user run this report  
UPDATE Postore SET lPrinted = 1 FROM @zPostore Z WHERE Z.UniqRecord = Postore.UNIQRECORD  
  
END  