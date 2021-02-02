-- ============================================================================================================  
-- Date   : 08/27/2019  
-- Author  : Sachin B  
-- Description : Used for Validate Import Customer Contact and Address fields
-- 01/15/2020 Sachin B  Remove Fax,linkAdd columns from template address section 
-- 01/15/2020 Sachin B: We need to have one column to set default address for bill and bill to Address in the template
-- 01/15/2020 Sachin B  Remove ContactFax,type columns from template contact section 
-- 01/15/2020 Sachin B: We need to have one column to set IsDefaultContact for billing contact and ship to contact in the template
-- ValidateCustAddressAndContactFields '74BC8625-C4FA-45B3-9535-DD5815F3480B'
-- 01/21/2021 Bekarys modified FOB's error message
-- ============================================================================================================  
  
CREATE PROC ValidateCustAddressAndContactFields  
 @ImportId UNIQUEIDENTIFIER, 
 --@CustRowId UNIQUEIDENTIFIER, 
 @RowId UNIQUEIDENTIFIER =NULL  
AS  
BEGIN  
   
 SET NOCOUNT ON    
 DECLARE @ContactSQL NVARCHAR(MAX),@ModuleId INT,@ContactFieldName varchar(max),@autoCust bit,@AddressFieldName varchar(max),@AddSQL NVARCHAR(MAX)
   
 DECLARE @ImportCustDetail TABLE (CustRowId UNIQUEIDENTIFIER) 

 -- 01/15/2020 Sachin B  Remove Fax,linkAdd columns from template address section 
-- 01/15/2020 Sachin B: We need to have one column to set default address for bill and bill to Address in the template
 DECLARE @ImportCustAddDetail TABLE (importId UNIQUEIDENTIFIER,CustRowId UNIQUEIDENTIFIER, RowId UNIQUEIDENTIFIER, 
		 CssClass VARCHAR(100),[Validation] VARCHAR(100), ADDRESS1 VARCHAR(MAX),ADDRESS2 VARCHAR(MAX),CITY VARCHAR(MAX),
		 COUNTRY VARCHAR(MAX), E_MAIL VARCHAR(MAX), FOB VARCHAR(MAX), IsDefaultAddress BIT, [PHONE_S] VARCHAR(MAX),
		 RECORDTYPE VARCHAR(MAX),RECV_DEFA VARCHAR(MAX),SHIP_DAYS VARCHAR(MAX), SHIPTO VARCHAR(MAX),SHIPVIA VARCHAR(MAX),STATE VARCHAR(MAX),
		 ZIP VARCHAR(MAX)) 

-- 01/15/2020 Sachin B  Remove ContactFax,type columns from template contact section 
-- 01/15/2020 Sachin B: We need to have one column to set IsDefaultContact for billing contact and ship to contact in the template

 DECLARE @ImportCustContactDetail TABLE (importId UNIQUEIDENTIFIER,CustRowId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),[Validation] VARCHAR(100),   
         CONTNOTE VARCHAR(MAX),DEPARTMENT VARCHAR(MAX),EMAIL VARCHAR(MAX),  
         FIRSTNAME VARCHAR(MAX), IsDefaultContact BIT, IsFavourite VARCHAR(MAX),LASTNAME VARCHAR(MAX),MIDNAME VARCHAR(MAX),MOBILE VARCHAR(MAX),NICKNAME VARCHAR(MAX),
		 TITLE VARCHAR(MAX), URL VARCHAR(MAX),WORKPHONE VARCHAR(MAX),WRKEMAIL VARCHAR(MAX)) 	

 DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))  
		 
 SELECT @autoCust = CASE WHEN w.settingId IS NOT NULL THEN  w.settingValue ELSE m.settingValue END FROM MnxSettingsManagement m
		LEFT JOIN wmSettingsManagement w on m.settingId = w.settingId
		WHERE settingName = 'autoGenerateCustomerNumber' AND settingDescription = 'AutoGenerateWO'   
  
 -- Insert statements for procedure here    
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
   
 SELECT @ContactFieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId AND SourceTableName ='CContact'  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')  	
   
   
 --Print @SQL  
 INSERT INTO @ImportCustDetail 
 SELECT DISTINCT rowid FROM ImportCustomerFields WHERE FkImportId = @ImportId
  
 --SELECT * FROM @ImportCustDetail  

 DECLARE @CustRowId UNIQUEIDENTIFIER

 DECLARE CustContact_cursor CURSOR LOCAL FAST_FORWARD FOR
 SELECT CustRowId FROM @ImportCustDetail

 OPEN CustContact_cursor;
 FETCH NEXT FROM CustContact_cursor
 INTO @CustRowId ;

WHILE @@FETCH_STATUS = 0
BEGIN

  SELECT @AddSQL = N'    
	  SELECT PVT.*  
	  FROM    
	  (  
	   SELECT ibf.fkImportId AS importId,ibf.CustRowId,ibf.rowid,
	   sub.class as CssClass,sub.Validation,fd.fieldName,adjusted'    
	   +' FROM ImportFieldDefinitions fd      
	   INNER JOIN ImportCustomerAddressFields ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+  
	   ' INNER JOIN ImportCustomerHeader h ON h.ImportId = ibf.FkImportId   
	   INNER JOIN   
	   (   
			SELECT fkImportId,rowid,MAX(status) as Class ,MIN(Message) as Validation    
			FROM ImportCustomerAddressFields fd  
			INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
			WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''  
			AND CustRowId ='''+ CAST(@CustRowId as CHAR(36))+'''   
			AND FieldName IN ('+REPLACE(REPLACE(@AddressFieldName,'[',''''),']','''')+')  
			GROUP BY fkImportId,rowid  
	   ) Sub    
	   ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid    
	   WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+''' 
	   AND CustRowId ='''+ CAST(@CustRowId as CHAR(36))+'''     
	  ) st    
	   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @AddressFieldName +')  
	  ) as PVT '  

	INSERT INTO @ImportCustAddDetail 
	EXEC SP_EXECUTESQL @AddSQL  
	--select * from @ImportCustAddDetail
	
	 UPDATE f  
	  SET [message] =     
	  CASE           
	   WHEN  ifd.FieldName = 'SHIPTO' THEN   
		   CASE   
			WHEN (TRIM(ISNULL(impt.SHIPTO,'')) = '')  THEN 'SHIPTO is required.'
			WHEN (custAdd.SHIPTO IS NOT NULL) THEN 'Entered SHIPTO Name already exists.'  
			WHEN (@autoCust = 0 AND duplicateShipToID.TotCustid > 1) THEN 'Customer Entered in Template is repeated.' 
			-- 31/12/2019 Sachin B modify impt.SHIPTO insted of blank '' due to change in logic for if linkRef doesnot matched then throw error in ship to when inserting data in import
		   ELSE  f.Message END    
	   WHEN  ifd.FieldName = 'RECORDTYPE' THEN   
		   CASE   
			WHEN (TRIM(impt.RECORDTYPE) = '')  THEN 'RECORDTYPE is required.' 
			WHEN (TRIM(impt.RECORDTYPE) <> '' AND impt.RECORDTYPE NOT IN ('B','S')) THEN 'RECORDTYPE must be in (''B'',''S'')'  
		  ELSE  '' END
   
     WHEN  ifd.FieldName = 'FOB' THEN   
          CASE   
			WHEN (impt.FOB <> '' AND impt.FOB IS NOT NULL 
			-- 1/21/2021 Bekarys modified FOB's error message
			AND impt.FOB NOT IN (SELECT s.TEXT FROM SUPPORT s WHERE  TRIM(s.TEXT) = TRIM(impt.FOB)  AND FIELDNAME='FOB')) THEN 'FOB does not exists in the system.'   
			ELSE  '' END  
                 
	   WHEN  ifd.FieldName = 'SHIPVIA' THEN   
          CASE   
			WHEN (impt.SHIPVIA <> '' AND impt.SHIPVIA IS NOT NULL 
				AND impt.SHIPVIA NOT IN (SELECT s.TEXT FROM SUPPORT s WHERE  TRIM(s.TEXT) = TRIM(impt.SHIPVIA)  AND FIELDNAME='SHIPVIA'))
			THEN 'SHIPVIA does not exists in the system.'   
			ELSE  '' END

	  WHEN  ifd.FieldName = 'SHIP_DAYS' THEN   
       CASE   
      WHEN (impt.SHIP_DAYS <> '' AND ISNUMERIC(impt.SHIP_DAYS)=1)  THEN ''   
      ELSE  'SHIP_DAYS column must be numeric' END      
	   ELSE '' END ,  
  
	  [Status] =   
	  CASE           
	   WHEN  ifd.FieldName = 'SHIPTO' THEN   
		   CASE   
			WHEN (TRIM(ISNULL(impt.SHIPTO,'')) = '')  THEN 'i05red'  
			WHEN (custAdd.SHIPTO IS NOT NULL) THEN 'i05red'  
			WHEN (@autoCust = 0 AND duplicateShipToID.TotCustid > 1) THEN 'i05red' 
			-- 31/12/2019 Sachin B modify impt.SHIPTO insted of blank '' due to change in logic for if linkRef doesnot matched then throw error in ship to when inserting data in import
		   ELSE  f.Status END    
	   WHEN  ifd.FieldName = 'RECORDTYPE' THEN   
		   CASE   
			WHEN (TRIM(impt.RECORDTYPE) = '')  THEN 'i05red' 
			WHEN (TRIM(impt.RECORDTYPE) <> '' AND impt.RECORDTYPE NOT IN ('B','S')) THEN 'i05red'  
		   ELSE  '' END
	WHEN  ifd.FieldName = 'FOB' THEN   
          CASE   
			WHEN (impt.FOB <> '' AND impt.FOB IS NOT NULL 
				AND impt.FOB NOT IN (SELECT s.TEXT FROM SUPPORT s WHERE  TRIM(s.TEXT) = TRIM(impt.FOB)  AND FIELDNAME='FOB')) THEN 'i05red'   
			ELSE  '' END           
	  
	   	WHEN  ifd.FieldName = 'SHIPVIA' THEN   
          CASE   
			WHEN (impt.SHIPVIA <> '' AND impt.SHIPVIA IS NOT NULL 
				AND impt.SHIPVIA NOT IN (SELECT s.TEXT FROM SUPPORT s WHERE  TRIM(s.TEXT) = TRIM(impt.SHIPVIA)  AND FIELDNAME='SHIPVIA'))
			THEN 'i05red'   
			ELSE  '' END 

	  WHEN  ifd.FieldName = 'SHIP_DAYS' THEN   
          CASE   
			WHEN (impt.SHIP_DAYS <> '' AND ISNUMERIC(impt.SHIP_DAYS)=1)  THEN ''   
			ELSE  'i05red' END           
	   ELSE '' END
	  --select *
	  FROM ImportCustomerAddressFields f   
	  JOIN ImportFieldDefinitions ifd  ON f.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId AND SourceTableName ='shipbill'   
	  JOIN ImportCustomerHeader h  ON f.FkImportId =h.ImportId  
	  INNER JOIN @ImportCustAddDetail impt ON f.RowId = impt.RowId  
	  INNER JOIN ImportCustomerFields custF ON f.CustRowId = custF.RowId 
	  OUTER APPLY 
	  (
		 SELECT  COUNT(SHIPTO) TotCustid FROM @ImportCustAddDetail 
		 WHERE TRIM(SHIPTO) = TRIM(impt.SHIPTO)
		 GROUP BY SHIPTO,RECORDTYPE
	  ) duplicateShipToID 
	   OUTER APPLY 
	  (
		 SELECT TOP 1 SHIPTO FROM SHIPBILL sb 
		 INNER JOIN CUSTOMER cust ON cust.CUSTNO =sb.CUSTNO  
		 WHERE TRIM(SHIPTO) = TRIM(impt.SHIPTO) 			
			AND (cust.CUSTNAME = (custF.Adjusted) AND custF.FkFieldDefId= (SELECT FieldDefId FROM ImportFieldDefinitions WHERE SourceFieldName='custname' AND SourceTableName='CUSTOMER'))
	  ) custAdd
	  WHERE (@RowId IS NULL OR f.RowId=@RowId) AND f.CustRowId =@CustRowId
	  
	SELECT @ContactSQL = N'    
	  SELECT PVT.*  
	  FROM    
	  (  
	   SELECT ibf.fkImportId AS importId,ibf.custrowid,ibf.rowid,
	   sub.class as CssClass,sub.Validation,fd.fieldName,adjusted'    
	   +' FROM ImportFieldDefinitions fd      
	   INNER JOIN ImportCustomerContactFields ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId AS VARCHAR(10))+  
	   ' INNER JOIN ImportCustomerHeader h ON h.ImportId = ibf.FkImportId   
	   INNER JOIN   
	   (   
			SELECT fkImportId,rowid,MAX(status) as Class ,MIN(Message) as Validation    
			FROM ImportCustomerContactFields fd  
			INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
			WHERE fkImportId ='''+ CAST(@importId AS CHAR(36))+'''  
			AND CustRowId ='''+ CAST(@CustRowId AS CHAR(36))+'''   
			AND FieldName IN ('+REPLACE(REPLACE(@ContactFieldName,'[',''''),']','''')+')  
			GROUP BY fkImportId,rowid  
	   ) Sub    
	   ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid    
	   WHERE ibf.fkImportId ='''+ CAST(@importId AS CHAR(36))+''' 
	   AND CustRowId ='''+ CAST(@CustRowId AS CHAR(36))+'''     
	  ) st    
	   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @ContactFieldName +')  
	  ) as PVT '  

	INSERT INTO @ImportCustContactDetail 
	EXEC SP_EXECUTESQL @ContactSQL   
	--select * from @ImportCustContactDetail
	
		 UPDATE f  
	  SET [message] =     
	  CASE           
	   WHEN  ifd.FieldName = 'FIRSTNAME' THEN   
		   CASE   
			WHEN (TRIM(ISNULL(impt.FIRSTNAME,'')) = '' OR impt.FIRSTNAME = '')  THEN 'FIRSTNAME is required.'  
			WHEN (TRIM(impt.FIRSTNAME) <> '' AND duplicateCustContact.TotCustid > 1) THEN 'Contact FIRSTNAME and LASTNAME combination can not be same for one Customer.'
			WHEN TRIM(impt.FIRSTNAME) <>'' AND (contactAddValidation.AddressDetailId IS NOT NULL AND contactAddValForError.errAdd>1) THEN 'Correct The Address First'
		   ELSE  '' END    
	   WHEN  ifd.FieldName = 'LASTNAME' THEN   
		   CASE   
			WHEN (TRIM(impt.LASTNAME) = '')  THEN 'LASTNAME is required.' 
			WHEN (TRIM(impt.LASTNAME) <> '' AND duplicateCustContact.TotCustid > 1) THEN 'Contact can not be duplicated with same FIRSTNAME and LASTNAME for one Customer.'  
		   ELSE  '' END      
	   ELSE '' END ,  
  
	  [Status] =   
	  CASE           
	   WHEN  ifd.FieldName = 'FIRSTNAME' THEN   
		   CASE   
			WHEN (TRIM(ISNULL(impt.FIRSTNAME,'')) = '')  THEN 'i05red'  
			WHEN (TRIM(impt.FIRSTNAME) <> '' AND duplicateCustContact.TotCustid > 1) THEN 'i05red' 
			WHEN TRIM(impt.FIRSTNAME) <>'' AND (contactAddValidation.AddressDetailId IS NULL OR contactAddValForError.errAdd>1) THEN 'i05red'
		   ELSE  '' END    
	   WHEN  ifd.FieldName = 'LASTNAME' THEN   
		   CASE   
			WHEN (TRIM(impt.LASTNAME) = '')  THEN 'i05red' 
			WHEN (TRIM(impt.LASTNAME) <> '' AND duplicateCustContact.TotCustid > 1) THEN 'i05red'  
		   ELSE  '' END      
	   ELSE '' END
	  --select *
	  FROM ImportCustomerContactFields f   
	  JOIN ImportFieldDefinitions ifd  ON f.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId AND SourceTableName ='CContact'   
	  JOIN ImportCustomerHeader h  ON f.FkImportId =h.ImportId  
	  INNER JOIN @ImportCustContactDetail impt ON f.RowId = impt.RowId  
	  INNER JOIN @ImportCustAddDetail custAdd ON f.RowId = impt.RowId  

	  OUTER APPLY 
	  (
		 SELECT  COUNT(ccDet.CustRowId) TotCustid 
		 FROM @ImportCustContactDetail ccDet
		 --INNER JOIN [ImportAddressContactLink] addCL ON ccDet.RowId = addCL.ContactRowId
		 WHERE TRIM(FIRSTNAME) = TRIM(impt.FIRSTNAME) AND TRIM(LASTNAME) = TRIM(impt.LASTNAME)  --AND TRIM(RECORDTYPE) = TRIM(addCL.RECORDTYPE) 
		 AND ccDet.CustRowId = @CustRowId AND  ccDet.importId =@ImportId
		 GROUP BY FIRSTNAME, LASTNAME --, RECORDTYPE		 
	  ) duplicateCustContact 

  OUTER APPLY (
					SELECT custAddF.* FROM ImportAddressContactLink  addContLnk 
					INNER JOIN ImportCustomerContactFields ccont ON addContLnk.ContactRowId = ccont.RowId 
					INNER JOIN ImportCustomerAddressFields custAddF ON addContLnk.AddressRowId= custAddF.RowId WHERE custAddF.FkImportId=@ImportId
	  )contactAddValidation

	  OUTER APPLY (
					SELECT COUNT(custAddF.AddressDetailId)errAdd FROM ImportAddressContactLink  addContLnk 
					INNER JOIN ImportCustomerContactFields ccont ON addContLnk.ContactRowId = ccont.RowId 
					INNER JOIN ImportCustomerAddressFields custAddF ON addContLnk.AddressRowId= custAddF.RowId WHERE custAddF.Status='i05red'
					AND custAddF.FkImportId=@ImportId
	  )contactAddValForError
	  WHERE (@RowId IS NULL OR f.RowId=@RowId) AND f.CustRowId =@CustRowId AND f.FkImportId =@ImportId

	DELETE FROM @ImportCustAddDetail   
	DELETE FROM @ImportCustContactDetail  

	FETCH NEXT FROM CustContact_cursor
	INTO @CustRowId;
END;	

CLOSE CustContact_cursor;
DEALLOCATE CustContact_cursor;

	-- Check length of string entered by user in template
	BEGIN TRY -- inside begin try      
		UPDATE f      
		SET [message]='Fileds Size can not be greater then ' + CAST(fd.fieldLength AS VARCHAR(50)) + ' characters.',[status]='i05red'         
		FROM ImportCustomerFields f       
		INNER JOIN importFieldDefinitions fd ON f.FkFieldDefId =fd.FieldDefId AND fd.fieldLength>0 and ModuleId = @ModuleId       
		WHERE fkImportId= @ImportId      
		AND LEN(f.adjusted)>fd.fieldLength   
		
		UPDATE f      
		SET [message]='Fileds Size can not be greater then ' + CAST(fd.fieldLength AS VARCHAR(50)) + ' characters.',[status]='i05red'         
		FROM ImportCustomerAddressFields f       
		INNER JOIN importFieldDefinitions fd ON f.FkFieldDefId =fd.FieldDefId AND fd.fieldLength>0 and ModuleId = @ModuleId       
		WHERE fkImportId= @ImportId      
		AND LEN(f.adjusted)>fd.fieldLength   
		
		UPDATE f      
		SET [message]='Fileds Size can not be greater then ' + CAST(fd.fieldLength AS VARCHAR(50)) + ' characters.',[status]='i05red'         
		FROM ImportCustomerContactFields f       
		INNER JOIN importFieldDefinitions fd ON f.FkFieldDefId =fd.FieldDefId AND fd.fieldLength>0 and ModuleId = @ModuleId       
		WHERE fkImportId= @ImportId      
		AND LEN(f.adjusted)>fd.fieldLength   
		
		-- Calling customer validation sp after address validation for getting error in customer if none of the addresses given against that customer are correct     
	   EXEC ValidateCustomerUploadRecords @ImportId

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