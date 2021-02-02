-- ============================================================================================================    
-- Date   : 12/18/2019    
-- Author  : Rajendra K   
-- Description : Used for Validate MTC uploaded data    
-- ValidateMTCData '4B680C27-196D-429A-A605-540B22870E6C'    
-- ============================================================================================================      
CREATE PROC ValidateMTCData    
 @ImportId UNIQUEIDENTIFIER,    
 @RowId UNIQUEIDENTIFIER = NULL    
AS    
BEGIN         
 SET NOCOUNT ON      
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@headerErrs VARCHAR(MAX),@red VARCHAR(20)='i05red';  
 DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))  
 
  DECLARE @LotDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER, LotRowId UNIQUEIDENTIFIER, 
         CssClass VARCHAR(MAX),Validation VARCHAR(MAX),DateCode VARCHAR(MAX),ExpDate VARCHAR(MAX),LotCode VARCHAR(MAX),PoNum VARCHAR(MAX)  
         ,ResQty VARCHAR(MAX))    
           
 DECLARE @MfgrDetails TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER,CssClass VARCHAR(MAX),  
       Validation VARCHAR(MAX),partMfg VARCHAR(MAX), mpn VARCHAR(MAX),Warehouse VARCHAR(MAX),Location VARCHAR(MAX),ResQty VARCHAR(MAX),UNIQ_KEY VARCHAR(MAX),  
       partno VARCHAR(MAX),rev VARCHAR(MAX),custPartNo VARCHAR(MAX),crev VARCHAR(MAX),IsLotted BIT,WorkCenter VARCHAR(MAX),useipkey BIT,SERIALYES BIT)    

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
	    

 SELECT @SQL = N'      
  SELECT importId,AssemblyRowId,CompRowId,AvlRowId,LotRowId,lot.*,DateCode,ExpDate,LotCode,PoNum,ResQty  
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
     
 INSERT INTO @LotDetail EXEC sp_executesql @SQL  
 INSERT INTO @MfgrDetails EXEC GetManufactureUploadData @importId;    

;WITH MTCData AS
	(
		  SELECT importId,AssemblyRowId,CompRowId,AvlRowId,LotRowId,MTCRowId,MTC.*,ResQty,MTC
          FROM    
          (   
	        SELECT DISTINCT fd.FkImportId AS importId,fd.AssemblyRowId,ic.CompRowId,ia.AvlRowId,il.LotRowId,mt.MTCRowId,mt.status ,mt.Message,ibf.fieldName,mt.Adjusted 
	        FROM ImportBOMToKitAssemly fd  
	        	INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
	        	INNER JOIN ImportBOMToKitAvls ia ON ic.CompRowId = ia.FKCompRowId
	        	INNER JOIN ImportBOMToKitMTC mt ON mt.FKAvlRowId = ia.AvlRowId
	        	LEFT JOIN ImportBOMToKitLot il ON il.LotRowId = mt.FkLotRowId
	        	INNER JOIN ImportFieldDefinitions ibf ON mt.FKFieldDefId = ibf.FieldDefId  
	        WHERE fkImportId = @ImportId
	        	AND FieldName IN ('ResQty','MTC') 
	        ) st    
           PIVOT (MAX(Adjusted) FOR fieldName IN ([ResQty],[MTC])  
          ) as PVT
          OUTER APPLY
          (
	        	SELECT MAX(Status) CssClass,MIN(Message) Validation FROM ImportBOMToKitMTC WHERE  MTCRowId = PVT.MTCRowId GROUP BY MTCRowId
          ) AS MTC
	)

  UPDATE mtc
  SET [message] = 
	  CASE  
		WHEN fd.FieldName = 'MTC' THEN 
			CASE WHEN mt.MTC = '' THEN  ''
			     WHEN ISNULL(ipKey.IPKEYUNIQUE,'') = '' THEN  'Please enter valid MTC.' 
			 ELSE '' END
	   ELSE '' END 
    ,[status] = 
	  CASE  
		WHEN fd.FieldName = 'MTC' THEN 
			CASE WHEN mt.MTC = '' THEN  ''
			     WHEN ISNULL(ipKey.IPKEYUNIQUE,'') = '' THEN  'i05red' 
			 ELSE '' END
	   ELSE '' END 
	 --select ipKey.* 
	FROM ImportFieldDefinitions fd
    INNER JOIN ImportBOMToKitMTC mtc ON mtc.FKFieldDefId = fd.FieldDefId AND fd.ModuleId = @ModuleId
	INNER JOIN MTCData mt ON mtc.MTCRowId = mt.MTCRowId
	INNER JOIN @MfgrDetails mf ON mt.AvlRowId = mf.AvlRowId
	LEFT JOIN @LotDetail l ON l.LotRowId = mt.LotRowId
	OUTER APPLY
	(
		 SELECT TOP 1 IP.IPKEYUNIQUE 
	     FROM INVENTOR I 
		 LEFT JOIN PARTTYPE p ON I.PART_CLASS = p.PART_CLASS AND I.PART_TYPE = p.PART_TYPE
	     INNER JOIN INVTMFGR IM ON I.UNIQ_KEY = IM.UNIQ_KEY AND IM.IS_DELETED = 0
	     INNER JOIN InvtMpnLink IML ON IM.UNIQMFGRHD = IML.uniqmfgrhd
	     INNER JOIN MfgrMaster MM ON IML.MfgrMasterId = MM.MfgrMasterId AND MM.PartMfgr = TRIM(mf.partMfg) AND MM.mfgr_pt_no = TRIM(mf.mpn)
	     INNER JOIN WAREHOUS WH ON IM.UNIQWH = WH.UNIQWH
	     LEFT JOIN INVTLOT IL ON IM.W_KEY = IL.W_KEY
	     INNER JOIN IPKEY IP ON I.UNIQ_KEY = IP.UNIQ_KEY 
	       	AND IM.W_KEY = IP.W_KEY
	       	AND COALESCE(IL.LOTCODE,IP.LOTCODE)= IP.LOTCODE
	       	AND ISNULL(IL.REFERENCE,IP.REFERENCE)= IP.REFERENCE
	       	AND ISNULL(IL.PONUM,IP.PONUM)= IP.PONUM
	       	AND 1 =(CASE WHEN IL.LOTCODE IS NULL OR IL.LOTCODE= '' THEN 1 
	       				 WHEN IL.EXPDATE IS NULL OR IL.EXPDATE= '' AND IP.EXPDATE IS NULL OR IP.EXPDATE = '' THEN 1 
	       				 WHEN IL.EXPDATE = IP.EXPDATE THEN 1 ELSE 0 END)
		WHERE IP.IPKEYUNIQUE = TRIM(mt.MTC) AND I.UNIQ_KEY = mf.UNIQ_KEY --AND IP.W_KEY = warehouse.W_KEY 
			 AND IP.LOTCODE = CASE WHEN p.LOTDETAIL = 1 THEN TRIM(l.Lotcode) ELSE '' END
			 AND IP.REFERENCE = CASE WHEN p.LOTDETAIL = 1 THEN TRIM(l.DateCode) ELSE '' END 
			 AND ISNULL(IP.ExpDate,'') = CASE WHEN p.LOTDETAIL = 1 THEN 
			                               (CASE WHEN l.ExpDate IS NOT NUll OR l.ExpDate <>'' 
										         THEN CAST(l.ExpDate AS DATETIME)
												 ELSE ISNULL(l.ExpDate,'') END) 
											ELSE '' END
			 AND IP.PONUM = CASE WHEN p.LOTDETAIL = 1 THEN TRIM(l.Ponum) ELSE '' END  
	  ) AS ipKey

  BEGIN TRY -- inside begin try        
    UPDATE mt        
   SET [message]='Field will be truncated to ' + CAST(f.fieldLength AS VARCHAR(50)) + ' characters.',[status]=@red   
   FROM ImportBOMToKitMTC mt
     INNER JOIN ImportBOMToKitAvls ia ON mt.FKAvlRowId = ia.AvlRowId  
     INNER JOIN ImportBOMToKitComponents iw ON ia.FKCompRowId = iw.CompRowId  
     INNER JOIN ImportBOMToKitAssemly a ON  a.AssemblyRowId = iw.FKAssemblyRowId    
     INNER JOIN ImportFieldDefinitions f  ON mt.FKFieldDefId =f.FieldDefId AND ModuleId = @ModuleId AND f.fieldLength > 0        
    WHERE fkImportId= @ImportId        
     AND LEN(mt.adjusted)>f.fieldLength          
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