-- ============================================================================================================  
-- Date   : 11/15/2019  
-- Author  : Sachin B  
-- Description : Used for Validate Import Customer Fields
-- 01/15/2020 Sachin B Modify SALEDSCTID to SaleDiscountType; to understand the value of SALEDSCTID to the user 
-- 01/15/2020 Sachin B  Remove LinkAdd columns from template for address section 
-- 01/15/2020 Sachin B  Remove Fax columns from template for customer, contact and ship to address section 
-- 01/15/2020 Sachin B  Remove LinkAdd columns from template for address section 
-- 01/15/2020 Sachin B: We need to have one column to set default address for bill to ship and bill to contact, ship to contact to in the template
-- ValidateCustomerUploadRecords '74BC8625-C4FA-45B3-9535-DD5815F3480B', '3F4AAD1C-C22A-4BD9-A670-DA57C3822A92' 
-- 01/21/2021 Bekarys Modified SIC_CODE's error message
-- 01/21/2021 Bekarys Modified SIC_DESC's error message
-- ============================================================================================================  
  
CREATE  PROC ValidateCustomerUploadRecords  
 @ImportId UNIQUEIDENTIFIER,  
 @RowId UNIQUEIDENTIFIER = NULL  
AS  
BEGIN  
   
 SET NOCOUNT ON    
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT, @FieldName varchar(max), @autoCust bit, @AddressFieldName varchar(max), @AddSQL NVARCHAR(MAX)

 -- 01/15/2020 Sachin B Modify SALEDSCTID to SaleDiscountType; to understand the value of SALEDSCTID to the user 
 DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,rowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),[Validation] VARCHAR(100),ACCTSTATUS VARCHAR(MAX),
 CREDITOK VARCHAR(MAX), CREDLIMIT VARCHAR(MAX), custname VARCHAR(MAX), custno VARCHAR(MAX),LinkAddRef VARCHAR(MAX),PHONE VARCHAR(MAX),
 [PROFILE] VARCHAR(MAX),RecordNum VARCHAR(MAX), RESL_NO VARCHAR(MAX), SaleDiscountType VARCHAR(MAX),SIC_CODE VARCHAR(MAX), SIC_DESC VARCHAR(MAX),
 [STATUS] VARCHAR(MAX),TERMS VARCHAR(MAX), TERRITORY VARCHAR(MAX), WebSite VARCHAR(MAX)) 



 -- IF WE ADD OR remove any column in import field defination please arrrange it by field name in its import table

-- 01/15/2020 Sachin B: We need to have one column to set default address for bill to ship and bill to contact, ship to contact to in the template
-- 01/15/2020 Sachin B  Remove Fax columns from template for customer, contact and ship to address section 
-- 01/15/2020 Sachin B  Remove LinkAdd columns from template for address section 
 DECLARE @ImportCustAddDetail TABLE (importId UNIQUEIDENTIFIER,CustRowId UNIQUEIDENTIFIER, RowId UNIQUEIDENTIFIER, 
		 CssClass VARCHAR(100),[Validation] VARCHAR(100), ADDRESS1 VARCHAR(MAX),ADDRESS2 VARCHAR(MAX),CITY VARCHAR(MAX),
		 COUNTRY VARCHAR(MAX), E_MAIL VARCHAR(MAX), FOB VARCHAR(MAX),[IsDefaultAddress] BIT, [PHONE_S] VARCHAR(MAX),
		 RECORDTYPE VARCHAR(MAX),RECV_DEFA VARCHAR(MAX),SHIP_DAYS VARCHAR(MAX), SHIPTO VARCHAR(MAX),SHIPVIA VARCHAR(MAX),STATE VARCHAR(MAX),
		 ZIP VARCHAR(MAX)) 

DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX)) 
 
SELECT @autoCust =  (
						SELECT ISNULL(wms.settingValue, mnxS.settingValue)AS settingValue  
						FROM MnxSettingsManagement mnxS 
						LEFT JOIN wmSettingsManagement wms ON  mnxS.settingId = wms.settingId 
						WHERE settingName='autoGenerateCustomerNumber'
					)

SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc ='MnxM_CustomerContacts' 

 SELECT @AddressFieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId AND SourceTableName ='shipbill'  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')	   
  
 -- Insert statements for procedure here    
 SELECT @FieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId AND SourceTableName ='CUSTOMER'  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')     
  
 SELECT @SQL = N'    
  SELECT PVT.*  
  FROM    
  (  
   SELECT ibf.fkImportId AS importId,ibf.rowid,
   sub.class as CssClass,sub.Validation,fd.fieldName,adjusted'    
   +' FROM ImportFieldDefinitions fd      
   INNER JOIN ImportCustomerFields ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+  
   ' INNER JOIN ImportCustomerHeader h ON h.ImportId = ibf.FkImportId   
   INNER JOIN   
   (   
		SELECT fkImportId,rowid,MAX(status) as Class ,MIN(Message) as Validation    
		FROM ImportCustomerFields fd  
		INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
		WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''    
		AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')  
		GROUP BY fkImportId,rowid  
   ) Sub    
   ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid    
   WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''     
  ) st    
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')  
  ) as PVT '  
   
 --Print @SQL  
 INSERT INTO @ImportDetail EXEC sp_executesql @SQL     
 --SELECT * FROM @ImportDetail  

   SELECT @AddSQL = N'    
	  SELECT PVT.*  
	  FROM    
	  (  
	   SELECT ibf.fkImportId AS importId,ibf.Custrowid,ibf.rowid,
	   sub.class as CssClass,sub.Validation,fd.fieldName,adjusted'    
	   +' FROM ImportFieldDefinitions fd      
	   INNER JOIN ImportCustomerAddressFields ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+  
	   ' INNER JOIN ImportCustomerHeader h ON h.ImportId = ibf.FkImportId   
	   INNER JOIN   
	   (   
			SELECT fkImportId,rowid,MAX(status) as Class ,MIN(Message) as Validation    
			FROM ImportCustomerAddressFields fd  
			INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
			WHERE fkImportId ='''+ CAST(@importId AS CHAR(36))+'''  
			AND FieldName IN ('+REPLACE(REPLACE(@AddressFieldName,'[',''''),']','''')+')  
			GROUP BY fkImportId,rowid  
	   ) Sub    
	   ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid    
	   WHERE ibf.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''    
	  ) st    
	   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @AddressFieldName +')  
	  ) as PVT '  

	INSERT INTO @ImportCustAddDetail EXEC SP_EXECUTESQL @AddSQL  
--Print @AddSQL
 UPDATE f  
 SET [message] =     
  CASE           
   WHEN  ifd.FieldName = 'custno' THEN   
       CASE   
		WHEN (@autoCust = 0 AND TRIM(ISNULL(impt.custno,'')) = '')  THEN 'custno is required.'  
		WHEN (@autoCust = 0 AND AutoCustGen.custno IS NOT NULL) THEN 'Entered custno already exists.'
		WHEN (@autoCust = 0 AND DuplicateCustID.TotCustId > 1) THEN 'Customer Id Entered in Template is repeated.' 
		WHEN (@autoCust = 1 AND DuplicateCustName.TotCustName > 1) THEN 'Customer Name Entered in Template is repeated.'
    WHEN (s.CustRowId IS NULL) THEN 'Customer required at least one address with recordtype S OR B' 
		WHEN (s.CustRowId IS NOT NULL AND s.CssClass ='i05red') THEN 'Customer required at least one address with correct information'  
       ELSE  '' END 
	      
   WHEN  ifd.FieldName = 'custname' THEN   
       CASE   
		WHEN (TRIM(impt.custname) = '')  THEN 'Customer Name is required.' 
		WHEN (CUSTNAME.custname IS NOT NULL) THEN 'Entered Customer Name already exists.'  
       ELSE  '' END   
   
   WHEN  ifd.FieldName = 'SIC_CODE' THEN   
       CASE  
		WHEN (TRIM(impt.SIC_CODE) <> '' AND impt.SIC_CODE NOT IN (SELECT SIC_CODE FROM SicCodes))  
		-- 01/21/2021 Bekarys Modified SIC_CODE's error message
		THEN  'SIC Code does not exists in the system.'  
		WHEN (impt.SIC_CODE IS NOT NULL AND TRIM(impt.SIC_CODE) <> '' AND impt.SIC_DESC IS NOT NULL AND TRIM(impt.SIC_DESC) <> '' AND SicCodeAndDesc.SIC_CODE IS NULL) 
		THEN  'The Entered SIC Code and SIC Description value does not matched'	
        ELSE  '' END  

	    WHEN  ifd.FieldName = 'SIC_DESC' THEN   
       CASE  
		WHEN (TRIM(impt.SIC_DESC) <> '' AND impt.SIC_DESC NOT IN (SELECT SIC_DESC FROM SicCodes))
		-- 01/21/2021 Bekarys Modified SIC_CODE's error message
		THEN  'SIC Description does not exists in the system.'  
		--THEN 'SIC_DESC must be in('+(SELECT STUFF((SELECT ','+ TRIM(SIC_DESC) FROM SicCodes FOR XML PATH('')),1,1,'')) +')'
		WHEN (impt.SIC_DESC IS NOT NULL AND TRIM(impt.SIC_DESC) <> '' AND SicCodeAndDesc.SIC_DESC IS NULL) 
		THEN  'The Entered SIC Code and SIC Description value does not matched '     
       ELSE  '' END   
	    
   WHEN  ifd.FieldName = 'TERRITORY' THEN   
       CASE   
		WHEN (TRIM(impt.TERRITORY) <> '' AND TERRITORY.TEXT IS NOT NULL)  
		     AND impt.TERRITORY NOT IN (SELECT s.TEXT FROM SUPPORT s WHERE TRIM(s.TEXT) =TRIM(impt.TERRITORY) AND s.FIELDNAME = 'TERRITORY')
		THEN 'TERRITORY does not exists in the system.'   
       ELSE  '' END    
	                
   WHEN  ifd.FieldName = 'STATUS' THEN   
       CASE   
		WHEN (  impt.[STATUS] IS NOT NULL AND TRIM(impt.[STATUS]) <> '' AND  impt.[STATUS] NOT IN (SELECT DISTINCT * FROM (VALUES ('Active'),  ('Inactive')) AS X(status)) )
		  THEN 'Either STATUS is empty or it does not exists in the system.'   
       ELSE  '' END   
	     	                
   WHEN  ifd.FieldName = 'ACCTSTATUS' THEN   
       CASE   
		WHEN (  impt.ACCTSTATUS IS NOT NULL AND TRIM(impt.ACCTSTATUS) <> '' AND  impt.ACCTSTATUS 
				NOT IN (SELECT DISTINCT * FROM (VALUES ('Active'), ('Inactive'), ('Prospect')) AS X(ACCTSTATUS)) )
		  THEN 'Either ACCTSTATUS is empty or it does not exists in the system.'   
       ELSE  '' END   
	                    
   WHEN  ifd.FieldName = 'CREDITOK' THEN   
       CASE   
		WHEN (TRIM(impt.CREDITOK) <> '' AND impt.CreditOk IS NOT NULL AND impt.CREDITOK NOT IN (SELECT LEFT(text,15) AS CreditOk  FROM support WHERE fieldname = 'CREDITOK'))
		THEN 'Credit Status is empty or it does not exists in the system. '   
       ELSE  '' END 

   WHEN  ifd.FieldName = 'TERMS' THEN   
       CASE   
		WHEN (impt.TERMS IS NOT NULL AND TRIM(impt.TERMS) <> '' AND impt.[TERMS] NOT IN (SELECT DESCRIPT FROM PmtTerms)) 
		THEN 'TERMS does not exists in the system.'   
       ELSE  '' END  

-- 01/15/2020 Sachin B Modify SALEDSCTID to SaleDiscountType; to understand the value of SALEDSCTID to the user 
	WHEN  ifd.FieldName = 'SaleDiscountType' THEN   
       CASE   
		WHEN (impt.SaleDiscountType IS NOT NULL  AND  TRIM(impt.SaleDiscountType) <> '' AND TRIM(impt.SaleDiscountType) NOT IN ( SELECT SALEDSCTNM  FROM SALEDSCT))
		THEN 'Sales Discount Type does not exists in the system.'   
       ELSE  '' END 

   WHEN  ifd.FieldName = 'CREDLIMIT' THEN   
       CASE   
      WHEN (impt.CREDLIMIT IS NOT NULL AND impt.CREDLIMIT <> '' AND  ISNUMERIC(impt.CREDLIMIT)=1)  THEN ''   
      ELSE  'CREDLIMIT column must be numeric' END     
   ELSE '' END ,  

  [Status] =   
  CASE           
   WHEN  ifd.FieldName = 'CUSTNO' THEN   
       CASE   
		WHEN (@autoCust = 0 AND TRIM(ISNULL(impt.CUSTNO,'')) = '')  THEN 'i05red'  
		WHEN (@autoCust = 0 AND AutoCustGen.CUSTNO IS NOT NULL) THEN 'i05red'
		WHEN (@autoCust = 0 AND DuplicateCustID.TotCustId > 1) THEN 'i05red' 
		WHEN (@autoCust = 1 AND DuplicateCustName.TotCustName > 1) THEN 'i05red'
		WHEN (s.CustRowId IS NULL ) THEN 'i05red' 
		WHEN (s.CustRowId IS NOT NULL AND s.CssClass ='i05red') THEN 'i05red'  

       ELSE  '' END    

		WHEN  ifd.FieldName = 'custname' THEN   
		CASE  WHEN  (impt.custname IS NOT NULL) AND (TRIM(impt.custname) = '')  THEN 'i05red'
			  WHEN (CUSTNAME.custname IS NOT NULL) THEN 'i05red'  
 
       ELSE  '' END  
	    
   WHEN  ifd.FieldName = 'SIC_CODE' THEN   
       CASE   
		WHEN (TRIM(impt.SIC_CODE) <> '' AND impt.SIC_CODE NOT IN (SELECT SIC_CODE FROM SicCodes))  THEN 'i05red'
		WHEN (impt.SIC_CODE IS NOT NULL AND TRIM(impt.SIC_CODE) <> '' AND SicCodeAndDesc.SIC_CODE IS NULL) THEN  'i05red'     
       ELSE  '' END   

	    WHEN  ifd.FieldName = 'SIC_DESC' THEN   
       CASE   
		WHEN (TRIM(impt.SIC_DESC) <> '' AND impt.SIC_DESC NOT IN (SELECT SIC_DESC FROM SicCodes))  THEN 'i05red'   
		WHEN (impt.SIC_DESC IS NOT NULL AND TRIM(impt.SIC_DESC) <> '' AND SicCodeAndDesc.SIC_DESC IS NULL) THEN  'i05red'  
       ELSE  '' END 
          
   WHEN  ifd.FieldName = 'STATUS' THEN   
       CASE   
	   WHEN (  impt.[STATUS] IS NOT NULL AND TRIM(impt.[STATUS]) <> '' AND  impt.[STATUS] NOT IN (SELECT DISTINCT * FROM (VALUES ('Active'),  ('Inactive')) AS X(status)) )
		THEN 'i05red' 
       ELSE  '' END    
	       
	WHEN  ifd.FieldName = 'ACCTSTATUS' THEN   
       CASE   
		WHEN (  impt.ACCTSTATUS IS NOT NULL AND TRIM(impt.ACCTSTATUS) <> '' AND  impt.ACCTSTATUS 
				NOT IN (SELECT DISTINCT * FROM (VALUES ('Active'), ('Inactive'), ('Prospect')) AS X(ACCTSTATUS)) )
		  THEN 'i05red'   
       ELSE  '' END                      
					            
	WHEN  ifd.FieldName = 'CREDITOK' THEN   
       CASE   
	   	WHEN (impt.CREDITOK IS NOT NULL AND  TRIM(impt.CreditOk) <> ''  AND impt.CREDITOK NOT IN (SELECT LEFT(text,15) AS CreditOk  FROM support WHERE fieldname = 'CREDITOK'))
		THEN 'i05red'   
       ELSE  '' END 
  
   WHEN  ifd.FieldName = 'TERMS' THEN   
       CASE   
		WHEN (TRIM(impt.TERMS) <> '' AND impt.TERMS IS NOT NULL AND impt.[TERMS] NOT IN (SELECT DESCRIPT FROM PmtTerms)) THEN 'i05red'   
       ELSE  '' END 

	   WHEN  ifd.FieldName = 'SaleDiscountType' THEN   
       CASE   
		WHEN impt.SaleDiscountType IS NOT NULL AND (TRIM(impt.SaleDiscountType) <> '' AND impt.SaleDiscountType NOT IN ( SELECT SALEDSCTNM FROM SALEDSCT))  THEN 'i05red' 
       ELSE  '' END 	
	      
		  	    
   WHEN  ifd.FieldName = 'TERRITORY' THEN   
       CASE   
		WHEN (TRIM(impt.TERRITORY) <> '' AND TERRITORY.TEXT IS NULL)  
		     AND impt.TERRITORY NOT IN (SELECT s.TEXT FROM SUPPORT s WHERE TRIM(s.TEXT) =TRIM(impt.TERRITORY) AND s.FIELDNAME = 'TERRITORY')
		THEN 'i05red'   
       ELSE  '' END  

    WHEN  ifd.FieldName = 'CREDLIMIT' THEN   
       CASE   
      WHEN (impt.CREDLIMIT <> '' AND ISNUMERIC(impt.CREDLIMIT)=1)  THEN ''   
      ELSE  'i05red' END   
   ELSE '' END

  FROM ImportCustomerFields f 
  JOIN ImportFieldDefinitions ifd  ON f.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId AND SourceTableName ='CUSTOMER' 
  JOIN importCustomerHeader h  ON f.FkImportId =h.ImportId  
  LEFT JOIN @ImportDetail impt ON f.RowId = impt.RowId  
  LEFT JOIN @ImportCustAddDetail s ON s.CustRowId = impt.rowId   
  OUTER APPLY 
  (
	  --SELECT ISNULL(wmSet.settingValue, mnxSet.settingValue)AS Custno 
	  --from MnxSettingsManagement mnxSet 
	  --LEFT JOIN wmSettingsManagement wmSet ON mnxSet.settingId = wmSet.settingId 
	  --WHERE settingName = 'LastGeneratedCustomerNumber'
	  SELECT TOP 1 custno from CUSTOMER WHERE TRIM(custno) = RIGHT('0000000000'+ CONVERT(VARCHAR,impt.custno),10)
  ) AutoCustGen
  OUTER APPLY 
  (
	 SELECT TOP 1 CUSTNO, count(CUSTNO) TotCustId FROM @ImportDetail 
	 WHERE TRIM(CUSTNO) = RIGHT('0000000000'+ CONVERT(VARCHAR,impt.CUSTNO),10) and @autoCust = 0 
	 GROUP BY CUSTNO
  ) DuplicateCustID
  OUTER APPLY 
  (
	 SELECT TOP 1 custname, count(custname) TotCustName 
	 FROM @ImportDetail 
	 WHERE TRIM(custname) = TRIM(impt.custname)
	 GROUP BY custname
  ) DuplicateCustName
  OUTER APPLY 
  (
	 SELECT TOP 1 CUSTNAME FROM CUSTOMER WHERE TRIM(CUSTNAME) = TRIM(impt.CUSTNAME)
  ) CUSTNAME
  OUTER APPLY
  (
     SELECT s.TEXT FROM SUPPORT s
	 WHERE TRIM(s.TEXT) =TRIM(impt.TERRITORY) AND s.FIELDNAME = 'TERRITORY'
  )TERRITORY
  OUTER APPLY
  (
     SELECT DESCRIPT FROM PmtTerms s
	 WHERE TRIM(s.DESCRIPT) =TRIM(impt.TERMS) 
  )terms  
  OUTER APPLY
  (
	SELECT DISTINCT * FROM (VALUES ('Active'),  ('Inactive')) AS X(status)
  )custStatus
  OUTER APPLY
  (
	SELECT left(text,15) AS CreditOk  
	FROM support WHERE fieldname = 'CREDITOK'    
  )CreditStatus
  OUTER APPLY
  (
	SELECT SALEDSCTNM  FROM SALEDSCT
  )SalesDiscountType
  OUTER APPLY
  (
		SELECT TOP 1 SIC_CODE, SIC_DESC FROM SicCodes  WHERE SIC_DESC = impt.SIC_DESC
  )SICCode_DESC
  OUTER APPLY
  (
		SELECT TOP 1 SIC_CODE, SIC_DESC FROM SicCodes WHERE SIC_CODE = impt.SIC_CODE
  )SICCODE
    OUTER APPLY
  (
	 SELECT TOP 1 SIC_CODE, SIC_DESC FROM SicCodes WHERE SIC_CODE = impt.SIC_CODE AND SIC_DESC = impt.SIC_DESC 
  )SicCodeAndDesc
  OUTER APPLY
  (
     SELECT s.CustRowId FROM @ImportCustAddDetail  s
	 WHERE s.CustRowId = impt.rowId 
  )addr   
  WHERE  f.FkImportId =@ImportId AND (@RowId IS NULL OR f.RowId=@RowId) 
    
   -- Check length of string entered by user in template
	BEGIN TRY -- inside begin try      
	  UPDATE f      
		SET [message]='Fields Size can not be greater than ' + CAST(fd.fieldLength AS VARCHAR(50)) + ' characters.',[status]='i05red'         
		FROM ImportCustomerFields f       
		INNER JOIN importFieldDefinitions fd ON f.FkFieldDefId =fd.FieldDefId AND fd.fieldLength>0 and ModuleId = @ModuleId       
		WHERE fkImportId= @ImportId      
		AND LEN(f.adjusted)>fd.fieldLength        
	 END TRY      
	 BEGIN CATCH       
	  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)      
	  SELECT      
	    ERROR_NUMBER() AS ErrorNumber      
	   ,ERROR_SEVERITY() AS ErrorSeverity      
	   ,ERROR_PROCEDURE() AS ErrorProcedure      
	   ,ERROR_LINE() AS ErrorLine      
	   ,ERROR_MESSAGE() AS ErrorMessage;          
	 END CATCH   
END