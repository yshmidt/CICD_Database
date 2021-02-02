 -- ============================================================================================================  
-- Date   : 08/27/2019  
-- Author  : Rajendra K 
-- Description : Used for get reference designator upload data  
-- GetRefDesignatorUploadData 'DF645959-80FE-49C5-A2AB-5B503E90CFCB','F0177D7F-3536-4E31-813D-326A9A4A1B75','C0782822-0FAF-4985-BE36-1284BE5AA657'
-- ============================================================================================================    
CREATE PROC GetRefDesignatorUploadData  
 @ImportId UNIQUEIDENTIFIER,
 @CompRowId UNIQUEIDENTIFIER = NULL,  
 @RefDesRowId UNIQUEIDENTIFIER = NULL,
 @IsError BIT = 0 
AS 

SET NOCOUNT ON     
BEGIN    
  SELECT PVT.* 
  INTO #RefData 
  FROM    
	  (   
	   SELECT ibf.fkImportId AS importId,ibf.AssemblyRowId,ic.CompRowId,ia.RefDesRowId,sub.class as CssClass,sub.Validation,fd.fieldName,ia.Adjusted 
	   FROM ImportFieldDefinitions fd 
		 INNER JOIN ImportBOMToKitRefDesg ia ON fd.FieldDefId = ia.FKFieldDefId     
		 INNER JOIN ImportBOMToKitComponents ic ON ia.FKCompRowId = ic.CompRowId
		 INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId
		 INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId     
		 INNER JOIN   
		   (   
				SELECT fkImportId,AssemblyRowId,CompRowId,RefDesRowId,MAX(ia.status) as Class ,MIN(ia.Message) as Validation		
				FROM ImportBOMToKitAssemly fd  
					INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
					INNER JOIN ImportBOMToKitRefDesg ia ON ic.CompRowId = ia.FKCompRowId
					INNER JOIN ImportFieldDefinitions ibf ON ia.FKFieldDefId = ibf.FieldDefId   
				WHERE fkImportId = @ImportId
					AND FieldName IN ('refdesg') 
					AND ia.Status = (CASE WHEN @IsError = 1 THEN ia.Status ELSE '' END)
				GROUP BY fkImportId,AssemblyRowId,CompRowId,RefDesRowId 
		   ) Sub    
	   ON ibf.fkImportid=Sub.FkImportId and ia.RefDesRowId = sub.RefDesRowId 
	   WHERE ibf.fkImportId = @ImportId
	  ) st    
	   PIVOT (MAX(Adjusted) FOR fieldName IN ([refdesg]) 
	  ) as PVT
  WHERE (@RefDesRowId IS NULL OR @RefDesRowId  = RefDesRowId) AND (@CompRowId IS NULL OR @CompRowId  = CompRowId) 

SELECT *,ROW_NUMBER() OVER(PARTITION BY CompRowId ORDER BY refdesg) AS Nbr  FROM #RefData

END