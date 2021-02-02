-- =====================================================================================  
-- Author  : Sachin B     
-- Date   : 11/20/2019
-- Description  : This SP is used for Get the customer imports Error
-- EXEC GetCustomerImportErrors 'BC06E36D-8116-4041-A79B-B2C235764291'
-- =====================================================================================  
CREATE PROC GetCustomerImportErrors  
 @ImportId UNIQUEIDENTIFIER
 
AS
BEGIN  
    
 SET NOCOUNT ON  

  DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@autoSup BIT, @AddrSQL NVARCHAR(MAX),@FieldName NVARCHAR(MAX),@AddressFieldName NVARCHAR(MAX)

   -- Insert statements for procedure here    
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

  DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,rowId UNIQUEIDENTIFIER, Ad_link VARCHAR(MAX) , 
		ACCTSTATUS VARCHAR(MAX), CREDITOK VARCHAR(MAX), CREDLIMIT VARCHAR(MAX), custname VARCHAR(MAX), custno VARCHAR(MAX), 
		LinkAddRef VARCHAR(MAX),PHONE VARCHAR(MAX),[PROFILE] VARCHAR(MAX),
		RecordNum VARCHAR(MAX), RESL_NO VARCHAR(MAX), SaleDiscountType VARCHAR(MAX), SIC_CODE VARCHAR(MAX), SIC_DESC VARCHAR(MAX), [STATUS] VARCHAR(MAX),
		TERMS VARCHAR(MAX), TERRITORY VARCHAR(MAX), WebSite VARCHAR(MAX)) 

  SELECT @SQL = N'    
  SELECT PVT.*  
  FROM    
  (  
   SELECT ibf.fkImportId AS ImportId,ibf.rowid as RowId
   ,(SELECT  top 1 Shipbill.linkadd FROM  shipbill   WHERE Shipbill.custno ='''' AND  (Shipbill.recordtype = ''S'' OR Shipbill.recordtype = ''B'' )  ) Ad_link
    ,fd.fieldName,adjusted'  +' FROM ImportFieldDefinitions fd      
   INNER JOIN ImportCustomerFields ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+  
   ' INNER JOIN importCustomerHeader h ON h.ImportId = ibf.FkImportId   
   INNER JOIN   
   (   
		SELECT fkImportId,rowid 
		FROM ImportCustomerFields fd  
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
	DECLARE @ImportCustAddDetail TABLE 
	(
		importId UNIQUEIDENTIFIER,CustRowId UNIQUEIDENTIFIER, RowId UNIQUEIDENTIFIER, 
		ADDRESS1 VARCHAR(MAX),ADDRESS2 VARCHAR(MAX),CITY VARCHAR(MAX),
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
	   INNER JOIN [ImportCustomerAddressFields] ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+  
	   ' INNER JOIN importCustomerHeader h ON h.ImportId = ibf.FkImportId   
	   INNER JOIN   
	   (   
			SELECT fkImportId,rowid   
			FROM [ImportCustomerAddressFields] fd  
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
	INSERT INTO @ImportCustAddDetail  
	EXEC SP_EXECUTESQL @AddrSQL  

	--select * from @ImportCustAddDetail

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

	  --sub.class as CssClass,sub.Validation,
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
			FROM ImportCustomerContactFields fd  
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

		DECLARE @ImportCustContactDetail TABLE 
		(	ImportId UNIQUEIDENTIFIER, CustRowId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,
		    CONTNOTE VARCHAR(MAX), DEPARTMENT VARCHAR(25), EMAIL VARCHAR(100),  
			FIRSTNAME VARCHAR(50), IsDefaultContact BIT,  IsFavourite BIT, LASTNAME VARCHAR(50), MIDNAME VARCHAR(50),
			MOBILE VARCHAR(25), NICKNAME VARCHAR(50), TITLE VARCHAR(50),
			[URL] VARCHAR(MAX), WORKPHONE VARCHAR(25), WRKEMAIL VARCHAR(100)
		)	

	INSERT INTO @ImportCustContactDetail  
	EXEC SP_EXECUTESQL @ContactSQL

 
 ;WITH custImportError AS(
	SELECT ibf.fkImportId AS ImportId,ibf.rowid as RowId ,idt.custno,idt.custname,'customer' AS ErrorRelatedTo,fd.fieldName,ibf.Message 
	FROM ImportFieldDefinitions fd      
   INNER JOIN ImportCustomerFields ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId =  @ModuleId 
   INNER JOIN importCustomerHeader h ON h.ImportId = ibf.FkImportId   
   INNER JOIN   
   (   
		SELECT fkImportId,rowid 
		FROM ImportCustomerFields fd  
		INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
		WHERE fkImportId =@importId    
		AND FieldName IN (SELECT F.FIELDNAME FROM ImportFieldDefinitions F WHERE ModuleId = @ModuleId AND SourceTableName ='customer'  )  
		AND fd.Status = 'i05red'
		GROUP BY fkImportId,rowid 
		
   ) Sub ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid 
   INNER JOIN @ImportDetail idt on  ibf.fkImportid=idt.ImportId and ibf.rowid=idt.rowid 
   WHERE ibf.Status = 'i05red'
)
,
custAddressError AS(
	SELECT distinct ibf.fkImportId AS ImportId,ibf.rowid as RowId ,cust.custno,cust.custname,'Address' AS ErrorRelatedTo,idt.RECORDTYPE,idt.SHIPTO,fd.fieldName,ibf.Message 
	FROM ImportFieldDefinitions fd      
   INNER JOIN [ImportCustomerAddressFields] ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId =  @ModuleId 
   INNER JOIN importCustomerHeader h ON h.ImportId = ibf.FkImportId   
   INNER JOIN   
   (   
		SELECT fkImportId,rowid 
		FROM [ImportCustomerAddressFields] fd  
		INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
		WHERE fkImportId =@importId    
		AND FieldName IN (SELECT F.FIELDNAME FROM ImportFieldDefinitions F WHERE ModuleId = @ModuleId AND SourceTableName ='shipbill'  )  
		AND fd.Status = 'i05red'
		GROUP BY fkImportId,rowid 
		
   ) Sub ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid 
   INNER JOIN @ImportCustAddDetail idt on  ibf.fkImportid=idt.ImportId and ibf.rowid=idt.rowid 
   LEFT JOIN custImportError cust on cust.RowId = idt.CustRowId
   WHERE ibf.Status = 'i05red'
)

,custContactError AS(
	SELECT distinct ibf.fkImportId AS ImportId,ibf.rowid as RowId ,cust.custno,cust.custname,'Contact' AS ErrorRelatedTo, idt.FIRSTNAME,idt.LASTNAME,fd.fieldName,ibf.Message 
	FROM ImportFieldDefinitions fd      
   INNER JOIN [ImportCustomerContactFields] ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId =  @ModuleId 
   INNER JOIN importCustomerHeader h ON h.ImportId = ibf.FkImportId   
   INNER JOIN   
   (   
		SELECT fkImportId,rowid 
		FROM [ImportCustomerContactFields] fd  
		INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
		WHERE fkImportId =@importId    
		AND FieldName IN (SELECT F.FIELDNAME FROM ImportFieldDefinitions F WHERE ModuleId = @ModuleId AND SourceTableName ='CCONTACT'  )  
		AND fd.Status = 'i05red'
		GROUP BY fkImportId,rowid 
		
   ) Sub ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid 
   INNER JOIN @ImportCustContactDetail idt on  ibf.fkImportid=idt.ImportId and ibf.rowid=idt.rowid 
   LEFT JOIN custImportError cust on cust.RowId = idt.CustRowId
   WHERE ibf.Status = 'i05red'
)

,AllError AS(
   SELECT custno,custname,ErrorRelatedTo,'' AS RECORDTYPE,'' AS Shipto,'' AS ContactFirstName,'' AS ContactLastName,fieldName,Message FROM custImportError
  UNION
   SELECT custno,custname,ErrorRelatedTo,RECORDTYPE,SHIPTO AS Shipto,'' AS ContactFirstName,'' AS ContactLastName,fieldName,Message FROM custAddressError
  UNION
   SELECT custno,custname,ErrorRelatedTo,'' AS RECORDTYPE,'' AS Shipto,FIRSTNAME As ContactFirstName,LASTNAME AS ContactLastName,fieldName,Message FROM custContactError
)

SELECT * FROM AllError ORDER BY custno,custname,ErrorRelatedTo

END  