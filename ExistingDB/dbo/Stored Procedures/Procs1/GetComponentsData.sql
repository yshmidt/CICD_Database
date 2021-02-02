 -- ============================================================================================================  
-- Date   : 08/27/2019  
-- Author  : Rajendra K 
-- Description : Used for get Components upload data  
-- 10/01/2019 Rajendra K : Added AssemblyData table for Assembly information
-- 10/01/2019 Rajendra K : Added join with Assembly 
-- 12/26/2019 Rajendra k  : Added useipkey and serialyes in selection list
-- GetComponentsData 'A7D1484C-2614-448D-995E-763AEAEF1E4C' ,'39FDBE9A-0C14-4F63-9E58-A09F557ED8BE'    
-- ============================================================================================================    
CREATE PROC GetComponentsData  
 @ImportId UNIQUEIDENTIFIER,
 @CompRowId UNIQUEIDENTIFIER = null
AS  
SET NOCOUNT ON   

BEGIN
 ;WITH AssemblyData AS(-- 10/01/2019 Rajendra K : Added AssemblyData table for Assembly information
 SELECT PVT.*      
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
  -- INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId     
   INNER JOIN     
   (     
     SELECT fkImportId,AssemblyRowId,MAX(status) AS Class ,MIN(Message) AS Validation    
     FROM ImportBOMToKitAssemly fd    
      INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
     WHERE fkImportId = @ImportId    
      AND FieldName IN ('assyDesc','assyNum','assypartclass','assyparttype','assyRev','custno')    
     GROUP BY fkImportId,AssemblyRowId    
   ) Sub   
 ON  ibf.AssemblyRowId=sub.AssemblyRowId     
 WHERE ibf.fkImportId = @ImportId      
  ) st      
   PIVOT (MAX(adjusted) FOR fieldName IN ([assyDesc],[assyNum],[assypartclass],[assyparttype],[assyRev],[custno])) AS PVT   
  )
  ,AssemblyD AS(
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
		,I.BOMCUSTNO 
   FROM AssemblyData A   
  LEFT JOIN INVENTOR I ON TRIM(PART_NO) = TRIM(A.assyNum) AND TRIM(REVISION) = TRIM(A.assyRev) AND  PART_SOURC = 'MAKE'  
 ) 							      
,ComponentsData AS (SELECT PVT.*  
FROM    
  (   
   SELECT Sub.fkImportId AS importId,Sub.AssemblyRowId,ic.CompRowId,sub.class as CssClass,sub.Validation,fd.fieldName,ic.Adjusted 
   FROM ImportFieldDefinitions fd      
	 INNER JOIN ImportBOMToKitComponents ic ON fd.FieldDefId = ic.FKFieldDefId
     --INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId
     --INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId     
	 INNER JOIN   
	   (   
			SELECT fkImportId,AssemblyRowId,CompRowId,MAX(ic.status) as Class ,MIN(ic.Message) as Validation		
			FROM ImportBOMToKitAssemly fd  
				INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
				INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId   
			WHERE fkImportId = @ImportId 
				AND FieldName IN ('bomNote','crev','custPartNo','itemno','partno','partSource','qty','rev','used','workCenter')
			GROUP BY fkImportId,CompRowId,AssemblyRowId
	   ) Sub    
   ON  ic.CompRowId = sub.CompRowId    
   WHERE Sub.fkImportId = @ImportId    
  ) st    
   PIVOT (MAX(Adjusted) FOR fieldName IN ([bomNote],[crev],[custPartNo],[itemno],[partno],[partSource],[qty],[rev],[used],[workCenter])) as PVT 
WHERE (@CompRowId IS NULL OR @CompRowId  = CompRowId) 
)
  SELECT C.importId
		,C.AssemblyRowId
		,CompRowId
		,C.CssClass
		,C.Validation
		,CAST(itemno AS INT) AS itemno
		,partSource
		,partno
		,rev
		,C.custPartNo
		,crev
		,CAST(qty AS NUMERIC(9,2)) AS Qty
		,bomNote
		,workCenter
		,CASE WHEN used IN ('n','no','0','false') THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS used
		,I.UNIQ_KEY
		,I.PART_CLASS
		,I.PART_TYPE
		,I.U_OF_MEAS 
		,ISNULL(P.LOTDETAIL,CAST(0 AS BIT)) AS IsLotted 
		,I.useipkey
		,I.SERIALYES  -- 12/26/2019 Rajendra k  : Added useipkey and serialyes in selection list
  FROM ComponentsData C -- 10/01/2019 Rajendra K : Added join with Assembly 
	INNER JOIN AssemblyD B ON C.AssemblyRowId = B.AssemblyRowId
  	LEFT JOIN INVENTOR I ON TRIM(PART_NO) = TRIM( C.partno) AND TRIM(REVISION) = TRIM(C.rev) AND TRIM(I.CUSTPARTNO) = TRIM(c.custPartNo) AND TRIM(I.CUSTREV) = TRIM(C.crev)
	LEFT JOIN  PARTTYPE p ON p.PART_TYPE = I.PART_TYPE AND p.PART_CLASS = I.PART_CLASS   
  WHERE I.CUSTNO = CASE WHEN C.partSource = 'CONSG'THEN B.BOMCUSTNO ELSE '' END
 END