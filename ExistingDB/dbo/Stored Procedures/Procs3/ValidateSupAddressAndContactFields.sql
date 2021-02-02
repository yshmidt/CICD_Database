-- ============================================================================================================    
-- Date   : 08/27/2019    
-- Author  : Sachin B    
-- Description : Used for Validate Import Supplier Fields
-- 08/26/20 Sachin B Added New DefaultAddress column for make address as defualt 
--28/01/2021 Asset K. grammatical error fixes frim "Fileds" to "Fields", and "then" to "than"
-- ValidateSupAddressAndContactFields 'F63F6C07-3C33-4E1F-AE6E-10CCF2AC17CF'  
-- ============================================================================================================    
    
CREATE PROC [dbo].[ValidateSupAddressAndContactFields]    
 @ImportId UNIQUEIDENTIFIER,   
 --@SupRowId UNIQUEIDENTIFIER,   
 @RowId UNIQUEIDENTIFIER =NULL    
AS    
BEGIN    
     
 SET NOCOUNT ON      
 DECLARE @ContactSQL NVARCHAR(MAX),@ModuleId INT,@ContactFieldName varchar(max),@autoSup bit,@AddressFieldName varchar(max),@AddSQL NVARCHAR(MAX)  
     
 DECLARE @ImportSupplierDetail TABLE (SupRowId UNIQUEIDENTIFIER)   
 -- 08/26/20 Sachin B Added New DefaultAddress column for make address as defualt 
 DECLARE @ImportSupAddDetail TABLE (importId UNIQUEIDENTIFIER,SupRowId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),[Validation] VARCHAR(100),     
         ADDRESS1 VARCHAR(MAX),ADDRESS2 VARCHAR(MAX),CITY VARCHAR(MAX),COUNTRY VARCHAR(MAX),DefaultAddress VARCHAR(MAX),    
         E_MAIL VARCHAR(MAX),FOB VARCHAR(MAX),LINKADD VARCHAR(MAX),RECORDTYPE VARCHAR(MAX),RECV_DEFA VARCHAR(MAX),SHIP_DAYS VARCHAR(MAX),  
   SHIPTO VARCHAR(MAX),SHIPVIA VARCHAR(MAX),STATE VARCHAR(MAX),ZIP VARCHAR(MAX))   
  
 DECLARE @ImportSupContactDetail TABLE (importId UNIQUEIDENTIFIER,SupRowId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),[Validation] VARCHAR(100),     
         CONTACTFAX VARCHAR(MAX),CONTNOTE VARCHAR(MAX),DEPARTMENT VARCHAR(MAX),EMAIL VARCHAR(MAX),    
         FIRSTNAME VARCHAR(MAX),IsFavourite VARCHAR(MAX),LASTNAME VARCHAR(MAX),MIDNAME VARCHAR(MAX),MOBILE VARCHAR(MAX),NICKNAME VARCHAR(MAX),  
   TITLE VARCHAR(MAX),TYPE VARCHAR(MAX),URL VARCHAR(MAX),WORKPHONE VARCHAR(MAX),WRKEMAIL VARCHAR(MAX))    
  
 DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))    
     
 SELECT @autoSup = micssys.xxsupnosys FROM micssys       
    
 -- Insert statements for procedure here      
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
 INSERT INTO @ImportSupplierDetail   
 SELECT DISTINCT rowid FROM ImportSupplierFields WHERE FkImportId = @ImportId  
    
 --SELECT * FROM @ImportSupplierDetail    
  
DECLARE @SupRowId UNIQUEIDENTIFIER  
  
 DECLARE supContact_cursor CURSOR LOCAL FAST_FORWARD FOR  
 SELECT SupRowId FROM @ImportSupplierDetail  
  
 OPEN supContact_cursor;  
 FETCH NEXT FROM supContact_cursor  
 INTO @SupRowId ;  
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
  
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
   AND SupRowId ='''+ CAST(@SupRowId as CHAR(36))+'''     
   AND FieldName IN ('+REPLACE(REPLACE(@AddressFieldName,'[',''''),']','''')+')    
   GROUP BY fkImportId,rowid    
    ) Sub      
    ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid      
    WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''   
    AND SupRowId ='''+ CAST(@SupRowId as CHAR(36))+'''       
   ) st      
    PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @AddressFieldName +')    
   ) as PVT '    
  
 INSERT INTO @ImportSupAddDetail   
 EXEC SP_EXECUTESQL @AddSQL    
   
  UPDATE f    
   SET [message] =       
   CASE             
    WHEN  ifd.FieldName = 'SHIPTO' THEN     
     CASE     
   WHEN (TRIM(ISNULL(impt.SHIPTO,'')) = '')  THEN 'SHIPTO is required.'    
   WHEN (@autoSup = 0 AND duplicateShipToID.TotSupid > 1) THEN 'Supplier Entered in Template is repeated.'   
     ELSE  '' END      
    WHEN  ifd.FieldName = 'SUPNAME' THEN     
     CASE     
   WHEN (TRIM(impt.RECORDTYPE) = '')  THEN 'RECORDTYPE is required.'   
   WHEN (TRIM(impt.RECORDTYPE) <> '' AND impt.RECORDTYPE NOT IN ('R','C')) THEN 'RECORDTYPE must be in (''R'',''C'')'    
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
   WHEN (@autoSup = 0 AND duplicateShipToID.TotSupid > 1) THEN 'i05red'   
     ELSE  '' END      
    WHEN  ifd.FieldName = 'SUPNAME' THEN     
     CASE     
   WHEN (TRIM(impt.RECORDTYPE) = '')  THEN 'i05red'   
   WHEN (TRIM(impt.RECORDTYPE) <> '' AND impt.RECORDTYPE NOT IN ('R','C')) THEN 'i05red'    
     ELSE  '' END  
   WHEN  ifd.FieldName = 'SHIP_DAYS' THEN     
          CASE     
   WHEN (impt.SHIP_DAYS <> '' AND ISNUMERIC(impt.SHIP_DAYS)=1)  THEN ''     
   ELSE  'i05red0' END             
    ELSE '' END  
   --select *  
   FROM ImportSupplierAddressField f     
   JOIN ImportFieldDefinitions ifd  on f.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId AND SourceTableName ='shipbill'     
   JOIN ImportSupplierHeader h  on f.FkImportId =h.ImportId    
   INNER JOIN @ImportSupAddDetail impt on f.RowId = impt.RowId    
   OUTER APPLY   
   (  
   SELECT  COUNT(SHIPTO) TotSupid from @ImportSupAddDetail   
   where TRIM(SHIPTO) = TRIM(impt.SHIPTO)  
   Group by SHIPTO,RECORDTYPE  
   ) duplicateShipToID   
   WHERE (@RowId IS NULL OR f.RowId=@RowId) AND f.SupRowId =@SupRowId  
     
 SELECT @ContactSQL = N'      
   SELECT PVT.*    
   FROM      
   (    
    SELECT ibf.fkImportId AS importId,ibf.suprowid,ibf.rowid,  
    sub.class as CssClass,sub.Validation,fd.fieldName,adjusted'      
    +' FROM ImportFieldDefinitions fd        
    INNER JOIN ImportSupplierContactField ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+    
    ' INNER JOIN ImportSupplierHeader h ON h.ImportId = ibf.FkImportId     
    INNER JOIN     
    (     
   SELECT fkImportId,rowid,MAX(status) as Class ,MIN(Message) as Validation      
   FROM ImportSupplierContactField fd    
   INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
   WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''    
   AND SupRowId ='''+ CAST(@SupRowId as CHAR(36))+'''     
   AND FieldName IN ('+REPLACE(REPLACE(@ContactFieldName,'[',''''),']','''')+')    
   GROUP BY fkImportId,rowid    
    ) Sub      
    ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid      
    WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''   
    AND SupRowId ='''+ CAST(@SupRowId as CHAR(36))+'''       
   ) st      
    PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @ContactFieldName +')    
   ) as PVT '    
  
 INSERT INTO @ImportSupContactDetail   
 EXEC SP_EXECUTESQL @ContactSQL     
   
   UPDATE f    
   SET [message] =       
   CASE             
    WHEN  ifd.FieldName = 'FIRSTNAME' THEN     
     CASE     
   WHEN (TRIM(ISNULL(impt.FIRSTNAME,'')) = '')  THEN 'FIRSTNAME is required.'    
   WHEN (@autoSup = 0 AND duplicateShipToID.TotSupid > 1) THEN 'Contact FIRSTNAME and LASTNAME combination can not be same for on Supplier.'   
     ELSE  '' END      
    WHEN  ifd.FieldName = 'LASTNAME' THEN     
     CASE     
   WHEN (TRIM(impt.LASTNAME) = '')  THEN 'LASTNAME is required.'   
   WHEN (TRIM(impt.LASTNAME) <> '' AND duplicateShipToID.TotSupid > 1) THEN 'Contact can not be dulicated with same FIRSTNAME and LASTNAME for one supplier.'    
     ELSE  '' END        
    ELSE '' END ,    
    
   [Status] =     
   CASE             
    WHEN  ifd.FieldName = 'FIRSTNAME' THEN     
     CASE     
   WHEN (TRIM(ISNULL(impt.FIRSTNAME,'')) = '')  THEN 'i05red'    
   WHEN (@autoSup = 0 AND duplicateShipToID.TotSupid > 1) THEN 'i05red'   
     ELSE  '' END      
    WHEN  ifd.FieldName = 'LASTNAME' THEN     
     CASE     
   WHEN (TRIM(impt.LASTNAME) = '')  THEN 'i05red'   
   WHEN (TRIM(impt.LASTNAME) <> '' AND duplicateShipToID.TotSupid > 1) THEN 'i05red'    
     ELSE  '' END        
    ELSE '' END  
   --select *  
   FROM ImportSupplierContactField f     
   JOIN ImportFieldDefinitions ifd  on f.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId AND SourceTableName ='CContact'     
   JOIN ImportSupplierHeader h  on f.FkImportId =h.ImportId    
   INNER JOIN @ImportSupContactDetail impt on f.RowId = impt.RowId    
   OUTER APPLY   
   (  
   SELECT  COUNT(FIRSTNAME) TotSupid from @ImportSupContactDetail   
   where TRIM(FIRSTNAME) = TRIM(impt.FIRSTNAME) AND TRIM(LASTNAME) = TRIM(impt.LASTNAME)  
   Group by FIRSTNAME,LASTNAME  
   ) duplicateShipToID   
   WHERE (@RowId IS NULL OR f.RowId=@RowId) AND f.SupRowId =@SupRowId   
  
 DELETE FROM @ImportSupAddDetail     
 DELETE FROM @ImportSupContactDetail    
  
 FETCH NEXT FROM supContact_cursor  
 INTO @SupRowId;  
END;   
  
CLOSE supContact_cursor;  
DEALLOCATE supContact_cursor;  
  
 -- Check length of string entered by user in template  
 BEGIN TRY -- inside begin try        
  UPDATE f     
  --28/01/2021 Asset K. grammatical error fixes frim "Fileds" to "Fields", and "then" to "than"
  SET [message]='Fields Size can not be greater than ' + CAST(fd.fieldLength AS VARCHAR(50)) + ' characters.',[status]='i05red'           
  FROM ImportSupplierFields f         
  INNER JOIN importFieldDefinitions fd ON f.FkFieldDefId =fd.FieldDefId AND fd.fieldLength>0 and ModuleId = @ModuleId         
  WHERE fkImportId= @ImportId        
  AND LEN(f.adjusted)>fd.fieldLength     
    
  UPDATE f        
  SET [message]='Fields Size can not be greater than ' + CAST(fd.fieldLength AS VARCHAR(50)) + ' characters.',[status]='i05red'           
  FROM ImportSupplierAddressField f         
  INNER JOIN importFieldDefinitions fd ON f.FkFieldDefId =fd.FieldDefId AND fd.fieldLength>0 and ModuleId = @ModuleId         
  WHERE fkImportId= @ImportId        
  AND LEN(f.adjusted)>fd.fieldLength     

  UPDATE f        
  SET [message]='Fields Size can not be greater than ' + CAST(fd.fieldLength AS VARCHAR(50)) + ' characters.',[status]='i05red'           
  FROM ImportSupplierContactField f         
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