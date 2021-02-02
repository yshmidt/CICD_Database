-- =====================================================================================    
-- Author  : Sachin B       
-- Date   : 08/28/2019  
-- Description  : This SP is Used for the Insert Supplier,Address and Its Contact data from import tables to its main table in the Main table  
-- EXEC UploadSuppliers '1e24b83b-a1ed-4d35-90be-6e16ddd9578e' , '49F80792-E15E-4B62-B720-21B360E3108A'   
-- Modification:  
-- 08/13/20 VL changed from using Micssys to get from mnxSettingManagement and minor fix for increasing auto number for supid  
-- 08/26/20 Sachin B Added New DefaultAddress column for make address as defualt
-- 08/26/20 Sachin B Add the cursur if no address is provide as default then make one of them as default
--=====================================================================================    
CREATE PROC [dbo].[UploadSuppliers]    
 @ImportId UNIQUEIDENTIFIER,  
 @UserId  UNIQUEIDENTIFIER =null   
  
AS  
BEGIN    
      
SET NOCOUNT ON   
BEGIN TRY                    
BEGIN TRANSACTION --transferTransaction      
  
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(max),@autoSup BIT, @AddrSQL NVARCHAR(MAX),@lastSupNo CHAR (10),  
         @ErrorMessage NVARCHAR(4000),@ErrorSeverity INT,@ErrorState INT  
  
 DECLARE @ImportDetail TABLE   
 (  
 ImportId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,   
 Ad_link CHAR(10), ACCTNO VARCHAR(15),CRLIMIT NUMERIC (8, 0),FAX VARCHAR(19),PHONE VARCHAR(19),    
 PO1099 VARCHAR(1),PURCH_TYPE VARCHAR(9),STATUS VARCHAR(16),SUP_TYPE VARCHAR(15),SUPID VARCHAR(10),  
 SUPNAME VARCHAR(50), SUPNOTE VARCHAR(MAX),TERMS VARCHAR(15)  
 )   
  
 DECLARE @ImportSupTable TABLE   
 (  
 ImportId UNIQUEIDENTIFIER, RowId UNIQUEIDENTIFIER,   
 UNIQSUPNO CHAR(10),SUPID CHAR(10)  
 )  
 DECLARE @AddressFieldName VARCHAR(max)      
  --getting module id      
 SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc ='MnxM_SupplierAndContacts'   
    
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
   SELECT ibf.fkImportId AS ImportId,ibf.rowid as RowId  
   ,(SELECT  top 1 Shipbill.linkadd FROM  shipbill   WHERE Shipbill.custno ='''' AND  Shipbill.recordtype = ''I''  ) Ad_link  
    ,fd.fieldName,adjusted'  +' FROM ImportFieldDefinitions fd        
   INNER JOIN ImportSupplierFields ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+    
   ' INNER JOIN ImportSupplierHeader h ON h.ImportId = ibf.FkImportId     
   INNER JOIN     
   (     
  SELECT fkImportId,rowid   
  FROM ImportSupplierFields fd    
  INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
  WHERE fkImportId ='''+ CAST(@importId AS CHAR(36))+'''      
  AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')    
  GROUP BY fkImportId,rowid   
  HAVING MAX(STATUS) <> ''i05red''   
    
   ) Sub      
   ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid      
   WHERE ibf.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''       
  ) st      
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')    
  ) as PVT '    
  
 -- 08/13/20 VL changed from using Micssys to get from mnxSettingManagement  
 --SELECT @autoSup = micssys.xxsupnosys FROM micssys   
 SELECT @autoSup = dbo.fn_GetSettingValue('AutoSupplierNumber')  
 IF (@autoSup=1)  
 BEGIN  
  EXEC GetNextSupplierNumber @pcNextNumber =@lastSupNo OUTPUT   
 END   
  
 INSERT INTO @ImportDetail   
 EXEC SP_EXECUTESQL @SQL     
  
 --select * from @ImportDetail   
 INSERT INTO @ImportSupTable(ImportId,RowId,UNIQSUPNO,SUPID )   
 SELECT ImportId, RowId, dbo.fn_GenerateUniqueNumber() AS UNIQSUPNO,  
     SUPID = CASE WHEN (@autoSup=0)   
     THEN RIGHT('0000000000'+SUPID,10)   
     -- 08/13/20 VL changed to not adding on number because GetNextSupplierNumber already add 1  
     --ELSE  RIGHT('0000000000'+ CONVERT(VARCHAR,@lastSupNo + ROW_NUMBER() OVER (ORDER BY SUPID)),10) END   
     ELSE  RIGHT('0000000000'+ CONVERT(VARCHAR,@lastSupNo + ROW_NUMBER() OVER (ORDER BY SUPID)-1),10) END   
 FROM @ImportDetail  
  
 --select * from @ImportSupTable  
 INSERT INTO SUPINFO (UNIQSUPNO, SUPID, SUPNAME, SUP_TYPE, ACCTNO, STATUS, PHONE, FAX, CRLIMIT, TERMS, SUPNOTE, PO1099, PURCH_TYPE,modifiedDate, Ad_link)   
 SELECT sup.UNIQSUPNO, sup.SUPID, SUPNAME, SUP_TYPE, ACCTNO, UPPER(STATUS), PHONE, FAX, CRLIMIT, TERMS, SUPNOTE, PO1099, PURCH_TYPE,  
 GETDATE() modifiedDate, Ad_link  
 FROM @ImportSupTable sup  
 INNER JOIN @ImportDetail idt ON  sup.ImportId=idt.ImportId AND sup.RowId =idt.RowId    
  
 -- 08/13/20 VL comment out the code, the last number should be updated in GetNextSupplierNumber  
 --IF (@autoSup=1)  
 --BEGIN  
 --  --updating last inserted Supplier id MicsSys table  
 --  IF EXISTS(SELECT 1 FROM @ImportSupTable)  
 --  UPDATE  MicsSys SET LastSupid= (SELECT TOP 1 SUPID FROM @ImportSupTable ORDER BY SUPID DESC)  
 --END   
  
--==============================================================================================================================================================================  
-----------------------------------------------------  Address field information -----------------------------------------------------  
--==============================================================================================================================================================================  
 -- 08/26/20 Sachin B Added New DefaultAddress column for make address as defualt
 DECLARE @ImportSupAddDetail TABLE   
 (  
  importId UNIQUEIDENTIFIER, SupRowId UNIQUEIDENTIFIER, rowId UNIQUEIDENTIFIER, ADDRESS1 VARCHAR(50), ADDRESS2 VARCHAR(50),  
  CITY VARCHAR(50), COUNTRY VARCHAR(50),DefaultAddress BIT, E_MAIL VARCHAR(50), FOB VARCHAR(15), LINKADD VARCHAR(10), RECORDTYPE VARCHAR(1), RECV_DEFA BIT   
  ,SHIP_DAYS VARCHAR(50), SHIPTO VARCHAR(50), SHIPVIA VARCHAR(15), STATE VARCHAR(3), ZIP VARCHAR(10)  
 )   
         
 SELECT @AddressFieldName = STUFF(      
      (      
       SELECT  ',[' +  F.FIELDNAME + ']' FROM     
       ImportFieldDefinitions F        
       WHERE ModuleId = @ModuleId AND SourceTableName ='shipbill'    
       ORDER BY F.FIELDNAME     
       FOR XML PATH('')      
      ),      
      1,1,'')   
  
   SELECT @AddrSQL = N'      
   SELECT PVT.*    
   FROM      
   (    
    SELECT ibf.fkImportId AS importId,ibf.suprowid,ibf.rowid, fd.fieldName,adjusted'+' FROM ImportFieldDefinitions fd        
    INNER JOIN ImportSupplierAddressField ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+    
    ' INNER JOIN ImportSupplierHeader h ON h.ImportId = ibf.FkImportId     
    INNER JOIN     
    (     
   SELECT fkImportId,rowid     
   FROM ImportSupplierAddressField fd    
   INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
   WHERE fkImportId ='''+ CAST(@importId AS CHAR(36))+'''    
   AND FieldName IN ('+REPLACE(REPLACE(@AddressFieldName,'[',''''),']','''')+')    
   GROUP BY fkImportId,rowid    
   HAVING MAX(STATUS) <> ''i05red''   
    ) Sub      
    ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid      
    WHERE ibf.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''      
   ) st      
    PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @AddressFieldName +')    
   ) as PVT '    
  
 --print @AddrSQL  
 INSERT INTO @ImportSupAddDetail    
 EXEC SP_EXECUTESQL @AddrSQL    
  
 DECLARE @ImportSupAddWithUpdatedLinkAddr TABLE   
 (  
  importId UNIQUEIDENTIFIER, SupRowId UNIQUEIDENTIFIER, rowId UNIQUEIDENTIFIER, LINKADD VARCHAR(10), CUSTNO VARCHAR(10), RECORDTYPE VARCHAR(1),DefaultAddress BIT 
 )   
  
 INSERT INTO @ImportSupAddWithUpdatedLinkAddr  
 SELECT DISTINCT ist.importId, isad.SupRowId, isad.rowId, dbo.fn_GenerateUniqueNumber() AS LINKADD, ist.SUPID AS CUSTNO, RECORDTYPE,DefaultAddress  
 FROM @ImportSupAddDetail  isad   
 JOIN @ImportSupTable ist ON isad.importId= ist.ImportId AND isad.SupRowId = ist.RowId  
  
 --select * from @ImportSupAddDetail  
 --select * from @ImportSupAddWithUpdatedLinkAddr  
  
 -- Loop over query result for either remit or commit address given to the supplier but not both of it. add it from code vise-versa------------------------------------  
 DECLARE @SupRowId UNIQUEIDENTIFIER,  @CUSTNO CHAR(10), @RecordType CHAR(1), @linkAddr CHAR(10), @rowId UNIQUEIDENTIFIER  
   
 DECLARE @supRecordCursor AS CURSOR;  
   
 SET @supRecordCursor = CURSOR LOCAL FAST_FORWARD FOR  
 SELECT DISTINCT isla.importId, isla.SupRowId, isla.rowId,  isla.LINKADD,  isla.CUSTNO, isla.RECORDTYPE  
 FROM  @ImportSupAddWithUpdatedLinkAddr isla  
 JOIN @ImportSupAddDetail isad ON isad.importId= isla.ImportId AND isad.SupRowId = isla.SupRowId AND isad.rowId =isla.rowId  
   
 OPEN @supRecordCursor;  
 FETCH NEXT FROM @supRecordCursor INTO @importId, @SupRowId,@rowId,@linkAddr, @CUSTNO, @RecordType ;  
    
 WHILE @@FETCH_STATUS = 0  
 BEGIN  
  --UPDATE SUPINFO   
  --SET  C_LINK= CASE WHEN (@RecordType='R') THEN C_LINK ELSE @linkAddr END,   
  --R_LINK= CASE WHEN (@RecordType='R') THEN @linkAddr ELSE R_LINK END  
  --FROM SUPINFO  sup   
  --INNER JOIN @ImportSupAddWithUpdatedLinkAddr isla  ON sup.SUPID = isla.CUSTNO   
  --WHERE isla.RECORDTYPE=@RecordType AND isla.importId= @importId AND isla.SupRowId=@SupRowId AND isla.rowId=@rowId AND isla.CUSTNO=@CUSTNO  
  
  IF NOT EXISTS   
  (			SELECT 1 FROM  @ImportSupAddWithUpdatedLinkAddr isla   
			JOIN @ImportSupAddDetail isad ON isad.importId= isla.ImportId AND isad.SupRowId = isla.SupRowId and isad.rowId =isla.rowId   
			WHERE  isla.ImportId=@ImportId AND isla.SupRowId = @SupRowId  AND isla.CUSTNO = @CUSTNO AND isla.RECORDTYPE<> @RecordType  
  )   
   BEGIN      
	   INSERT INTO @ImportSupAddWithUpdatedLinkAddr (importId , SupRowId , rowId , LINKADD , CUSTNO , RECORDTYPE,DefaultAddress)        
	   SELECT isla.importId, isla.SupRowId, isla.rowId,  dbo.fn_GenerateUniqueNumber() AS LINKADD,  isla.CUSTNO,
	   CASE WHEN (@RecordType='R') THEN 'C' ELSE 'R' END,isad.DefaultAddress   
	   FROM  @ImportSupAddWithUpdatedLinkAddr isla   
	   JOIN @ImportSupAddDetail isad ON isad.importId= isla.ImportId AND isad.SupRowId = isla.SupRowId AND isad.rowId =isla.rowId   
	   WHERE  isla.ImportId=@ImportId AND isla.SupRowId = @SupRowId   AND isla.CUSTNO = @CUSTNO AND isla.RECORDTYPE= @RecordType  
  
   --UPDATE SUPINFO SET  C_LINK= CASE WHEN (@RecordType='R') THEN isla.LINKADD   ELSE  C_LINK END,  
   --R_LINK= CASE WHEN (@RecordType='c') THEN  isla.LINKADD  ELSE R_LINK  END  
   --FROM SUPINFO  sup   
   --INNER JOIN @ImportSupAddWithUpdatedLinkAddr isla  ON sup.SUPID = isla.CUSTNO   
   --WHERE isla.RECORDTYPE=CASE WHEN (@RecordType='R') THEN 'C' ELSE 'R'END  
   --AND isla.importId= @importId AND isla.SupRowId=@SupRowId AND isla.rowId=@rowId AND isla.CUSTNO=@CUSTNO    
  END  
  FETCH NEXT FROM @supRecordCursor INTO @importId, @SupRowId,@rowId,@linkAddr, @CUSTNO, @RecordType  ;--  
 END  
  
 CLOSE @supRecordCursor;  
 DEALLOCATE @supRecordCursor;  
  
    --SELECT * FROM @ImportSupAddWithUpdatedLinkAddr  
 INSERT INTO SHIPBILL   
 (  
  LINKADD, CUSTNO, SHIPTO, ADDRESS1, ADDRESS2, CITY, [STATE], ZIP, COUNTRY, PHONE, FAX, E_MAIL,   
  FOB, SHIPVIA, RECORDTYPE, SHIP_DAYS, RECV_DEFA, modifiedDate   
 )  
 SELECT DISTINCT  isla.LINKADD,  isla.CUSTNO, SHIPTO, ADDRESS1, ADDRESS2, CITY, [STATE], ZIP, COUNTRY,  
 '' PHONE, '' FAX, E_MAIL, FOB, SHIPVIA, isla.RECORDTYPE, SHIP_DAYS, RECV_DEFA, GETDATE() modifiedDate   
 FROM  @ImportSupAddWithUpdatedLinkAddr isla  
 JOIN @ImportSupAddDetail isad ON isad.importId= isla.ImportId AND isad.SupRowId = isla.SupRowId AND isad.rowId =isla.rowId  
   
 ---------------------------------------------------------------- Loop over supplier to link addresses------------------------------------  
 DECLARE @UNIQSUPNO CHAR (10),  @SUPID CHAR(10);   
 DECLARE @RLink CHAR(10),@CLink char(10) 
 DECLARE @supAddrLinkCursor AS CURSOR;   
  
 SET @supAddrLinkCursor = CURSOR LOCAL FAST_FORWARD FOR  
 SELECT sup.UNIQSUPNO, sup.SUPID, isla.LINKADD, isla.RECORDTYPE  
 FROM @ImportSupTable sup  
 INNER JOIN @ImportDetail idt ON  sup.ImportId=idt.ImportId AND sup.RowId =idt.RowId  
 INNER JOIN @ImportSupAddWithUpdatedLinkAddr isla  ON sup.SUPID = isla.CUSTNO   
 WHERE  isla.importId= @importId AND isla.SupRowId=sup.RowId AND isla.DefaultAddress = 1 
   
 OPEN @supAddrLinkCursor;  
 
 FETCH NEXT FROM @supAddrLinkCursor INTO @UNIQSUPNO, @SUPID, @linkAddr, @RecordType;   
 
 WHILE @@FETCH_STATUS = 0  
 BEGIN  
  
  SET @RLink =(Select TRIM(R_LINK) FROM SUPINFO WHERE UNIQSUPNO =@UNIQSUPNO)  
  SET @CLink =(Select TRIM(C_LINK) FROM SUPINFO WHERE UNIQSUPNO =@UNIQSUPNO)  
  
  IF(@RecordType='R' AND @RLink = '')  
  BEGIN  
   UPDATE SUPINFO SET  R_LINK=@linkAddr  
   FROM SUPINFO sup  
   INNER JOIN @ImportSupAddWithUpdatedLinkAddr isla  ON sup.SUPID = isla.CUSTNO   
   WHERE isla.RECORDTYPE=@RecordType  AND isla.CUSTNO=@SUPID AND sup.UNIQSUPNO =@UNIQSUPNO  
  END  
   
  IF(@RecordType='C' AND @CLink = '')  
  BEGIN  
   UPDATE SUPINFO SET  C_LINK=@linkAddr  
   FROM SUPINFO  sup   
   INNER JOIN @ImportSupAddWithUpdatedLinkAddr isla  ON sup.SUPID = isla.CUSTNO   
   WHERE isla.RECORDTYPE=@RecordType  AND isla.CUSTNO=@SUPID AND sup.UNIQSUPNO =@UNIQSUPNO  
  END   

  FETCH NEXT FROM @supAddrLinkCursor INTO  @UNIQSUPNO,@SUPID, @linkAddr, @RecordType   
 END  
  
 CLOSE @supAddrLinkCursor;  
 DEALLOCATE @supAddrLinkCursor;  

 ---------------------------------------------------------------------Loop for if default address is not provided in template------------------------------
 -- 08/26/20 Sachin B Add the cursur if no address is provide as default then make one of them as default
 DECLARE @supAddrLinkDefaultCursor AS CURSOR;   
 SET @supAddrLinkDefaultCursor = CURSOR LOCAL FAST_FORWARD FOR  
 SELECT sup.UNIQSUPNO, sup.SUPID, isla.LINKADD, isla.RECORDTYPE  
 FROM @ImportSupTable sup  
 INNER JOIN @ImportDetail idt ON  sup.ImportId=idt.ImportId AND sup.RowId =idt.RowId  
 INNER JOIN @ImportSupAddWithUpdatedLinkAddr isla  ON sup.SUPID = isla.CUSTNO   
 WHERE  isla.importId= @importId AND isla.SupRowId=sup.RowId
   
 OPEN @supAddrLinkDefaultCursor;  
 
 FETCH NEXT FROM @supAddrLinkDefaultCursor INTO @UNIQSUPNO, @SUPID, @linkAddr, @RecordType;   
 
 WHILE @@FETCH_STATUS = 0  
 BEGIN  
  
  SET @RLink =(Select TRIM(R_LINK) FROM SUPINFO WHERE UNIQSUPNO =@UNIQSUPNO)  
  SET @CLink =(Select TRIM(C_LINK) FROM SUPINFO WHERE UNIQSUPNO =@UNIQSUPNO)  
  
  IF(@RecordType='R' AND @RLink = '')  
  BEGIN  
   UPDATE SUPINFO SET  R_LINK=@linkAddr  
   FROM SUPINFO sup  
   INNER JOIN @ImportSupAddWithUpdatedLinkAddr isla  ON sup.SUPID = isla.CUSTNO   
   WHERE isla.RECORDTYPE=@RecordType  AND isla.CUSTNO=@SUPID AND sup.UNIQSUPNO =@UNIQSUPNO  
  END  
   
  IF(@RecordType='C' AND @CLink = '')  
  BEGIN  
   UPDATE SUPINFO SET  C_LINK=@linkAddr  
   FROM SUPINFO  sup   
   INNER JOIN @ImportSupAddWithUpdatedLinkAddr isla  ON sup.SUPID = isla.CUSTNO   
   WHERE isla.RECORDTYPE=@RecordType  AND isla.CUSTNO=@SUPID AND sup.UNIQSUPNO =@UNIQSUPNO  
  END   

  FETCH NEXT FROM @supAddrLinkDefaultCursor INTO  @UNIQSUPNO,@SUPID, @linkAddr, @RecordType   
 END  
  
 CLOSE @supAddrLinkDefaultCursor;  
 DEALLOCATE @supAddrLinkDefaultCursor;  

  ------------------------------------------------------------------------ Contacts fields Import ---------------------------------  
 DECLARE @ContactSQL NVARCHAR(MAX),@ContactFieldName varchar(max)  
  
 SELECT @ContactFieldName = STUFF(      
      (      
       SELECT  ',[' +  F.FIELDNAME + ']' FROM     
       ImportFieldDefinitions F        
       WHERE ModuleId = @ModuleId AND SourceTableName ='CContact'    
       ORDER BY F.FIELDNAME     
       FOR XML PATH('')      
      ),      
      1,1,'')     
      
 --select @nextContactNumber  
 SELECT @ContactSQL = N'      
   SELECT PVT.*    
   FROM      
   (    
    SELECT ibf.fkImportId AS importId,ibf.suprowid,ibf.rowid, fd.fieldName,adjusted'      
    +' FROM ImportFieldDefinitions fd        
    INNER JOIN ImportSupplierContactField ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+    
    ' INNER JOIN ImportSupplierHeader h ON h.ImportId = ibf.FkImportId     
    INNER JOIN     
    (     
   SELECT fkImportId,rowid,MAX(status) as Class ,MIN(Message) as Validation      
   FROM ImportSupplierContactField fd    
   INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
   WHERE fkImportId ='''+ CAST(@importId AS CHAR(36))+'''    
   AND FieldName IN ('+REPLACE(REPLACE(@ContactFieldName,'[',''''),']','''')+')    
   GROUP BY fkImportId,rowid    
   HAVING MAX(STATUS) <> ''i05red''   
    ) Sub      
    ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid      
    WHERE ibf.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''   
   ) st      
    PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @ContactFieldName +')    
   ) as PVT '    
     
  DECLARE @ImportSupContactDetail TABLE   
  ( importId UNIQUEIDENTIFIER, SupRowId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,  
   CONTACTFAX VARCHAR(25), CONTNOTE VARCHAR(MAX), DEPARTMENT VARCHAR(25), EMAIL VARCHAR(100),    
   FIRSTNAME VARCHAR(50), IsFavourite BIT, LASTNAME VARCHAR(50), MIDNAME VARCHAR(50),  
   MOBILE VARCHAR(25), NICKNAME VARCHAR(50), TITLE VARCHAR(50), TYPE VARCHAR(1),  
   [URL] VARCHAR(MAX), WORKPHONE VARCHAR(25), WRKEMAIL VARCHAR(100)  
  )    
   --EXEC SP_EXECUTESQL @ContactSQL  
  INSERT INTO @ImportSupContactDetail    
  EXEC SP_EXECUTESQL @ContactSQL  
  
  DECLARE @nextContactNumber CHAR (10)  
  EXEC GetNextCcontactNumber  @nextContactNumber OUT  
  
  DECLARE @insertedContactData TABLE (CID VARCHAR(10) )  
  
  INSERT INTO CCONTACT   
  (  
   CID, [TYPE], LASTNAME, FIRSTNAME, MIDNAME, NICKNAME, IS_EDITED, CUSTNO, DEPARTMENT, TITLE, WORKPHONE, EMAIL, CONTACTFAX,   
   STATUS, modifiedDate, IsSynchronizedFlag, FkUserId,Mobile,IsFavourite,url,CONTNOTE  
  )  
  OUTPUT inserted.CID  
  INTO @insertedContactData  
  SELECT CID = RIGHT('0000000000'+ CONVERT(VARCHAR,@nextContactNumber + ROW_NUMBER() OVER (ORDER BY SUPID)),10),  
  'S',  LASTNAME, FIRSTNAME, MIDNAME, NICKNAME, '' IS_EDITED,  ist.SUPID As CUSTNO, DEPARTMENT, TITLE, WORKPHONE, EMAIL, CONTACTFAX,   
  'Active' STATUS, GETDATE(), 0 IsSynchronizedFlag,  NEWID() FkUserId,MOBILE,IsFavourite,URL,CONTNOTE   
  FROM @ImportSupContactDetail iscd  
  JOIN @ImportSupTable ist ON iscd.importId= ist.ImportId and iscd.SupRowId = ist.RowId  
  
  --updating last inserted contact id MicsSys table  
  IF EXISTS(SELECT 1 FROM @insertedContactData)  
  BEGIN  
    UPDATE  MicsSys SET LastCid= (SELECT TOP 1 CID FROM @insertedContactData ORDER BY CID DESC)  
  END   
COMMIT TRANSACTION                
                
END TRY        
-- 06/20/16 YS change how catch is working need to make sure it is working as expected          
BEGIN CATCH                            
 IF @@TRANCOUNT > 0   
  ROLLBACK TRANSACTION;        
     SELECT @ErrorMessage = ERROR_MESSAGE(),  
        @ErrorSeverity = ERROR_SEVERITY(),  
        @ErrorState = ERROR_STATE();  
  RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
               );  
                      
END CATCH               
END