-- ============================================================================================================  
-- Date   : 09/24/2019  
-- Author  : Mahesh B	
-- Description : Used for Get Validated SOMain data
-- GetValidatedSOMainData   '2E678C7C-B1AF-42D4-B703-0F04E2150D9A'
-- ============================================================================================================  
CREATE PROC GetValidatedSOMainData  
 @ImportId UNIQUEIDENTIFIER
AS  
BEGIN       
  SELECT PVT.importId
		, PVT.RowId
		, TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, PVT.CustNo),10))))  AS CustNo
		, (CASE WHEN (ISNULL(PVT.Contact_Name,'') ='') THEN '' ELSE 
			CASE WHEN (ISNULL((SELECT CID FROM  CCONTACT WHERE TRIM(LASTNAME+','+FIRSTNAME) = PVT.Contact_Name),'')='') THEN '' ELSE
			(SELECT CID FROM  CCONTACT WHERE TRIM(LASTNAME+','+FIRSTNAME) = PVT.Contact_Name) END END) AS Contact_Name
		, TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, PVT.SONO),10))))  AS SONO
		, CASE WHEN (PVT.OrderDate ='' OR  PVT.OrderDate IS NULL) THEN CONVERT(VARCHAR, CAST(CAST(GETDATE() AS DATE) AS SMALLDATETIME),25) ELSE PVT.OrderDate END AS OrderDate
  FROM    
  (  
     SELECT so.fkImportId AS importId,so.RowId,Sub.class AS CssClass,Sub.Validation,fd.fieldName,so.adjusted
	 FROM ImportFieldDefinitions fd
     INNER JOIN ImportSOMainFields so ON so.FKFieldDefId=fd.FieldDefId
     INNER JOIN ImportSOUploadHeader h ON h.ImportId = so.FkImportId   
	 INNER JOIN   
	   (   
			SELECT fd.FkImportId,fd.RowId,MAX(fd.Status) AS Class ,MIN(fd.Message) AS Validation		
			FROM ImportSOMainFields fd  
				INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId 
				INNER JOIN ImportSOUploadHeader h ON h.ImportId=fd.FkImportId
			WHERE  fd.fkImportId = @ImportId
				AND FieldName IN ('CustNo','Contact_Name','SONO','OrderDate')  
				GROUP BY fd.fkImportId,fd.RowId
				HAVING MAX(fd.STATUS) <> 'i05red'
	   ) Sub    
    ON so.fkImportid=Sub.FkImportId AND so.RowId=Sub.RowId   
    WHERE so.fkImportId = @ImportId
  ) st    
  PIVOT (MAX(adjusted) FOR fieldName IN (CustNo,Contact_Name,SONO,OrderDate)) AS PVT 
END