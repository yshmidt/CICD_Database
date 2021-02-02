-- ============================================================================================================  
-- Date   : 08/21/2019  
-- Author  : Rajendra K 
-- Description : Used for Validate Assembly upload data  
-- 10/03/2019 Rajendra K : Added error message for description
-- 10/03/2019 Rajendra K : Changed Conditions for parttype & partclass
-- 10/14/2019 Rajendra k : Changed Messages
-- 10/14/2019 Rajendra k : Added Zero for Cust No
-- 11/21/2019 Rajendra k : Changed Old PRICHEAD table, used new table priceheader,priceCustomer for customer validation
-- ValidateAssemblyRecords 'BB75803B-A4AB-4710-B23E-0296896BD5AD'  
-- ============================================================================================================  
  
CREATE PROC ValidateAssemblyRecords  
 @ImportId UNIQUEIDENTIFIER  
 --@RowId UNIQUEIDENTIFIER =NULL  
AS  
BEGIN  
   
 SET NOCOUNT ON    
 DECLARE @SQL NVARCHAR(MAX),@SQLQ NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@WoFieldName VARCHAR(MAX) ,@headerErrs VARCHAR(MAX),@red VARCHAR(20)='i05red';
 DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))      
  
 DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CssClass VARCHAR(MAX),Validation VARCHAR(MAX),
							  assyDesc VARCHAR(MAX),assyNum VARCHAR(MAX),assypartclass VARCHAR(MAX),
							  assyparttype VARCHAR(MAX),assyRev VARCHAR(MAX),custno VARCHAR(MAX))   

 DECLARE @WODetail TABLE (importId UNIQUEIDENTIFIER,WORowId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER, CssClass VARCHAR(100),Validation VARCHAR(100), bldqty VARCHAR(10),
							  Due_date VARCHAR(100),End_date VARCHAR(100), JobType VARCHAR(100),kitDefWarehouse VARCHAR(100),Line_no VARCHAR(100),OrderDate VARCHAR(100),
							  PRJNUMBER VARCHAR(100),PRJUNIQUE	VARCHAR(100),RoutingName VARCHAR(100),SONO VARCHAR(100),Start_date VARCHAR(100),wono VARCHAR(100),Wonote VARCHAR(100))

 -- Insert statements for procedure here   
SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_BOMtoKITUpload' and FilePath = 'BOMtoKITUpload'  
 
SELECT @FieldName = STUFF(    
      (    
		   SELECT  ',[' +  F.FIELDNAME + ']' FROM   
		   ImportFieldDefinitions F      
		   WHERE ModuleId = @ModuleId AND FieldName in ('custno','assyDesc','assyRev','assyNum','assypartclass','assyparttype')  
		   ORDER BY F.FIELDNAME   
		   FOR XML PATH('')    
      ),    
      1,1,'')  
	  
SELECT @WoFieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId  AND FieldName in ('bldqty','Due_date','End_date','JobType','kitDefWarehouse','Line_no','OrderDate','PRJNUMBER','PRJUNIQUE'
						,'RoutingName','SONO','Start_date','wono','Wonote')  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'') 	     
  
 SELECT @SQL = N'    
  SELECT PVT.*  
  FROM    
  (   SELECT ibf.fkImportId AS importId,ibf.AssemblyRowId,sub.class as CssClass,sub.Validation,fd.fieldName,adjusted 
  FROM ImportFieldDefinitions fd      
     INNER JOIN ImportBOMToKitAssemly ibf ON fd.FieldDefId = ibf.FKFieldDefId 
     INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId   
	   INNER JOIN   
	   (   
		    SELECT fkImportId,AssemblyRowId,MAX(status) as Class ,MIN(Message) as Validation		
		    FROM ImportBOMToKitAssemly fd  
			INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
		    WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''   
			AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')  
		    GROUP BY fkImportId,AssemblyRowId   
	   ) Sub    
   ON ibf.fkImportid=Sub.FkImportId and ibf.AssemblyRowId=sub.AssemblyRowId   
   WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''     
  ) st    
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')   
  ) as PVT '        
  
 SELECT @SQLQ = N'    
   SELECT PVT.*  
  FROM    
  (   
   SELECT ibf.fkImportId AS importId,ic.WORowId,ibf.AssemblyRowId,sub.class as CssClass,sub.Validation,fd.fieldName,ic.Adjusted 
   FROM ImportFieldDefinitions fd      
	 INNER JOIN ImportBOMToKitWorkOrder ic ON fd.FieldDefId = ic.FKFieldDefId
     INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId
     INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId     
	 INNER JOIN   
	   (   
			SELECT fkImportId,WORowId,AssemblyRowId,MAX(ic.status) as Class ,MIN(ic.Message) as Validation		
			FROM ImportBOMToKitAssemly fd  
				INNER JOIN ImportBOMToKitWorkOrder ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
				INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId   
			WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''    
				AND FieldName IN ('+REPLACE(REPLACE(@WoFieldName,'[',''''),']','''')+')     
			GROUP BY fkImportId,WORowId,AssemblyRowId 
	   ) Sub    
   ON ibf.fkImportid=Sub.FkImportId and ic.WORowId = sub.WORowId AND ic.FKAssemblyRowId = sub.AssemblyRowId 
   WHERE ibf.fkImportId = '''+ CAST(@importId as CHAR(36))+'''  
  ) st    
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @WoFieldName +')   
  ) as PVT '

--Print @SQL  
 INSERT INTO @ImportDetail EXEC sp_executesql @SQL  
 INSERT INTO @WODetail EXEC sp_executesql @SQLQ;   
--SELECT * FROM @ImportDetail  
   
 UPDATE a  
 SET [message] = 
 --select impt.assypartclass,invt.PART_CLASS,
  CASE           
   WHEN  ifd.FieldName = 'custno' THEN   
		CASE WHEN (TRIM(ISNULL(impt.CUSTNO,'')) = '') THEN ''
			 WHEN (TRIM(ISNULL(impt.CUSTNO,'')) <> '' AND CUSTOMER.STATUS <>'Active') THEN 'Entered Customer is not Active.'
			 WHEN (TRIM(ISNULL(impt.CUSTNO,'')) <> '' AND (RIGHT('0000000000'+ CONVERT(VARCHAR,impt.CUSTNO),10)=CUSTOMER.CUSTNO)) THEN 
				-- Customer with Sales Order No. validation
				CASE WHEN (TRIM(ISNULL(wo.SONO,'')) <> '') AND (TRIM(CUSTOMER.CUSTNO) <> TRIM(SOdet.SOCUSTNO)) THEN 
					'Entered customer no. does not match with SONO.' 
				ELSE 
					-- Customer with BOM validation
					CASE WHEN bom_Det.totalCst > 0 AND bom_Det.CUSTNO <> CUSTOMER.CUSTNO THEN 'Customer Does not match with the BOM Customer.' 
						 ELSE -- 10/14/2019 Rajendra k : Added Zero for Cust No
							CASE WHEN TRIM(INVENTORBOM.BOMCUSTNO) = RIGHT('0000000000'+ CONVERT(VARCHAR,TRIM(impt.CUSTNO)),10) THEN ''
								 WHEN PriceheadCnt.PhCount = 0 THEN ''
								 WHEN PriceheadCnt.PhCount > 0 AND Pricehead.CUSTNOCnt > 0 THEN ''
								 ELSE 'Provided Customer is Not Available in Price setup'
							END
					END
				END
		ELSE 'Entered Customer No. is not valid.' END			  

   WHEN  ifd.FieldName = 'assyNum' THEN     -- 10/14/2019 Rajendra k : Changed Messages
       CASE WHEN (impt.assyNum = '')  THEN 'Please enter Assembly No.'
	   		WHEN ((TRIM(impt.assyNum) = invt.PART_NO) AND invt.STATUS <> 'Active') THEN 'Please enter valid Active Assembly no.'
		    WHEN ((TRIM(impt.assyNum) <> invt.PART_NO) OR invt.PART_NO IS NULL) THEN 'Please enter valid Assembly NO/Rev.' ELSE '' END 

   WHEN  ifd.FieldName = 'assyRev' THEN   
       CASE WHEN (impt.assyRev = '')  THEN ''
		    WHEN ((TRIM(impt.assyRev) <> invt.REVISION) OR invt.REVISION IS NULL)  THEN 'Please enter valid Assembly No/Rev.' ELSE '' END 

   WHEN  ifd.FieldName = 'assyDesc' THEN    -- 10/03/2019 Rajendra K : Added error message for description
       CASE WHEN (impt.assyDesc = '' AND invt.PART_NO IS NULL)  THEN 'Please enter Description'
		    WHEN (((impt.assyDesc IS NOT NULL OR impt.assyDesc != '') AND invt.DESCRIPT IS NOT NULL) AND (invt.PART_NO IS NULL OR invt.PART_NO = ''))  
				THEN 'Please enter valid Description' ELSE '' END 	

   WHEN  ifd.FieldName = 'assypartclass' THEN   
       CASE WHEN (impt.assypartclass = '' AND invt.PART_NO IS NULL)  THEN 'Please enter Part Class.'
		    WHEN (((impt.assypartclass IS NOT NULL OR impt.assypartclass != '') AND invt.PART_CLASS IS NULL) AND (invt.PART_NO IS NULL OR invt.PART_NO = ''))  
				THEN 'Please enter valid Part Class.' ELSE '' END -- 10/03/2019 Rajendra K : Changed Conditions for parttype & partclass

   WHEN  ifd.FieldName = 'assyparttype' THEN   
       CASE WHEN (impt.assyparttype = '')  THEN ''
		    WHEN (((impt.assyparttype IS NOT NULL OR impt.assyparttype != '') AND invt.PART_TYPE IS NULL) AND (invt.PART_NO IS NULL OR invt.PART_NO = ''))
				 THEN 'Please enter valid Part Type.' ELSE '' END -- 10/03/2019 Rajendra K : Changed Conditions for parttype & partclass
 ELSE '' END 
  
 ,[status] =   
  CASE           
   WHEN  ifd.FieldName = 'custno' THEN   
		CASE WHEN (TRIM(ISNULL(impt.CUSTNO,'')) = '') THEN ''
			 WHEN (TRIM(ISNULL(impt.CUSTNO,'')) <> '' AND CUSTOMER.STATUS <>'Active') THEN 'i05red'
			 WHEN (TRIM(ISNULL(impt.CUSTNO,'')) <> '' AND (RIGHT('0000000000'+ CONVERT(VARCHAR,impt.CUSTNO),10)=CUSTOMER.CUSTNO)) THEN 
				-- Customer with Sales Order No. validation
				CASE WHEN (TRIM(ISNULL(wo.SONO,'')) <> '') AND (TRIM(CUSTOMER.CUSTNO) <> TRIM(SOdet.SOCUSTNO)) THEN 
					'i05red' 
				ELSE 
					-- Customer with BOM validation
					CASE WHEN bom_Det.totalCst > 0 AND bom_Det.CUSTNO <> CUSTOMER.CUSTNO THEN 'i05red' 
						 ELSE -- 10/14/2019 Rajendra k : Added Zero for Cust No
							CASE WHEN TRIM(INVENTORBOM.BOMCUSTNO) = RIGHT('0000000000'+ CONVERT(VARCHAR,TRIM(impt.CUSTNO)),10) THEN ''
								 WHEN PriceheadCnt.PhCount = 0 THEN ''
								 WHEN PriceheadCnt.PhCount > 0 AND Pricehead.CUSTNOCnt > 0 THEN ''
								 ELSE 'i05red'
							END
					END
				END
		ELSE 'i05red' END  

   WHEN  ifd.FieldName = 'assyNum' THEN   
       CASE WHEN (impt.assyNum = '')  THEN 'i05red'
	   		WHEN ((TRIM(impt.assyNum) = invt.PART_NO) AND invt.STATUS <> 'Active') THEN 'i05red'
		    WHEN ((TRIM(impt.assyNum) <> invt.PART_NO) OR invt.PART_NO IS NULL) THEN 'i05red' ELSE '' END 

   WHEN  ifd.FieldName = 'assyRev' THEN   
       CASE WHEN (impt.assyRev = '')  THEN ''
		    WHEN ((TRIM(impt.assyRev) <> invt.REVISION) OR invt.REVISION IS NULL)  THEN 'i05red' ELSE '' END 

   WHEN  ifd.FieldName = 'assyDesc' THEN   
       CASE WHEN (impt.assyDesc = '' AND invt.PART_NO IS NULL)  THEN 'i05red'
		    WHEN (((impt.assyDesc IS NOT NULL OR impt.assyDesc != '') AND invt.DESCRIPT IS NOT NULL) AND (invt.PART_NO IS NULL OR invt.PART_NO = ''))  
				THEN 'i05red' ELSE '' END 	

   WHEN  ifd.FieldName = 'assypartclass' THEN   
       CASE WHEN (impt.assypartclass = '' AND invt.PART_NO IS NULL)  THEN 'i05red'
		    WHEN (((impt.assypartclass IS NOT NULL OR impt.assypartclass != '') AND invt.PART_CLASS IS NULL) AND (invt.PART_NO IS NULL OR invt.PART_NO = ''))  
				THEN 'i05red' ELSE '' END 

   WHEN  ifd.FieldName = 'assyparttype' THEN   
       CASE WHEN (impt.assyparttype = '')  THEN ''
		    WHEN (((impt.assyparttype IS NOT NULL OR impt.assyparttype != '') AND invt.PART_TYPE IS NULL) AND (invt.PART_NO IS NULL OR invt.PART_NO = ''))
				 THEN 'i05red' ELSE '' END 
 ELSE '' END 
  FROM ImportBOMToKitAssemly a  
	 JOIN ImportFieldDefinitions ifd  ON a.FKFieldDefId =ifd.FieldDefId AND UploadType = 'BOMtoKITUpload' 
	 JOIN ImportBOMToKitHeader h  ON a.FkImportId =h.ImportId  
	 INNER JOIN @ImportDetail impt ON a.fkimportid = impt.importId
	 LEFT JOIN @WODetail wo ON impt.AssemblyRowId = wo.AssemblyRowId
	 OUTER APPLY (
			SELECT TOP 1 CUSTNO, custName,STATUS FROM CUSTOMER C 
			WHERE CUSTNO = CASE WHEN impt.CUSTNO <> '' THEN RIGHT('0000000000'+ CONVERT(VARCHAR,impt.CUSTNO),10) ELSE C.CUSTNO END 
		) CUSTOMER
	 OUTER APPLY (
		SELECT TOP 1 TRIM(PART_NO) PART_NO, TRIM(REVISION) REVISION, TRIM(DESCRIPT) DESCRIPT, TRIM(PART_CLASS) PART_CLASS,TRIM(PART_TYPE) PART_TYPE,UNIQ_KEY,STATUS 
		FROM INVENTOR 
		WHERE TRIM(PART_NO) =  TRIM(impt.assyNum) AND TRIM(REVISION) =  TRIM(impt.assyRev) AND PART_SOURC = 'MAKE' AND MAKE_BUY = 0
	 ) invt  
	 OUTER APPLY (
			SELECT distinct count(custno) totalCst, CUSTNO FROM BOM_DET b 
				JOIN inventor i ON b.uniq_key=i.uniq_key 
				WHERE BOMPARENT = invt.UNIQ_KEY and PART_SOURC='CONSG' 
				GROUP BY custno
		) bom_Det
		OUTER APPLY (
			SELECT TOP 1 BOMCUSTNO FROM INVENTOR i WHERE I.UNIQ_KEY = TRIM(invt.UNIQ_KEY) 
		) INVENTORBOM
		OUTER APPLY (
			--SELECT COUNT(CATEGORY) PhCount FROM PricHead H WHERE uniq_key = invt.UNIQ_KEY
			SELECT COUNT(custno) PhCount -- 11/21/2019 Rajendra k : Changed Old PRICHEAD table, used new table priceheader,priceCustomer for customer validation
			FROM priceheader ph 
			INNER JOIN priceCustomer pc ON ph.uniqprhead = pc.uniqprhead
			WHERE uniq_key = invt.UNIQ_KEY 
		) PriceheadCnt
		OUTER APPLY (
		    SELECT TOP 1 ISNULL(COUNT(custno),0) CUSTNOCnt -- 11/21/2019 Rajendra k : Changed Old PRICHEAD table, used new table priceheader,priceCustomer for customer validation
			FROM priceheader ph
			INNER JOIN priceCustomer pc ON ph.uniqprhead = pc.uniqprhead
			WHERE uniq_key = invt.UNIQ_KEY AND (pc.custno = (RIGHT('0000000000'+ CONVERT(VARCHAR,impt.CUSTNO),10)) OR pc.custno = '000000000~')
			--SELECT TOP 1 ISNULL(COUNT(CATEGORY),0) CUSTNOCnt FROM PricHead H 
			--WHERE uniq_key = invt.UNIQ_KEY AND (H.CATEGORY = impt.CUSTNO OR H.CATEGORY = '000000000~')
	    ) Pricehead
				OUTER APPLY (
			SELECT TOP 1 SUBSTRING(SO.SONO, PATINDEX('%[^0]%',SO.SONO), 10) SONO, 
						 SUBSTRING(LINE_NO, PATINDEX('%[^0]%',LINE_NO), 7) LINE_NO, UNIQ_KEY, 
						 TRIM(SOM.CUSTNO) SOCUSTNO FROM SODETAIL SO 
						 JOIN SOMAIN SOM ON SOM.SONO = SO.SONO
				WHERE TRIM(SUBSTRING(SO.SONO, PATINDEX('%[^0]%',SO.SONO), 10)) = 
					CASE WHEN TRIM(wo.SONO) <> '' THEN 
						TRIM(SUBSTRING(wo.SONO, PATINDEX('%[^0]%',TRIM(wo.SONO)), 10)) 
					ELSE 
						TRIM(SUBSTRING(SO.SONO, PATINDEX('%[^0]%',SO.SONO), 10)) END
				AND SUBSTRING(LINE_NO, PATINDEX('%[^0]%',LINE_NO), 7) 
				=	CASE WHEN TRIM(wo.Line_no) <> '' THEN
								CASE WHEN RTRIM(LTRIM(wo.Line_no)) = '' THEN 
									(
										SELECT TOP 1 SUBSTRING(LINE_NO, PATINDEX('%[^0]%',LINE_NO), 7) 
										FROM SODETAIL WHERE UNIQ_KEY = invt.UNIQ_KEY 
										AND balance > 0 
										AND SUBSTRING(SO.SONO, PATINDEX('%[^0]%',SO.SONO), 10) = SUBSTRING(wo.SONO, PATINDEX('%[^0]%',wo.SONO), 10) 
									) 
								WHEN RTRIM(LTRIM(wo.Line_no)) <> '' THEN
									SUBSTRING(wo.Line_no, PATINDEX('%[^0]%',wo.Line_no), 7)  
								END
						 ELSE SUBSTRING(SO.LINE_NO, PATINDEX('%[^0]%',SO.LINE_NO), 7) END
		) SOdet
-- Check length of string entered by user in template
	BEGIN TRY -- inside begin try      
	  UPDATE a      
		SET [message]='Field will be truncated to ' + CAST(f.fieldLength AS VARCHAR(50)) + ' characters.',[status]=@red 
		FROM ImportBOMToKitAssemly a 	 
		INNER JOIN ImportFieldDefinitions f  ON a.FKFieldDefId =f.FieldDefId AND ModuleId = @ModuleId AND f.fieldLength > 0      
	    WHERE fkImportId= @ImportId AND LEN(a.adjusted)>f.fieldLength        
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