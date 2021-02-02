-- ============================================================================================================    
-- Date   : 05/15/2020    
-- Author  : Rajendra K   
-- Description : Used for getting data to create new location
-- GetInvtAdjustData 'D6DB6300-2488-4C06-84DD-F01AC364F771' 
-- ============================================================================================================      
CREATE PROC GetInvtAdjustData  
 @ImportId UNIQUEIDENTIFIER 
AS    
BEGIN    
     
 SET NOCOUNT ON			
  DECLARE @ModuleId INT  
  
  SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_InventoryAdjustmentUpload' and FilePath = 'InventoryAdjustmentUpload'       
  
 ;WITH ImportDetail AS(  
 SELECT PVT.*    
  FROM      
  (     
  SELECT iaf.fkImportId AS importId,iaf.RowId,sub.class as CssClass,sub.Validation,fd.fieldName,adjusted   
  FROM ImportFieldDefinitions fd        
     INNER JOIN ImportInvtAdjustFields iaf ON fd.FieldDefId = iaf.FKFieldDefId   
     INNER JOIN ImportInvtAdjustHeader h ON h.ImportId = iaf.FkImportId      
   INNER JOIN     
   (     
       SELECT fkImportId,fd.RowId,MAX(status) as Class ,MIN(Message) as Validation    
       FROM ImportInvtAdjustFields fd    
    INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
       WHERE fkImportId =CAST(@importId as CHAR(36))  
    AND SheetNo = 1 AND ModuleId = @ModuleId  
       GROUP BY fkImportId,fd.RowId    
    ) Sub      
   ON iaf.fkImportid=Sub.FkImportId and iaf.RowId=sub.RowId     
   WHERE iaf.fkImportId =CAST(@importId as CHAR(36))  
  ) st      
   PIVOT (MAX(adjusted) FOR fieldName IN ([CompanyName],[countQty],[custpartno],[custrev],[ExpDate],[INSTORE],[location],[Lotcode],  
   [mfgr_pt_no],[MTC],[part_no],[part_sourc],[partmfgr],[Ponum],[QtyPerPackage],[Reference],[revision],[SERIALITEMS],[warehouse])     
  ) as PVT  
  )  
    
	--SELECT * from ImportDetail
  SELECT impt.importId   
  ,impt.RowId  
  ,impt.CssClass  
  ,impt.Validation  
  ,CAST(impt.countQty AS NUMERIC(9,2)) AS countQty  
  ,impt.part_sourc  
  ,impt.part_no  
  ,impt.revision  
  ,impt.partmfgr  
  ,impt.mfgr_pt_no  
  ,impt.warehouse  
  ,impt.location  
  ,impt.Lotcode  
  ,impt.Reference  
  ,impt.Ponum  
  ,impt.MTC  
  ,impt.SERIALITEMS  
  ,im.W_KEY  
  ,mpn.UNIQMFGRHD  
  ,I.UNIQ_KEY  
  ,wa.UNIQWH  
  ,I.SERIALYES  
  ,I.useipkey 
  ,ISNULL(sup.UNIQSUPNO ,'') AS UNIQSUPNO
  ,CASE WHEN impt.INSTORE IN ('n','no','0','false') THEN CAST(0 AS BIT)   
        WHEN ISNULL(impt.INSTORE,'') = '' THEN CAST(0 AS BIT)   
     ELSE CAST(1 AS BIT) END AS INSTORE   
  FROM ImportDetail impt  
  INNER JOIN INVENTOR I ON I.PART_NO = impt.part_no AND I.REVISION = impt.revision  AND I.PART_SOURC = ISNULL(TRIM(impt.part_sourc),'')  
  LEFT JOIN INVTMFGR im ON I.UNIQ_KEY = im.UNIQ_KEY AND (im.LOCATION = TRIM(impt.location) OR ISNULL(im.LOCATION,'')= '')
  INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = im.UNIQ_KEY AND im.UNIQMFGRHD = mpn.uniqmfgrhd AND im.IS_DELETED = 0       
  INNER JOIN MfgrMaster mfM  ON mfM.MfgrMasterId = mpn.MfgrMasterId  AND mfM.IS_DELETED = 0    
  LEFT JOIN WAREHOUS wa ON wa.UNIQWH = im.UNIQWH AND wa.WAREHOUSE = TRIM(impt.warehouse)  AND wa.IS_DELETED = 0
  OUTER APPLY  
  (   
   SELECT Custno FROM CUSTOMER WHERE custname = TRIM(impt.CompanyName)  
  ) AS Cust  
  OUTER APPLY  
  (   
   SELECT UNIQSUPNO FROM SUPINFO WHERE SUPNAME = TRIM(impt.CompanyName)  
  ) AS Sup  
  WHERE mfM.mfgr_pt_no = TRIM(impt.mfgr_pt_no) AND mfM.PartMfgr = TRIM(impt.partmfgr)  
  AND I.CUSTNO = CASE WHEN TRIM(impt.part_sourc) = 'CONSG' THEN Cust.CUSTNO ELSE '' END   
  AND I.CUSTPARTNO = CASE WHEN TRIM(impt.part_sourc) = 'CONSG' THEN impt.custpartno ELSE '' END   
  AND I.CUSTREV = CASE WHEN TRIM(impt.part_sourc) = 'CONSG' THEN impt.custrev ELSE '' END    
  AND ISNULL(i.UNIQ_KEY,'') <>'' AND ISNULL(mpn.UNIQMFGRHD,'') <>'' --AND ISNULL(wa.UNIQWH,'') = '' 
  AND mfM.autolocation = 1
END