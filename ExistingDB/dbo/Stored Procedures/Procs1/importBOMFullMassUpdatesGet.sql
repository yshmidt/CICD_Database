-- =============================================    
-- Author:  David Sharp    
-- Create date: 4/18/2012    
-- Description: get mass update items    
-- 12/17/13 DS added GUID for the UI 
-- 05/15/2019 Vijay G Added temp tables for the getting part_tye Error
-- 05/15/2019 Vijay G changed sp for bring wrong part type data or bring part class data if part type wrong  
-- 05/15/2019 Vijay G modify sp for get only  differenct art class and part type in bulk error tab not bring same part type,part class,warehouse and workcenter 
--[importBOMFullMassUpdatesGet] '4a7c49ef-3462-4359-814b-5f1540ea5954' 
-- =============================================    
CREATE PROCEDURE [dbo].[importBOMFullMassUpdatesGet]     
 -- Add the parameters for the stored procedure here    
 @importId uniqueidentifier    
AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
    
    -- Insert statements for procedure here    
    DECLARE @minStatus VARCHAR(20) = 'i03blue',@PartClassFieldDefId UNIQUEIDENTIFIER    
    SET @PartClassFieldDefId = (SELECT fielddefid FROM importBOMFieldDefinitions WHERE fieldName='partClass')  

-- 05/15/2019 Vijay G Added temp tables for the getting part_tye Error	
;WITH tempData As(        
   SELECT newid()tId,rowId, fd.fieldName, ibf.original,ibf.adjusted,CAST(0 AS BIT) IsExists ,detailId
   FROM importBOMFields AS ibf   
   INNER JOIN importBOMFieldDefinitions fd ON ibf.fkFieldDefId = fd.fieldDefId    
   WHERE   
   ibf.[status] > @minStatus and fkImportId = @importId AND fd.fixMatches = 1  --Or fieldName='partClass'  
   --GROUP BY fieldName, adjusted,original    
  )  
  ,withPartClassData As(  
     select t.tId,t.rowId, fd.fieldName, field.original,field.adjusted,newid()tColId,field.detailId  
  FROM tempData t  
  LEFT JOIN importBOMFields field ON t.rowId =field.rowId AND field.fkFieldDefId = @PartClassFieldDefId  
  INNER JOIN importBOMFieldDefinitions fd ON field.fkFieldDefId = fd.fieldDefId      
  WHERE t.fieldName='partType'  
  )  
  --select * from withPartClassData  
  ,withPartClassTypeData AS(  
    SELECT td.tId,  
 ISNULL(cData.fieldName,'') FieldName,ISNULL(cData.original,'') Original,ISNULL(cData.adjusted,'') Adjusted,   
 td.fieldName dFieldName,td.original dOriginal,td.adjusted dAdjusted,  
    CASE WHEN pc.part_class IS NULL THEN CAST(0 AS BIT)  
 ELSE CAST(1 AS BIT) END IsExists,tColId,cData.detailId  
 FROM tempData td  
 INNER JOIN withPartClassData cData ON td.rowId =cData.rowId AND td.fieldName ='partType'  
 LEFT JOIN PartClass pc ON pc.part_class = cData.adjusted  
  )  
  
  ,AllData AS (  
  SELECT tId, FieldName,Original,Adjusted,dFieldName,dOriginal,dAdjusted,IsExists,tColId FROM withPartClassTypeData  
 UNION ALL  
  SELECT tId, FieldName,Original,Adjusted,''dFieldName,''dOriginal,''dAdjusted,CAST(0 AS BIT) IsExists,newid()tColId    
  FROM tempData WHERE fieldName<>'partType' and detailId not in (select detailId from withPartClassTypeData)  
  )  
-- 05/15/2019 Vijay G changed sp for bring wrong part type data or bring part class data if part type wrong 
 SELECT * INTO #importBOMFieldDef FROM (
		SELECT tId,FieldName,Original,Adjusted,dFieldName,dOriginal,dAdjusted,IsExists,tColId FROM AllData   
		UNION   
		SELECT NEWID(),fd.fieldNAme, iba.original,adjusted,''dFieldName,''dOriginal,''dAdjusted,CAST(0 AS BIT) IsExists,newid()tColId     
			FROM importBOMAvl iba   
			INNER JOIN importBOMFieldDefinitions fd ON iba.fkFieldDefId=fd.fieldDefId
		WHERE iba.[status] > @minStatus and fkImportId = @importId AND fd.fixMatches = 1
		GROUP BY fieldName,adjusted,original) a

-- 05/15/2019 Vijay G modify sp for get only  differenct art class and part type in bulk error tab not bring same part type,part class,warehouse and workcenter 
 ;With CTE as   
 (  
	SELECT *, row_number() OVER (PARTITION BY FieldName,Adjusted,dFieldName,dAdjusted ORDER BY FieldName) AS RowNumber 
	FROM #importBOMFieldDef
 )  
 SELECT * FROM CTE WHERE RowNumber = 1
 IF OBJECT_ID('tempdb..#importBOMFieldDef') IS NOT NULL 
	DROP TABLE #importBOMFieldDef
END  