-- ============================================================================================================    
-- Date   : 08/27/2019    
-- Author  : Sachin B    
-- Description : Used for Validate Import Supplier Fields  
-- ValidateSupplierUploadRecords '7EBF233A-47AB-4390-AD43-9119ABDA04D4'   
-- Modification:  
-- 08/13/20 VL changed from using Micssys to get from mnxSettingManagement for the auto/manual number  
-- 08/26/20 Sachin B Added New DefaultAddress column for make address as defualt
--28/01/2021 Asset K. Added check for po1099 when importing Template and fixed some typos in the messages
-- ============================================================================================================    
    
CREATE PROC [dbo].[ValidateSupplierUploadRecords]    
 @ImportId UNIQUEIDENTIFIER,    
 @RowId UNIQUEIDENTIFIER = NULL    
AS    
BEGIN    
     
 SET NOCOUNT ON      
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName varchar(max),@autoSup bit,@AddressFieldName varchar(max),@AddSQL NVARCHAR(MAX)  
     
 DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,rowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),[Validation] VARCHAR(100),     
         ACCTNO VARCHAR(MAX),CRLIMIT VARCHAR(MAX),FAX VARCHAR(MAX),PHONE VARCHAR(MAX),    
         PO1099 VARCHAR(MAX),PURCH_TYPE VARCHAR(MAX),STATUS VARCHAR(MAX),SUP_TYPE VARCHAR(MAX),SUPID VARCHAR(MAX),SUPNAME VARCHAR(MAX),  
   SUPNOTE VARCHAR(MAX),TERMS VARCHAR(MAX))   
 -- 08/26/20 Sachin B Added New DefaultAddress column for make address as defualt 
 DECLARE @ImportSupAddDetail TABLE (importId UNIQUEIDENTIFIER,SupRowId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),[Validation] VARCHAR(100),     
         ADDRESS1 VARCHAR(MAX),ADDRESS2 VARCHAR(MAX),CITY VARCHAR(MAX),COUNTRY VARCHAR(MAX),DefaultAddress VARCHAR(MAX),    
         E_MAIL VARCHAR(MAX),FOB VARCHAR(MAX),LINKADD VARCHAR(MAX),RECORDTYPE VARCHAR(MAX),RECV_DEFA VARCHAR(MAX),SHIP_DAYS VARCHAR(MAX),  
   SHIPTO VARCHAR(MAX),SHIPVIA VARCHAR(MAX),STATE VARCHAR(MAX),ZIP VARCHAR(MAX))   
  
DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))    
  
-- 08/13/20 VL changed from using Micssys to get from mnxSettingManagement  
--SELECT @autoSup = micssys.xxsupnosys FROM micssys   
SELECT @autoSup = dbo.fn_GetSettingValue('AutoSupplierNumber')     
  
 SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc ='MnxM_SupplierAndContacts'   
  
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
       WHERE ModuleId = @ModuleId AND SourceTableName ='SUPINFO'    
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
   INNER JOIN ImportSupplierFields ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+    
   ' INNER JOIN ImportSupplierHeader h ON h.ImportId = ibf.FkImportId     
   INNER JOIN     
   (     
  SELECT fkImportId,rowid,MAX(status) as Class ,MIN(Message) as Validation      
  FROM ImportSupplierFields fd    
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
    SELECT ibf.fkImportId AS importId,ibf.suprowid,ibf.rowid,  
    sub.class as CssClass,sub.Validation,fd.fieldName,adjusted'      
    +' FROM ImportFieldDefinitions fd        
    INNER JOIN ImportSupplierAddressField ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+    
    ' INNER JOIN ImportSupplierHeader h ON h.ImportId = ibf.FkImportId     
    INNER JOIN     
    (     
   SELECT fkImportId,rowid,MAX(status) as Class ,MIN(Message) as Validation      
   FROM ImportSupplierAddressField fd    
   INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
   WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''    
   AND FieldName IN ('+REPLACE(REPLACE(@AddressFieldName,'[',''''),']','''')+')    
   GROUP BY fkImportId,rowid    
    ) Sub      
    ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid      
    WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''      
   ) st      
    PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @AddressFieldName +')    
   ) as PVT '    
  
 INSERT INTO @ImportSupAddDetail   
 EXEC SP_EXECUTESQL @AddSQL    
  
  
 UPDATE f    
  SET [message] =       
  CASE             
   WHEN  ifd.FieldName = 'SUPID' THEN     
       CASE     
  WHEN (@autoSup = 0 AND TRIM(ISNULL(impt.SUPID,'')) = '')  THEN 'SUPID is required.'    
  WHEN (@autoSup = 0 AND AutoSupGen.SUPID IS NOT NULL) THEN 'Entered SUPID already exists.'  
  WHEN (@autoSup = 0 AND DuplicateSUPID.TotSupid > 1) THEN 'Supplier Entered in Template is repeated.'   
  WHEN (s.SupRowId IS NULL ) THEN 'Supplier required at least one address with recordtype R OR C'   
       ELSE  '' END      
   WHEN  ifd.FieldName = 'SUPNAME' THEN     
       CASE     
  WHEN (TRIM(impt.SUPNAME) = '')  THEN 'SUPNAME is required.'   
  WHEN (supName.SUPNAME IS NOT NULL) THEN 'Entered SUPNAME already exists.'    
       ELSE  '' END     
   WHEN  ifd.FieldName = 'PURCH_TYPE' THEN     
       CASE     
  WHEN (TRIM(impt.PURCH_TYPE) <> '' AND impt.PURCH_TYPE NOT IN ('Inventory','MRO','Both'))  THEN 'PURCH_TYPE must be in (''Inventory'',''MRO'',''Both'')'     
       ELSE  '' END
	--28/01/2021 Asset K. Added check for po1099 when importing Template
  WHEN ifd.FieldName = 'PO1099' THEN
        CASE
  WHEN(impt.PO1099 <> '0' and impt.PO1099 <>'1') then 'PO1099 value can either be 0 or 1.'
        ELSE '' END
   WHEN  ifd.FieldName = 'SUP_TYPE' THEN     
       CASE     
  WHEN (TRIM(impt.SUP_TYPE) = '' OR supType.TEXT2 IS NULL)  THEN 'Either SUP_TYPE is empty or it not exits in the system.'     
       ELSE  '' END                   
   WHEN  ifd.FieldName = 'STATUS' THEN     
       CASE     
  WHEN (TRIM(impt.STATUS) = '' OR supStatus.TEXT2 IS NULL)  THEN 'Either STATUS is empty or it not exits in the system.'     
       ELSE  '' END                   
   WHEN  ifd.FieldName = 'TERMS' THEN     
       CASE     
  WHEN (TRIM(impt.TERMS) <> '' AND terms.DESCRIPT IS NULL)  THEN 'TERMS is not exits in the system.'     
       ELSE  '' END    
   WHEN  ifd.FieldName = 'CRLIMIT' THEN     
       CASE     
      WHEN (impt.CRLIMIT <> '' AND ISNUMERIC(impt.CRLIMIT)=1)  THEN ''     
      ELSE  'CRLIMIT column must be numeric' END       
   ELSE '' END ,    
    
  [Status] =     
  CASE             
   WHEN  ifd.FieldName = 'SUPID' THEN     
       CASE     
  WHEN (@autoSup = 0 AND TRIM(ISNULL(impt.SUPID,'')) = '')  THEN 'i05red'    
  WHEN (@autoSup = 0 AND AutoSupGen.SUPID IS NOT NULL) THEN 'i05red'  
  WHEN (@autoSup = 0 AND DuplicateSUPID.TotSupid > 1) THEN 'i05red'   
  WHEN (s.SupRowId IS NULL ) THEN 'i05red'   
       ELSE  '' END      
   WHEN  ifd.FieldName = 'SUPNAME' THEN     
       CASE     
  WHEN (TRIM(impt.SUPNAME) = '')  THEN 'i05red'   
  WHEN (supName.SUPNAME IS NOT NULL) THEN 'i05red'    
       ELSE  '' END     
   WHEN  ifd.FieldName = 'PURCH_TYPE' THEN     
       CASE     
  WHEN (TRIM(impt.PURCH_TYPE) <> '' AND impt.PURCH_TYPE NOT IN ('Inventory','MRO','Both'))  THEN 'i05red'     
       ELSE  '' END
	   --28/01/2021 Asset K. Added check for po1099 when importing Template
  WHEN ifd.FieldName = 'PO1099' THEN
        CASE
   WHEN(impt.PO1099 <> '0' and impt.PO1099 <>'1') then 'i05red'
        ELSE '' END
   WHEN  ifd.FieldName = 'SUP_TYPE' THEN     
       CASE     
  WHEN (TRIM(impt.SUP_TYPE) = '' OR supType.TEXT2 IS NULL)  THEN 'i05red'     
       ELSE  '' END                   
   WHEN  ifd.FieldName = 'STATUS' THEN     
       CASE     
  WHEN (TRIM(impt.STATUS) = '' OR supStatus.TEXT2 IS NULL)  THEN 'i05red'     
       ELSE  '' END                   
   WHEN  ifd.FieldName = 'TERMS' THEN     
       CASE     
  WHEN (TRIM(impt.TERMS) <> '' AND terms.DESCRIPT IS NULL)  THEN 'i05red'     
       ELSE  '' END   
    WHEN  ifd.FieldName = 'CRLIMIT' THEN     
       CASE     
      WHEN (impt.CRLIMIT <> '' AND ISNUMERIC(impt.CRLIMIT)=1)  THEN ''     
      ELSE  'i05red' END     
   ELSE '' END  
  --select *  
  FROM ImportSupplierFields f     
  JOIN ImportFieldDefinitions ifd  ON f.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId AND SourceTableName ='SUPINFO'     
  JOIN ImportSupplierHeader h  ON f.FkImportId =h.ImportId    
  LEFT JOIN @ImportDetail impt ON f.RowId = impt.RowId    
  LEFT JOIN @ImportSupAddDetail s ON s.SupRowId = impt.rowId AND ((s.RECORDTYPE='R' OR s.RECORDTYPE='C') OR S.LINKADD ='')  
  OUTER APPLY   
  (  
  SELECT TOP 1 SUPID from SUPINFO where TRIM(SUPID) = RIGHT('0000000000'+ CONVERT(VARCHAR,impt.SUPID),10)  
  ) AutoSupGen  
  OUTER APPLY   
  (  
  SELECT TOP 1 SUPID, count(SUPID) TotSupid from @ImportDetail   
  where TRIM(SUPID) = RIGHT('0000000000'+ CONVERT(VARCHAR,impt.SUPID),10) and @autoSup = 0   
  Group by SUPID  
  ) DuplicateSUPID  
  OUTER APPLY   
  (  
  SELECT TOP 1 SUPNAME from SUPINFO where TRIM(SUPNAME) = TRIM(impt.SUPNAME)  
  ) supName  
  OUTER APPLY  
  (  
     SELECT TEXT2 FROM SUPPORT s  
  WHERE TRIM(s.TEXT2) =TRIM(impt.SUP_TYPE) AND s.FIELDNAME = 'SUP_TYPE'  
  )supType  
  OUTER APPLY  
  (  
     SELECT TEXT2 FROM SUPPORT s  
  WHERE TRIM(s.TEXT2) = TRIM(impt.STATUS) AND s.FIELDNAME = 'SUPPL_STAT'  
  )supStatus  
  OUTER APPLY  
  (  
     SELECT DESCRIPT FROM PmtTerms s  
  WHERE TRIM(s.DESCRIPT) =TRIM(impt.TERMS)   
  )terms    
  -- OUTER APPLY  
  --(  
  --   SELECT s.SupRowId FROM @ImportSupAddDetail  s  
  --WHERE s.SupRowId = impt.rowId   
  --)addr     
  --WHERE (@RowId IS NULL OR f.RowId=@RowId)     
  
  -- Check length of string entered by user in template  
 BEGIN TRY -- inside begin try        
   UPDATE f      
     --28/01/2021 Asset K. grammatical error fixes frim "Fileds" to "Fields", and "then" to "than"
  SET [message]='Fields Size can not be greater than ' + CAST(fd.fieldLength AS VARCHAR(50)) + ' characters.',[status]='i05red'           
  FROM ImportSupplierFields f         
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