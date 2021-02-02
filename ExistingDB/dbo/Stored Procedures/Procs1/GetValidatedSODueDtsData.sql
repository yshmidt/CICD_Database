-- ============================================================================================================  
-- Date   : 09/27/2019  
-- Author  : Mahesh B	
-- Description : Used for Get Validated Due dates data
-- GetValidatedSODueDtsData '37EF77FE-6011-485E-81B4-EE5942D418EE'
-- ============================================================================================================  
CREATE PROC GetValidatedSODueDtsData    
 @ImportId UNIQUEIDENTIFIER
AS  
BEGIN
SELECT  PVT.importId,PVT.FKSODetailRowId
  ,TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, PVT.SONO),10)))) AS SONO
  ,CASE WHEN (ISNULL(PVT.Commit_Dts,'') = '') THEN PVT.Due_Dts ELSE PVT.Commit_Dts END AS COMMIT_DTS
  ,CASE WHEN (ISNULL(PVT.Ship_Dts,'') = '')  THEN PVT.Due_Dts ELSE PVT.Ship_Dts  END AS SHIP_DTS
  ,PVT.Due_Dts  AS DUE_DTS
  ,PVT.Qty  AS Qty
  FROM    
  ( SELECT isom.fkImportId AS importId,idts.FKSODetailRowId,idts.RowId,Sub.class AS CssClass,Sub.Validation,fd.fieldName,idts.adjusted 
	FROM ImportFieldDefinitions fd      
    INNER JOIN ImportSODueDtsFields idts ON fd.FieldDefId = idts.FKFieldDefId 
	INNER JOIN ImportSODetailFields idtl ON idtl.RowId=idts.FKSODetailRowId
	INNER JOIN ImportSOMainFields isom ON isom.RowId=idtl.SOMainRowId
	INNER JOIN   
	   (   
			SELECT iso.fkImportId,fd.FKSODetailRowId,fd.RowId,MAX(fd.Status) AS Class ,MIN(fd.Message) as Validation		
			FROM ImportSODueDtsFields fd  
				INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId 
				INNER JOIN ImportSODetailFields isdt ON isdt.RowId=fd.FKSODetailRowId
				INNER JOIN ImportSOMainFields iso ON iso.RowId=isdt.SOMainRowId  
			WHERE iso.fkImportId =  @ImportId
				AND FieldName IN ('SONO','Commit_Dts','Ship_Dts','Due_Dts','Qty')
				GROUP BY iso.fkImportId,fd.FKSODetailRowId ,fd.RowId
				HAVING MAX(fd.STATUS) <> 'i05red'
	   ) Sub    
    ON isom.fkImportid=Sub.FkImportId AND idts.FKSODetailRowId=Sub.FKSODetailRowId
    WHERE isom.fkImportId = @ImportId
  ) st    
  PIVOT (MAX(adjusted) FOR fieldName IN (SONO,Commit_Dts,Ship_Dts,Due_Dts,Qty)) AS PVT 
END