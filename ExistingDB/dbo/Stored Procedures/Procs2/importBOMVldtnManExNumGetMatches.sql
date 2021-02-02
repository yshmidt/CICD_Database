        
-- =============================================        
-- Author:  David Sharp        
-- Create date: 4/27/2012        
-- Description: check ManEx Part Number        
-- 06/26/13 YS use new fnKeepAlphaNumeric() function that uses PATINDEX() to keep alpha-numeric charcaters only in place of fn_RemoveSpecialCharacters()        
-- 08/05/13 DS Changed 'New' part number value to '===== NEW ====='        
-- 10/30/13 DS implemented cleanPn and removed stripping special characters for performance.        
-- 11/05/13 DS revised how we collect matches        
-- 03/11/14 DS removed the duplicate record because of standard cost differences, and only include AVLs marked as included on the BOM in the match, and only those for the provided row        
-- 03/14/14 DS added handling for skip blank rev setting        
-- 06/17/14 DS change method for getting a module setting        
-- 10/13/14 YS removed invtmfhd table and replaced with 2 new tables        
-- 01/10/18 YS  Vijay found extra line         
-- 01/23/18 Vijay G : To avoid duplicate AVL records added distinct keyword.         
-- 01/24/2018: Vijay G: Removed the where condition to get matching part by descr        
-- 02/13/18: Vijay G: Declare and used the ModulId of the Bill of Material & Import (BOM) to get setting values        
-- 03/28/2018: Vijay G: Added the where condition to get only internal part match by descr. No need to get consign part.        
-- 06/01/18  Vijay G : Get the module id using ModuleDesc resource key        
-- 06/01/18  Vijay G : Used the same settingName which are present in the MnxSettingsManagement table.        
-- 08/06/18: Vijay G: To Get matching Score as per template field matching        
-- 08/21/18: Vijya G: To get the selected column value depending on the matching score.        
-- 11/29/18: Vijya G: Change rev from  varchar(4) to varchar(8)        
-- 12/12/18: Vijya G: added Order by clause to partNo to display new (====NEW====) records at the end of list -- ORDER BY score desc         
-- 01/10/18 Vijay G :Add Custno,CustPartNo/CustRevision Column      
-- 01/18/19 Vijay G :Custno,CustPartNo/CustRevision Column Not Getting Values          
-- 02/08/19 Vijay G : Find the Original Value of description from the BOM Import      
-- 05/21/19 Vijay G : Fix the Discription Match Issue Add Left Join    
-- 06/11/19 Vijay G : Modify the Logic for the Selected Value      
-- 06/11/19 Vijay G : Get Match Parts only When the Score is Set CustPartNo
-- 06/18/19 Vijay G : added one filter to join 'e.mfg =iA.mfg' to get manufacture match    
-- 04/16/2020 Sachin B: Added partsource column to get partsource of match part 
-- 07/20/2020 Sachin B: Apply the CustomerPartNo match with @tPartsAll insted of @tPartsOrig
-- 07/22/2020 Sachin B: When Multiple Match is found with AVL then select radio button for the part which is matched in main grid
-- 07/22/2020 Sachin B: Get Empty CustNo and Cust Part No
-- 07/22/2020 Sachin B: Remove the Part Source from the select statement
-- 07/27/2020 Sachin B: Get Internal Part PART_NO,REVISION,DESCRIPT,STDCOST Class and Type
-- [importBOMVldtnManExNumGetMatches] 'd0bbd107-fcee-495c-9e9b-228929c1ecb3','4BDE3B5B-09CC-EA11-B55B-408D5C0435C0'        
-- =============================================        
CREATE PROCEDURE [dbo].[importBOMVldtnManExNumGetMatches]        
 -- Add the parameters for the stored procedure here        
 @importId uniqueIdentifier,        
 @rowId uniqueidentifier        
AS        
BEGIN        
 -- SET NOCOUNT ON added to prevent extra result sets from        
 -- interfering with SELECT statements.        
 SET NOCOUNT ON;        
        
    -- Insert statements for procedure here        
    -- validate check to see if the provided manex number exists, or if exactly one match is found and can be populated.        
 -- 02/13/18: Vijay G: Declared the ModulId variable        
    DECLARE @partnum varchar(max),@rev varchar(max),@descript varchar(max),@providedpn varchar(max),@cpartno varchar(max),        
   @partId uniqueidentifier,@revId uniqueidentifier,@descId uniqueidentifier,@mpnId uniqueidentifier,@cpartId uniqueidentifier,        
   @manexMatch int, @custMatch int, @AVLMatch int, @descriptMatch int, @skipBlankRev bit = 1,  @fastCheck bit = 0,@rCount int, @moduleId int        
         
 -- Get field Def Ids        
 SELECT @partId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'partNo'        
 SELECT @revId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'rev'        
 SELECT @descId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'descript'        
 SELECT @mpnId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'mpn'        
 SELECT @cpartId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'custPartNo'        
        
 -- 02/13/18: Vijay G: Used the ModulId of the Bill of Material & Import (BOM) to get setting values        
 -- 06/01/18 Vijay G : Get the module id using ModuleDesc resource key        
 SELECT @moduleId = ModuleId FROM mnxModule WHERE ModuleDesc = 'MnxM_EngProdBOMImport'        
        
 -- 10/30/13 DS store the import bom fields for faster comparison         
 DECLARE  @tPartsAll importBom        
 INSERT INTO @tPartsAll EXEC [dbo].[sp_getImportBOMItems] @importId,0,null,0,@rowId        
 DECLARE  @tPartsOrig importBom        
 INSERT INTO @tPartsOrig EXEC [dbo].[sp_getImportBOMItems] @importId,0,null,1,@rowId        
 DECLARE @tAvlAll tImportBomAvl         
 INSERT INTO @tAvlAll EXEC [ImportBomGetAvlToComplete] @importID         
         
 /* Get the user settings for the match weight */        
 DECLARE @sTable mnxSettings        
 INSERT INTO @sTable         
 -- 06/01/18 Vijay G : Used the same settingName which are present in the MnxSettingsManagement table.        
 EXEC [settingsGetValues] @moduleId,0,1        
 SELECT @AVLMatch=COALESCE(settingValue,70) FROM @sTable WHERE settingName='ImpAVLMatch'        
 SELECT @manexMatch=COALESCE(settingValue,100) FROM @sTable WHERE settingName='ImpManexPartMatch'        
 SELECT @custMatch=COALESCE(settingValue,80) FROM @sTable WHERE settingName='ImpCustPartMatch'        
 SELECT @descriptMatch=COALESCE(settingValue,10) FROM @sTable WHERE settingName='ImpDescMatch'        
 SELECT @skipBlankRev=COALESCE(settingValue,1) FROM @sTable WHERE settingName='ImpSkipBlankRev'        
 ---01/10/18 YS  Vijay found extra line         
 --SELECT @AVLMatch=COALESCE(settingValue,70) FROM @sTable WHERE settingName='impAVLMatch'        
 DELETE FROM @sTable        
         
 DECLARE @iAvlTable TABLE(cleanMpn varchar(max),rowId uniqueidentifier,mfg varchar(100))        
          
 -- 06/26/13 YS use new fnKeepAlphaNumeric() function that uses PATINDEX() to keep alpha-numeric charcaters only in place of fn_RemoveSpecialCharacters()        
 -- 01/23/18 Vijay G : To avoid duplicate AVL records added distinct keyword.        
 INSERT INTO @iAvlTable        
 SELECT DISTINCT UPPER(dbo.fnKeepAlphaNumeric(adjusted)),fkRowId,ta.PartMfgr        
  FROM importBOMAvl ia INNER JOIN @tAvlAll ta ON ia.fkRowId=ta.rowId        
  WHERE fkImportId = @importId AND fkFieldDefId = @mpnId AND adjusted<>'' AND ia.bom=1 AND ia.fkRowId=@rowId        
         
 -- 10/30/13 DS started using InvtMpnClean to improve performance        
 DECLARE @eAvlTable TABLE(uniq_key varchar(10),cleanMpn varchar(max), mfg varchar(100))        
 INSERT INTO @eAvlTable        
 --10/13/14 YS removed invtmfhd table and replaced with 2 new tables        
 SELECT DISTINCT l.UNIQ_KEY,c.cleanmpn, m.PARTMFGR        
  --10/13/14 YS removed invtmfhd table and replaced with 2 new tables        
  --FROM INVTMFHD m INNER JOIN INVENTOR i ON i.UNIQ_KEY = m.UNIQ_KEY         
  FROM InvtMPNLink l INNER JOIN MfgrMaster M on l.mfgrMasterId=m.MfgrMasterId        
  INNER JOIN INVENTOR i ON i.UNIQ_KEY = l.UNIQ_KEY         
   INNER JOIN InvtMpnClean c ON c.mfgr_pt_no = m.MFGR_PT_NO        
  WHERE CUSTNO = '' AND 
  c.MFGR_PT_NO<>'' AND cleanMpn IN (select cleanmpn from @iAvlTable)        
         
 -- 11/29/18: Vijya G: Change rev from  varchar(4) to varchar(8)          
-- 01/10/18 Vijay G :Add Custno,CustPartNo/CustRevision Column        
--04/16/2020 Sachin B: Added partsource column to get partsource of match part          
 DECLARE @matchTbl TABLE (uniq_key varchar(10),selected bit,partno varchar(50),rev varchar(8),descript varchar(200),status varchar(10),score int,          
        C bit,M int,D bit,partClass varchar(8),partType varchar(8),u_of_m varchar(8),        
     standardCost decimal(18,4),color varchar(20),vldtn varchar(20),match varchar(500),custNo CHAR(10),CustPartNo char(33),PartSource Varchar(10))          
 /*         
 * 2. Build possible match list        
 * Check for existing record matches        
 */        
 /* Internal Part Matches */        
--04/16/2020 Sachin B: Added partsource column to get partsource of match part        
 INSERT INTO @matchTbl(uniq_key,selected,partno,rev,descript,status,score,C,M,D,partClass,partType,u_of_m,standardCost,custNo,CustPartNo,PartSource)          
 SELECT inv.uniq_key,CAST(1 as bit),        
   inv.PART_NO,inv.REVISION,inv.DESCRIPT,inv.STATUS,@manexMatch,        
   CAST(0 as bit),0,CAST(0 as bit),        
   inv.PART_CLASS,inv.PART_TYPE,inv.U_OF_MEAS,inv.STDCOST,        
   -- 01/10/18 Vijay G :Add Custno,CustPartNo/CustRevision Column        
   inv.CUSTNO,        
   CASE COALESCE(NULLIF(inv.CUSTREV,''), '')        
   WHEN '' THEN  LTRIM(RTRIM(inv.CUSTPARTNO))         
   ELSE LTRIM(RTRIM(inv.CUSTPARTNO)) + '/' + inv.CUSTREV         
   END AS CustPartNoWithRev              --08/06/18: Vijay G: To Get matching Score as per template field matching        
   ,inv.PART_SOURC        
 FROM @tPartsOrig tp         
 INNER JOIN INVENTOR inv ON tp.partno = inv.PART_NO        
 WHERE inv.CUSTNO=''         
 AND 1=CASE WHEN @skipBlankRev = 0 OR tp.rev<>'' THEN CASE WHEN tp.rev=inv.REVISION THEN 1 ELSE 0 END ELSE 1 END    
 -- 06/11/19 Vijay G : Get Match Parts only When the Score is Set    
 AND @manexMatch>0        
        
 /* Customer Part Matches */        
 -- 06/26/13 YS use new fnKeepAlphaNumeric() function that uses PATINDEX() to keep alpha-numeric charcaters only in place of fn_RemoveSpecialCharacters()        
 --04/16/2020 Sachin B: Added partsource column to get partsource of match part  
 INSERT INTO @matchTbl(uniq_key,selected,partno,rev,descript,status,score,C,M,D,partClass,partType,u_of_m,standardCost,custNo,CustPartNo,PartSource)          
 SELECT inv.INT_UNIQ AS UNIQ_KEY,CAST(CASE WHEN tp.rowId IN(SELECT rowId FROM @matchTbl)THEN 0 ELSE 1 END AS bit)selected,        
   i2.PART_NO, i2.REVISION, i2.DESCRIPT, i2.STATUS,@custMatch AS Score,        
   CAST(1 AS bit) AS C, 0 AS M,CAST(0 AS bit) AS D,        
   -- 07/27/2020 Sachin B: Get Internal Part PART_NO,REVISION,DESCRIPT,STDCOST Class and Type
   i2.PART_CLASS,i2.PART_TYPE,i2.U_OF_MEAS,i2.STDCOST,         
   -- 01/10/18 Vijay G :Add Custno,CustPartNo/CustRevision Column        
   -- 01/18/19 Vijay G :Custno,CustPartNo/CustRevision Column Not Getting Values  
   -- 07/22/2020 Sachin B: Get Empty CustNo and Cust Part No
   '' as CustNo,
   '' as CustPartNoWithRev,        
   --inv.CUSTNO,        
   --CASE COALESCE(NULLIF(inv.CUSTREV,''), '')        
   --WHEN '' THEN  LTRIM(RTRIM(inv.CUSTPARTNO))         
   --ELSE LTRIM(RTRIM(inv.CUSTPARTNO)) + '/' + inv.CUSTREV         
   --END AS CustPartNoWithRev,    
   inv.PART_SOURC       
   --08/06/18: Vijay G: To Get matching Score as per template field matching        
 FROM INVENTOR inv 
 -- 07/20/2020 Sachin B: Apply the CustomerPartNo match with @tPartsAll insted of @tPartsOrig        
 INNER JOIN @tPartsOrig tp ON tp.custPartNo = inv.CUSTPARTNO         
 INNER JOIN INVENTOR i2 ON i2.UNIQ_KEY = inv.INT_UNIQ        
 -- 10/30/13 DS IF the rev is provided with the import, it MUST match existing records        
 -- 02/17/14 DS skip empty customer part numbers        
 WHERE 1=CASE WHEN @skipBlankRev = 0 OR tp.crev<>'' THEN CASE WHEN tp.crev = inv.CUSTREV THEN 1 ELSE 0 END ELSE 1 END AND tp.custPartNo<>''        
 -- 06/11/19 Vijay G : Get Match Parts only When the Score is Set    
 AND @custMatch>0    
        
 /* Check AVLs to find possible Matches */        
--04/16/2020 Sachin B: Added partsource column to get partsource of match part  
 INSERT INTO @matchTbl(uniq_key,selected,partno,rev,descript,status,score,C,M,D,partClass,partType,u_of_m,standardCost,custNo,CustPartNo,PartSource)          
 -- 08/21/18: Vijya G: To get the selected column value depending on the matching score.         
 SELECT e.UNIQ_KEY,
   --CAST(CASE WHEN iA.rowId IN(SELECT rowId FROM @matchTbl)THEN 0 ELSE 1 END AS bit)selected, 
   -- 07/22/2020 Sachin B: When Multiple Match is found with AVL then select radio button for the part which is matched in main grid
   CAST(CASE WHEN iA.rowId IN(SELECT rowId FROM @matchTbl)
   THEN 0 
   ELSE CAST(CASE WHEN e.uniq_key IN(SELECT uniq_key FROM @tPartsOrig)THEN 1 ELSE 0 END AS bit) END AS bit)selected,        
   inv.PART_NO, inv.REVISION, inv.DESCRIPT, inv.STATUS,SUM(@AVLMatch) Score,        
   CAST(0 AS bit) C, COUNT(e.uniq_key) AS M,CAST(0 AS bit) AS D,        
   inv.PART_CLASS,inv.PART_TYPE,inv.U_OF_MEAS,inv.STDCOST,        
   -- 01/10/18 Vijay G :Add Custno,CustPartNo/CustRevision Column        
   inv.CUSTNO,        
   CASE COALESCE(NULLIF(inv.CUSTREV,''), '')        
   WHEN '' THEN  LTRIM(RTRIM(inv.CUSTPARTNO))         
   ELSE LTRIM(RTRIM(inv.CUSTPARTNO)) + '/' + inv.CUSTREV         
   END AS CustPartNoWithRev  ,inv.PART_SOURC          
 FROM @eAvlTable e         
 -- 06/18/19 Vijay G : added one filter to join 'e.mfg =iA.mfg'    
 INNER JOIN @iAvlTable iA ON e.cleanMpn = iA.cleanMpn  AND e.mfg =iA.mfg        
 INNER JOIN INVENTOR inv ON e.uniq_key = inv.UNIQ_KEY        
 WHERE iA.cleanMpn <> '' AND 1=CASE WHEN ia.mfg<>'' AND ia.mfg<>'GENR' THEN CASE WHEN ia.mfg=e.mfg THEN 1 ELSE 0 END ELSE 1 END    
 -- 06/11/19 Vijay G : Get Match Parts only When the Score is Set    
 AND @AVLMatch>0       
 GROUP BY e.UNIQ_KEY, inv.PART_NO, inv.REVISION, inv.DESCRIPT, inv.STATUS, iA.rowId,inv.PART_CLASS,inv.PART_TYPE,inv.U_OF_MEAS,inv.STDCOST,         
    inv.CUSTNO,inv.CUSTPARTNO,inv.CUSTREV,inv.PART_SOURC          
         
 /* Check to see if the mpn matches regardless of the mfg (if a match hasn't already been found) */      
 -- 06/11/19 Vijay G : Modify the Logic for the Selected Value       
 --04/16/2020 Sachin B: Added partsource column to get partsource of match part  
 INSERT INTO @matchTbl(uniq_key,selected,partno,rev,descript,status,score,C,M,D,partClass,partType,u_of_m,standardCost,custNo,CustPartNo,PartSource)      
 -- 06/11/19 Vijay G : Modify the Logic for the Selected Value     
 SELECT e.UNIQ_KEY,
   --CAST(CASE WHEN iA.rowId IN(SELECT rowId FROM @matchTbl)THEN 0 ELSE 1 END AS bit)selected, 
   -- 07/22/2020 Sachin B: When Multiple Match is found with AVL then select radio button for the part which is matched in main grid
   CAST(CASE WHEN iA.rowId IN(SELECT rowId FROM @matchTbl)
   THEN 0 
   ELSE CAST(CASE WHEN e.uniq_key IN(SELECT uniq_key FROM @tPartsOrig)THEN 1 ELSE 0 END AS bit) END AS bit)selected,        
   inv.PART_NO, inv.REVISION, inv.DESCRIPT, inv.STATUS,SUM(@AVLMatch) Score,        
   CAST(0 AS bit) C, COUNT(e.uniq_key) AS M,CAST(0 AS bit) AS D,        
   inv.PART_CLASS,inv.PART_TYPE,inv.U_OF_MEAS,inv.STDCOST,        
   -- 01/10/18 Vijay G :Add Custno,CustPartNo/CustRevision Column        
   inv.CUSTNO,        
   CASE COALESCE(NULLIF(inv.CUSTREV,''), '')        
   WHEN '' THEN  LTRIM(RTRIM(inv.CUSTPARTNO))         
   ELSE LTRIM(RTRIM(inv.CUSTPARTNO)) + '/' + inv.CUSTREV         
   END AS CustPartNoWithRev,    
   inv.PART_SOURC    
 FROM @eAvlTable e         
 INNER JOIN @iAvlTable iA ON e.cleanMpn = iA.cleanMpn       
 INNER JOIN INVENTOR inv ON e.uniq_key = inv.UNIQ_KEY        
 WHERE iA.cleanMpn <> '' AND ia.rowId NOT IN (SELECT rowId FROM @matchTbl)        
 GROUP BY e.UNIQ_KEY, inv.PART_NO, inv.REVISION, inv.DESCRIPT, inv.STATUS, iA.rowId,inv.PART_CLASS,inv.PART_TYPE,inv.U_OF_MEAS,inv.STDCOST,         
 inv.CUSTNO,inv.CUSTPARTNO,inv.CUSTREV ,inv.PART_SOURC         
        
 -- 10/30/13 DS Converted to use @iTable        
 -- {DELETED}        
         
 /* Check Description to find possible Matches*/        
  -- TODO: Compare standardized and cleaned description fields        
--04/16/2020 Sachin B: Added partsource column to get partsource of match part         
 INSERT INTO @matchTbl(uniq_key,selected,partno,rev,descript,status,score,C,M,D,partClass,partType,u_of_m,standardCost,custNo,CustPartNo,PartSource)          
 -- 08/21/18: Vijya G: To get the selected column value depending on the matching score.         
 SELECT inv.UNIQ_KEY,    
   --CAST(CASE WHEN tp.rowId IN(SELECT rowId FROM @matchTbl)THEN 0 ELSE 1 END AS bit)selected,     
   CAST(    
  CASE WHEN tp.rowId IN(SELECT tp.rowId FROM @matchTbl)THEN 0      
  ELSE CASE WHEN tp.rowId NOT IN(SELECT tp.rowId FROM @matchTbl) AND tp1.uniq_key is not null THEN 1 ELSE 0 END     
  END AS bit    
 )selected,        
   inv.PART_NO,inv.REVISION,inv.DESCRIPT,inv.STATUS,@descriptMatch AS Score,        
   CAST(0 AS bit) C,0 M,CAST(1 AS bit) D,        
   inv.PART_CLASS,inv.PART_TYPE,inv.U_OF_MEAS,inv.STDCOST,        
   -- 01/10/18 Vijay G :Add Custno,CustPartNo/CustRevision Column        
   inv.CUSTNO,        
   CASE COALESCE(NULLIF(inv.CUSTREV,''), '')        
   WHEN '' THEN  LTRIM(RTRIM(inv.CUSTPARTNO))         
   ELSE LTRIM(RTRIM(inv.CUSTPARTNO)) + '/' + inv.CUSTREV         
   END AS CustPartNoWithRev,inv.PART_SOURC              
   -- 08/06/18: Vijay G: To Get matching Score as per template field matching        
 FROM INVENTOR inv         
 INNER JOIN @tPartsOrig tp ON tp.descript=inv.DESCRIPT      
 -- 05/21/19 Vijay G : Fix the Discription Match Issue Add Left Join    
 LEFT JOIN  @tPartsOrig tp1 ON tp1.descript=inv.DESCRIPT AND tp1.uniq_key =inv.UNIQ_KEY      
  --03/28/2018: Vijay G: Added the where condition to get only internal part match by descr. No need to get consign part.        
 -- 06/11/19 Vijay G : Get Match Parts only When the Score is Set    
 WHERE inv.CUSTNO = '' AND tp.uniq_key <>''  AND @descriptMatch>0      
          
  ---- 10/30/13 DS Removed special character stripping to improve performance        
  ---- 10/30/13 DS Converted to use @iTable and blocked the description search if an internal part is already selected.        
  -- {DELETED}        
           
  -- 06/26/13 YS use new fnKeepAlphaNumeric() function that uses PATINDEX() to keep alpha-numeric charcaters only in place of fn_RemoveSpecialCharacters()        
  -- {DELETED}        
         
 DECLARE @qTbl TABLE (uniq_key varchar(10),qty float,uniqWH varchar(10))        
 INSERT INTO @qTbl        
 SELECT uniq_key, SUM(qty_oh)qty,max(UNIQWH)        
  FROM INVTMFGR WHERE UNIQ_KEY IN (SELECT UNIQ_KEY FROM @matchTbl) GROUP BY UNIQ_KEY        
         
 -- Insert a "NEW" record so the user can opt for a NEW part        
 -- 01/10/18 Vijay G :Add Custno,CustPartNo/CustRevision Column        
 INSERT INTO @matchTbl(uniq_key,selected,partno,rev,descript,status,score,C,M,D,partClass,partType,u_of_m,standardCost,custNo,CustPartNo)        
 -- 02/08/19 Vijay G : Find the Original Value of description from the BOM Import      
 SELECT 'NEW',0,'===== NEW =====','',left(i.original,45),'NEW',0,0,0,0,'','','',0,'',''         
 FROM importBOMFields i WHERE fkFieldDefId=@descId AND i.rowId=@rowId AND i.fkImportId=@importId        
        
 --SELECT * FROM @matchTbl        
 -- 01/10/18 Vijay G :Add Custno,CustPartNo/CustRevision Column        
--04/16/2020 Sachin B: Added partsource column to get partsource of match part 
-- 07/22/2020 Sachin B: Remove the Part Source from the select statement        
 SELECT @rowId,m.uniq_key,CAST(MAX(CAST(m.selected AS int))AS bit)selected,        
   m.partno, m.rev,m.descript,m.status,q.qty,SUM(m.score)score,        
   CAST(MAX(CAST(m.C AS int))AS bit)C,SUM(m.M)M,CAST(MAX(CAST(m.D AS int))AS bit)D,        
   partClass,partType,u_of_m,MAX(standardCost)standardCost,w.WAREHOUSE,custNo,CustPartNo--,PartSource           
 FROM @matchTbl m         
 LEFT OUTER JOIN @qTbl q ON q.UNIQ_KEY = m.uniq_key         
 LEFT OUTER JOIN WAREHOUS w ON w.UNIQWH = q.uniqWH        
 GROUP BY m.uniq_key,m.partno,m.rev,m.descript,m.status,q.qty,partClass,partType,u_of_m,w.WAREHOUSE,custNo, CustPartNo --,PartSource        
 -- 12/12/18: Vijya G: added Order by clause to partNo to display new (====NEW====) records at the end of list -- ORDER BY score desc         
    Order By m.partno         
          
END