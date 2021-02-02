-- ============================================================================================================  
-- Date   : 08/23/2019  
-- Author  : Rajendra K 
-- Description : Used for Validate Manufacture uploaded data 
-- 10/03/2019 Rajendra k : Changed the joins 
-- 10/03/2019 Rajendra k : Changed Conditions 
-- 10/23/2019 Rajendra k : Added impt.mpn <> '' Condition if mpn is not empty
-- 10/25/2019 Rajendra k : Added 1=1 Condition if mpn is empty
-- 11/02/2019 Rajendra k : Changed Condition if both mpn and partmfgr are empty
-- 12/16/2019 Rajendra k : Added condition for partmfgr validation
-- ValidateManufactureUploadData 'A7D1484C-2614-448D-995E-763AEAEF1E4C' 
-- ====================================================================================================o========    
CREATE PROC ValidateManufactureUploadData  
 @ImportId UNIQUEIDENTIFIER,  
 @AvlRowId UNIQUEIDENTIFIER = NULL  
AS  
BEGIN  
   
 SET NOCOUNT ON    
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@headerErrs VARCHAR(MAX),@red VARCHAR(20)='i05red';
 DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))      
  
 DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER,
							  CssClass VARCHAR(MAX),Validation VARCHAR(MAX),Location VARCHAR(MAX),mpn VARCHAR(MAX),partMfg VARCHAR(MAX),ResQty VARCHAR(MAX)
							  ,Warehouse VARCHAR(MAX))  
							  
 DECLARE @ComoponentsDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,CssClass VARCHAR(MAX),Validation VARCHAR(MAX),itemno NUMERIC
							,partSource  VARCHAR(MAX),partno  VARCHAR(MAX),rev  VARCHAR(MAX),custPartNo  VARCHAR(MAX),crev  VARCHAR(MAX),qty NUMERIC,bomNote  VARCHAR(MAX)
							,workCenter VARCHAR(MAX),used BIT,UNIQ_KEY VARCHAR(MAX),PART_CLASS VARCHAR(MAX),PART_TYPE VARCHAR(MAX),U_OF_MEAS VARCHAR(100),IsLotted BIT,useipkey BIT,SERIALYES BIT) 

 -- Insert statements for procedure here 
SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_BOMtoKITUpload' and FilePath = 'BOMtoKITUpload'   
 SELECT @FieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId  AND FieldName in ('Location','mpn','partMfg','ResQty','Warehouse')  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')     
  --10/03/2019 Rajendra k : Changed the joins 
 SELECT @SQL = N'    
  SELECT importId,AssemblyRowId,CompRowId,AvlRowId,Avls.*,Location,mpn,partMfg,ResQty,Warehouse
  FROM    
  (   
	SELECT aa.fkImportId AS importId,aa.AssemblyRowId,c.CompRowId,ia.AvlRowId,ia.Status,ia.Message,fd.fieldName,ia.Adjusted 
	   FROM ImportFieldDefinitions fd 
		INNER JOIN ImportBOMToKitAvls ia ON fd.FieldDefId = ia.FKFieldDefId
		INNER JOIN ImportBOMToKitComponents c ON ia.FKCompRowId = c.CompRowId
		INNER JOIN ImportBOMToKitAssemly aa ON c.FKAssemblyRowId = aa.AssemblyRowId
	WHERE fkImportId = '''+ CAST(@ImportId as CHAR(36))+'''
		AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+') 
	) st    
   PIVOT (MAX(Adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')    
  ) as PVT
  OUTER APPLY
  (
		SELECT MAX(Status) CssClass,MIN(Message) Validation FROM ImportBOMToKitAvls where AvlRowId = PVT.AvlRowId GROUP BY AvlRowId
  ) AS Avls'
   
 --Print @SQL  
 INSERT INTO @ImportDetail EXEC sp_executesql @SQL
 INSERT INTO @ComoponentsDetail EXEC GetComponentsData @importId     
 --SELECT * FROM @ImportDetail  
 --SELECT * FROM @ComoponentsDetail  
   
 UPDATE ia  
 SET [message] =  
-- --select impt.partno, invt.PART_NO,
 CASE 
  WHEN  ifd.FieldName = 'mpn' THEN   
       CASE WHEN (impt.mpn = '')  THEN ''-- 10/23/2019 Rajendra k : Added impt.mpn <> '' Condition if mpn is not empty
			WHEN ((TRIM(impt.mpn) <> manufact.mfgr_pt_no) AND manufact.delManufact = 1  AND impt.mpn <> '') THEN 'Please enter valid non-deleted manufacturer part no.' 
		    WHEN (((TRIM(impt.mpn) <> manufact.mfgr_pt_no) OR manufact.mfgr_pt_no IS NULL) AND impt.mpn <> '')  THEN 'Please enter valid manufacturer part no.' 			
			ELSE '' END 

  WHEN  ifd.FieldName = 'partMfg' THEN   
       CASE WHEN (ISNULL(impt.partMfg,'') = '' AND ISNULL(impt.partMfg,'') <> '')  THEN 'Please enter manufacturer.'-- 11/02/2019 Rajendra k : Changed Condition if both mpn and partmfgr are empty
			WHEN ((TRIM(impt.partMfg) <> manufact.partmfgr) AND manufact.delManufact = 1) THEN 'Please enter valid non-deleted manufacturer.' 
		    WHEN ((TRIM(impt.partMfg) <> manufact.partmfgr) OR manufact.partmfgr IS NULL AND ISNULL(impt.partMfg,'') = '' AND ISNULL(impt.partMfg,'') <> '') THEN 'Please enter valid manufacturer.' 
			WHEN ((TRIM(impt.partMfg) <> manufact.partmfgr) OR manufact.partmfgr IS NULL AND  ISNULL(impt.partMfg,'') <> '') THEN 'Please enter valid manufacturer.' 						
			ELSE '' END -- 12/16/2019 Rajendra k : Added condition for partmfgr validation

  WHEN  ifd.FieldName = 'Warehouse' THEN   
       CASE WHEN (impt.Warehouse = '')  THEN ''
			WHEN ((TRIM(impt.Warehouse) <> invt.Warehouse) AND invt.delWare = 1) THEN 'Please enter valid non-deleted Warehouse.' 
		    WHEN ((TRIM(impt.Warehouse) <> invt.Warehouse) OR invt.Warehouse IS NULL) THEN 'Please enter valid Warehouse.' 			
			ELSE '' END 

  WHEN  ifd.FieldName = 'Location' THEN   
       CASE WHEN (impt.Location = '')  THEN ''
			WHEN ((TRIM(impt.Location) <> invt.Location) AND invt.delLoc = 1) THEN 'Please enter valid non-deleted Location.' 
		    WHEN ((TRIM(impt.Location) <> invt.Location) OR invt.Location IS NULL) THEN 'Please enter valid Location.' 			
			ELSE '' END 

  WHEN ifd.FieldName = 'ResQty' THEN 
		CASE WHEN (ISNUMERIC(impt.ResQty) = 1) THEN ''
		ELSE 'Reserve Quantity must be numeric value.' END																						
ELSE '' END 

,[status] = 
CASE 
  WHEN  ifd.FieldName = 'mpn' THEN   
       CASE WHEN (impt.mpn = '')  THEN ''-- 10/23/2019 Rajendra k : Added impt.mpn <> '' Condition if mpn is not empty
			WHEN ((TRIM(impt.mpn) <> manufact.mfgr_pt_no) AND manufact.delManufact = 1  AND impt.mpn <> '') THEN 'i05red' 
		    WHEN (((TRIM(impt.mpn) <> manufact.mfgr_pt_no) OR manufact.mfgr_pt_no IS NULL) AND impt.mpn <> '') THEN 'i05red' 			
			ELSE '' END 

  WHEN  ifd.FieldName = 'partMfg' THEN   
       CASE WHEN (ISNULL(impt.partMfg,'') = '' AND ISNULL(impt.partMfg,'') <> '')  THEN 'i05red'-- 11/02/2019 Rajendra k : Changed Condition if both mpn and partmfgr are empty
			WHEN ((TRIM(impt.partMfg) <> manufact.partmfgr) AND manufact.delManufact = 1) THEN 'i05red' 
		    WHEN ((TRIM(impt.partMfg) <> manufact.partmfgr) OR manufact.partmfgr IS NULL AND ISNULL(impt.partMfg,'') = '' AND ISNULL(impt.partMfg,'') <> '') THEN 'i05red' 	
			WHEN ((TRIM(impt.partMfg) <> manufact.partmfgr) OR manufact.partmfgr IS NULL AND  ISNULL(impt.partMfg,'') <> '') THEN 'i05red' 			
			ELSE '' END -- 12/16/2019 Rajendra k : Added condition for partmfgr validation

  WHEN  ifd.FieldName = 'Warehouse' THEN   
       CASE WHEN (impt.Warehouse = '')  THEN ''
			WHEN ((TRIM(impt.Warehouse) <> invt.Warehouse) AND invt.delWare = 1) THEN 'i05red' 
		    WHEN ((TRIM(impt.Warehouse) <> invt.Warehouse) OR invt.Warehouse IS NULL) THEN 'i05red' 			
			ELSE '' END 

  WHEN  ifd.FieldName = 'Location' THEN   
       CASE WHEN (impt.Location = '')  THEN ''
			WHEN ((TRIM(impt.Location) <> invt.Location) AND invt.delLoc = 1) THEN 'i05red' 
		    WHEN ((TRIM(impt.Location) <> invt.Location) OR invt.Location IS NULL) THEN 'i05red' 			
			ELSE '' END 

  WHEN ifd.FieldName = 'ResQty' THEN 
		CASE WHEN (ISNUMERIC(impt.ResQty) = 1) THEN ''
		ELSE 'i05red' END													
ELSE '' END 

  FROM ImportBOMToKitAvls ia 
	  INNER JOIN ImportFieldDefinitions ifd  ON ia.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId
	 -- INNER JOIN ImportBOMToKitHeader h  ON h.ImportId = @ImportId 
	  INNER JOIN @ImportDetail impt ON ia.AvlRowId = impt.AvlRowId
	  INNER JOIN @ComoponentsDetail c ON ia.FKCompRowId = c.CompRowId
	  OUTER APPLY
	  (
			SELECT TOP 1 i.UNIQ_KEY,uniqmfgrhd,PartMfgr,mfgr_pt_no,mp.is_deleted AS delManufact
			FROM INVENTOR I 
				JOIN InvtMPNLink mp ON i.UNIQ_KEY = mp.uniq_key
				JOIN MfgrMaster mster ON mp.MfgrMasterId  = mster.MfgrMasterId-- 10/25/2019 Rajendra k : Added 1=1 Condition if mpn is empty 
			WHERE mster.PartMfgr = TRIM(impt.partMfg) AND (mster.mfgr_pt_no = TRIM(impt.mpn) OR (1=1 AND impt.mpn = '')) AND (I.UNIQ_KEY =  c.UNIQ_KEY OR  (TRIM(PART_NO) = TRIM(c.partno) 
				 AND TRIM(REVISION) = TRIM(c.rev) AND TRIM(c.custPartNo) = TRIM(CUSTPARTNO)))  
	  )manufact
	  OUTER APPLY 
	  (
			SELECT i.UNIQ_KEY,im.UNIQMFGRHD,im.IS_DELETED AS delLoc,w.IS_DELETED AS delWare,LOCATION,WAREHOUSE
			FROM INVENTOR i 
				JOIN INVTMFGR im ON i.UNIQ_KEY = im.UNIQ_KEY
				JOIN WAREHOUS w ON im.UNIQWH = w.UNIQWH-- 10/03/2019 Rajendra k : Changed Conditions
			WHERE manufact.UNIQ_KEY = i.UNIQ_KEY AND im.UNIQMFGRHD = manufact.uniqmfgrhd--(I.UNIQ_KEY = c.UNIQ_KEY OR  (TRIM(PART_NO) = TRIM(c.partno) AND TRIM(REVISION) = TRIM(c.rev) AND TRIM(c.custPartNo) = TRIM(CUSTPARTNO))) 
				AND ((w.WAREHOUSE IS NULL AND w.WAREHOUSE = '') OR w.WAREHOUSE = TRIM(impt.Warehouse)) AND (im.LOCATION = TRIM(impt.Location)) 
	  ) invt  
	WHERE (@AvlRowId = ia.AvlRowId OR @AvlRowId IS NULL)  	
	   	 
-- Check length of string entered by user in template
	BEGIN TRY -- inside begin try      
	  UPDATE ia      
		SET [message]='Field will be truncated to ' + CAST(f.fieldLength AS VARCHAR(50)) + ' characters.',[status]=@red 
		FROM ImportBOMToKitAvls ia 
			INNER JOIN ImportBOMToKitComponents iw ON ia.FKCompRowId = iw.CompRowId
			INNER JOIN ImportBOMToKitAssemly a ON  a.AssemblyRowId = iw.FKAssemblyRowId	 
			INNER JOIN ImportFieldDefinitions f  ON ia.FKFieldDefId =f.FieldDefId AND ModuleId = @ModuleId AND f.fieldLength > 0      
		WHERE fkImportId= @ImportId      
				AND LEN(ia.adjusted)>f.fieldLength        
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