 -- ============================================================================================================  
-- Date   : 10/14/2019  
-- Author  : Rajendra K 
-- Description : Used for to get Components upload data  
-- GetComponentsAllData 'C8D6E832-8C19-412A-A67F-E1379A49A1C4'   
-- ============================================================================================================    
CREATE PROC GetComponentsAllData  
 @ImportId UNIQUEIDENTIFIER
AS  
SET NOCOUNT ON   

BEGIN
SELECT PVT.importId
		,PVT.AssemblyRowId
		,CompRowId
		,PVT.CssClass
		,PVT.Validation
		,CAST(itemno AS INT) AS itemno
		,partSource
		,partno
		,rev
		,PVT.custPartNo
		,crev
		,CAST(qty AS NUMERIC(9,2)) AS Qty
		,bomNote
		,workCenter
		,CASE WHEN used IN ('n','no','0','false') THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS used  
FROM    
  (   
   SELECT Sub.fkImportId AS importId,Sub.AssemblyRowId,ic.CompRowId,sub.class as CssClass,sub.Validation,fd.fieldName,ic.Adjusted 
   FROM ImportFieldDefinitions fd      
	 INNER JOIN ImportBOMToKitComponents ic ON fd.FieldDefId = ic.FKFieldDefId   
	 INNER JOIN   
	   (   
			SELECT fkImportId,AssemblyRowId,CompRowId,MAX(ic.status) as Class ,MIN(ic.Message) as Validation		
			FROM ImportBOMToKitAssemly fd  
				INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
				INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId   
			WHERE fkImportId =@ImportId
				AND FieldName IN ('bomNote','crev','custPartNo','itemno','partno','partSource','qty','rev','used','workCenter')
			GROUP BY fkImportId,CompRowId,AssemblyRowId
	   ) Sub    
   ON  ic.CompRowId = sub.CompRowId    
   WHERE Sub.fkImportId =@ImportId
  ) st    
   PIVOT (MAX(Adjusted) FOR fieldName IN ([bomNote],[crev],[custPartNo],[itemno],[partno],[partSource],[qty],[rev],[used],[workCenter])) as PVT 
END