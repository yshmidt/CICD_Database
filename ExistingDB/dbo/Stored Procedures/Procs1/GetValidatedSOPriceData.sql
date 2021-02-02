-- ============================================================================================================  
-- Date   : 09/27/2019  
-- Author  : Mahesh B	
-- Description : Used for Get Validated Price data
-- GetValidatedSOPriceData    'B309D81F-285A-42CD-89E8-2ACA8D2AB182'  
-- ============================================================================================================  
CREATE PROC GetValidatedSOPriceData    
 @ImportId UNIQUEIDENTIFIER
AS  
BEGIN
SELECT  PVT.importId,PVT.FKSODetailRowId
,TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, PVT.SONO),10)))) AS SONO
,CASE WHEN (ISNULL(PVT.Price,'')='') THEN 0 ELSE CAST(PVT.Price AS DECIMAL(13,5)) END AS Price
,CASE WHEN (ISNULL(PVT.Qty,'')='') THEN 0 ELSE CAST(PVT.Qty AS DECIMAL(13,2)) END Qty
,PVT.SaleTypeId,PVT.Taxable
  FROM
  ( SELECT isom.fkImportId AS importId,idts.FKSODetailRowId,Sub.class AS CssClass,Sub.Validation,fd.fieldName,idts.adjusted 
	FROM ImportFieldDefinitions fd      
    INNER JOIN ImportSOPriceFields idts ON fd.FieldDefId = idts.FKFieldDefId 
	INNER JOIN ImportSODetailFields idtl ON idtl.RowId=idts.FKSODetailRowId
	INNER JOIN ImportSOMainFields isom ON isom.RowId=idtl.SOMainRowId
	INNER JOIN   
	   (   
			SELECT iso.fkImportId,fd.RowId,MAX(fd.Status) AS Class ,MIN(fd.Message) AS Validation		
			FROM ImportSOPriceFields fd  
				INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId 
				INNER JOIN ImportSODetailFields isdt ON isdt.RowId=fd.FKSODetailRowId
				INNER JOIN ImportSOMainFields iso ON iso.RowId=isdt.SOMainRowId  
			WHERE iso.fkImportId =   @ImportId
				AND FieldName IN ('SONO','Price','Qty','SaleTypeId','Taxable')
				GROUP BY iso.fkImportId,fd.RowId  
				HAVING MAX(fd.STATUS) <> 'i05red'
	   ) Sub    
    ON isom.fkImportid=Sub.FkImportId AND idts.RowId=Sub.RowId
    WHERE isom.fkImportId = @ImportId
  ) st    
  PIVOT (MAX(adjusted) FOR fieldName IN (SONO,Price,Qty,SaleTypeId,Taxable)) AS PVT 
END