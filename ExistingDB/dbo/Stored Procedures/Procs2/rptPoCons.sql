  
-- =============================================  
-- Author:  Vicky Lu  
-- Create date: 03/28/19  
-- Description: PO Instore consumption report, by Partmfgr,Mfgr_pt_no or by supplier, contract  
-- Reports:  POCONSMF.mrt and POCONSSC  
-- Modified Satish B: 05/28/2019 Replace @lcUniq_key with @lcUniqMfgrHd to consumption report by Part Mfgr & Mfgr Part Number  
-- Modified Satish B: 05/28/2019 Add  @tUniqMfgrHd temporary table to add multiple take multiple PartMfr and Mfgr Part Number Consumption report 
  --- 01/30/20 YS take package information from mfgrmaster table  
-- =============================================  
--select * from postore  
--exec rptPoCons @lcUniqSupno='', @lcUniqMfgrHd='_2NI0UG5CF,_2I40NBTJS,_2460JGU8Z',@lcSort='Part Mfgr & Mfgr Part Number',@userId='49F80792-E15E-4B62-B720-21B360E3108A'  
CREATE PROCEDURE [dbo].[rptPoCons]    
 @lcUniqSupno varchar(max) = ''  
 -- Satish B: 05/28/2019 Replace @lcUniq_key with @lcUniqMfgrHd to consumption report by Part Mfgr & Mfgr Part Number  
 ,@lcUniqMfgrHd varchar(max) = ''  
 --,@lcUniq_key varchar(max) = ''  
 ,@lcSort char(35) = '' --Part Mfgr & Mfgr Part Number or 'Supplier & Contract Number'  
 ,@userId uniqueidentifier= null  
AS  
BEGIN  
  
 DECLARE  @tSupplier tSupplier  
 DECLARE @tSupNo as table (Uniqsupno char (10))  
 -- Satish B: 05/28/2019 Add  @tUniqMfgrHd temporary table to add multiple take multiple PartMfr and Mfgr Part Number Consumption report  
 DECLARE @tUniqMfgrHd as table (uniqmfgrhd char (10))  
 -- get list of Suppliers for @userid with access  
 INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, 'All'; --11/23/16 DRP:  replaced @supplierStatus with All  
   
 --- have to check for all suppliers @lcUniqSupNo for all no need to run [fn_simpleVarcharlistToTable], no data will be retuned  
 IF @lcUniqSupno is not null and @lcUniqSupno <>'' and @lcUniqSupno<>'All'  
  INSERT into @tSupNo select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqSupno,',')  
   WHERE CAST (id as CHAR(10)) IN (SELECT Uniqsupno from @tSupplier)  
 ELSE  
 --- empty or null customer or part number means no selection were made  
 IF  @lcUniqSupno='All'   
 BEGIN  
  INSERT INTO @tSupNo SELECT UniqSupno FROM @tSupplier   
   
 END  
 -- Satish B: 05/28/2019 Add  @tUniqMfgrHd temporary table to add multiple take multiple PartMfr and Mfgr Part Number Consumption report  
 IF @lcUniqMfgrHd<>''  
 BEGIN  
      INSERT INTO @tUniqMfgrHd select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqMfgrHd,',')  
 END  
  
IF @lcSort = 'Part Mfgr & Mfgr Part Number'  
--- 01/30/20 YS take package information from mfgrmaster table 
 SELECT DISTINCT Supinfo.supname, Inventor.part_no,Inventor.revision,Inventor.part_class,Inventor.part_type,  
  Inventor.descript, Inventor.u_of_meas, Inventor.pur_uofm,  
 --- 01/30/20 YS take package information from mfgrmaster table 
  m.part_pkg as package, Inventor.buyer_type, Inventor.stdcost,  
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
  inner join mfgrmaster m on POSTORE.PARTMFGR=m.PartMfgr
  and postore.MFGR_PT_NO=m.mfgr_pt_no
  INNER JOIN Inventor ON Inventor.Uniq_key=Postore.Uniq_key  
  inner join warehous on  Warehous.UniqWh=Postore.UniqWh  
  INNER JOIN Poitems ON POSTORE.UNIQLNNO = Poitems.Uniqlnno  
  WHERE (@lcUniqSupno <> '' AND @lcUniqMfgrHd = '' AND H.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo))  
  OR (@lcUniqSupno = '' AND @lcUniqMfgrHd <> '' AND Postore.UniqMfgrHd IN (SELECT uniqmfgrhd from @tUniqMfgrHd))  
  ORDER BY Postore.Partmfgr, Postore.Mfgr_pt_no, Supname, Contr_no, Inventor.Part_no, Inventor.Revision, DATE_ISU  
ELSE  
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
  inner join mfgrmaster m on POSTORE.PARTMFGR=m.PartMfgr
  and postore.MFGR_PT_NO=m.mfgr_pt_no
    INNER JOIN Inventor ON Inventor.Uniq_key=Postore.Uniq_key  
  inner join warehous on  Warehous.UniqWh=Postore.UniqWh  
  INNER JOIN Poitems ON POSTORE.UNIQLNNO = Poitems.Uniqlnno  
  WHERE (@lcUniqSupno <> '' AND @lcUniqMfgrHd = '' AND H.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo))  
  OR (@lcUniqSupno = '' AND @lcUniqMfgrHd <> '' AND Postore.UniqMfgrHd IN (SELECT uniqmfgrhd from @tUniqMfgrHd))  
  ORDER BY Supname, Contr_no, Inventor.Part_no, Inventor.Revision, Postore.Partmfgr, Postore.Mfgr_pt_no  
END  