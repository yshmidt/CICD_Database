--- =======================================================================================================================================              
-- Author: Satish B              
-- Create date:  4/25/2018              
-- Description: Imports the XML file to SQL table              
-- Modified  Satish B: 05/15/2019 Auto Populated by default            
-- Modified  VijayG: 05/15/2019 Set default POItype as Inventory if poitType is null or empty from template           
-- Shiv P: 08/05/2019 When user put the invalid part no and revision in the template and description is empty then we populating warehouse from inventor and part no rev is invalid then description is null          
-- Shiv P: 08/14/2019 To insert the PartClass/PartType/Description in Description when user validate the uploaded record          
-- Shiv P: 09/11/2019  Creating the problem to upload the PO so remove that code          
-- Modified  11/05/2019 Shiv P : Added change for when date is not empty then we are insert that into empty        
-- Modified  11/11/2019 Shiv P : Added change for validate the date    
-- Modified  12/11/2019 Mahesh B : Added change Sequance of column    
-- Modified  22/11/2019 Shiv P : To update the S_ORD_QTY in PoItems table    
-- Modified  27/11/2019 Nitesh B : Added CASE to insert requesttp based on poitType if not provided    
-- Modified  12/09/2019 Shiv P : Removed condition to select default Warehouse while upload when it is empty   
-- Modified  12/10/2019 Shiv P : Removed condition to select default requesttp based on poitType while upload
-- Modified  12/10/2019 Shiv P : Added condition to select default requesttp based on poitType while upload
-- Modified  12/11/2019 Shiv P : To add the schd qty if date and qty are same
-- Modified  01/16/2020 Shiv P : Remove price column from group by   
-- Satyawan H 06/04/2020 : Added PartNo, PartMfgr, Mfgr_pt_No condition for unique identification of the same part and same item No validation
-- Satyawan H 06/04/2020 : Added mfgr_pt_No and Part_mfgr in selection and Unpivot
-- Satyawan H 06/07/2020 : Added PartMfgr and MfgrPtNo from existing if not provided
-- Modified  10/09/2020 Shiv P : CAST schdQty to numeric(10,2) to calculate SUM and select schdQty as varchar
-- =======================================================================================================================================              
CREATE PROC ImportPOUploadXML
-- Add the parameters for the stored procedure here              
@importId uniqueidentifier,              
@userId uniqueidentifier,              
@x xml                 
AS              
BEGIN              
 SET NOCOUNT ON;              
 /* If import ID is not provided, create a new is */              
 IF (@importId IS NULL) SET @importId = NEWID()              
 /* Get user initials for the header */              
 DECLARE @userInit varchar(5),@lFreight bit=0,@moduleId char(10)              
 SELECT @userInit = Initials FROM aspnet_Profile WHERE userId = @userId              
 SET @moduleId=(SELECT ModuleId FROM MnxModule WHERE modulename='PO Upload')              
 DECLARE @lRollback bit=0,@headerErrs varchar(MAX),@partErrs varchar(MAX),@avlErrs varchar(MAX)              
 DECLARE @ErrTable TABLE (ErrNumber int,ErrSeverity int,ErrProc varchar(MAX),ErrLine int,ErrMsg varchar(MAX))              
	
 BEGIN TRY  -- outside begin try              
    BEGIN TRANSACTION               
  /* Create two table variables.  1 - a unique list of parts to be loaded. 2 - all records passed by the xml */              
  DECLARE @itemsTable TABLE (rowId uniqueidentifier DEFAULT NEWSEQUENTIALID() PRIMARY KEY,rowNum int, itemNo varchar(MAX),poitType varchar(MAX),partNo varchar(MAX)              
          ,revision varchar(MAX),descript varchar(MAX),costEachFc varchar(MAX),pur_UOFM varchar(MAX),taxId varchar(MAX),partMfgr varchar(MAX),mfgr_Pt_No varchar(MAX)              
          ,isFirm varchar(MAX),pur_LTime varchar(MAX),pur_LUnit varchar(MAX),minOrd varchar(MAX),ordMult varchar(MAX),firstArticle varchar(MAX)              
          ,inspExcept varchar(MAX),inspException varchar(MAX), inspexnote varchar(MAX),schdDate varchar(MAX)              
          ,origCommitDt varchar(MAX),schdQty varchar(MAX),warehouse varchar(MAX),location varchar(MAX),woPrjNumber varchar(MAX)              
          ,requesttp varchar(MAX),requestor varchar(MAX),glNbr varchar(MAX),ord_Qty varchar(MAX),costeach varchar(MAX)              
          ,poNum varchar(MAX),supName varchar(MAX),terms varchar(MAX)              
          ,buyer varchar(MAX),priority varchar(MAX),confTo varchar(MAX),taxable varchar(MAX),itemnote varchar(MAX)              
          ,shipChgAMT varchar(MAX),is_SCTAX varchar(MAX),scTaxPct varchar(MAX),shipCharge varchar(MAX),shipVia varchar(MAX),fob varchar(MAX)    
          ,s_ord_qty varchar(MAX) )              
                      
  DECLARE @tempTable TABLE (rowId uniqueidentifier DEFAULT NEWSEQUENTIALID() PRIMARY KEY,rowNum int, itemNo varchar(MAX),poitType varchar(MAX)              
          ,partNo varchar(MAX),revision varchar(MAX),descript varchar(MAX),costEachFc varchar(MAX)              
          ,pur_UOFM varchar(MAX),taxId varchar(MAX),partMfgr varchar(MAX),mfgr_Pt_No varchar(MAX)              
          ,isFirm varchar(MAX),pur_LTime varchar(MAX),pur_LUnit varchar(MAX),minOrd varchar(MAX),ordMult varchar(MAX)              
          ,firstArticle varchar(MAX),inspExcept varchar(MAX),inspException varchar(MAX),inspexnote varchar(MAX),poNum varchar(MAX)              
          ,supName varchar(MAX),poNote varchar(MAX),terms varchar(MAX)              
          ,buyer varchar(MAX),shipChgAMT varchar(MAX),is_SCTAX varchar(MAX),scTaxPct varchar(MAX),shipCharge varchar(MAX),fob varchar(MAX)              
          ,shipVia varchar(MAX),lFreightInclude varchar(MAX),schdDate varchar(MAX)              
          ,origCommitDt varchar(MAX),schdQty varchar(MAX),warehouse varchar(MAX)              
          ,location varchar(MAX),woPrjNumber varchar(MAX),requesttp varchar(MAX),requestor varchar(MAX)              
          ,glNbr varchar(MAX),priority varchar(MAX),confTo varchar(MAX),ord_Qty varchar(MAX),costeach varchar(MAX)              
          ,taxable varchar(MAX),itemnote varchar(MAX),s_ord_qty varchar(MAX))              
              
  DECLARE @scheduleTable TABLE (rowId uniqueidentifier,rowNum int, itemNo varchar(MAX),scheduleRowId uniqueidentifier,poitType varchar(MAX)              
          ,partNo varchar(MAX),revision varchar(MAX),descript varchar(MAX),costEachFc varchar(MAX)              
          ,pur_UOFM varchar(MAX),taxId varchar(MAX),partMfgr varchar(MAX),mfgr_Pt_No varchar(MAX)              
          ,isFirm varchar(MAX),pur_LTime varchar(MAX),pur_LUnit varchar(MAX),minOrd varchar(MAX),ordMult varchar(MAX)              
          ,firstArticle varchar(MAX),inspExcept varchar(MAX),inspException varchar(MAX)              
          ,inspexnote varchar(MAX),poNum varchar(MAX),supName varchar(MAX),poNote varchar(MAX),terms varchar(MAX)              
          ,buyer varchar(MAX),shipChgAMT varchar(MAX),is_SCTAX varchar(MAX),scTaxPct varchar(MAX),shipCharge varchar(MAX),fob varchar(MAX)              
          ,shipVia varchar(MAX),lFreightInclude varchar(MAX),schdDate varchar(MAX)              
          ,origCommitDt varchar(MAX),schdQty varchar(MAX),warehouse varchar(MAX)              
          ,location varchar(MAX),woPrjNumber varchar(MAX),requesttp varchar(MAX),requestor varchar(MAX)              
          ,glNbr varchar(MAX),priority varchar(MAX),confTo varchar(MAX),ord_Qty varchar(MAX),costeach varchar(MAX)              
          ,taxable varchar(MAX),itemnote varchar(MAX))              
         
  /* Parse PO records and insert into table variable */              
  INSERT INTO @tempTable(rowNum,itemno,poitType,partNo,revision,descript,costEachFc,pur_UOFM,taxId,partMfgr,mfgr_Pt_No,isFirm,pur_LTime,pur_LUnit,minOrd,
          ordMult,firstArticle,inspExcept,inspException,inspexnote,poNum,supName,poNote,terms,buyer,shipChgAMT,is_SCTAX,scTaxPct,shipCharge,fob,shipVia,
          lFreightInclude,schdDate,origCommitDt,schdQty,warehouse,location,woPrjNumber,requesttp,requestor,glNbr,priority,confTo,ord_Qty,costeach,taxable,
          itemnote,s_ord_qty)              
   SELECT DENSE_RANK() OVER(ORDER BY               
     x.importPO.query('ITEMNO/text()').value('.','VARCHAR(MAX)')+              
     x.importPO.query('DESCRIPT/text()').value('.', 'VARCHAR(MAX)'))rowNum,              
     x.importPO.query('ITEMNO/text()').value('.','VARCHAR(MAX)') itemno,              
     x.importPO.query('POITTYPE/text()').value('.', 'VARCHAR(MAX)') poitType,              
     x.importPO.query('PARTNO/text()').value('.', 'VARCHAR(MAX)') partNo,              
     x.importPO.query('REVISION/text()').value('.', 'VARCHAR(MAX)') revision,               
     x.importPO.query('DESCRIPT/text()').value('.', 'VARCHAR(MAX)') descript,              
     x.importPO.query('COSTEACHFC/text()').value('.', 'VARCHAR(MAX)')costEachFc,              
     x.importPO.query('PUR_UOFM/text()').value('.', 'VARCHAR(MAX)')pur_UOFM,              
     x.importPO.query('TAXID/text()').value('.', 'VARCHAR(MAX)')taxId,        
     x.importPO.query('PARTMFGR/text()').value('.', 'VARCHAR(MAX)')partMfgr,              
     x.importPO.query('MFGR_PT_NO/text()').value('.', 'VARCHAR(MAX)')mfgr_Pt_No,              
     x.importPO.query('ISFIRM/text()').value('.', 'VARCHAR(MAX)')isFirm,              
     x.importPO.query('PUR_LTIME/text()').value('.', 'VARCHAR(MAX)')pur_LTime,              
     x.importPO.query('PUR_LUNIT/text()').value('.', 'VARCHAR(MAX)')pur_LUnit,              
     x.importPO.query('MINORD/text()').value('.', 'VARCHAR(MAX)')minOrd,              
     x.importPO.query('ORDMULT/text()').value('.', 'VARCHAR(MAX)')ordMult,              
     x.importPO.query('FIRSTARTICLE/text()').value('.', 'VARCHAR(MAX)')firstArticle,              
     x.importPO.query('INSPEXCEPT/text()').value('.', 'VARCHAR(MAX)')inspExcept,              
     x.importPO.query('INSPEXCEPTION/text()').value('.', 'VARCHAR(MAX)')inspException,              
     x.importPO.query('INSPEXNOTE/text()').value('.', 'VARCHAR(MAX)')inspexnote,              
     x.importPO.query('PONUM/text()').value('.', 'VARCHAR(MAX)')poNum,              
     x.importPO.query('SUPNAME/text()').value('.', 'VARCHAR(MAX)')supName,              
     x.importPO.query('PONOTE/text()').value('.', 'VARCHAR(MAX)')poNote,              
     x.importPO.query('TERMS/text()').value('.', 'VARCHAR(MAX)')terms,              
     x.importPO.query('BUYER/text()').value('.', 'VARCHAR(MAX)')buyer,              
     x.importPO.query('SHIPCHGAMOUNT/text()').value('.', 'VARCHAR(MAX)')shipChgAMT,              
     x.importPO.query('IS_SCTAX/text()').value('.', 'VARCHAR(MAX)')is_SCTAX,              
     x.importPO.query('SCTAXPCT/text()').value('.', 'VARCHAR(MAX)')scTaxPct,              
     x.importPO.query('SHIPCHARGE/text()').value('.', 'VARCHAR(MAX)')shipCharge,              
     x.importPO.query('FOB/text()').value('.', 'VARCHAR(MAX)')fob,              
     x.importPO.query('SHIPVIA/text()').value('.', 'VARCHAR(MAX)')shipVia,              
     x.importPO.query('LFREIGHTINCLUDE/text()').value('.', 'VARCHAR(MAX)')lFreightInclude,              
     x.importPO.query('SCHDDATE/text()').value('.', 'VARCHAR(MAX)')schdDate,              
     x.importPO.query('ORIGCOMMITDT/text()').value('.', 'VARCHAR(MAX)')origCommitDt,              
     x.importPO.query('SCHDQTY/text()').value('.', 'VARCHAR(MAX)')schdQty,              
     x.importPO.query('WAREHOUSE/text()').value('.', 'VARCHAR(MAX)')warehouse,              
     x.importPO.query('LOCATION/text()').value('.', 'VARCHAR(MAX)')location,              
     x.importPO.query('WOPRJNUMBER/text()').value('.', 'VARCHAR(MAX)')woPrjNumber,              
     x.importPO.query('REQUESTTP/text()').value('.', 'VARCHAR(MAX)')requesttp,              
     x.importPO.query('REQUESTOR/text()').value('.', 'VARCHAR(MAX)')requestor,              
     x.importPO.query('GLNBR/text()').value('.', 'VARCHAR(MAX)')glNbr,              
     x.importPO.query('PRIORITY/text()').value('.', 'VARCHAR(MAX)')priority,              
     x.importPO.query('CONFTO/text()').value('.', 'VARCHAR(MAX)')confTo,              
     x.importPO.query('ORD_QTY/text()').value('.', 'VARCHAR(MAX)')ord_Qty,              
     x.importPO.query('COSTEACH/text()').value('.', 'VARCHAR(MAX)')costeach,              
     x.importPO.query('TAXABLE/text()').value('.', 'VARCHAR(MAX)')taxable,              
     x.importPO.query('ITEMNOTE/text()').value('.', 'VARCHAR(MAX)')itemnote,      
  x.importPO.query('S_ORD_QTY/text()').value('.', 'VARCHAR(MAX)')s_ord_qty    
    FROM @x.nodes('/Root/Row') AS X(importPO)              
    OPTION (OPTIMIZE FOR(@x = NULL))     
     
  --Modified  22/11/2019 Shiv P : To update the S_ORD_QTY in PoItems table    
  UPDATE t SET t.s_ord_qty=     
  CAST(CAST( CASE WHEN u.[TO]=i.U_OF_MEAS THEN (t.ord_Qty* u.FORMULA)     
  WHEN u.[TO]=i.PUR_UOFM THEN (t.ord_Qty / u.FORMULA) ELSE  t.s_ord_qty END as DECIMAL(10,2)) as VARCHAR)    
  FROM @tempTable t    
  JOIN INVENTOR i ON  i.PART_NO = t.PartNo AND i.REVISION=CONVERT(VARCHAR(4), t.RevisiON)      
  JOIN UNIT u ON ((u.[FROM] = i.PUR_UOFM AND u.[TO]=i.U_OF_MEAS) OR (u.[FROM] = i.U_OF_MEAS AND u.[TO]=i.PUR_UOFM))    
  WHERE  PART_SOURC IN('Buy','MAKE') AND i.U_OF_MEAS != t.pur_UOFM AND t.poitType='Invt part'    
        
  /* Create a unique list of parts filtering out duplicate rows for multiple line item*/              
  INSERT INTO @itemsTable(rowNum,itemNo,poitType,partNo,revision,descript,costEachFc,pur_UOFM,taxId,partMfgr,mfgr_Pt_No              
              ,isFirm,pur_LTime,pur_LUnit,minOrd,ordMult,firstArticle,inspExcept,inspException,inspexnote,ord_Qty,              
              costeach,poNum,supName,terms,buyer,priority,confTo,taxable,itemnote,shipChgAMT,is_SCTAX,scTaxPct,
              shipCharge,shipVia,fob,s_ord_qty)                
  SELECT rowNum,itemNo,          
  --VijayG: 05/15/2019 Set default POItype as Inventory if poitType is null or empty from template           
  CASE WHEN (poitType='INVT PART' OR poitType='' OR poitType = NULL) THEN 'Invt Part' ELSE poitType END,partNo,revision,          
  --Shiv P: 08/14/2019 To insert the PartClass/PartType/Description in Description when user validate the uploaded record          
  --Shiv P: 09/11/2019  Creating the problem to upload the PO so remove that code          
  CASE WHEN descript = '' OR descript = NULL THEN (SELECT TOP 1 descript from inventor where part_no=partNo) ELSE descript END          
    ,costEachFc,pur_UOFM,taxId              
    ,CASE WHEN (partMfgr='' OR partMfgr=NULL) AND (select COUNT(im.uniqmfgrhd) from inventor i join invtmpnlink im on i.uniq_key = im.uniq_key where i.part_no=partNo) > 0               
     THEN (SELECT TOP 1 m.partmfgr from inventor i join invtmpnlink im on i.uniq_key = im.uniq_key join mfgrmaster m on im.mfgrmasterid=m.mfgrmasterid where i.part_no=partNo) ELSE partMfgr END              
    ,CASE WHEN (partMfgr='' OR partMfgr=NULL) AND (select COUNT(im.uniqmfgrhd) from inventor i join invtmpnlink im on i.uniq_key = im.uniq_key where i.part_no=partNo) > 0               
     THEN (SELECT TOP 1 m.mfgr_pt_no from inventor i join invtmpnlink im on i.uniq_key = im.uniq_key join mfgrmaster m on im.mfgrmasterid=m.mfgrmasterid where i.part_no=partNo) ELSE mfgr_Pt_No END              
    ,CASE WHEN isFirm='yes' OR isFirm='1' THEN 1 ELSE 0 END              
    ,CASE WHEN pur_LTime = '' OR pur_LTime = NULL THEN (SELECT TOP 1 pur_LTime from inventor where part_no=partNo) ELSE pur_LTime END              
    ,CASE WHEN pur_LUnit = '' OR pur_LUnit = NULL THEN (SELECT TOP 1 pur_LUnit from inventor where part_no=partNo) ELSE pur_LUnit END              
    ,CASE WHEN minOrd = '' OR minOrd = NULL THEN (SELECT TOP 1 minOrd from inventor where part_no=partNo) ELSE minOrd END              
    ,CASE WHEN ordMult = '' OR ordMult = NULL THEN (SELECT TOP 1 ordMult from inventor where part_no=partNo) ELSE ordMult END              
    ,CASE WHEN firstArticle='yes' OR firstArticle='1' THEN 1 ELSE 0 END,CASE WHEN inspExcept='yes' OR inspExcept='1' THEN 1 ELSE 0 END              
    ,inspException,inspexnote,ord_Qty,MAX(costeach),poNum,supName,              
    CASE WHEN terms='' OR terms = null THEN (SELECT Top 1 Terms FROM SUPINFO WHERE Supname = supName) ELSE terms END              
    ,buyer              
    ,CASE WHEN [priority]='' OR [priority] = NULL THEN 'STANDARD' ELSE [priority] END              
    ,confTo,
    CASE WHEN taxable='yes' OR taxable='1' THEN 1 ELSE 0 END,
    itemnote,shipChgAMT,is_SCTAX,scTaxPct,shipCharge,shipVia,fob,s_ord_qty              
   FROM @tempTable             
   -- Modified  01/16/2020 Shiv P : Remove price column from group by                
   GROUP BY rowNum,itemNo,poitType,partNo,revision,descript,costEachFc,pur_UOFM,taxId,partMfgr,mfgr_Pt_No,isFirm,pur_LTime,pur_LUnit,minOrd,
				 ordMult,firstArticle,inspExcept,inspException,inspexnote,ord_Qty,poNum,supName,terms,buyer,priority,confTo,taxable,itemnote,
				 shipChgAMT,is_SCTAX,scTaxPct,shipCharge,shipVia,fob, s_ord_qty               
   ORDER BY itemno              
     
    /* Create a unique list of parts filtering out duplicate rows for multiple schedule*/              
  INSERT INTO @scheduleTable(rowId,rowNum, itemNo,scheduleRowId,poitType,partNo,revision,descript,costEachFc,pur_UOFM,taxId,partMfgr,  
  mfgr_Pt_No,isFirm,pur_LTime,pur_LUnit,minOrd,ordMult,firstArticle,inspExcept,inspException,inspexnote,ord_Qty,costeach,poNum,  
  supName,terms,buyer,[priority],confTo,taxable,itemnote ,shipChgAMT,is_SCTAX,scTaxPct,shipCharge,shipVia,fob,schdDate,schdQty,  
  origCommitDt,warehouse,[location],woPrjNumber,requesttp,requestor,glNbr)              
  SELECT null,rowNum, itemNo, null,poitType,partNo,revision,descript,costEachFc,pur_UOFM,taxId,
  -- Satyawan H 06/07/2020 : Added PartMfgr and MfgrPtNo from existing if not provided
  CASE WHEN (partMfgr='' OR partMfgr=NULL) AND (select COUNT(im.uniqmfgrhd) from inventor i join invtmpnlink im on i.uniq_key = im.uniq_key where i.part_no=partNo) > 0               
  THEN (SELECT TOP 1 m.partmfgr from inventor i join invtmpnlink im on i.uniq_key = im.uniq_key join mfgrmaster m on im.mfgrmasterid=m.mfgrmasterid where i.part_no=partNo) ELSE partMfgr END,
  CASE WHEN (partMfgr='' OR partMfgr=NULL) AND (select COUNT(im.uniqmfgrhd) from inventor i join invtmpnlink im on i.uniq_key = im.uniq_key where i.part_no=partNo) > 0               
  THEN (SELECT TOP 1 m.mfgr_pt_no from inventor i join invtmpnlink im on i.uniq_key = im.uniq_key join mfgrmaster m on im.mfgrmasterid=m.mfgrmasterid where i.part_no=partNo) ELSE mfgr_Pt_No END
  ,CASE WHEN isFirm='yes' OR isFirm='1' THEN 1 ELSE 0 END,pur_LTime,pur_LUnit,minOrd,ordMult              
  ,CASE WHEN firstArticle='yes' OR firstArticle='1' THEN 1 ELSE 0 END
  ,CASE WHEN inspExcept='yes' OR inspExcept='1' THEN 1 ELSE 0 END,  
  inspException,inspexnote,ord_Qty,costeach,poNum,supName,terms,buyer,[priority],confTo,  
  CASE WHEN taxable='yes' OR taxable='1' THEN 1 ELSE 0 END,itemnote,shipChgAMT,is_SCTAX,scTaxPct ,shipCharge,shipVia,fob,              
 --Modified  11/05/2019 Shiv P : Added change for when date is not empty then we are insert that into empty        
  --Modified  11/11/2019 Shiv P : Added change for validate the date    
 CASE WHEN schdDate != ''  AND ISDATE(schdDate) = 1 THEN CAST(TRIM(schdDate) AS DATE ) ELSE '' END, 
 -- Modified  12/11/2019 Shiv P : To add the schd qty if date and qty are same  
 -- Modified  10/09/2020 Shiv P : CAST schdQty to numeric(10,2) to calculate SUM and select schdQty as varchar
 CAST(SUM(CASE WHEN ISNUMERIC(schdQty) = 1 THEN CAST(schdQty AS numeric(10,2)) ELSE 0 END) AS varchar) schdQty,  
 CASE WHEN origCommitDt='' THEN CASE WHEN schdDate <>'' AND ISDATE(schdDate) = 1  THEN CAST(TRIM(schdDate) AS DATE ) ELSE '' END     
 ELSE     
 CASE WHEN origCommitDt != ''  AND ISDATE(origCommitDt) = 1 THEN CAST(TRIM(origCommitDt) AS DATE ) ELSE '' END    
 END,  
 warehouse       
 --Modified  12/09/2019 Shiv P : Removed condition to select default Warehouse while upload when it is empty   
 --CASE WHEN warehouse='' OR warehouse=NULL THEN   
 -- CASE WHEN (  
 --    SELECT COUNT( w.warehouse)   
 --    FROM WAREHOUS w   
 --    join PartClass p ON p.UNIQWH=w.UNIQWH              
 --    JOIN INVENTOR i on i.part_class = p.part_class   
 --    WHERE i.part_no=partNo and i.REVISION =revision  
 --     ) > 0   
 --   THEN (  
 --    SELECT TOP 1 w.warehouse from WAREHOUS w   
 --    join PartClass p ON p.UNIQWH=w.UNIQWH              
 --    JOIN INVENTOR i on i.part_class = p.part_class   
 --    WHERE i.part_no=partNo AND i.REVISION =revision  
 --   )               
 --   ELSE (SELECT WAREHOUSE FROM WAREHOUS WHERE [DEFAULT] =1) END ELSE warehouse  END    
 ,[location],CASE WHEN woPrjNumber='' OR woPrjNumber = NULL OR requesttp = 'Invt Recv' THEN 'N/A' ELSE woPrjNumber END,    
  --Modified  27/11/2019 Nitesh B : Added CASE to insert requesttp based on poitType if not provided    
  --Modified  12/10/2019 Shiv P : Removed condition to select default requesttp based on poitType while upload 
	--CASE WHEN requesttp <> '' OR requesttp <> NULL THEN requesttp     
	--	WHEN poitType='INVT PART' THEN 'Invt Recv'    
	--	WHEN poitType='MRO' THEN 'MRO'    
	--	WHEN poitType='Services' THEN 'Services'    
	--ELSE '' END,    
 requesttp,   
 requestor,glNbr                    
   FROM @tempTable t             
   GROUP BY schdDate,rowNum,itemNo,poitType,partNo,revision,descript,costEachFc,pur_UOFM,taxId,partMfgr,mfgr_Pt_No,isFirm
				,pur_LTime,pur_LUnit,minOrd,ordMult,firstArticle,inspExcept,inspException,inspexnote,ord_Qty,costeach                    
				,poNum,supName,terms,buyer,priority,confTo,taxable,itemnote,shipChgAMT,is_SCTAX,scTaxPct ,shipCharge,shipVia
				,fob,schdQty,origCommitDt,warehouse,location,woPrjNumber,requesttp,requestor,glNbr                    
		ORDER BY schdDate 

 -- Update row id // Add comment with name and data              
 UPDATE  t1               
 SET t1.rowId= t2.rowId   ,  
 t1.warehouse = 
   CASE WHEN t1.warehouse='' OR t1.warehouse=NULL   
   THEN 
	   COALESCE((SELECT TOP 1 ISNULL(wa.warehouse,' ') from Inventor i  
	   INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY    
	   INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId  
										  AND mfMaster.PartMfgr=t2.partMfgr   
										  AND mfmaster.mfgr_pt_no=t2.mfgr_Pt_No  
	   INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd   
	   INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH    
	   WHERE i.part_no=t2.partNo and i.revision=t2.revision 
        AND wa.Warehouse <> 'WIP' AND Warehouse <> 'WO-WIP'   
				AND Warehouse <> 'MRB'  AND Netable = 1          
	   AND imfgr.Is_Deleted = 0 AND mpn.Is_deleted = 0 AND mfMaster.IS_DELETED=0),'')
   ELSE   
	t1.warehouse  
   END,
	--Modified  12/10/2019 Shiv P : Added condition to select default requesttp based on poitType while upload
	t1.requesttp = CASE WHEN ISNULL(t1.requesttp,'') = '' AND t2.poitType = 'INVT PART' THEN 'Invt Recv' 
						WHEN ISNULL(t1.requesttp,'') = '' AND t2.poitType = 'MRO' THEN 'MRO' 
						WHEN ISNULL(t1.requesttp,'') = '' AND t2.poitType = 'Services' THEN 'Services' 
      ELSE 
      t1.requesttp   
			END  
  FROM @scheduleTable t1 
  INNER JOIN @itemsTable t2 ON t1.itemno=t2.itemno              
  -- Satyawan H 06/04/2020 : Added PartNo, PartMfgr, Mfgr_pt_No condition for unique identification of the same part and same item No validation
       			AND t1.partNo = t2.partNo
				AND t1.partMfgr = t2.partMfgr 
				AND t1.mfgr_Pt_No = t2.mfgr_Pt_No

 -- Update schedule row id // Add comment with name and data              
 UPDATE s1              
 SET scheduleRowId = x.RowUniq               
 FROM @scheduleTable s1              
 INNER JOIN  (SELECT NEWID() AS RowUniq,itemNo 
        FROM @scheduleTable 
        GROUP BY itemNo,schdDate,PartNo,partMfgr,mfgr_Pt_No
  ) x              
 ON  s1.itemno = x.itemno              
              
  /*Check to see if the assembly already has an active import and cancel if it does */              
  DECLARE @poNum varchar(max),@supplier varchar(max),@terms varchar(max),@buyer varchar(max),@poDate varchar(max),
    @priority varchar(max),@confTo varchar(max),@status varchar(max),@lFreightInclude varchar(max),
    @poNote varchar(max),@shipChgAMT varchar(max),@is_SCTAX varchar(max),@sc_TaxPct varchar(max),
    @shipCharge varchar(max),@shipVia varchar(max),@fob varchar(max),@existImportId uniqueidentifier,@existCount int              

  SELECT  @poNum = poNum,@supplier =supName,@terms = terms,@buyer =buyer,
          @priority = CASE WHEN [priority]='' OR [priority] = NULL THEN 'STANDARD' ELSE [priority] END,
          @confTo =confTo,@lFreightInclude=lFreightInclude,@poNote=poNote,@shipChgAMT=shipChgAMT,@is_SCTAX=is_SCTAX, 
          @sc_TaxPct = scTaxPct, @shipCharge=shipCharge,@shipVia =shipVia,@fob =fob               
  FROM @tempTable              
  SET @poDate=GETDATE() SET @status ='New'              
                
  SELECT @existImportId=POImportId,@existCount=COUNT(*) FROM ImportPOMain WHERE poNumber=@poNum GROUP BY POImportId              

  IF @existCount>0              
   SELECT @existImportId AS existingId              
  ELSE              
  BEGIN              
   	/*ImportPOMainAdd*/              
			BEGIN TRY 
			-- inside begin try            
    /* Match existing assembly record */              
    DECLARE @ePOUnique varchar(10)='',@msg varchar(MAX)=''              

    IF(@lFreightInclude='yes' OR @lFreightInclude='1')              
    BEGIN              
     SET @lFreight=1              
    END              
              
    EXEC ImportPOMainAdd @importId,@userInit,NULL,'',@msg,@poNum,@supplier,@terms,@buyer,@priority,@confTo,@poDate,@status,
              @lFreight,@poNote,@shipChgAMT,@is_SCTAX,@sc_TaxPct,@shipCharge,@shipVia,@fob              
   END TRY              
                 
   BEGIN CATCH               
    INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)              
    SELECT ERROR_NUMBER() AS ErrorNumber              
     ,ERROR_SEVERITY() AS ErrorSeverity              
     ,ERROR_PROCEDURE() AS ErrorProcedure              
     ,ERROR_LINE() AS ErrorLine              
     ,ERROR_MESSAGE() AS ErrorMessage;              
    SET @headerErrs = 'There are issues with the header information while trying to load PO Number: '+@poNum              
   END CATCH              
                 
	 /*ImportPODetails*/
   BEGIN TRY -- inside begin try              
    INSERT INTO ImportPODetails (fkPOImportId,fkFieldDefId,RowId,Original,Adjusted)              
     SELECT @importId,fd.FieldDefId,u.rowId,u.adjusted,u.adjusted              
      FROM(              
   --Shiv P: 08/05/2019 When user put the invalid part no and revision in the template and description is empty 
   --then we populating warehouse from inventor and part no rev is invalid then description is null          
       SELECT rowId,itemno,poitType,partNo,revision,ISNULL(descript,'') AS descript ,costEachFc,pur_UOFM
          ,partMfgr,mfgr_Pt_No,isFirm,pur_LTime,pur_LUnit,minOrd,ordMult,firstArticle,inspExcept,inspException              
          ,ord_Qty,costeach,poNum,supName,buyer,priority,confTo,taxable,itemnote,shipChgAMT,is_SCTAX,scTaxPct              
          ,shipCharge,shipVia,fob,inspexnote,taxId ,s_ord_qty FROM @itemsTable
      )p              
       UNPIVOT              
       (adjusted FOR fieldName IN              
        (
         itemno,poitType,partNo,revision,descript,costEachFc,pur_UOFM,partMfgr,mfgr_Pt_No,isFirm,pur_LTime,pur_LUnit,
         minOrd,ordMult,firstArticle,inspExcept,inspException,ord_Qty,costeach,poNum,supName,buyer,priority,confTo,
         taxable,itemnote,shipChgAMT,is_SCTAX,scTaxPct,shipCharge,shipVia,fob,inspexnote,taxId,s_ord_qty           
    )) AS u              
       INNER JOIN ImportFieldDefinitions fd ON fd.fieldName = u.fieldName                
       WHERE fd.ModuleId=@moduleId              
              
   END TRY      
   BEGIN CATCH        
    INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)              

				SELECT ERROR_NUMBER() AS ErrorNumber                    
     ,ERROR_SEVERITY() AS ErrorSeverity              
     ,ERROR_PROCEDURE() AS ErrorProcedure              
     ,ERROR_LINE() AS ErrorLine              
     ,ERROR_MESSAGE() AS ErrorMessage;              
    SET @partErrs = 'There are issues with loading item records.  No additional information available.  Please review the spreadsheet before trying again.'              
   END CATCH                 
  
   /*Schedule details*/              
   BEGIN TRY -- inside begin try              
	INSERT INTO ImportPOSchedule(fkPOImportId,fkFieldDefId,fkRowId,adjusted,original,scheduleRowId)              
     SELECT @importId,fd.FieldDefId,u.rowId,u.adjusted,u.adjusted,scheduleRowId              
      FROM(              
	  -- Satyawan H 06/04/2020 : Added mfgr_pt_No and Part_mfgr in selection and Unpivot
      SELECT p.rowId,p.schdDate,p.origCommitDt,p.schdQty,p.warehouse,p.[location],--,p.mfgr_Pt_No,p.partMfgr,
        p.woPrjNumber,p.requesttp,p.requestor,p.glNbr,p.scheduleRowId              
       FROM @scheduleTable p               
             GROUP BY p.rowId,p.schdDate,p.origCommitDt,p.schdQty,p.warehouse,p.[location],
             p.woPrjNumber,p.requesttp,p.requestor,p.glNbr,p.scheduleRowId--,p.mfgr_Pt_No,p.partMfgr              
      )p              
      UNPIVOT              
      (adjusted FOR fieldName IN              
					(schdDate,origCommitDt,schdQty,warehouse,[location],woPrjNumber,requesttp,requestor,glNbr)--,mfgr_Pt_No,partMfgr)                    
      ) AS u              
      INNER JOIN ImportFieldDefinitions fd ON fd.fieldName = u.fieldName              
      WHERE fd.ModuleId=@moduleId              
	END TRY              
	BEGIN CATCH               
		INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)              
				SELECT ERROR_NUMBER() AS ErrorNumber                    
		 ,ERROR_SEVERITY() AS ErrorSeverity              
		 ,ERROR_PROCEDURE() AS ErrorProcedure              
		 ,ERROR_LINE() AS ErrorLine              
		 ,ERROR_MESSAGE() AS ErrorMessage;              
		SET @avlErrs = 'Unknown Error while importing schedule info.  Please review the values before proceeding.'              
	END CATCH              
                  
	/*Tax details*/              
   BEGIN TRY -- inside begin try              
    INSERT INTO ImportPOTax(fkPOImportId,fkFieldDefId,fkRowId,adjusted,original,TaxRowId)              
     SELECT @importId,fd.FieldDefId,u.rowId,u.adjusted,u.adjusted,newid()TaxRowId              
      FROM(              
      SELECT p.rowId,t.taxId              
					FROM @itemsTable p 
					INNER JOIN @tempTable t ON p.rowNum=t.rowNum                    
       GROUP BY p.rowId,t.taxId              
      )p              
      UNPIVOT              
      (adjusted FOR fieldName IN              
      (taxId)              
      ) AS u              
      INNER JOIN ImportFieldDefinitions fd ON fd.fieldName = u.fieldName              
      WHERE fd.ModuleId=@moduleId              
   END TRY              
   BEGIN CATCH               
    INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)              
				SELECT ERROR_NUMBER() AS ErrorNumber                    
     ,ERROR_SEVERITY() AS ErrorSeverity              
     ,ERROR_PROCEDURE() AS ErrorProcedure              
     ,ERROR_LINE() AS ErrorLine              
     ,ERROR_MESSAGE() AS ErrorMessage;              
    SET @avlErrs = 'Unknown Error while importing schedule info.  Please review the values before proceeding.'              
   END CATCH              
              
   DECLARE @errCnt int = 0              
   SELECT @errCnt=COUNT(*) FROM @ErrTable               
   IF @errCnt>0              
   BEGIN              
    SELECT * FROM @ErrTable              
    ROLLBACK              
				--RETURN -1                      
   END               
  END              
                
  COMMIT              
 END TRY              
 BEGIN CATCH              
  SET @lRollback=1              
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)              
		SELECT ERROR_NUMBER() AS ErrorNumber                    
   ,ERROR_SEVERITY() AS ErrorSeverity              
   ,ERROR_PROCEDURE() AS ErrorProcedure              
   ,ERROR_LINE() AS ErrorLine              
   ,ERROR_MESSAGE() AS ErrorMessage;              
  ROLLBACK              

  BEGIN TRY              
   SELECT DISTINCT @importId,ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg FROM @ErrTable              
  END TRY              
  BEGIN CATCH              
		SELECT ERROR_NUMBER() AS ErrorNumber                    
   ,ERROR_SEVERITY() AS ErrorSeverity              
   ,ERROR_PROCEDURE() AS ErrorProcedure              
   ,ERROR_LINE() AS ErrorLine              
   ,ERROR_MESSAGE() AS ErrorMessage;              
  END CATCH              
  SELECT * FROM @ErrTable              
  SELECT 'Problems uploading file' AS uploadError              
		--RETURN -1                    
 END CATCH   
 --EXEC ImportPOVldtnCheckValues @importId                
END
