  -- ============================================================================================================  
-- Date   : 08/21/2019  
-- Author  : Rajendra K 
-- Description : Used for get Assembly upload data  
-- GetValidAssemblyRecords '377A0964-424F-4F51-B832-2DE35242CB18'  
-- ============================================================================================================    
CREATE PROC GetValidAssemblyRecords  
 @ImportId UNIQUEIDENTIFIER  

AS
SET NOCOUNT ON; 

BEGIN
SELECT Pvt.importId,Pvt.AssemblyRowId,Pvt.CssClass,Pvt.Validation,Pvt.custno,Pvt.assyDesc,pvt.assyNum,pvt.assyRev,pvt.assypartclass,Pvt.assyparttype
FROM        
(
  SELECT ibf.fkImportId AS importId,ibf.AssemblyRowId,sub.class as CssClass,sub.Validation,fd.fieldName,adjusted 
  FROM ImportFieldDefinitions fd      
     INNER JOIN ImportBOMToKitAssemly ibf ON fd.FieldDefId = ibf.FKFieldDefId 
     INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId        
	INNER JOIN 
	(
			SELECT fkImportId,AssemblyId,MAX(STATUS) as Class ,MIN(MESSAGE) AS VALIDATION      
			FROM ImportBOMToKitAssemly rf
			inner join ImportFieldDefinitions ifd on ifd.FieldDefId = rf.FKFieldDefId
			WHERE ifd.FieldName IN ('assyDesc','assyNum','assypartclass','assyparttype','assyRev','custno') 
			AND fkImportId = @Importid    
			GROUP BY fkImportId,AssemblyId
			HAVING MAX(STATUS) <> 'i05red'
	) Sub    
	ON ibf.fkImportid=Sub.FkImportId and ibf.AssemblyId=sub.AssemblyId        
	WHERE ibf.fkImportId = @Importid        
) st        
PIVOT (MAX(adjusted) FOR fieldName IN (assyDesc,assyNum,assypartclass,assyparttype,assyRev,custno)) AS PVT
END 