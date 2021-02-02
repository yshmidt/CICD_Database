 -- ============================================================================================================  
-- Date   : 08/27/2019  
-- Author  : Rajendra K 
-- Description : Used for get Components upload data  
-- 09/30/2019 Rajendra k : Added case satatment when woek center is null or blank to get as 'STAG'
-- 10/03/2019 Rajendra k  : Changed table CTE to Temp And removed joins
-- 12/26/2019 Rajendra k  : Added useipkey and serialyes in selection list
-- GetManufactureUploadData 'F4508CF6-D038-492F-A687-1111E9009C65' ,0 
-- ============================================================================================================    
CREATE PROC GetManufactureUploadData		
 @ImportId UNIQUEIDENTIFIER,  
 @IsManufact BIT = 0
AS  
SET NOCOUNT ON   

BEGIN -- 10/03/2019 Rajendra k  : Changed table CTE to Temp And removed joins
--;with ComponentsData AS(
  SELECT PVT.*  
  INTO #ComponentsData
  FROM    
    (   
     SELECT Sub.fkImportId AS importId,Sub.AssemblyRowId,ic.CompRowId,sub.class AS CssClass,sub.Validation,fd.fieldName,ic.Adjusted 
     FROM ImportFieldDefinitions fd      
  	   INNER JOIN ImportBOMToKitComponents ic ON fd.FieldDefId = ic.FKFieldDefId
       --INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId
       --INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId     
  	   INNER JOIN   
  	   (   
  			SELECT fkImportId,CompRowId,AssemblyRowId,MAX(ic.status) AS Class ,MIN(ic.Message) AS Validation		
  			FROM ImportBOMToKitAssemly fd  
  				INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
  				INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId   
  			WHERE fkImportId = @ImportId 
  				AND FieldName IN ('bomNote','crev','custPartNo','itemno','partno','partSource','qty','rev','used','workCenter')
  			GROUP BY fkImportId,CompRowId,AssemblyRowId 
  	   ) Sub    
     ON ic.CompRowId = sub.CompRowId    
     WHERE Sub.fkImportId = @ImportId    
    ) st    
     PIVOT (MAX(Adjusted) FOR fieldName IN ([bomNote],[crev],[custPartNo],[itemno],[partno],[partSource],[qty],[rev],[used],[workCenter])) AS PVT 
--)
--, manufactData AS(
  SELECT PVT.*  
  INTO #manufactData
  FROM    
    ( 
     SELECT Sub.fkImportId AS importId,Sub.AssemblyRowId,Sub.CompRowId,ia.AvlRowId,sub.class AS CssClass,sub.Validation,fd.fieldName,ia.Adjusted 
     FROM ImportFieldDefinitions fd 
	 INNER JOIN ImportBOMToKitAvls ia ON fd.FieldDefId = ia.FKFieldDefId     
	 --INNER JOIN ImportBOMToKitComponents ic ON ia.FKCompRowId = ic.CompRowId
  --   INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId
  --   INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId     
	 INNER JOIN   
	   (   
			SELECT fkImportId,AssemblyRowId,CompRowId,AvlRowId,MAX(ia.status) AS Class ,MIN(ia.Message) AS Validation		
			FROM ImportBOMToKitAssemly fd  
				INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
				INNER JOIN ImportBOMToKitAvls ia ON ic.CompRowId = ia.FKCompRowId
				INNER JOIN ImportFieldDefinitions ibf ON ia.FKFieldDefId = ibf.FieldDefId   
			WHERE fkImportId = @ImportId 
				AND FieldName IN ('partMfg','mpn','ResQty') 
				OR (FieldName = CASE WHEN @IsManufact = 0 THEN 'Location' ELSE '' END 
				OR (FieldName = CASE WHEN @IsManufact = 0 THEN 'Warehouse' ELSE '' END))
			GROUP BY fkImportId,AssemblyRowId,CompRowId,AvlRowId 
	   ) Sub    
   ON ia.AvlRowId = sub.AvlRowId --AND ibf.fkImportid=Sub.FkImportId  AND ia.FKCompRowId = sub.CompRowId
   WHERE Sub.fkImportId = @ImportId    
  ) st    
   PIVOT (MAX(Adjusted) FOR fieldName IN ([partMfg],[mpn],[Warehouse],[Location],[ResQty])   
  ) AS PVT
--)
   SELECT D.*
	,I.UNIQ_KEY
	,C.partno
	,c.rev
	,c.custPartNo
	,c.crev
	,ISNULL(P.LOTDETAIL,CAST(0 AS BIT)) AS IsLotted    	-- 09/30/2019 Rajendra k : Added case satatment when woek center is null or blank to get as 'STAG'
	,CASE WHEN c.workCenter = '' THEN 'STAG' ELSE c.workCenter END AS workCenter
	,I.useipkey
	,I.SERIALYES-- 12/26/2019 Rajendra k  : Added useipkey and serialyes in selection list
  FROM  #manufactData D 
  INNER JOIN #ComponentsData C ON D.CompRowId = C.CompRowId
  LEFT JOIN INVENTOR I ON TRIM(PART_NO) = TRIM( C.partno) AND TRIM(REVISION) = TRIM(C.rev) AND I.custPartNo = c.custPartNo AND CUSTREV = C.crev
  LEFT JOIN  PARTTYPE p ON p.PART_TYPE = I.PART_TYPE AND p.PART_CLASS = I.PART_CLASS   
 END