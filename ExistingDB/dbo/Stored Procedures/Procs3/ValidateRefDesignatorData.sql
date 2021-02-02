-- ============================================================================================================      
-- Date   : 08/26/2019      
-- Author  : Rajendra K     
-- Description : Used for Validate reference designato uploaded data 
-- 10/01/2019 Rajendra K : Changed the joins     
-- 12/26/2019 Rajendra K : Added column useipkey,serialyes in @ComoponentsDetail table 
-- ValidateRefDesignatorData 'C3353D9B-BEFC-46F6-B3BE-4963C881D6D7'     
-- ============================================================================================================        
CREATE PROC ValidateRefDesignatorData      
 @ImportId UNIQUEIDENTIFIER,      
 @RowId UNIQUEIDENTIFIER =NULL      
AS      
BEGIN      
       
 SET NOCOUNT ON        
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@headerErrs VARCHAR(MAX)  
 DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))          
      
 DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,RefDesRowId UNIQUEIDENTIFIER,    
         CssClass VARCHAR(MAX),Validation VARCHAR(MAX),refdesg VARCHAR(MAX))              
    
 DECLARE @ComoponentsDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,CssClass VARCHAR(MAX),Validation VARCHAR(MAX),itemno NUMERIC  
       ,partSource  VARCHAR(MAX),partno  VARCHAR(MAX),rev  VARCHAR(MAX),custPartNo  VARCHAR(MAX),crev  VARCHAR(MAX),qty NUMERIC,bomNote  VARCHAR(MAX)  
       ,workCenter VARCHAR(MAX),used BIT,UNIQ_KEY VARCHAR(MAX),PART_CLASS VARCHAR(MAX),PART_TYPE VARCHAR(MAX),U_OF_MEAS VARCHAR(100),IsLotted BIT,useipkey BIT,SERIALYES BIT)   
   -- 12/26/3019 Rajendra K : Added column useipkey,serialyes in @ComoponentsDetail table 
   
 -- Insert statements for procedure here     
 SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_BOMtoKITUpload' and FilePath = 'BOMtoKITUpload'       
 SELECT @FieldName = STUFF(        
      (        
       SELECT  ',[' +  F.FIELDNAME + ']' FROM       
       ImportFieldDefinitions F          
       WHERE ModuleId = @ModuleId  AND FieldName IN ('refdesg')       
       ORDER BY F.FIELDNAME       
       FOR XML PATH('')        
      ),        
      1,1,'')         
  
 SELECT @SQL = N'        
  SELECT PVT.*      
  FROM        
  (       
   SELECT Sub.fkImportId AS importId,Sub.AssemblyRowId,Sub.CompRowId,ia.RefDesRowId,sub.class as CssClass,sub.Validation,fd.fieldName,ia.Adjusted     
   FROM ImportFieldDefinitions fd    
     '--INNER JOIN ImportBOMToKitComponents ic ON ia.FKCompRowId = ic.CompRowId      
	 --INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId      -- 10/01/2019 Rajendra K : Changed the joins
   	 --INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId   
	 +'INNER JOIN ImportBOMToKitRefDesg ia ON fd.FieldDefId = ia.FKFieldDefId                          
     INNER JOIN       
	(       
		SELECT fkImportId,AssemblyRowId,CompRowId,RefDesRowId,MAX(ia.status) as Class ,MIN(ia.Message) as Validation      
		FROM ImportBOMToKitAssemly fd      
		 INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId    
		 INNER JOIN ImportBOMToKitRefDesg ia ON ic.CompRowId = ia.FKCompRowId    
		 INNER JOIN ImportFieldDefinitions ibf ON ia.FKFieldDefId = ibf.FieldDefId       
		WHERE fkImportId ='''+ CAST(@ImportId as CHAR(36))+'''    
		  AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')     
		GROUP BY fkImportId,AssemblyRowId,CompRowId,RefDesRowId     
		) Sub        
		ON ia.RefDesRowId = sub.RefDesRowId     
		WHERE Sub.fkImportId = '''+ CAST(@ImportId as CHAR(36))+'''     
  ) st        
   PIVOT (MAX(Adjusted) FOR fieldName IN ('+ @FieldName +')) as PVT'    
       
 Print @SQL      
 INSERT INTO @ImportDetail EXEC sp_executesql @SQL         
 INSERT INTO @ComoponentsDetail EXEC GetComponentsData @importId     
 --SELECT * FROM @ImportDetail      
    
 UPDATE ia      
 SET [message] =      
  CASE     
   WHEN  ifd.FieldName = 'refdesg' THEN       
     CASE WHEN (TRIM(impt.refdesg) = '' OR TRIM(impt.refdesg) IS NULL) THEN ''     
  ELSE CASE     
    WHEN LEN(TRIM(impt.refdesg)) > 51  THEN 'Reference designator length can not be greator than 50 charcters.'   
    WHEN impt.refdesg <>'' AND invt.U_OF_MEAS = 'EACH' AND refde.refCount > comp.qty THEN 'Reference designator can not be greater than part Quantity.'     
    ELSE '' END    
  END                             
  ELSE '' END     
    
 ,[status] =     
  CASE     
   WHEN  ifd.FieldName = 'refdesg' THEN       
     CASE WHEN (TRIM(impt.refdesg) = '' OR TRIM(impt.refdesg) IS NULL) THEN ''     
  ELSE CASE     
    WHEN LEN(TRIM(impt.refdesg)) > 51  THEN 'i05red'   
    WHEN impt.refdesg <>'' AND invt.U_OF_MEAS = 'EACH' AND refde.refCount > comp.qty THEN 'i05red'     
    ELSE '' END    
  END                             
  ELSE '' END   
 --select  refde.*,impt.refdesg, invt.U_OF_MEAS 
  FROM  ImportBOMToKitRefDesg ia     
   INNER JOIN ImportBOMToKitComponents ic ON ia.FKCompRowId = ic.CompRowId    
   INNER JOIN ImportBOMToKitAssemly a ON  a.AssemblyRowId = ic.FKAssemblyRowId      
   INNER JOIN ImportFieldDefinitions ifd  ON ia.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId    
   INNER JOIN ImportBOMToKitHeader h  ON a.FkImportId = h.ImportId      
   INNER JOIN @ImportDetail impt ON ia.RefDesRowId = impt.RefDesRowId   
   INNER JOIN  @ComoponentsDetail comp ON impt.CompRowId = comp.CompRowId  
   OUTER APPLY  
   (  
  SELECT COUNT(refdesg) AS refCount FROM @ImportDetail GROUP BY CompRowId  
   ) refde  
    OUTER APPLY  
   (  
  SELECT U_OF_MEAS FROM INVENTOR WHERE UNIQ_KEY = comp.UNIQ_KEY  
   ) invt  
  WHERE (@RowId IS NULL OR @RowId = ia.RefDesRowId)    
END