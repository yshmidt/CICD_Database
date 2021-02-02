-- ============================================================================================================    
-- Date   : 08/23/2019    
-- Author  : Rajendra K   
-- Description : Used for Validate Manufacture uploaded data    
-- 10/03/2019 Rajendra k : Changed the joins   
-- 10/03/2019 Rajendra k : Changed the validation conditions  
-- 10/14/2019 Rajendra k : Changed Messages  
-- 10/16/2019 Rajendra k : Changed Messages.  
-- 10/23/2019 Rajendra k : Added condition if lot details fields are empty  
-- 10/25/2019 Rajendra k : Added Ponum field  
-- 11/05/2019 Rajendra k : Added condition partMfg <>''   
-- 12/26/2019 Rajendra k : Added useipkey and serialyes in @MfgrDetails table
-- 12/30/2019 Rajendra k : Changed the validation for lotcode field if it is empty then do not give error
-- ValidateLotDetails '4B680C27-196D-429A-A605-540B22870E6C'    
-- ============================================================================================================      
CREATE PROC ValidateLotDetails    
 @ImportId UNIQUEIDENTIFIER,    
 @RowId UNIQUEIDENTIFIER = NULL    
AS    
BEGIN    
     
 SET NOCOUNT ON      
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@headerErrs VARCHAR(MAX),@red VARCHAR(20)='i05red';  
 DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))        
    
 DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER,  
         CssClass VARCHAR(MAX),Validation VARCHAR(MAX),DateCode VARCHAR(MAX),ExpDate VARCHAR(MAX),LotCode VARCHAR(MAX),PoNum VARCHAR(MAX)  
         ,ResQty VARCHAR(MAX))    
           
 DECLARE @MfgrDetails TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER,CssClass VARCHAR(MAX),  
       Validation VARCHAR(MAX),partMfg VARCHAR(MAX), mpn VARCHAR(MAX),Warehouse VARCHAR(MAX),Location VARCHAR(MAX),ResQty VARCHAR(MAX),UNIQ_KEY VARCHAR(MAX),  
       partno VARCHAR(MAX),rev VARCHAR(MAX),custPartNo VARCHAR(MAX),crev VARCHAR(MAX),IsLotted BIT,WorkCenter VARCHAR(MAX),useipkey BIT,SERIALYES BIT)            
  -- 12/26/2019 Rajendra k  : Added useipkey and serialyes in @MfgrDetails table
  
 -- Insert statements for procedure here   
 SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_BOMtoKITUpload' and FilePath = 'BOMtoKITUpload'    
 SELECT @FieldName = STUFF(      
      (      
       SELECT  ',[' +  F.FIELDNAME + ']' FROM     
       ImportFieldDefinitions F        
       WHERE ModuleId = @ModuleId  AND FieldName IN ('DateCode','ExpDate','LotCode','PoNum','ResQty')     
       ORDER BY F.FIELDNAME     
       FOR XML PATH('')      
      ),      
      1,1,'')       
  -- 10/03/2019 Rajendra k : Changed the joins   
 SELECT @SQL = N'      
  SELECT importId,AssemblyRowId,CompRowId,AvlRowId,lot.*,DateCode,ExpDate,LotCode,PoNum,ResQty  
  FROM      
  (     
 SELECT DISTINCT fd.FkImportId AS importId,fd.AssemblyRowId,ic.CompRowId,ia.AvlRowId,il.LotRowId,il.status ,il.Message,ibf.fieldName,il.Adjusted   
 FROM ImportBOMToKitAssemly fd    
  INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId  
  INNER JOIN ImportBOMToKitAvls ia ON ic.CompRowId = ia.FKCompRowId  
  INNER JOIN ImportBOMToKitLot il ON ia.AvlRowId = il.FKAvlRowId  
  INNER JOIN ImportFieldDefinitions ibf ON il.FKFieldDefId = ibf.FieldDefId    
 WHERE fkImportId = '''+ CAST(@ImportId as CHAR(36))+'''  
  AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')   
 ) st      
   PIVOT (MAX(Adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')    
  ) as PVT  
  OUTER APPLY  
  (  
  SELECT MAX(Status) CssClass,MIN(Message) Validation FROM ImportBOMToKitLot where  LotRowId = PVT.LotRowId GROUP BY LotRowId  
  ) AS lot'  
     
 --Print @SQL    
 INSERT INTO @ImportDetail EXEC sp_executesql @SQL     
 INSERT INTO @MfgrDetails EXEC GetManufactureUploadData @importId;  
-- SELECT * FROM @ImportDetail    
--SELECT * FROM @MfgrDetails   
  
IF EXISTS(SELECT 1 FROM @ImportDetail)  
BEGIN  
  UPDATE il  -- 10/03/2019 Rajendra k : Changed the validation conditions  
  SET [message] =    
 --select impt.ResQty, mfgr.IsLotted,  
  CASE   
   WHEN  ifd.FieldName = 'LotCode' THEN  -- 12/30/2019 Rajendra k : Changed the validation for lotcode field if it is empty then do not give error  
     CASE --WHEN (impt.LotCode = '' AND mfgr.IsLotted = 1)  THEN 'Please enter Lotcode.'-- 10/16/2019 Rajendra k : Changed Messages.  
		  WHEN (impt.LotCode <> '' AND mfgr.IsLotted = 1 AND ((TRIM(impt.LotCode) <> lotDet.LotCode) OR lotDet.LotCode IS NULL) AND ISNULL(mfgr.partMfg,'') <>'')   
		  THEN 'Please enter valid Lotcode,Expiration Date, Reference, Ponum combination for given warehouse and location.' ELSE '' END -- 11/05/2019 Rajendra k : Added condition partMfg <>''   
     
  WHEN ifd.FieldName = 'ResQty' THEN   
    CASE WHEN (ISNUMERIC(impt.ResQty) != 1 AND impt.ResQty <= 0 AND mfgr.IsLotted = 1) THEN 'Reserve quantity must be greater than zero.'  
      ELSE '' END  
     
   WHEN  ifd.FieldName = 'DateCode' THEN     
     CASE WHEN (impt.DateCode = '')  THEN ''  
    WHEN ((TRIM(impt.DateCode) <> lotDet.REFERENCE) OR lotDet.REFERENCE IS NULL) AND mfgr.IsLotted = 1 AND ISNULL(mfgr.partMfg,'') <>'' THEN 'Please enter valid Lotcode,Expiration Date, Reference, Ponum combination for given warehouse and location.'
	 ELSE '' END   
     
   WHEN ifd.FieldName = 'ExpDate' THEN  
     CASE WHEN (impt.ExpDate = '' OR impt.ExpDate IS NULL) AND mfgr.IsLotted = 1 THEN ''  
    WHEN ((ISDATE(impt.ExpDate) != 1) OR lotDet.EXPDATE IS NULL) AND mfgr.IsLotted = 1  AND ISNULL(mfgr.partMfg,'') <>'' THEN 'Please enter valid Lotcode,Expiration Date, Reference, Ponum combination for given warehouse and location.'
	 -- 10/14/2019 Rajendra k : Changed Messages      
    ELSE '' END  
     
   WHEN  ifd.FieldName = 'PoNum' THEN   -- 10/25/2019 Rajendra k : Added Ponum field  
     CASE WHEN (impt.PoNum = '')  THEN ''  
    WHEN ((TRIM(impt.PoNum) <> lotDet.PONUM) OR impt.PoNum IS NULL) AND mfgr.IsLotted = 1  AND ISNULL(mfgr.partMfg,'') <>'' THEN 'Please enter valid Lotcode,Expiration Date, Reference, Ponum combination for given warehouse and location.' ELSE '' END      
                      
 ELSE '' END   
  
 ,[status] =   
  CASE   
     WHEN  ifd.FieldName = 'LotCode' THEN  -- 12/30/2019 Rajendra k : Changed the validation for lotcode field if it is empty then do not give error   
     CASE --WHEN (impt.LotCode = '' AND mfgr.IsLotted = 1)  THEN 'i05red'  
		  WHEN (impt.LotCode <> '' AND mfgr.IsLotted = 1 AND ((TRIM(impt.LotCode) <> lotDet.LotCode) OR lotDet.LotCode IS NULL) AND ISNULL(mfgr.partMfg,'') <>'')   
          THEN 'i05red' ELSE '' END -- 11/05/2019 Rajendra k : Added condition partMfg <>''   
     
  WHEN ifd.FieldName = 'ResQty' THEN   
    CASE WHEN (ISNUMERIC(impt.ResQty) != 1 AND impt.ResQty <= 0 AND mfgr.IsLotted = 1) THEN 'i05red'  
      ELSE '' END  
     
   WHEN  ifd.FieldName = 'DateCode' THEN     
     CASE WHEN (impt.DateCode = '')  THEN ''  
    WHEN ((TRIM(impt.DateCode) <> lotDet.REFERENCE) OR lotDet.REFERENCE IS NULL) AND mfgr.IsLotted = 1 AND ISNULL(mfgr.partMfg,'') <>'' THEN 'i05red' ELSE '' END   
     
   WHEN ifd.FieldName = 'ExpDate' THEN  
     CASE WHEN (impt.ExpDate = '' OR impt.ExpDate IS NULL) AND mfgr.IsLotted = 1 THEN ''  
    WHEN ((ISDATE(impt.ExpDate) != 1) OR lotDet.EXPDATE IS NULL) AND mfgr.IsLotted = 1 AND ISNULL(mfgr.partMfg,'') <>'' THEN 'i05red'      
    ELSE '' END  
     
   WHEN  ifd.FieldName = 'PoNum' THEN   -- 10/25/2019 Rajendra k : Added Ponum field  
     CASE WHEN (impt.PoNum = '')  THEN ''  
    WHEN ((TRIM(impt.PoNum) <> lotDet.PONUM) OR impt.PoNum IS NULL) AND mfgr.IsLotted = 1  AND ISNULL(mfgr.partMfg,'') <>'' THEN 'i05red' ELSE '' END                            
 ELSE '' END   
--select lotDet.*  
 FROM  ImportBOMToKitLot il   
    INNER JOIN ImportFieldDefinitions ifd  ON il.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId  
   -- INNER JOIN ImportBOMToKitHeader h  ON h.ImportId  = @ImportId  
    INNER JOIN @ImportDetail impt ON il.FKAvlRowId = impt.AvlRowId-- 10/03/2019 Rajendra k : Changed the joins   
    INNER JOIN @MfgrDetails mfgr ON impt.AvlRowId = mfgr.AvlRowId  
    OUTER APPLY  
    (  
    SELECT TOP 1 mfgr_pt_no,PartMfgr,imfgr.IS_DELETED AS DeletedLocation,w.IS_DELETED AS DeletedWarehouse,mfMaster.is_deleted AS DeletedManufact,  
        WAREHOUSE,LOCATION,i.UNIQ_KEY,QTY_OH,LOTCODE,EXPDATE,PONUM,REFERENCE  
    FROM INVENTOR i  
      INNER JOIN InvtMPNLink mpn on i.UNIQ_KEY = mpn.uniq_key  
      INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId      
      INNER JOIN INVTMFGR imfgr ON  imfgr.UNIQMFGRHD = mpn.uniqmfgrhd  
      INNER JOIN INVTLOT il ON imfgr.W_KEY = il.W_KEY  
      INNER JOIN  WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH    
    WHERE TRIM(mfMaster.PartMfgr) = TRIM(mfgr.partMfg)   
      AND (TRIM(mfMaster.mfgr_pt_no) = TRIM(mfgr.mpn) OR (1=1 AND mfgr.mpn = ''))  
      AND imfgr.IS_DELETED = 0   
      AND mfMaster.is_deleted = 0   
      AND (TRIM(LOCATION) = TRIM(mfgr.Location) OR (1=1 AND mfgr.Location = ''))  
      AND (TRIM(w.WAREHOUSE) = TRIM(mfgr.Warehouse) OR (1=1 AND mfgr.Warehouse = ''))-- 10/23/2019 Rajendra k : Added condition if lot details fields are empty  
      AND (i.UNIQ_KEY = mfgr.UNIQ_KEY  
      OR (TRIM(PART_NO) = TRIM(mfgr.partno)   
      AND TRIM(REVISION) = TRIM(mfgr.rev)  
      AND TRIM(CUSTPARTNO) = TRIM(mfgr.custPartNo)  
      AND TRIM( CUSTREV) =  TRIM(mfgr.crev)))  
      AND (TRIM(impt.LotCode) =  TRIM(il.LOTCODE) OR (1=1 AND impt.LotCode = ''))  
      AND (CASE WHEN impt.ExpDate IS NOT NUll OR impt.ExpDate <>''   
         THEN CAST(impt.ExpDate AS DATETIME)   
         ELSE ISNULL(impt.ExpDate,'') END = ISNULL(il.ExpDate,'') OR (1=1 AND (impt.ExpDate = ''OR impt.ExpDate IS NULL)))  
      AND (ISNULL(impt.DateCode,'') = IL.REFERENCE OR (1=1 AND (impt.DateCode = '' OR impt.DateCode IS NULL)))  
      AND (ISNULL(impt.PoNum,'') = IL.PONUM OR (1=1 AND (impt.PoNum = ''OR impt.PoNum IS NULL)))  
    ) lotDet  
  
  --Check length of string entered by user in template  
  BEGIN TRY -- inside begin try        
    UPDATE il        
   SET [message]='Field will be truncated to ' + CAST(f.fieldLength AS VARCHAR(50)) + ' characters.',[status]=@red   
   FROM ImportBOMToKitLot il  
     INNER JOIN ImportBOMToKitAvls ia ON il.FKAvlRowId = ia.AvlRowId  
     INNER JOIN ImportBOMToKitComponents iw ON ia.FKCompRowId = iw.CompRowId  
     INNER JOIN ImportBOMToKitAssemly a ON  a.AssemblyRowId = iw.FKAssemblyRowId    
     INNER JOIN ImportFieldDefinitions f  ON il.FKFieldDefId =f.FieldDefId AND ModuleId = @ModuleId AND f.fieldLength > 0        
    WHERE fkImportId= @ImportId        
     AND LEN(il.adjusted)>f.fieldLength          
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
END  