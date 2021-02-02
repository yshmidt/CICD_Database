-- =====================================================================================    
-- Author  : Sachin B       
-- Date   : 11/18/2019  
-- Description  : This SP is Used for the Insert Customer,Address and its related linking, Its also adds Contact data and its contacts linking with the addresses from import tables to its main table  
-- 01/15/2020 Sachin B Modify SALEDSCTID to SaleDiscountType; to understand the value of SALEDSCTID to the user   
-- 01/15/2020 Sachin B Remove Fax columns from template for customer, contact and ship to address section   
-- 01/15/2020 Sachin B Remove [TYPE] columns from template for customer  
-- 01/15/2020 Sachin B We need to have one column to set default address for bill to ship and bill to contact, ship to contact to in the template  
-- 01/15/2020 Sachin B Some fields are not populating in "CCONTACT" table from customer upload are MOBILE,IsFavourite,[URL],CONTNOTE, WRKEMAIL  
-- 01/15/2020 Sachin B On uploading a customer from customer upload its populating "Null" in save initials column and having no value in aspmnx_UserCustomers table due to that its not displaying on UI    
-- 01/16/2020 Sachin B Linked customer to the user if has restricted to customer otherwise we do not linked customer to the user  
-- 04/15/2020 Sachin B  Add Condtion RECV_DEFA = '1' OR RECV_DEFA = 'true' 
-- 04/23/2020 Satyawan H: Set ELSE 0 If Setting up the default address is handled from Server side code now.
-- EXEC UploadCustomerAndContact '8D695730-C48C-4CAC-A2F3-64ED0EEFD2B3' , '49F80792-E15E-4B62-B720-21B360E3108A'     
--=====================================================================================    
CREATE PROC UploadCustomerAndContact   
 @ImportId UNIQUEIDENTIFIER,  
 @UserId  UNIQUEIDENTIFIER =null   
 AS  
  
BEGIN    
      
SET NOCOUNT ON   
BEGIN TRY                    
BEGIN TRANSACTION --transferTransaction      
   
 --==============================================================================================================================================================================  
-----------------------------------------------------  customer field information and insert data in customer table section -----------------------------------------------------  
--==============================================================================================================================================================================  
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(max),@autoCust BIT, @AddrSQL NVARCHAR(MAX),@lastCustNo CHAR (10)  
 ,@AddressFieldName VARCHAR(max),@ContactSQL NVARCHAR(MAX),@ContactFieldName varchar(max),@ErrorMessage NVARCHAR(4000),@ErrorSeverity INT,@ErrorState INT  
 --Table for the customer fields  
  
 -- 01/15/2020 Sachin B Remove Fax columns from template for customer, contact and ship to address section  
 -- 01/15/2020 Sachin B Modify SALEDSCTID to SaleDiscountType; to understand the value of SALEDSCTID to the user   
 DECLARE @ImportDetail TABLE   
 (  
  importId UNIQUEIDENTIFIER,rowId UNIQUEIDENTIFIER,Ad_link CHAR(10),   
  ACCTSTATUS VARCHAR(MAX), CREDITOK VARCHAR(MAX), CREDLIMIT VARCHAR(MAX), custname VARCHAR(MAX), custno VARCHAR(MAX),   
  LinkAddRef VARCHAR(MAX),PHONE VARCHAR(MAX),[PROFILE] VARCHAR(MAX),  
  RecordNum VARCHAR(MAX), RESL_NO VARCHAR(MAX), SaleDiscountType VARCHAR(MAX), SIC_CODE VARCHAR(MAX), SIC_DESC VARCHAR(MAX), [STATUS] VARCHAR(MAX),  
  TERMS VARCHAR(MAX), TERRITORY VARCHAR(MAX), WebSite VARCHAR(MAX)  
 )   
  
 DECLARE @ImportCustTable TABLE   
 (  
 ImportId UNIQUEIDENTIFIER, RowId UNIQUEIDENTIFIER,CUSTNO CHAR(10)  
 )  
   
 SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc ='MnxM_CustomerContacts'   
    
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
   SELECT ibf.fkImportId AS ImportId,ibf.rowid as RowId  
   ,(SELECT  top 1 Shipbill.LINKADD FROM  shipbill WHERE  Shipbill.recordtype IN ( ''B'', ''S'' ) ) Ad_link  
    ,fd.fieldName,adjusted'  +' FROM ImportFieldDefinitions fd        
   INNER JOIN ImportCustomerFields  ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+    
   ' INNER JOIN importCustomerHeader  h ON h.ImportId = ibf.FkImportId     
   INNER JOIN     
   (     
  SELECT fkImportId,rowid   
  FROM ImportCustomerFields fd    
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
  
 SELECT @autoCust = (  
        SELECT ISNULL(wms.settingValue, mnxS.settingValue)AS settingValue    
        FROM MnxSettingsManagement mnxS   
            LEFT JOIN wmSettingsManagement wms ON mnxS.settingId = wms.settingId   
        WHERE settingName='autoGenerateCustomerNumber'  
      )  
  
 INSERT INTO @ImportDetail   
 EXEC SP_EXECUTESQL @SQL     
 DECLARE @pcNextNumber char(10)    
  
 IF (@autoCust=1)  
  BEGIN  
      DECLARE @CustRowId UNIQUEIDENTIFIER  
  
   DECLARE CustNo_cursor CURSOR LOCAL FAST_FORWARD FOR  
   SELECT rowId FROM @ImportDetail  
  
   OPEN CustNo_cursor;  
   FETCH NEXT FROM CustNo_cursor  
   INTO @CustRowId ;  
  
   WHILE @@FETCH_STATUS = 0  
   BEGIN  
    EXEC [GetNextCustomerNo] @pcNextNumber  OUTPUT  
  
    INSERT INTO @ImportCustTable(ImportId,RowId,CUSTNO )   
    SELECT ImportId, RowId,@pcNextNumber  
    FROM @ImportDetail WHERE rowId =@CustRowId and importId =@ImportId  
  
    FETCH NEXT FROM CustNo_cursor  
    INTO @CustRowId;  
   END;   
   CLOSE CustNo_cursor;  
   DEALLOCATE CustNo_cursor;  
  END  
 ELSE  
  BEGIN  
     INSERT INTO @ImportCustTable(ImportId,RowId,CUSTNO )   
     SELECT ImportId, RowId,RIGHT('0000000000'+CUSTNO,10)  
     FROM @ImportDetail  
  END  
 --select * from @ImportCustTable  
  
 INSERT INTO  CUSTOMER (CUSTNO, CUSTNAME,PHONE, TERRITORY, TERMS,CREDLIMIT,[PROFILE],CUSTNOTE,ACCTSTATUS,CREDITOK,  
     RESL_NO,SIC_CODE,SIC_DESC,[STATUS],SALEDSCTID, WebSite, SAVEINIT)   
 SELECT cust.CUSTNO,CUSTNAME,PHONE, TERRITORY, TERMS, CREDLIMIT, [PROFILE], '' CUSTNOTE, CASE WHEN ACCTSTATUS = '' THEN 'Active' ELSE ACCTSTATUS END  ACCTSTATUS,  
     CREDITOK,RESL_NO,SIC_CODE,SIC_DESC,CASE WHEN [STATUS] = '' THEN 'Active' ELSE [STATUS] END [STATUS],  
     ISNULL((SELECT SALEDSCTID FROM SALEDSCT WHERE SALEDSCTNM = CASE WHEN SaleDiscountType IS NOT NULL THEN (TRIM(SaleDiscountType)) ELSE SaleDiscountType END),'')AS SaleDiscountType,   
     WebSite, (SELECT UserName FROM aspnet_Users WHERE UserId=@UserId)AS SAVEINIT --,CUSTPFX  
 FROM @ImportCustTable cust  
 INNER JOIN @ImportDetail idt   
  ON  cust.ImportId=idt.ImportId AND cust.RowId =idt.RowId    
  
-- 01/16/2020 Sachin B Linked customer to the user if has restricted to customer otherwise we do not linked customer to the user   
-- 01/15/2020 Sachin B On uploading a customer from customer upload its populating "Null" in save initials column and having no value in aspmnx_UserCustomers table due to that its not displaying on UI    
     IF EXISTS (SELECT * FROM aspmnx_UserCustomers WHERE fkUserId=@UserId)  
  BEGIN  
    INSERT INTO aspmnx_UserCustomers (UserCustId, fkUserId, fkCustno)  
  SELECT NEWID() AS UserCustId, @UserId AS fkUserId, cust.CUSTNO fkCustno  
   FROM @ImportCustTable cust  
   INNER JOIN @ImportDetail idt   
   ON  cust.ImportId=idt.ImportId AND cust.RowId =idt.RowId  
  END   
--==============================================================================================================================================================================  
-----------------------------------------------------  Address field information -----------------------------------------------------  
--==============================================================================================================================================================================  
 -- 01/15/2020 Sachin B  Remove Fax columns from template for customer , contact and ship to address section  
 -- 01/15/2020 Sachin B: We need to have one column to set default address for bill to ship and bill to contact, ship to contact to in the template  
 DECLARE @ImportCustAddDetail TABLE   
 (  
  ImportId UNIQUEIDENTIFIER,CustRowId UNIQUEIDENTIFIER, RowId UNIQUEIDENTIFIER, ADDRESS1 VARCHAR(MAX),ADDRESS2 VARCHAR(MAX),CITY VARCHAR(MAX),  
   COUNTRY VARCHAR(MAX), E_MAIL VARCHAR(MAX), FOB VARCHAR(MAX), IsDefaultAddress BIT, [PHONE_S] VARCHAR(MAX),  
   RECORDTYPE VARCHAR(MAX),RECV_DEFA VARCHAR(MAX),SHIP_DAYS VARCHAR(MAX), SHIPTO VARCHAR(MAX),SHIPVIA VARCHAR(MAX),STATE VARCHAR(MAX),  
   ZIP VARCHAR(MAX)  
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
    SELECT ibf.fkImportId AS importId,ibf.CustRowId,ibf.rowid, fd.fieldName,adjusted'+' FROM ImportFieldDefinitions fd        
    INNER JOIN ImportCustomerAddressFields  ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+    
    ' INNER JOIN importCustomerHeader h ON h.ImportId = ibf.FkImportId     
    INNER JOIN     
    (     
   SELECT fkImportId,rowid     
   FROM ImportCustomerAddressFields fd    
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
 INSERT INTO @ImportCustAddDetail     
 EXEC SP_EXECUTESQL @AddrSQL    
  
 DECLARE @ImportCustAddWithUpdatedLinkAddr TABLE   
 (  
  ImportId UNIQUEIDENTIFIER, CustRowId UNIQUEIDENTIFIER, RowId UNIQUEIDENTIFIER, LINKADD VARCHAR(10), CUSTNO VARCHAR(10), RECORDTYPE VARCHAR(1)  
 )   
  
 INSERT INTO @ImportCustAddWithUpdatedLinkAddr  
 SELECT DISTINCT ist.ImportId, icad.CustRowId, icad.RowId, dbo.fn_GenerateUniqueNumber() AS LINKADD, ist.CUSTNO AS CUSTNO, RECORDTYPE  
 FROM @ImportCustAddDetail  icad   
 JOIN @ImportCustTable ist ON icad.ImportId= ist.ImportId AND icad.CustRowId = ist.RowId  
  
 --select * from @ImportCustAddDetail  
 --select * from @ImportCustAddWithUpdatedLinkAddr  
    --SELECT * FROM @ImportCustAddWithUpdatedLinkAddr  
  
 INSERT INTO SHIPBILL   
 (  
  LINKADD, CUSTNO, SHIPTO, ADDRESS1, ADDRESS2, CITY, [STATE], ZIP, COUNTRY, PHONE, E_MAIL,   
  FOB, SHIPVIA, RECORDTYPE, SHIP_DAYS, RECV_DEFA, modifiedDate, IsDefaultAddress    
 )  
  
 SELECT   icla.LINKADD,  icla.CUSTNO, SHIPTO, ADDRESS1, ADDRESS2, CITY, [STATE], ZIP, COUNTRY, icad.PHONE_S, E_MAIL,  
  FOB, SHIPVIA, icla.RECORDTYPE, SHIP_DAYS, 
  -- 04/15/2020 Sachin B  Add Condtion RECV_DEFA = '1' OR RECV_DEFA = 'true' 
   CASE  WHEN RECV_DEFA = 'Y' OR RECV_DEFA = 'YES' OR RECV_DEFA = '1' OR RECV_DEFA = 'true'  THEN 1   
         --WHEN RECV_DEFA = 'N' OR RECV_DEFA = 'NO' THEN 0   
         ELSE 0 END AS RECV_DEFA  ,   
  GETDATE() modifiedDate,  
  CASE WHEN icla.RECORDTYPE='S' --THEN 0 ELSE IsDefaultAddress END IsDefaultAddress  
    THEN 0 ELSE CASE WHEN (icad.IsDefaultAddress = 1)  
       THEN 1   
       ELSE CASE WHEN(checkDefaultBillForCust.Adjusted = 1) THEN 0 ELSE 1 END   
      END   
     END  
 FROM  @ImportCustAddWithUpdatedLinkAddr icla  
  OUTER APPLY  
  (   
   select addFimport.* FROM  ImportCustomerAddressFields addFimport   
   JOIN @ImportCustAddDetail addDet ON addDet.ImportId= addFimport.FkImportId AND addDet.CustRowId = addFimport.CustRowId AND addDet.RowId =addFimport.rowId   
   join ImportFieldDefinitions on FieldDefId=FKFieldDefId  WHERE FKFieldDefId =(SELECT FieldDefId FROM ImportFieldDefinitions WHERE SourceTableName='SHIPBILL' and SourceFieldName='IsDefaultAddress')  
   AND FkImportId=@ImportId AND addFimport.CustRowId =  icla.CustRowId AND Adjusted= '1' AND addDet.SHIPTO<>SHIPTO  
  )checkDefaultBillForCust  
 JOIN @ImportCustAddDetail icad ON icad.ImportId= icla.ImportId AND icad.CustRowId = icla.CustRowId AND icad.RowId =icla.rowId  
  
 ---------------------------------------------------------------- Loop over CUSTOMER to link addresses------------------------------------  
 INSERT INTO ADDRESSLINKTABLE ( ShipConfirmToAddress, BillRemitAddess,  IsDefaultAddress)  
 SELECT t2.LINKADD ShipConfirmToAddress, addressData.LINKADD BillRemitAddess,  
   IsDefaultAddress = CASE WHEN (defaultShipAddrFromTemplate.Adjusted) = 1   
         THEN 1   
         ELSE 0  
    -- 04/23/2020 Satyawan H: Set ELSE 0 If Setting up the default address is handled from Server side code now.
    --CASE WHEN (ISdefaultShipAddrSetForSameBill.Adjusted IS NOT NULL)    
    --         THEN 0 ELSE CASE WHEN (defaultShippingAddress.LINKADD = t2.LINKADD) THEN 1 ELSE 0 END     
    --         END             
        END   
 --(defaultShippingAddress.LINKADD = t2.LINKADD)  
  FROM    
  ImportBillShipAddressLink addrLink       
  INNER JOIN @ImportCustAddWithUpdatedLinkAddr addressData    
   ON  addrLink.FkImportId = addressData.ImportId  AND addrLink.CustRowId=addressData.CustRowId AND  addressData.RowId=addrLink.BillAddressRowId  
        INNER JOIN  
  (  
      SELECT  iclaforShip.LINKADD, ShipAddressRowId, BillAddressRowId  
   FROM ImportBillShipAddressLink addrLink1     
   INNER JOIN @ImportCustAddWithUpdatedLinkAddr iclaforShip    
   ON  addrLink1.FkImportId = iclaforShip.ImportId AND addrLink1.CustRowId=iclaforShip.CustRowId AND  addrLink1.ShipAddressRowId=iclaforShip.RowId    
  ) T2 on addrLink.ShipAddressRowId=T2.ShipAddressRowId   
  OUTER APPLY  
  (      
   SELECT addrLink.*, AddressDetailId, Adjusted, [Status], [Message] FROM ImportBillShipAddressLink addrLink   
   INNER JOIN ImportCustomerAddressFields shipRow   
   ON addrLink.ShipAddressRowId = shipRow.RowId  
   where shipRow.FKFieldDefId = (SELECT FieldDefId FROM ImportFieldDefinitions WHERE SourceTableName='shipbill' AND ModuleId=5 AND FieldName='IsDefaultAddress')  
    AND shipRow.RowId = T2.ShipAddressRowId    
  )defaultShipAddrFromTemplate  
   OUTER APPLY  
  (      
   SELECT distinct shipRow.AddressDetailId, shipRow.Adjusted , shipRow.[Status], shipRow.[Message]   
    FROM ImportBillShipAddressLink addrLink   
    INNER JOIN ImportCustomerAddressFields shipRow ON addrLink.ShipAddressRowId = shipRow.RowId  
    INNER JOIN ImportCustomerAddressFields billRow ON addrLink.BillAddressRowId = billRow.RowId  
    WHERE shipRow.FKFieldDefId = (SELECT FieldDefId FROM ImportFieldDefinitions WHERE SourceTableName='shipbill' AND ModuleId=5 AND FieldName='IsDefaultAddress')   
    AND shipRow.RowId = T2.BillAddressRowId AND shipRow.RowId <> T2.ShipAddressRowId AND shipRow.Adjusted= '1'    
  )ISdefaultShipAddrSetForSameBill  
  OUTER APPLY  
  (  
   SELECT top 1  BillAddressRowId, ShipAddressRowId, iclaforShip.LINKADD  
   FROM ImportBillShipAddressLink addrLink1     
   INNER JOIN @ImportCustAddWithUpdatedLinkAddr iclaforShip    
   ON  addrLink1.FkImportId = iclaforShip.ImportId AND addrLink1.CustRowId=iclaforShip.CustRowId AND  addrLink1.ShipAddressRowId=iclaforShip.RowId    
   WHERE BillAddressRowId =T2.BillAddressRowId  
  ) defaultShippingAddress   
  WHERE  addrLink.FkImportId = @importId   
------------------------------------------------------------------------ Contacts fields Import ---------------------------------  
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
    SELECT ibf.fkImportId AS importId,ibf.CustRowId,ibf.rowid, fd.fieldName,adjusted'      
    +' FROM ImportFieldDefinitions fd        
    INNER JOIN [ImportCustomerContactFields] ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+    
    ' INNER JOIN importCustomerHeader h ON h.ImportId = ibf.FkImportId     
    INNER JOIN     
    (     
   SELECT fkImportId,rowid,MAX(status) as Class ,MIN(Message) as Validation      
   FROM [ImportCustomerContactFields] fd    
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
   -- 01/15/2020 Sachin B Remove Fax columns from template for customer, contact and ship to address section  
   -- 01/15/2020 Sachin B Remove [TYPE] columns from template for customer  
   -- 01/15/2020 Sachin B Remove supplier and contacts Link address and Type fields  
   -- 01/15/2020 Sachin B We need to have one column to set default address for bill to ship and bill to contact, ship to contact to in the template+  
  DECLARE @ImportCustContactDetail TABLE   
  ( ImportId UNIQUEIDENTIFIER, CustRowId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,  
    CONTNOTE VARCHAR(MAX), DEPARTMENT VARCHAR(25), EMAIL VARCHAR(100),    
   FIRSTNAME VARCHAR(50), IsDefaultContact BIT, IsFavourite BIT, LASTNAME VARCHAR(50), MIDNAME VARCHAR(50),  
   MOBILE VARCHAR(25), NICKNAME VARCHAR(50), TITLE VARCHAR(50),  
   [URL] VARCHAR(MAX), WORKPHONE VARCHAR(25), WRKEMAIL VARCHAR(100)  
  )  
      
  INSERT INTO @ImportCustContactDetail    
  EXEC SP_EXECUTESQL @ContactSQL  
  
  DECLARE @nextContactNumber CHAR (10)  
  EXEC GetNextCcontactNumber  @nextContactNumber OUT  
  
  DECLARE @insertedContactData TABLE (CID VARCHAR(10) )  
  
  DECLARE @ImportCustContactWithContactId TABLE   
  (  
   ImportId UNIQUEIDENTIFIER, CustRowId UNIQUEIDENTIFIER, RowId UNIQUEIDENTIFIER, CID VARCHAR(10), CUSTNO VARCHAR(10), [TYPE] VARCHAR(1)  
  )   
  
  INSERT INTO @ImportCustContactWithContactId  
  SELECT DISTINCT iccd.ImportId, iccd.CustRowId, iccd.RowId, CID = RIGHT('0000000000'+ CONVERT(VARCHAR,@nextContactNumber + ROW_NUMBER() OVER (ORDER BY custno)),10),  
   CUSTNO, 'C'  
  FROM @ImportCustContactDetail iccd  
  INNER JOIN @ImportCustTable ict ON iccd.importId= ict.ImportId and iccd.CustRowId = ict.RowId  
  
-- 01/15/2020 Sachin B Some fields are not populating in "CCONTACT" table from customer upload are MOBILE,IsFavourite,[URL],CONTNOTE, WRKEMAIL  
  INSERT INTO CCONTACT   
  (  
   CID, [TYPE], LASTNAME, FIRSTNAME, MIDNAME, NICKNAME, IS_EDITED, CUSTNO, DEPARTMENT, TITLE, WORKPHONE, EMAIL,   
   [STATUS], modifiedDate, IsSynchronizedFlag, FkUserId,  
   Mobile,IsFavourite,url,CONTNOTE, WRKEMAIL  
  )  
  OUTPUT inserted.CID  
  INTO @insertedContactData  
   SELECT icContactId.cid , icContactId.[type], contactDet.LASTNAME, contactDet.FIRSTNAME, contactDet.MIDNAME, contactDet.NICKNAME, '' IS_EDITED,  CUSTNO As CUSTNO,  
   contactDet.DEPARTMENT, contactDet.TITLE, contactDet.WORKPHONE, contactDet.EMAIL,  
   'Active' STATUS, GETDATE(), 0 IsSynchronizedFlag,  NEWID() FkUserId, MOBILE,IsFavourite,[URL],CONTNOTE, WRKEMAIL  
    FROM  @ImportCustContactWithContactId icContactId  
    JOIN @ImportCustContactDetail contactDet ON contactDet.ImportId= icContactId.ImportId AND contactDet.CustRowId = icContactId.CustRowId   
    AND contactDet.RowId =icContactId.rowId AND icContactId.ImportId=@ImportId  
  
  --updating last inserted contact id MicsSys table  
  IF EXISTS(SELECT 1 FROM @insertedContactData)  
  BEGIN  
    UPDATE  MicsSys SET LastCid= (SELECT TOP 1 CID FROM @insertedContactData ORDER BY CID DESC)  
  END   
----------------------------------------------------------------------------------------------------------------------------------------------------------------------  
--------------------------------------------------- Insert Data in the contacts and address linkings --------------------------------------------------------------  
----------------------------------------------------------------------------------------------------------------------------------------------------------------------  
   INSERT INTO BillingContactLink(BillRemitAddess, CID, IsDefaultAddress)  
   SELECT ica.LINKADD, icContactId.CID,  
    IsDefaultAddress = CASE WHEN (ISDefaultBillContFromTemplate.Adjusted IS NOT NULL)    
             THEN 1  
          ELSE CASE WHEN (ISDefaultBillContCheckForAnotherContacts.Adjusted IS NOT NULL)  
            THEN 0  
            ELSE CASE WHEN (ISDefaultBillingContact.CID = icContactId.CID ) THEN 1 ELSE 0 END    
            END  
         END   
   FROM [ImportAddressContactLink] acl   
   INNER JOIN @ImportCustTable ict ON ict.ImportId=acl.FkImportId AND ict.RowId=acl.CustRowId   
   INNER JOIN @ImportCustContactWithContactId icContactId ON icContactId.ImportId=acl.FkImportId AND icContactId.CustRowId=acl.CustRowId AND icContactId.RowId=acl.ContactRowId  
   INNER JOIN @ImportCustAddWithUpdatedLinkAddr ica  ON ica.RowId=acl.AddressRowId AND ica.RecordType='B'  
   INNER JOIN @ImportCustAddDetail icad ON icad.ImportId=acl.FkImportId  AND icad.RowId=acl.AddressRowId  
    OUTER APPLY(    
      SELECT contFields.* FROM [ImportAddressContactLink] addContLnk  
      INNER JOIN ImportCustomerContactFields contFields ON addContLnk.ContactRowId = contFields.RowId  
       AND FKFieldDefId=(SELECT FieldDefId FROM ImportFieldDefinitions WHERE FieldName ='IsDefaultContact')      
      WHERE addContLnk.FkImportId=@ImportId  AND addContLnk.ContactRowId = acl.ContactRowId  AND Adjusted='1' --AND RecordType='B'        
   )ISDefaultBillContFromTemplate  
     
   OUTER APPLY  
    (  
     SELECT contFields.* FROM [ImportAddressContactLink] addContLnk  
      INNER JOIN ImportCustomerContactFields contFields ON addContLnk.ContactRowId = contFields.RowId and addContLnk.CustRowId=contFields.CustRowId  
        AND FKFieldDefId=(SELECT FieldDefId FROM ImportFieldDefinitions WHERE FieldName ='IsDefaultContact')  
      --INNER JOIN @ImportCustAddDetail icad ON icad.ImportId=addContLnk.FkImportId  AND icad.RowId=addContLnk.AddressRowId and addContLnk.CustRowId=contFields.CustRowId AND icad.RecordType='B'  
      WHERE addContLnk.FkImportId=@ImportId  AND addContLnk.AddressRowId = icad.RowId AND Adjusted='1'   
      AND addContLnk.ContactRowId<>icContactId.RowId  
  
   )ISDefaultBillContCheckForAnotherContacts  
   OUTER APPLY(  
    SELECT TOP 1 icContactId.CID  
    FROM [ImportAddressContactLink] acl   
    INNER JOIN @ImportCustTable ict ON ict.ImportId=acl.FkImportId AND ict.RowId=acl.CustRowId   
    INNER JOIN @ImportCustContactWithContactId icContactId ON icContactId.ImportId=acl.FkImportId AND icContactId.CustRowId=acl.CustRowId AND icContactId.RowId=acl.ContactRowId  
    INNER JOIN @ImportCustAddWithUpdatedLinkAddr custAdd  ON custAdd.RowId=acl.AddressRowId AND custAdd.RecordType='B' and custAdd.LINKADD= ica.LINKADD ORDER BY LINKADD, CID  
   )ISDefaultBillingContact  
-------------------------------------- Insert data in ShipingContactLink table ----------------------------------------------------------------------------------------------  
  INSERT INTO ShipingContactLink( ShipConfirmAddess, CID, IsDefaultAddress)   
  SELECT DISTINCT ica.LINKADD, icContactId.CID,  
     IsDefaultAddress =CASE WHEN (ISDefaultSHIPContFromTemplate.Adjusted IS NOT NULL)    
             THEN 1 ELSE 0  
         END   
      --CASE WHEN (ISDefaultShippingContact.CID = icContactId.CID) THEN 1 ELSE 0 END       
   FROM [ImportAddressContactLink] acl   
   INNER JOIN @ImportCustTable ict ON ict.ImportId=acl.FkImportId AND ict.RowId=acl.CustRowId   
   INNER JOIN @ImportCustContactWithContactId icContactId ON icContactId.ImportId=acl.FkImportId AND icContactId.CustRowId=acl.CustRowId AND icContactId.RowId=acl.ContactRowId  
   INNER JOIN @ImportCustAddWithUpdatedLinkAddr ica  ON ica.RowId=acl.AddressRowId AND ica.RecordType='S'  
   -- INNER JOIN @ImportCustAddDetail icad ON icad.ImportId=acl.FkImportId  AND icad.RowId=acl.AddressRowId --AND  acl.CustRowId=  acad.CustRowId  
   OUTER APPLY(    
      SELECT contFields.* FROM [ImportAddressContactLink] addContLnk  
      INNER JOIN ImportCustomerContactFields contFields ON addContLnk.ContactRowId = contFields.RowId  
       AND FKFieldDefId=(SELECT FieldDefId FROM ImportFieldDefinitions WHERE FieldName ='IsDefaultContact')      
      WHERE addContLnk.FkImportId=@ImportId  AND addContLnk.ContactRowId = acl.ContactRowId  AND Adjusted='1' --AND RecordType='B'        
   )ISDefaultSHIPContFromTemplate  
------------------------------------------------------------------------     END Address contact linking section --------------------------------------------------------------  
COMMIT TRANSACTION                              
END TRY              
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