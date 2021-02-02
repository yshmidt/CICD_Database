-- ============================================================================================================  
-- Date   : 08/23/2019  
-- Author  : Rajendra K 
-- Description : Used for Validate Components uploaded data  
-- 09/30/2019 Rajendar K : Changed custpartno condition for "CONSG" Part
-- 10/09/2019 Rajendar K : Added condition for Itemno to update error
-- ValidateComponentsRecords 'DA328B29-D9E6-4611-BB5B-92F6B1600E41'
-- ============================================================================================================    
CREATE PROC ValidateComponentsRecords  
 @ImportId UNIQUEIDENTIFIER  
 --@RowId UNIQUEIDENTIFIER =NULL  
AS  
BEGIN  
   
 SET NOCOUNT ON    
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@headerErrs VARCHAR(MAX),@red VARCHAR(20)='i05red'
 DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))      
  
 DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,CssClass VARCHAR(MAX),Validation VARCHAR(MAX),
							  bomNote VARCHAR(MAX),crev VARCHAR(MAX),custPartNo VARCHAR(MAX),itemno VARCHAR(MAX),partno VARCHAR(MAX),partSource VARCHAR(MAX),qty VARCHAR(MAX),
							  rev VARCHAR(MAX) ,used VARCHAR(MAX),workCenter VARCHAR(MAX))   

  DECLARE @Bom Table (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),assyDesc VARCHAR(100)
							 ,assyNum VARCHAR(100),assypartclass VARCHAR(100),assyparttype VARCHAR(100),assyRev VARCHAR(100),custno VARCHAR(100),UNIQ_KEY VARCHAR(10));

 INSERT INTO @Bom EXEC GetAssemblyRecords @importId
 -- Insert statements for procedure here   
 SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_BOMtoKITUpload' and FilePath = 'BOMtoKITUpload'     
 SELECT @FieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId  AND FieldName in ('bomNote','crev','custPartNo','itemno','partno','partSource','qty','rev','used','workCenter')  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')     
  
 SELECT @SQL = N'    
  SELECT PVT.*  
  FROM    
  (   
   SELECT Sub.fkImportId AS importId,Sub.AssemblyRowId,Sub.CompRowId,sub.class as CssClass,sub.Validation,fd.fieldName,ic.Adjusted 
   FROM ImportFieldDefinitions fd      
	 INNER JOIN ImportBOMToKitComponents ic ON fd.FieldDefId = ic.FKFieldDefId
     '--INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId
    -- INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId     
	 +'INNER JOIN   
	   (   
			SELECT fkImportId,AssemblyRowId,CompRowId,MAX(ic.status) as Class ,MIN(ic.Message) as Validation		
			FROM ImportBOMToKitAssemly fd  
				INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
				INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId   
			WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''   
				AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')  
			GROUP BY fkImportId,CompRowId,AssemblyRowId
	   ) Sub    
   ON ic.CompRowId = sub.CompRowId    
   WHERE Sub.fkImportId ='''+ CAST(@importId as CHAR(36))+'''     
  ) st    
   PIVOT (MAX(Adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')   
  ) as PVT 
  ORDER BY [itemno]'  
   
 --Print @SQL  
 INSERT INTO @ImportDetail EXEC sp_executesql @SQL     
 --SELECT * FROM @ImportDetail  
   
 UPDATE ic  
 SET [message] =  
 --select impt.partno,Item.partno, invt.PART_NO,ifd.FieldName,invt.PART_NO,Item.workCenter,Item.itemno,impt.itemno,ic.Message,
 CASE 
  WHEN  ifd.FieldName = 'partno' THEN
       CASE WHEN (impt.partno = '')  THEN 'Please enter Part no.'
			WHEN (impt.partSource = 'CONSG' AND cust.BOMCUSTNO IS NOT NULL AND invt.custno IS NULL) THEN 'Cannot add consg part as the Assembly does not have Customer.'
		    WHEN ((TRIM(impt.partno) <> invt.PART_NO) OR invt.PART_NO IS NULL) THEN 'Please enter valid Part no.' 
			WHEN ((TRIM(impt.partno) = invt.PART_NO) AND invt.STATUS <> 'Active') THEN 'Please enter valid Active Part no.'
			WHEN (assem.partno is NOT null ) Then 'Assembly can not be part of bill of material.'
		    WHEN (TRIM(impt.partno) = invt.PART_NO AND TRIM(impt.partno) = TRIM(Item.partno) AND TRIM(item.workCenter) = TRIM(impt.workCenter) AND TRIM(impt.rev) = '') 
				THEN 'Part no/Rev already exists in '+impt.workCenter+' work center' 
			ELSE '' END

   WHEN  ifd.FieldName = 'rev' THEN   
       CASE WHEN (impt.rev = '')  THEN ''
		    WHEN ((TRIM(impt.rev) <> invt.REVISION) OR invt.REVISION IS NULL)  THEN 'Please enter valid Rev.' 
			ELSE 
			 CASE WHEN impt.partno = Item.partno AND impt.rev = Item.rev  AND item.workCenter = impt.workCenter 
					THEN 'Part no/Rev already exists in '+impt.workCenter+ 'work center'
				  ELSE '' END
			END 
			 
   WHEN  ifd.FieldName = 'custPartNo' THEN   
       CASE WHEN (impt.custPartNo = '' AND impt.partSource = 'CONSG')  THEN 'Please enter Cust Part no.'
		    WHEN ((TRIM(impt.custPartNo) <> invt.custPartNo) OR invt.custPartNo IS NULL) AND impt.partSource = 'CONSG' THEN 'Please enter valid customer PartNo.' ELSE '' END

   WHEN  ifd.FieldName = 'crev' THEN   
       CASE WHEN (impt.crev = '' AND impt.partSource = 'CONSG')  THEN ''
		    WHEN ((TRIM(impt.crev) <> invt.CUSTREV) OR invt.CUSTREV IS NULL) AND impt.partSource = 'CONSG' THEN 'Please enter valid customer Rev.' ELSE '' END
			 
   WHEN  ifd.FieldName = 'partSource' THEN   
       CASE WHEN (impt.partSource = '')  THEN ''
		    WHEN (((TRIM(impt.partSource) <> invt.PART_SOURC) OR invt.PART_SOURC IS NULL) AND impt.partSource  NOT IN ('BUY','CONSG','MAKE','PHANTOM')) THEN 'Please enter valid part source.' ELSE '' END

   WHEN  ifd.FieldName = 'workCenter' THEN   
       CASE WHEN (impt.workCenter = '')  THEN ''
		    WHEN ((TRIM(impt.workCenter) <> WoCenter.DEPT_ID) OR WoCenter.DEPT_ID IS NULL)  THEN 'Please enter valid work center.' ELSE '' END   
			
	WHEN ifd.FieldName = 'used' THEN
		CASE
			WHEN (TRIM(impt.used)<>'' AND TRIM(impt.used) IS NOT NULL)
				THEN CASE 
					WHEN  TRIM(impt.used) NOT IN ('1','0','true','false','yes','no','y','n')
						THEN'Entered the invalid data into used.Values can be ( Y OR N ,YES OR NO ,True or False ,1 OR 0)'
					ELSE '' END
				ELSE '' END		
				
	WHEN ifd.FieldName = 'itemno' THEN 
	CASE WHEN impt.itemno <> '' AND impt.itemno IS NOT NULL 
		 THEN 
				CASE WHEN (ISNUMERIC(impt.itemno) = 1 AND CAST(impt.itemno AS NUMERIC(4,0)) > 0) THEN 
					CASE WHEN impt.itemno  = Item.itemno
							THEN 'Item Number already exists. Please provide different item no.' 
						 ELSE '' END
				ELSE 'Item number must be greater than zero.' END	
		ELSE '' END
		
	WHEN ifd.FieldName = 'qty' THEN 
		CASE WHEN (ISNUMERIC(impt.qty) = 1) THEN ''
		ELSE 'Quantity must be numeric value.' END																
ELSE '' END 

,[status] = 
CASE 
  WHEN  ifd.FieldName = 'partno' THEN   
       CASE WHEN (impt.partno = '')  THEN 'i05red'
			WHEN (impt.partSource = 'CONSG' AND cust.BOMCUSTNO IS NOT NULL AND invt.custno IS NULL) THEN 'i05red'
		    WHEN ((TRIM(impt.partno) <> invt.PART_NO) OR invt.PART_NO IS NULL) THEN 'i05red' 
			WHEN ((TRIM(impt.partno) = invt.PART_NO) AND invt.STATUS <> 'Active') THEN 'i05red'
			WHEN (assem.partno is NOT null ) Then 'i05red'
		    WHEN (TRIM(impt.partno) = invt.PART_NO AND TRIM(impt.partno) = TRIM(Item.partno) AND TRIM(item.workCenter) = TRIM(impt.workCenter) AND TRIM(impt.rev) = '') 
				THEN 'i05red' 
			ELSE '' END

   WHEN  ifd.FieldName = 'rev' THEN   
       CASE WHEN (impt.rev = '')  THEN ''
		    WHEN ((TRIM(impt.rev) <> invt.REVISION) OR invt.REVISION IS NULL)  THEN 'i05red' 
			ELSE 
			 CASE WHEN impt.partno = Item.partno AND impt.rev = Item.rev  AND item.workCenter = impt.workCenter 
					THEN 'i05red'
				  ELSE '' END
			END 			 
			 
   WHEN  ifd.FieldName = 'custPartNo' THEN   
       CASE WHEN (impt.custPartNo = '' AND impt.partSource = 'CONSG')  THEN 'i05red'
		    WHEN ((TRIM(impt.custPartNo) <> invt.custPartNo) OR invt.custPartNo IS NULL) AND impt.partSource = 'CONSG' THEN 'i05red' ELSE '' END

   WHEN  ifd.FieldName = 'crev' THEN   
       CASE WHEN (impt.crev = '' AND impt.partSource = 'CONSG')  THEN ''
		    WHEN ((TRIM(impt.crev) <> invt.CUSTREV) OR invt.CUSTREV IS NULL) AND impt.partSource = 'CONSG' THEN 'i05red.' ELSE '' END
			 
   WHEN  ifd.FieldName = 'partSource' THEN   
       CASE WHEN (impt.partSource = '')  THEN ''
		    WHEN (((TRIM(impt.partSource) <> invt.PART_SOURC) OR invt.PART_SOURC IS NULL) AND impt.partSource  NOT IN ('BUY','CONSG','MAKE','PHANTOM')) THEN 'i05red' ELSE '' END
  
   WHEN  ifd.FieldName = 'workCenter' THEN   
       CASE WHEN (impt.workCenter = '')  THEN ''
		    WHEN ((TRIM(impt.workCenter) <> WoCenter.DEPT_ID) OR WoCenter.DEPT_ID IS NULL)  THEN 'i05red' ELSE '' END
			
   WHEN ifd.FieldName = 'used' THEN
		CASE
			WHEN (TRIM(impt.used)<>'' AND TRIM(impt.used) IS NOT NULL)
				THEN CASE 
					WHEN  TRIM(impt.used) NOT IN ('1','0','true','false','yes','no','y','n')
						THEN 'i05red'
					ELSE '' END
				ELSE '' END	
				
	WHEN ifd.FieldName = 'itemno' THEN 
	CASE WHEN impt.itemno <> '' AND impt.itemno IS NOT NULL 
		 THEN 
				CASE WHEN (ISNUMERIC(impt.itemno) = 1 AND CAST(impt.itemno AS NUMERIC(4,0)) > 0) THEN
					CASE WHEN impt.itemno = Item.itemno
							THEN 'i05red' 
						 ELSE '' END
				ELSE 'i05red' END
		ELSE '' END
		
	WHEN ifd.FieldName = 'qty' THEN 
		CASE WHEN (ISNUMERIC(impt.qty) = 1) THEN ''
		ELSE 'i05red' END												
ELSE '' END 

  FROM ImportBOMToKitComponents ic
	--  INNER JOIN ImportBOMToKitAssemly a ON  a.AssemblyRowId = ic.FKAssemblyRowId	 
	  INNER JOIN ImportFieldDefinitions ifd  ON ic.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId 
	  --INNER JOIN ImportBOMToKitHeader h  ON a.FkImportId =h.ImportId  
	  INNER JOIN @ImportDetail impt ON ic.CompRowId = impt.CompRowId
	  OUTER APPLY 
	  (
			SELECT partno FROM @Bom 
			WHERE TRIM(assyNum) =  TRIM(impt.partno) AND TRIM(assyRev) =  TRIM(impt.rev) AND partSource ='MAKE'
	  )assem
	  OUTER APPLY 
	  (
			SELECT i.BOMCUSTNO FROM @Bom b INNER JOIN INVENTOR i ON b.UNIQ_KEY = i.UNIQ_KEY
	  )cust
	  OUTER APPLY 
	  (
			SELECT TOP 1 TRIM(PART_NO) PART_NO, TRIM(REVISION) REVISION, TRIM(DESCRIPT) DESCRIPT, TRIM(PART_CLASS) PART_CLASS,TRIM(PART_TYPE) PART_TYPE, 
			TRIM(PART_SOURC) PART_SOURC,TRIM(CUSTPARTNO) CUSTPARTNO,TRIM(CUSTREV) CUSTREV,STATUS,TRIM(custno) custno
			FROM INVENTOR 
			WHERE TRIM(PART_NO) =  TRIM(impt.partno) 
				  AND TRIM(REVISION) =  TRIM(impt.rev) -- 09/30/2019 Rajendar K : Changed custpartno condition for "CONSG" Part
				  AND TRIM(CUSTPARTNO)  =  CASE WHEN impt.partSource = 'CONSG' THEN  TRIM(impt.custPartNo) ELSE '' END
				  AND TRIM(CUSTREV) =  CASE WHEN impt.partSource = 'CONSG' THEN  TRIM(impt.crev)  ELSE '' END
				  AND custno = CASE WHEN impt.partSource = 'CONSG'THEN cust.BOMCUSTNO ELSE '' END
	  ) invt   
	  OUTER APPLY
	  (
			SELECT DEPT_ID  FROM DEPTS where TRIM(DEPT_ID) = TRIM(impt.workCenter)
	  ) WoCenter
	  OUTER APPLY
	  (
			SELECT TOP 1 CompRowId,CASE WHEN itemno IS NULL OR itemno = '' THEN 0 ELSE CAST(itemno AS NUMERIC(4,0)) END AS itemno,partno,rev,workCenter 
			FROM @ImportDetail 
			WHERE impt.CompRowId != CompRowId AND impt.itemno = itemno-- 10/09/2019 Rajendar K : Added condition for Itemno to update error
	  ) Item
 --Check length of string entered by user in template
	BEGIN TRY -- inside begin try		
	  UPDATE iw      
		SET [message]='Field will be truncated to ' + CAST(f.fieldLength AS VARCHAR(50)) + ' characters.',[status]=@red 
		FROM ImportBOMToKitComponents iw
		  INNER JOIN ImportBOMToKitAssemly a ON  a.AssemblyRowId = iw.FKAssemblyRowId	 
		  INNER JOIN ImportFieldDefinitions f  ON iw.FKFieldDefId =f.FieldDefId AND ModuleId = @ModuleId AND f.fieldLength > 0      
			WHERE fkImportId= @ImportId      
				AND LEN(iw.adjusted)>f.fieldLength        
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