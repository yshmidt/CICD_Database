  -- ============================================================================================================    
-- Date   : 08/21/2019    
-- Author  : Rajendra K   
-- Description : Used for get Assembly upload data    
-- GetAssemblyRecords  '01D2A63A-3D84-47D2-B08E-38A7497D7020'
-- ============================================================================================================      
CREATE PROC GetAssemblyRecords    
 @ImportId UNIQUEIDENTIFIER    
AS    
BEGIN  
SET NOCOUNT ON   
     
SELECT PVT.*   
INTO #AssemblyData   
FROM      
  (  
    SELECT ibf.fkImportId AS importId  
    ,ibf.AssemblyRowId  
    ,sub.class AS CssClass  
    ,sub.Validation  
    ,fd.fieldName  
    ,adjusted   
 FROM ImportFieldDefinitions fd        
   INNER JOIN ImportBOMToKitAssemly ibf ON fd.FieldDefId = ibf.FKFieldDefId   
   INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId     
   INNER JOIN     
   (     
     SELECT fkImportId,AssemblyRowId,MAX(status) AS Class ,MIN(Message) AS Validation    
     FROM ImportBOMToKitAssemly fd    
      INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
     WHERE fkImportId = @ImportId    
      AND FieldName IN ('assyDesc','assyNum','assypartclass','assyparttype','assyRev','custno')    
     GROUP BY fkImportId,AssemblyRowId    
   ) Sub   
 ON ibf.fkImportid=Sub.FkImportId and ibf.AssemblyRowId=sub.AssemblyRowId     
 WHERE ibf.fkImportId = @ImportId      
  ) st      
   PIVOT (MAX(adjusted) FOR fieldName IN ([assyDesc],[assyNum],[assypartclass],[assyparttype],[assyRev],[custno])) AS PVT   
  
   SELECT A.importId
		,A.AssemblyRowId
		,A.CssClass
		,A.Validation
		,A.assyDesc
		,A.assyNum
		,A.assypartclass
		,A.assyparttype
		,A.assyRev
		,CASE WHEN A.custno IS NULL OR A.custno <> '' THEN RIGHT('0000000000'+ CONVERT(VARCHAR,A.custno),10) ELSE '' END AS custno
		,I.UNIQ_KEY  
   FROM #AssemblyData A   
  LEFT JOIN INVENTOR I ON TRIM(PART_NO) = TRIM(A.assyNum) AND TRIM(REVISION) = TRIM(A.assyRev) AND  PART_SOURC = 'MAKE'  
  -- AND TRIM(I.CUSTNO) =  RIGHT('0000000000'+ CONVERT(VARCHAR,A.custno),10)  
END