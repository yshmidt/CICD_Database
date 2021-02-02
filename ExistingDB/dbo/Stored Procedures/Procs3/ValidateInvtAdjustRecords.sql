-- ============================================================================================================    
-- Date   : 11/21/2019    
-- Author  : Rajendra K   
-- Description : Used for Validate  data   
-- 05/28/2020 Rajendra k : Added instore condition
-- 06/12/2020 Rajendra k : Added condition if lot details not exists and countQty = 0
-- 06/15/2020 Rajendra k : Added casting for the CountQty in condition
-- ValidateInvtAdjustRecords '338557AA-13D9-4FDF-B854-E12B060C9E57'      
-- ============================================================================================================      
CREATE PROC ValidateInvtAdjustRecords    
 @ImportId UNIQUEIDENTIFIER    
 --@RowId UNIQUEIDENTIFIER =NULL    
AS    
BEGIN    
     
 SET NOCOUNT ON     
  DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@headerErrs VARCHAR(MAX)  
  DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))    
  DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(MAX),Validation VARCHAR(MAX), CompanyName VARCHAR(MAX),  
         countQty VARCHAR(MAX),custpartno VARCHAR(MAX),custrev VARCHAR(MAX),ExpDate VARCHAR(MAX),INSTORE VARCHAR(MAX),location VARCHAR(MAX),Lotcode VARCHAR(MAX),  
         mfgr_pt_no VARCHAR(MAX) ,MTC VARCHAR(MAX),part_no VARCHAR(MAX),part_sourc VARCHAR(MAX),partmfgr VARCHAR(MAX),Ponum VARCHAR(MAX),  
         QtyPerPackage VARCHAR(MAX),Reference VARCHAR(MAX),revision VARCHAR(MAX),SERIALITEMS VARCHAR(MAX),warehouse VARCHAR(MAX))     
  
          -- Insert statements for procedure here     
SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_InventoryAdjustmentUpload' and FilePath = 'InventoryAdjustmentUpload'    
   
SELECT @FieldName = STUFF(      
      (      
     SELECT  ',[' +  F.FIELDNAME + ']' FROM     
     ImportFieldDefinitions F        
     WHERE ModuleId = @ModuleId AND F.SheetNo = 1  
     ORDER BY F.FIELDNAME     
     FOR XML PATH('')      
      ),      
      1,1,'')    
  
  
  
 SELECT @SQL = N'      
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
      WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''     
   AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')    
      GROUP BY fkImportId,fd.RowId      
    ) Sub      
   ON iaf.fkImportid=Sub.FkImportId and iaf.RowId=sub.RowId     
   WHERE iaf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''       
  ) st      
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')     
  ) as PVT'    
  
  --EXEC sp_executesql @SQL   
  INSERT INTO @ImportDetail EXEC sp_executesql @SQL    
  --SELECT * FROM @ImportDetail    
  
  SELECT Invt.*,impt.RowId INTO #partData FROM @ImportDetail impt  
  OUTER APPLY  
  (   
  SELECT Custno FROM CUSTOMER WHERE custname = TRIM(impt.CompanyName)  
  ) AS Cust  
  OUTER APPLY  
  (  
     SELECT TOP 1 SERIALYES,useipkey,UNIQ_KEY,PART_NO,I.U_OF_MEAS,PART_SOURC,CUSTNO,CUSTPARTNO,MAKE_BUY,CUSTREV,REVISION,ISNULL(P.LOTDETAIL,CAST(0 AS BIT)) AS IsLotted   
  FROM INVENTOR I  
  LEFT JOIN  PARTTYPE p ON p.PART_TYPE = I.PART_TYPE AND p.PART_CLASS = I.PART_CLASS    
  WHERE PART_NO = impt.part_no AND REVISION = impt.revision  --AND PART_SOURC = ISNULL(TRIM(impt.part_sourc),'')  
  AND CUSTNO = CASE WHEN TRIM(impt.part_sourc) = 'CONSG' THEN Cust.CUSTNO ELSE '' END   
  AND CUSTPARTNO = CASE WHEN TRIM(impt.part_sourc) = 'CONSG' THEN impt.custpartno ELSE '' END   
  AND CUSTREV = CASE WHEN TRIM(impt.part_sourc) = 'CONSG' THEN impt.custrev ELSE '' END   
  ) AS Invt  
  
/****** Used to validate Column Data ******/        
 BEGIN TRY    
 UPDATE iaf    
 SET [message] =   
   CASE             
   WHEN  fd.FieldName = 'custpartno' THEN   
  CASE WHEN impt.part_sourc = 'CONSG' AND impt.custpartno = '' THEN  'Please enter Customer Part no.'  
    WHEN impt.part_sourc = 'CONSG' AND ISNULL(Invt.CUSTPARTNO,'') = '' THEN  'Please enter valid customer Part No.'  
    ELSE '' END  
  
   WHEN  fd.FieldName = 'custrev' THEN   
  CASE WHEN impt.part_sourc = 'CONSG' AND impt.custrev = '' THEN  ''  
    WHEN impt.part_sourc = 'CONSG' AND ISNULL(Invt.CUSTREV,'') = '' THEN  'Please enter valid customer Revision.'  
    ELSE '' END  
  
   WHEN  fd.FieldName = 'CompanyName' THEN   
  CASE WHEN impt.part_sourc = 'CONSG' AND impt.CompanyName = '' THEN  'Please enter Company name.'  
       WHEN TRIM(impt.INSTORE) IN ('1','true','yes','y') AND impt.CompanyName = '' THEN  'Please enter Company name.'  
    WHEN TRIM(impt.INSTORE) IN ('1','true','yes','y') AND impt.CompanyName <> '' AND ISNULL(Sup.SUPNAME,'') = '' THEN  'Please enter valid Company name.'  
    ELSE '' END  
  
   WHEN  fd.FieldName = 'part_no' THEN   
  CASE WHEN impt.part_no = '' THEN  'Please enter Part no.'  
    WHEN ISNULL(Invt.PART_NO,'') = '' THEN  'Please enter valid Part No.'   
    ELSE '' END  
  
   WHEN  fd.FieldName = 'revision' THEN   
  CASE WHEN impt.revision = '' THEN  ''  
    WHEN ISNULL(Invt.REVISION,'') = '' THEN  'Please enter valid Revision.'   
    ELSE '' END  
  
   WHEN  fd.FieldName = 'partmfgr' THEN   
  CASE WHEN impt.partmfgr = '' THEN  'Please enter manufacturer.'  
    WHEN ((TRIM(impt.partmfgr) <> manufact.partmfgr) AND manufact.delManufact = 1) THEN 'Please enter valid non-deleted manufacturer.'   
       WHEN  manufact.partmfgr IS NULL AND ISNULL(impt.partmfgr,'') <> '' THEN 'Please enter valid manufacturer.'    
    ELSE '' END  
  
   WHEN  fd.FieldName = 'mfgr_pt_no' THEN   
  CASE WHEN impt.mfgr_pt_no = '' AND impt.partmfgr = '' THEN  'Please enter valid manufacturer part no.'  
    WHEN  (manufact.mfgr_pt_no IS NULL OR (TRIM(impt.mfgr_pt_no) <> manufact.mfgr_pt_no))  THEN 'Please enter valid manufacturer part no.'    
    ELSE '' END  
  
  WHEN  fd.FieldName = 'warehouse' THEN     
       CASE WHEN (impt.warehouse = '')  THEN 'Please enter Warehouse.'  
   WHEN ((TRIM(impt.warehouse) <> warehouse.Warehouse) AND warehouse.delWare = 1) THEN 'Please enter valid non-deleted Warehouse.'   
      WHEN ((TRIM(impt.warehouse) <> warehouse.Warehouse) OR warehouse.Warehouse IS NULL) THEN 'Please enter valid Warehouse.'      
   ELSE '' END   
  
  WHEN  fd.FieldName = 'location' THEN     
       CASE WHEN (impt.location = '')  THEN ''  
   WHEN ((TRIM(impt.location) <> warehouse.Location) AND warehouse.delLoc = 1) THEN 'Please enter valid non-deleted Location.'   
      WHEN ((TRIM(impt.location) <> warehouse.Location) OR warehouse.Location IS NULL) THEN 'Please enter valid Location.'      
   ELSE '' END   
  
  WHEN fd.FieldName = 'countQty' THEN   
     CASE WHEN (ISNUMERIC(impt.countQty) = 1) THEN  -- 06/15/2020 Rajendra k : Added casting for the CountQty in condition   
   CASE WHEN Invt.IsLotted = 0 AND Invt.useipkey = 0 AND ((CAST(impt.countQty AS NUMERIC(9,2))  <= 0 AND mfgrQty.Qty_Oh = 0 AND mfgrQty.MTCRes = 1) OR CAST(impt.countQty AS NUMERIC(9,2)) = mfgrQty.Qty_Oh)    
      THEN 'Not able to adjust the reserved parts or available qty is same as countqty'  
     WHEN Invt.IsLotted = 1 AND Invt.useipkey = 0 AND ((CAST(impt.countQty AS NUMERIC(9,2))  <= 0 AND lotQty.Qty_Oh = 0 AND lotQty.lotQty = 1) OR CAST(impt.countQty AS NUMERIC(9,2)) = lotQty.Qty_Oh)    
      THEN 'Not able to adjust the reserved parts or available qty is same as countqty'  
     WHEN Invt.useipkey = 1 AND ((CAST(impt.countQty AS NUMERIC(9,2))  <= 0 AND ipKey.Qty_Oh = 0 AND ipKey.MTCRes = 1 ) OR CAST(impt.countQty AS NUMERIC(9,2)) = ipKey.Qty_Oh )    
     THEN 'Not able to adjust the reserved parts or available qty is same as countqty'  
     ELSE '' END   
       ELSE 'Count quantity must be Numeric.' END  
  
  WHEN fd.FieldName = 'QtyPerPackage' AND Invt.useipkey = 1 THEN   
     CASE WHEN (ISNUMERIC(impt.QtyPerPackage) = 1) THEN ''  
       ELSE 'Count quantity must be Numeric.' END  
  
  WHEN fd.FieldName = 'INSTORE' THEN  
    CASE  
     WHEN (TRIM(impt.INSTORE)<>'' AND TRIM(impt.INSTORE) IS NOT NULL)  
    THEN CASE   
     WHEN  TRIM(impt.INSTORE) NOT IN ('1','0','true','false','yes','no','y','n')  
      THEN'Entered the invalid data into INSTORE.Values can be ( Y OR N ,YES OR NO ,True or False ,1 OR 0)'  
     ELSE '' END  
    ELSE '' END   
  
   WHEN  fd.FieldName = 'MTC' THEN   
  CASE WHEN impt.MTC = '' THEN  ''  
    WHEN ISNULL(ipKey.IPKEYUNIQUE,'') = '' THEN  'Please enter valid MTC.'   
    ELSE '' END  
  
   WHEN  fd.FieldName = 'Lotcode' THEN   
  CASE WHEN ISNULL(impt.Lotcode,'') = '' AND Invt.IsLotted = 1 THEN  'Please enter Lotcode.'  -- 06/12/2020 Rajendra k : Added condition if lot details not exists and countQty = 0
     WHEN Invt.IsLotted = 1 AND Invt.useipkey = 0 AND ((CAST(impt.countQty AS NUMERIC(9,2))  <= 0 AND lotQty.Qty_Oh IS NULL))  
      THEN 'cannot find a match to a lotcode/expdate/reference/ponum in the database.'  
    ELSE '' END  
  
   WHEN  fd.FieldName = 'part_sourc' THEN   
  CASE WHEN ISNULL(impt.part_sourc,'') <> '' AND impt.part_sourc <> Invt.PART_SOURC THEN 'Please enter Valid part sourc.'  
    ELSE '' END  
  
  WHEN  fd.FieldName = 'SERIALITEMS'  THEN        
        CASE WHEN (Invt.SERIALYES = 1) AND (SerialNoCnt.SerialNo < 1  OR impt.countQty != SerialNoCnt.SerialNo) THEN  'The CountQty and Serial number count does not match'         
             WHEN (Invt.SERIALYES = 0) AND SerialNoCnt.SerialNo > 0 THEN  'NO Serial No have to be entered.'        
             ELSE '' END   
  
   ELSE '' END   
     
 ,[status] =     
  CASE     
   WHEN  fd.FieldName = 'custpartno' THEN   
  CASE WHEN impt.part_sourc = 'CONSG' AND impt.custpartno = '' THEN  'i05red'  
    WHEN impt.part_sourc = 'CONSG' AND ISNULL(Invt.CUSTPARTNO,'') = '' THEN  'i05red'   
    ELSE '' END  
  
   WHEN  fd.FieldName = 'custrev' THEN   
  CASE WHEN impt.part_sourc = 'CONSG' AND impt.custrev = '' THEN  ''  
    WHEN impt.part_sourc = 'CONSG' AND ISNULL(Invt.CUSTREV,'') = '' THEN  'i05red'  
    ELSE '' END  
  
   WHEN  fd.FieldName = 'CompanyName' THEN   
  CASE WHEN impt.part_sourc = 'CONSG' AND impt.CompanyName = '' THEN  'i05red'  
    WHEN TRIM(impt.INSTORE) IN ('1','true','yes','y') AND impt.CompanyName = '' THEN  'i05red'  
    WHEN TRIM(impt.INSTORE) IN ('1','true','yes','y') AND impt.CompanyName <> '' AND ISNULL(Sup.SUPNAME,'') = '' THEN  'i05red'  
    ELSE '' END  
  
   WHEN  fd.FieldName = 'part_no' THEN   
  CASE WHEN impt.part_no = '' THEN  'i05red'  
    WHEN ISNULL(Invt.PART_NO,'') = '' THEN  'i05red'   
    ELSE '' END  
  
   WHEN  fd.FieldName = 'revision' THEN   
  CASE WHEN impt.revision = '' THEN  ''  
    WHEN ISNULL(Invt.REVISION,'') = '' THEN  'i05red'   
    ELSE '' END  
  
   WHEN  fd.FieldName = 'partmfgr' THEN   
  CASE WHEN impt.mfgr_pt_no = '' AND impt.partmfgr = '' THEN  'i05red'  
    WHEN ((TRIM(impt.partmfgr) <> manufact.partmfgr) AND manufact.delManufact = 1) THEN 'i05red'  
       WHEN  manufact.partmfgr IS NULL AND ISNULL(impt.partmfgr,'') <> '' THEN 'i05red'  
    ELSE '' END  
  
   WHEN  fd.FieldName = 'mfgr_pt_no' THEN   
  CASE WHEN impt.mfgr_pt_no = '' THEN  ''  
    WHEN  (manufact.mfgr_pt_no IS NULL OR (TRIM(impt.mfgr_pt_no) <> manufact.mfgr_pt_no))  THEN 'i05red'     
    ELSE '' END  
  
  WHEN  fd.FieldName = 'warehouse' THEN     
       CASE WHEN (impt.warehouse = '')  THEN 'i05red'  
   WHEN ((TRIM(impt.warehouse) <> warehouse.Warehouse) AND warehouse.delWare = 1) THEN 'i05red'   
      WHEN ((TRIM(impt.warehouse) <> warehouse.Warehouse) OR warehouse.Warehouse IS NULL) THEN 'i05red'      
   ELSE '' END   
  
  WHEN  fd.FieldName = 'location' THEN     
       CASE WHEN (impt.location = '')  THEN ''  
   WHEN ((TRIM(impt.location) <> warehouse.Location) AND warehouse.delLoc = 1) THEN 'i05red'    
      WHEN ((TRIM(impt.location) <> warehouse.Location) OR warehouse.Location IS NULL) THEN 'i05red'       
   ELSE '' END   
  
  WHEN fd.FieldName = 'countQty' THEN   
     CASE WHEN (ISNUMERIC(impt.countQty) = 1) THEN  -- 06/15/2020 Rajendra k : Added casting for the CountQty in condition   
      CASE WHEN Invt.IsLotted = 0 AND Invt.useipkey = 0 AND ((CAST(impt.countQty AS NUMERIC(9,2)) <= 0 AND mfgrQty.Qty_Oh = 0 AND mfgrQty.MTCRes = 1) OR CAST(impt.countQty AS NUMERIC(9,2)) = mfgrQty.Qty_Oh)    
      THEN 'i05red'  
     WHEN Invt.IsLotted = 1 AND Invt.useipkey = 0 AND ((CAST(impt.countQty AS NUMERIC(9,2)) <= 0 AND lotQty.Qty_Oh = 0 AND lotQty.lotQty = 1) OR CAST(impt.countQty AS NUMERIC(9,2)) = lotQty.Qty_Oh)    
      THEN 'i05red' 
     WHEN Invt.useipkey = 1 AND ((CAST(impt.countQty AS NUMERIC(9,2)) <= 0 AND ipKey.Qty_Oh = 0 AND ipKey.MTCRes = 1 ) OR CAST(impt.countQty AS NUMERIC(9,2)) = ipKey.Qty_Oh )    
     THEN 'i05red'  
     ELSE '' END   
       ELSE 'i05red' END  
  
  WHEN fd.FieldName = 'QtyPerPackage' AND Invt.useipkey = 1 THEN   
     CASE WHEN (ISNUMERIC(impt.QtyPerPackage) = 1) THEN ''  
       ELSE 'i05red' END  
  
  WHEN fd.FieldName = 'INSTORE' THEN  
    CASE  
     WHEN (TRIM(impt.INSTORE)<>'' AND TRIM(impt.INSTORE) IS NOT NULL)  
    THEN CASE   
     WHEN  TRIM(impt.INSTORE) NOT IN ('1','0','true','false','yes','no','y','n')  
      THEN 'i05red'  
     ELSE '' END  
    ELSE '' END   
  
   WHEN  fd.FieldName = 'MTC' THEN   
  CASE WHEN impt.MTC = '' THEN  ''  
    WHEN ISNULL(ipKey.IPKEYUNIQUE,'') = '' THEN  'i05red'   
    ELSE '' END  
  
   WHEN  fd.FieldName = 'Lotcode' THEN   
  CASE WHEN ISNULL(impt.Lotcode,'') = '' AND Invt.IsLotted = 1 THEN  'i05red'   -- 06/12/2020 Rajendra k : Added condition if lot details not exists and countQty = 0
     WHEN Invt.IsLotted = 1 AND Invt.useipkey = 0 AND ((CAST(impt.countQty AS NUMERIC(9,2))  <= 0 AND lotQty.Qty_Oh IS NULL))  
      THEN 'i05red'  
    ELSE '' END  
  
   WHEN  fd.FieldName = 'part_sourc' THEN   
  CASE WHEN ISNULL(impt.part_sourc,'') <> '' AND impt.part_sourc <> Invt.PART_SOURC THEN  'i05red'    
    ELSE '' END  
  
  WHEN  fd.FieldName = 'SERIALITEMS'  THEN        
        CASE WHEN (Invt.SERIALYES = 1) AND (SerialNoCnt.SerialNo < 1  OR impt.countQty != SerialNoCnt.SerialNo) THEN  'i05red'         
             WHEN (Invt.SERIALYES = 0) AND SerialNoCnt.SerialNo > 0 THEN  'i05red'        
             ELSE '' END   
  
   ELSE '' END  
 --select *   
  FROM ImportFieldDefinitions fd        
  INNER JOIN ImportInvtAdjustFields iaf ON fd.FieldDefId = iaf.FKFieldDefId AND UploadType = 'InventoryAdjustmentUpload'   
  LEFT JOIN @ImportDetail impt on iaf.RowId=impt.RowId  AND fd.ModuleId = @ModuleId  
  OUTER APPLY  
  (   
  SELECT * FROM #partData WHERE impt.RowId = RowId  
  ) AS Invt  
   OUTER APPLY  
 (  
      SELECT TOP 1 i.UNIQ_KEY,uniqmfgrhd,PartMfgr,mfgr_pt_no,mp.is_deleted AS delManufact  
      FROM INVENTOR I   
      JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key  
      JOIN MfgrMaster mster ON mp.MfgrMasterId = mster.MfgrMasterId  
      WHERE mster.PartMfgr = TRIM(impt.partmfgr) AND mster.mfgr_pt_no = TRIM(impt.mfgr_pt_no) AND i.UNIQ_KEY = Invt.UNIQ_KEY  
 )manufact  
 OUTER APPLY   
 (  
  SELECT i.UNIQ_KEY,im.UNIQMFGRHD,im.IS_DELETED AS delLoc,w.IS_DELETED AS delWare,LOCATION,WAREHOUSE,im.W_KEY  
  FROM INVENTOR i   
  JOIN INVTMFGR im ON i.UNIQ_KEY = im.UNIQ_KEY  
  JOIN WAREHOUS w ON im.UNIQWH = w.UNIQWH  
  WHERE i.UNIQ_KEY = Invt.UNIQ_KEY AND im.UNIQMFGRHD = manufact.uniqmfgrhd AND w.WAREHOUSE = TRIM(impt.warehouse) 
  AND im.LOCATION = TRIM(impt.location) AND im.instore = impt.instore -- 05/28/2020 Rajendra k : Added instore condition
 ) warehouse    
 OUTER APPLY  
 (  
  SELECT (QTY_OH - Reserved) AS Qty_Oh,CASE WHEN Reserved > 0 THEN 1 ELSE 0 END AS MTCRes   
  FROM INVTMFGR  
   WHERE W_KEY = warehouse.W_KEY  
 )AS mfgrQty  
 OUTER APPLY  
 (  
  SELECT (LotQty - LotResQty) AS Qty_Oh,CASE WHEN LotResQty > 0 THEN 1 ELSE 0 END AS lotQty   
  FROM INVTLOT  
   WHERE W_KEY = warehouse.W_KEY AND LOTCODE = CASE WHEN Invt.IsLotted = 1 THEN TRIM(impt.Lotcode) ELSE '' END  
    AND REFERENCE = CASE WHEN Invt.IsLotted = 1 THEN TRIM(impt.Reference) ELSE '' END   
    AND ISNULL(ExpDate,'') = CASE WHEN Invt.IsLotted = 1 THEN   
                                  (CASE WHEN impt.ExpDate IS NOT NUll OR impt.ExpDate <>''   
                   THEN CAST(impt.ExpDate AS DATETIME)  
             ELSE ISNULL(impt.ExpDate,'') END)   
           ELSE '' END  
    AND PONUM = CASE WHEN Invt.IsLotted = 1 THEN TRIM(impt.Ponum) ELSE '' END    
 )AS lotQty  
 OUTER APPLY  
 (  
  SELECT SUPNAME   
  FROM INVTMFGR im   
  INNER JOIN SUPINFO s ON im.uniqsupno = s.UNIQSUPNO   
  INNER JOIN WAREHOUS w ON im.UNIQWH = w.UNIQWH  
  WHERE UNIQ_KEY = Invt.UNIQ_KEY AND SUPNAME = TRIM(impt.CompanyName)  
        AND im.UNIQMFGRHD = manufact.uniqmfgrhd AND w.WAREHOUSE = TRIM(impt.warehouse) AND im.LOCATION = TRIM(impt.location)  
 ) Sup  
 OUTER APPLY  
 (  
   SELECT IP.IPKEYUNIQUE,IP.PkgBalance - IP.qtyAllocatedTotal AS Qty_Oh, CASE WHEN IP.qtyAllocatedTotal > 0 THEN 1 ELSE 0 END AS MTCRes  
      FROM INVENTOR I   
      INNER JOIN INVTMFGR IM ON I.UNIQ_KEY = IM.UNIQ_KEY AND IM.IS_DELETED = 0  
      INNER JOIN InvtMpnLink IML ON IM.UNIQMFGRHD = IML.uniqmfgrhd  
      INNER JOIN MfgrMaster MM ON IML.MfgrMasterId = MM.MfgrMasterId  
      INNER JOIN WAREHOUS WH ON IM.UNIQWH = WH.UNIQWH  
      LEFT JOIN INVTLOT IL ON IM.W_KEY = IL.W_KEY  
      LEFT JOIN IPKEY IP ON I.UNIQ_KEY = IP.UNIQ_KEY   
         AND IM.W_KEY = IP.W_KEY  
         AND COALESCE(IL.LOTCODE,IP.LOTCODE)= IP.LOTCODE  
         AND ISNULL(IL.REFERENCE,IP.REFERENCE)= IP.REFERENCE  
         AND ISNULL(IL.PONUM,IP.PONUM)= IP.PONUM  
         AND 1 =(CASE WHEN IL.LOTCODE IS NULL OR IL.LOTCODE= '' THEN 1   
             WHEN IL.EXPDATE IS NULL OR IL.EXPDATE= '' AND IP.EXPDATE IS NULL OR IP.EXPDATE = '' THEN 1   
             WHEN IL.EXPDATE = IP.EXPDATE THEN 1 ELSE 0 END)  
  WHERE IP.IPKEYUNIQUE = impt.MTC AND I.UNIQ_KEY = Invt.UNIQ_KEY AND IP.W_KEY = warehouse.W_KEY   
    AND IP.LOTCODE = CASE WHEN Invt.IsLotted = 1 THEN TRIM(impt.Lotcode) ELSE '' END  
    AND IP.REFERENCE = CASE WHEN Invt.IsLotted = 1 THEN TRIM(impt.Reference) ELSE '' END   
    AND ISNULL(IP.ExpDate,'') = CASE WHEN Invt.IsLotted = 1 THEN   
                                  (CASE WHEN impt.ExpDate IS NOT NUll OR impt.ExpDate <>''   
                   THEN CAST(impt.ExpDate AS DATETIME)  
             ELSE ISNULL(impt.ExpDate,'') END)   
           ELSE '' END  
    AND IP.PONUM = CASE WHEN Invt.IsLotted = 1 THEN TRIM(impt.Ponum) ELSE '' END    
 )ipKey  
 OUTER APPLY   
    (  
   SELECT COUNT(SerialDetailId) SerialNo   
   FROM ImportInvtAdjustSerialFields isf  
   JOIN importFieldDefinitions ON FkFieldDefId=FieldDefId WHERE isf.FkRowId= iaf.RowId         
   AND importFieldDefinitions.FIELDNAME ='Serialno'        
    ) SerialNoCnt    
 WHERE iaf.FkImportId = @importId  
  END TRY        
  BEGIN CATCH         
   INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)        
   SELECT        
    ERROR_NUMBER() AS ErrorNumber        
    ,ERROR_SEVERITY() AS ErrorSeverity        
    ,ERROR_PROCEDURE() AS ErrorProcedure        
    ,ERROR_LINE() AS ErrorLine        
    ,ERROR_MESSAGE() AS ErrorMessage;        
   SET @headerErrs = 'There are issues validating the non-string fields.'        
   SELECT * FROM @ErrTable        
  END CATCH     
  
  BEGIN TRY  
 ;WITH SerialData AS (  
   SELECT DISTINCT invt.RowId,f.Adjusted,f.SerialDetailId,f.SerialRowId  
   FROM ImportInvtAdjustSerialFields f  
   JOIN importFieldDefinitions ON f.FkFieldDefId = importFieldDefinitions.FieldDefId  
   JOIN ImportInvtAdjustFields invt ON  invt.RowId =  f.FkRowId  
   WHERE FkImportId = @ImportId AND FieldName = 'Serialno'  
 )  
  UPDATE f   
  SET f.[original] =  
 CASE WHEN  fd.FieldName = 'Serialno' THEN    
   CASE WHEN  LEN (f.[original]) !=30 AND  f.[original]   <>''  
       THEN  RIGHT(REPLICATE('0', 30) + LTRIM(f.Original), 30)   
    ELSE f.Original  END  
  ELSE f.Original END     
  
  ,f.[Adjusted] =   
 CASE WHEN  fd.FieldName = 'Serialno' THEN    
   CASE WHEN  LEN (f.[Adjusted]) !=30 AND  f.[Adjusted]   <>''  
       THEN  RIGHT(REPLICATE('0', 30) + LTRIM(f.Adjusted), 30)   
    ELSE f.Adjusted  END  
  ELSE f.Adjusted END    
          
  ,f.[Message]=   
  CASE WHEN  fd.FieldName = 'Serialno' THEN   
   CASE WHEN invt.Adjusted = ''  THEN  'Please enter serial number.'  
     WHEN ISNULL(DupSerial.Adjusted,'') <> '' THEN 'Serial No could not be same.'  
     WHEN ISNULL(invtSerdup.SERIALUNIQ,'') <> '' THEN 'Serial number already exists in the system. Can not add it again.'  
     WHEN ISNULL(invtSer.SERIALUNIQ,'') <> '' THEN 'Serial number already exists in the system. Can not add it again.'  
     WHEN invtSerCount.SerCnt > 1 THEN 'Serial number already exists in the system.  Can not add it again.'  
     ELSE '' END  
  ELSE '' END      
  ,f.[Status]=   
  CASE WHEN  fd.FieldName = 'Serialno' THEN   
   CASE WHEN invt.Adjusted = '' THEN  'i05red'  
     WHEN ISNULL(DupSerial.Adjusted,'') <> '' THEN 'i05red'  
     WHEN ISNULL(invtSerdup.SERIALUNIQ,'') <> '' THEN 'i05red'  
     WHEN ISNULL(invtSer.SERIALUNIQ,'') <> '' THEN 'i05red'  
     WHEN invtSerCount.SerCnt > 1 THEN 'i05red'  
     ELSE '' END  
  ELSE '' END   
 --select invt.Adjusted,DupSerial.*,invtSer.*,invtSerCount.*,invtSerdup.*  
     FROM  ImportInvtAdjustSerialFields f   
  INNER JOIN ImportFieldDefinitions fd ON fd.FieldDefId = f.FKFieldDefId AND UploadType = 'InventoryAdjustmentUpload'   
  INNER JOIN @ImportDetail impt ON impt.RowId = f.FkRowId  
  INNER JOIN SerialData invt ON  invt.SerialDetailId= f.SerialDetailId  
  OUTER APPLY  
  (   
  SELECT UNIQ_KEY,SERIALYES,PART_SOURC,MAKE_BUY FROM #partData WHERE impt.RowId = RowId  
  ) AS InvtPart  
  OUTER APPLY  
  (  
      SELECT TOP 1 i.UNIQ_KEY,uniqmfgrhd,PartMfgr,mfgr_pt_no,mp.is_deleted AS delManufact  
      FROM INVENTOR I   
      INNER JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key  
      INNER JOIN MfgrMaster mster ON mp.MfgrMasterId = mster.MfgrMasterId  
      WHERE mster.PartMfgr = TRIM(impt.partmfgr) AND mster.mfgr_pt_no = TRIM(impt.mfgr_pt_no) AND i.UNIQ_KEY = InvtPart.UNIQ_KEY  
  )manufact  
     OUTER APPLY   
  (  
    SELECT TOP 1 SERIALUNIQ   
    FROM INVTSER   
    WHERE SERIALNO =RIGHT(REPLICATE('0', 30) + LTRIM(f.Adjusted), 30) AND UNIQ_KEY != InvtPart.UNIQ_KEY  
    AND (UNIQMFGRHD = CASE WHEN (InvtPart.PART_SOURC <> 'MAKE' OR MAKE_BUY = 0) THEN manufact.uniqmfgrhd ELSE '' END OR (InvtPart.PART_SOURC <> 'MAKE' OR MAKE_BUY = 1))  
  ) invtSer  
  OUTER APPLY   
  (  
    SELECT TOP 1 SERIALUNIQ   
    FROM INVTSER   
    WHERE SERIALNO =RIGHT(REPLICATE('0', 30) + LTRIM(f.Adjusted), 30) AND UNIQ_KEY = InvtPart.UNIQ_KEY  
    AND (UNIQMFGRHD = CASE WHEN (InvtPart.PART_SOURC <> 'MAKE' OR MAKE_BUY = 0) THEN manufact.uniqmfgrhd ELSE '' END OR (InvtPart.PART_SOURC <> 'MAKE' OR MAKE_BUY = 1))  
  ) invtSerdup  
  OUTER APPLY   
  (  
    SELECT COUNT(SERIALUNIQ) AS SerCnt FROM INVTSER WHERE SERIALNO =RIGHT(REPLICATE('0', 30) + LTRIM(f.Adjusted), 30) AND UNIQ_KEY = InvtPart.UNIQ_KEY  
    AND (UNIQMFGRHD = CASE WHEN (InvtPart.PART_SOURC <> 'MAKE' OR MAKE_BUY = 0) THEN manufact.uniqmfgrhd ELSE '' END OR (InvtPart.PART_SOURC <> 'MAKE' OR MAKE_BUY = 1))  
  ) invtSerCount  
  OUTER APPLY  
  (  
  SELECT Adjusted FROM SerialData WHERE Adjusted = RIGHT(REPLICATE('0', 30) + LTRIM(invt.Adjusted), 30) AND SerialRowId <> invt.SerialRowId AND invt.RowId = RowId  
  )AS DupSerial  
      END TRY  
  BEGIN CATCH   
   INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)  
   SELECT  
    ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_PROCEDURE() AS ErrorProcedure  
    ,ERROR_LINE() AS ErrorLine  
    ,ERROR_MESSAGE() AS ErrorMessage;  
   SET @headerErrs = 'There are issues validating the non-string fields.'  
  END CATCH   
   
 BEGIN TRY -- inside begin try        
  UPDATE f        
   SET [message]='Field will be truncated to ' + CAST(fd.fieldLength AS varchar(50)) + ' characters.',[status]='i05red'  
   FROM ImportInvtAdjustFields f         
   INNER JOIN importFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength > 0        
   WHERE fkImportId=@importId  AND fd.ModuleId = @ModuleId  
   AND LEN(f.adjusted) > fd.fieldLength          
 END TRY        
 BEGIN CATCH         
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)        
  SELECT       
   ERROR_NUMBER() AS ErrorNumber        
   ,ERROR_SEVERITY() AS ErrorSeverity        
   ,ERROR_PROCEDURE() AS ErrorProcedure        
   ,ERROR_LINE() AS ErrorLine        
   ,ERROR_MESSAGE() AS ErrorMessage;        
  SET @headerErrs = 'There are issues in the fields to be truncated.'        
 END CATCH   
  
 --To check length of field for serial fields  
 BEGIN TRY   
 UPDATE f  
  SET [message]='Field will be truncated to ' + CAST(fd.fieldLength AS VARCHAR(50)) + ' characters.'  
     ,[status]='i05red'  
  FROM  ImportInvtAdjustSerialFields f JOIN  ImportInvtFields  ON FkRowId = ImportInvtFields.RowId  
  INNER JOIN importFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength>0  
  WHERE  fkImportId = @importId AND fd.ModuleId = @ModuleId  
  AND LEN(f.adjusted) > fd.fieldLength    
 END TRY  
 BEGIN CATCH   
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)  
  SELECT  
   ERROR_NUMBER() AS ErrorNumber  
   ,ERROR_SEVERITY() AS ErrorSeverity  
   ,ERROR_PROCEDURE() AS ErrorProcedure  
   ,ERROR_LINE() AS ErrorLine  
   ,ERROR_MESSAGE() AS ErrorMessage;  
  SET @headerErrs = 'There are issues in the fields to be truncated.'  
 END CATCH  
END