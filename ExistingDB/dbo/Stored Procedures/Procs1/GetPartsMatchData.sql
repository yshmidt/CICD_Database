-- ================================================    
-- Author: Vijay G    
-- Created Date: 12/06/2019    
-- Description : If score is not set and part is existing in the system then use parts value from inventor table     
--01/16/2020 Vijay G Replace name of columns/variable sid with mtc    
--01/05/2021 Sachin B Add Location in the Pivot Query 
-- GetPartsMatchData ''    
-- ================================================    
CREATE PROCEDURE GetPartsMatchData    
@importId UNIQUEIDENTIFIER=null    
    
AS BEGIN    
    
SET NOCOUNT ON    
    
    DECLARE @manexMatch int, @custMatch int,@AVLMatch int, @descriptMatch int,@moduleId int    
    
  SELECT @moduleId = ModuleId FROM mnxModule WHERE ModuleDesc = 'MnxM_EngProdBOMImport'    
    
 DECLARE @sTable mnxSettings    
    
 INSERT INTO @sTable     
 EXEC [settingsGetValues] @moduleId,0,1    
      
 SELECT @AVLMatch=COALESCE(settingValue,70) FROM @sTable WHERE settingName='ImpAVLMatch'    
 SELECT @manexMatch=COALESCE(settingValue,100) FROM @sTable WHERE settingName='ImpManexPartMatch'    
 SELECT @custMatch=COALESCE(settingValue,80) FROM @sTable WHERE settingName='ImpCustPartMatch'    
 SELECT @descriptMatch=COALESCE(settingValue,10) FROM @sTable WHERE settingName='ImpDescMatch'    
    
IF(@AVLMatch='0' AND @manexMatch='0' AND @custMatch='0' AND @descriptMatch='0')    
 BEGIN    
  DECLARE  @tPartsAll importBom             
    
  INSERT INTO @tPartsAll            
  EXEC [dbo].[sp_getImportBOMItems] @importId     
        
  UPDATE t SET     
  t.descript = i.DESCRIPT, t.bomNote=i.BOM_NOTE,t.partClass=i.PART_CLASS,t.crev=i.CUSTREV,    
  t.custno=i.CUSTNO,t.partno=i.PART_NO,t.partSource=i.PART_SOURC,t.partType=i.PART_TYPE,    
  t.u_of_m=i.PUR_UOFM,t.invNote=i.INV_NOTE,t.matlType=i.MATLTYPE,t.serial=i.SERIALYES,    
  --01/16/2020 Vijay G Replace name of columns/variable sid with mtc     
  t.[mtc]=i.useipkey,t.standardCost=i.STDCOST          
  FROM @tPartsAll t           
  INNER JOIN INVENTOR i ON i.PART_NO =t.partno AND i.REVISION = t.rev AND i.CUSTNO = ISNULL(t.CUSTNO,'')     
 
  --01/05/2021 Sachin B Add Location in the Pivot Query       
  UPDATE i    
  SET i.adjusted = u.adjusted,i.uniq_key=u.uniq_key    
  FROM    
  (    
   SELECT importId,rowId,[uniq_key],[itemno],[used],[partSource],[partClass],[partType],[qty],[custPartNo],[cRev],    
   [descript],[u_of_m],[warehouse],[standardCost],[workCenter],[partno],[rev],[location]    
   FROM @tPartsAll    
     )p    
  UNPIVOT    
  (    
   adjusted FOR fieldName IN     
   (    
    [itemno],[used],[partSource],[partClass],[partType],[qty],[custPartNo],[cRev],[descript],[u_of_m],[warehouse],    
    [standardCost],[workCenter],[partno],[rev],[location]      
   )    
  ) AS u     
  INNER JOIN importBOMFieldDefinitions fd ON fd.fieldName = u.fieldName     
  INNER JOIN importBOMFields i ON i.rowId=u.rowId AND i.fkFieldDefId=fd.fieldDefId AND i.fkImportId=u.importId        
 END    
END