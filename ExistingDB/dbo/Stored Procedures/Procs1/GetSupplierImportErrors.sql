-- =====================================================================================    
-- Author  : Sachin B       
-- Date   : 09/05/2019  
-- Description  : This SP is used for Get the Supplier imports Error  
-- 08/26/20 Sachin B Added New DefaultAddress column for make address as defualt
-- EXEC GetSupplierImportErrors '75E46D2E-8D35-4339-9267-1D40A56C580C'  
-- =====================================================================================    
CREATE PROC GetSupplierImportErrors    
 @ImportId UNIQUEIDENTIFIER  
   
AS  
BEGIN    
      
 SET NOCOUNT ON    
  
  DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@autoSup BIT, @AddrSQL NVARCHAR(MAX),@FieldName NVARCHAR(MAX),@AddressFieldName NVARCHAR(MAX)  
  
   -- Insert statements for procedure here      
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
  
   DECLARE @ImportDetail TABLE   
 (  
 ImportId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,   
 Ad_link CHAR(10), ACCTNO VARCHAR(MAX),CRLIMIT VARCHAR(MAX),FAX VARCHAR(MAX),PHONE VARCHAR(MAX),    
 PO1099 VARCHAR(MAX),PURCH_TYPE VARCHAR(MAX),STATUS VARCHAR(MAX),SUP_TYPE VARCHAR(MAX),SUPID VARCHAR(MAX),  
 SUPNAME VARCHAR(MAX), SUPNOTE VARCHAR(MAX),TERMS VARCHAR(MAX)  
 )   
  
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
    
   ) Sub      
   ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid      
   WHERE ibf.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''        
  ) st      
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')    
  ) as PVT '  
  
  INSERT INTO @ImportDetail   
  EXEC SP_EXECUTESQL @SQL   
  
  
  -------------------------------------------------------  Address field information -----------------------------------------------------  
  -- 08/26/20 Sachin B Added New DefaultAddress column for make address as defualt
 DECLARE @ImportSupAddDetail TABLE   
 (  
  importId UNIQUEIDENTIFIER, SupRowId UNIQUEIDENTIFIER, rowId UNIQUEIDENTIFIER,ADDRESS1 VARCHAR(MAX), ADDRESS2 VARCHAR(MAX),  
  CITY VARCHAR(MAX),COUNTRY VARCHAR(MAX),DefaultAddress VARCHAR(MAX),E_MAIL VARCHAR(MAX), FOB VARCHAR(MAX), LINKADD VARCHAR(MAX),RECORDTYPE VARCHAR(MAX), RECV_DEFA BIT   
  ,SHIP_DAYS VARCHAR(50),SHIPTO VARCHAR(50), SHIPVIA VARCHAR(MAX),STATE VARCHAR(MAX), ZIP VARCHAR(MAX)  
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
    ) Sub      
    ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid      
    WHERE ibf.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''      
   ) st      
    PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @AddressFieldName +')    
   ) as PVT '    
  
 --print @AddrSQL  
 INSERT INTO @ImportSupAddDetail    
 EXEC SP_EXECUTESQL @AddrSQL    
  
 --select * from @ImportSupAddDetail  
  
 --  ------------------------------------------------------------------------ Contacts fields Import ---------------------------------  
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
   AND FieldName IN ('+REPLACE(REPLACE(@ContactFieldName,'[',''''),']','''')+')    
   GROUP BY fkImportId,rowid    
    ) Sub      
    ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid      
    WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''   
   ) st      
    PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @ContactFieldName +')    
   ) as PVT '    
     
 DECLARE @ImportSupContactDetail TABLE  
  (   
  importId UNIQUEIDENTIFIER,SupRowId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,  
  CssClass VARCHAR(100),[Validation] VARCHAR(100),     
  CONTACTFAX VARCHAR(MAX),CONTNOTE VARCHAR(MAX),DEPARTMENT VARCHAR(MAX),EMAIL VARCHAR(MAX),    
  FIRSTNAME VARCHAR(MAX),IsFavourite VARCHAR(MAX),LASTNAME VARCHAR(MAX),MIDNAME VARCHAR(MAX),  
  MOBILE VARCHAR(MAX),NICKNAME VARCHAR(MAX), TITLE VARCHAR(MAX),TYPE VARCHAR(MAX),  
  URL VARCHAR(MAX),WORKPHONE VARCHAR(MAX),WRKEMAIL VARCHAR(MAX)  
 )    
  
 INSERT INTO @ImportSupContactDetail    
 EXEC SP_EXECUTESQL @ContactSQL  
  
   
 ;WITH supImportError AS(  
 SELECT ibf.fkImportId AS ImportId,ibf.rowid as RowId ,idt.SUPID,idt.SUPNAME,'Supplier' AS ErrorRelatedTo,fd.fieldName,ibf.Message   
 FROM ImportFieldDefinitions fd        
   INNER JOIN ImportSupplierFields ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId =  @ModuleId   
   INNER JOIN ImportSupplierHeader h ON h.ImportId = ibf.FkImportId     
   INNER JOIN     
   (     
  SELECT fkImportId,rowid   
  FROM ImportSupplierFields fd    
  INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
  WHERE fkImportId =@importId      
  AND FieldName IN (SELECT F.FIELDNAME FROM ImportFieldDefinitions F WHERE ModuleId = @ModuleId AND SourceTableName ='SUPINFO'  )    
  AND fd.Status = 'i05red'  
  GROUP BY fkImportId,rowid   
    
   ) Sub ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid   
   INNER JOIN @ImportDetail idt on  ibf.fkImportid=idt.ImportId and ibf.rowid=idt.rowid   
   WHERE ibf.Status = 'i05red'  
)  
,  
supAddressError AS(  
 SELECT distinct ibf.fkImportId AS ImportId,ibf.rowid as RowId ,sup.SUPID,sup.SUPNAME,'Address' AS ErrorRelatedTo,idt.RECORDTYPE,idt.SHIPTO,fd.fieldName,ibf.Message   
 FROM ImportFieldDefinitions fd        
   INNER JOIN ImportSupplierAddressField ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId =  @ModuleId   
   INNER JOIN ImportSupplierHeader h ON h.ImportId = ibf.FkImportId     
   INNER JOIN     
   (     
  SELECT fkImportId,rowid   
  FROM ImportSupplierAddressField fd    
  INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
  WHERE fkImportId =@importId      
  AND FieldName IN (SELECT F.FIELDNAME FROM ImportFieldDefinitions F WHERE ModuleId = @ModuleId AND SourceTableName ='shipbill'  )    
  AND fd.Status = 'i05red'  
  GROUP BY fkImportId,rowid   
    
   ) Sub ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid   
   INNER JOIN @ImportSupAddDetail idt on  ibf.fkImportid=idt.ImportId and ibf.rowid=idt.rowid   
   LEFT JOIN supImportError sup on sup.RowId = idt.SupRowId  
   WHERE ibf.Status = 'i05red'  
)  
  
,supContactError AS(  
 SELECT distinct ibf.fkImportId AS ImportId,ibf.rowid as RowId ,sup.SUPID,sup.SUPNAME,'Contact' AS ErrorRelatedTo,idt.FIRSTNAME,idt.LASTNAME,fd.fieldName,ibf.Message   
 FROM ImportFieldDefinitions fd        
   INNER JOIN ImportSupplierContactField ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId =  @ModuleId   
   INNER JOIN ImportSupplierHeader h ON h.ImportId = ibf.FkImportId     
   INNER JOIN     
   (     
  SELECT fkImportId,rowid   
  FROM ImportSupplierContactField fd    
  INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
  WHERE fkImportId =@importId      
  AND FieldName IN (SELECT F.FIELDNAME FROM ImportFieldDefinitions F WHERE ModuleId = @ModuleId AND SourceTableName ='CCONTACT'  )    
  AND fd.Status = 'i05red'  
  GROUP BY fkImportId,rowid   
    
   ) Sub ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid   
   INNER JOIN @ImportSupContactDetail idt on  ibf.fkImportid=idt.ImportId and ibf.rowid=idt.rowid   
   LEFT JOIN supImportError sup on sup.RowId = idt.SupRowId  
   WHERE ibf.Status = 'i05red'  
)  
  
,AllError AS(  
   SELECT SUPID,SUPNAME,ErrorRelatedTo,'' AS RECORDTYPE,'' AS Shipto,'' AS ContactFirstName,'' AS ContactLastName,fieldName,Message FROM supImportError  
  UNION  
   SELECT SUPID,SUPNAME,ErrorRelatedTo,RECORDTYPE,SHIPTO AS Shipto,'' AS ContactFirstName,'' AS ContactLastName,fieldName,Message FROM supAddressError  
  UNION  
   SELECT SUPID,SUPNAME,ErrorRelatedTo,'' AS RECORDTYPE,'' AS Shipto,FIRSTNAME As ContactFirstName,LASTNAME AS ContactLastName,fieldName,Message FROM supContactError  
)  
  
SELECT * FROM AllError ORDER BY SUPID,SUPNAME,ErrorRelatedTo  
  
END 