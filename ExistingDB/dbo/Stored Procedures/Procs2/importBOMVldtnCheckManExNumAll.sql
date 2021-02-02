-- =============================================                
-- Author:  David Sharp                
-- Create date: 4/27/2012                
-- Description: check ManEx Part Number                
-- 05/15/13 YS use import bom udf table type in place of temp db                
-- 07/23/13 DS Added exception for manual numbered parts.                
-- 08/05/13 DS Changed 'New' part number value to '===== NEW ====='                
-- 10/23/13 DS revised the AVL verification process for speed improvements                
-- 10/31/13 DS Repivot the import fields to get the latest updates prior to checking for existing values.                
-- 11/05/13 DS Revised how we collect matches and select the best match.                
-- 03/07/14 DS added workCenter and qty to fields not changed by match                
-- 03/11/14 DS changed how it selected records to eliminate duplicates                
-- 03/14/14 DS added handling for skip blank rev setting                
-- 04/02/14 DS removed autonumber validation because it is part of check values                
-- 04/12/14 DS added the ability to skip a match type by setting weight to 0                
-- 06/17/14 DS change method for getting a module setting                
--10/13/14 YS removed invtmfhd table and replaced with 2 new tables                
-- 01/19/15 YS added @rowid, if null or rows                
-- 01/20/15 DS added sort to rev for matches to better control the auto selection.                
-- 06/25/15 DS skipped partno and description match if the fields are empty                
-- 08/31/15 YS/DS - emi had a problem becuase they had 5 character revision entered and this script only concidered 4                  
-- 09/09/15 DS Ensure only one uniq_key will be considered when multiple matches found                
-- 02/20/17 YS if 2 parts with the same AVLs pay attention to is_deleted                
-- 01/10/18 Vijay G: Set blue color if find part with possible matches by AVLs                
-- 01/22/18 Vijay G: Set the validation color if par no value updated by system                
-- 02/05/18 Vijay G: Added the condition for revision to set the validation color if revision value updated by system                
-- 02/13/18: Vijay G: Used the ModulId of the Bill of Material & Import (BOM) to get setting values                
-- 03/27/2018: Vijay G: Changed the asc to Ascending and desc to Descending.                
-- 04/20/18 Vijay G : Moved the Auto Number and Auto Make No setting value from MICSSYS,InvtSetup table to MnxSettingsManagement and wmSettingsManagement table                
-- 04/20/18 Vijay G : Check Auto Part No and Auto Make Part Number setting value from wmSettingsManagement                
-- 06/01/18 Vijay G : Get the setting value by setting name if exist in wmSettingsManagement otherwise from MnxSettingsManagement                
-- 06/01/18 Vijay G : Used the same settingName which are present in the MnxSettingsManagement table.                
-- 08/10/18 Vijay G: Added the condition to do not set status white if part no is empty in template. Set status as it is i.e. red                
-- 11/02/18 Vijay G: Set the validation color if part  part source is consign                
-- 01/26/2019 Sachin B: Fix the Issue the Issue find STDCOST for the Existing Parts                
-- 01/24/2019 : Sachin B:Use the BOM Comp Part Class Warehouse if Not then Use Default Warehouse and Also If Comp Part_Class and Warehouse both are Empty then also use Default Warehouse                 
-- 05/15/2019 Vijay G: Added two column for change value of adjusted if part number is existing                
-- 05/15/2019 Vijay G: Add and condition in the join with invtmpnlink table INNER JOIN InvtMpnClean c ON c.mfgr_pt_no = m.MFGR_PT_NO AND c.partMfgr = m.PartMfgr                
-- 05/21/2019 Vijay G: Add And Condition for rowid is not exists in @matchTbl                
-- 05/22/2019 Vijay G: Fix the CustPartNo and Custrev Blue Color Highlighted                
-- 01/06/2019 Vijay G: Add the color for warehouse if warehouse value is not from spreadsheet                
-- 06/08/2019 Vijay G: Fix the Issue the if the Auto Part no Setting os on and user is adding new part it will show ===== NEW ===== in Part No Fields                
-- 06/11/2019 Vijay G: Add the color for warehouse if warehouse value is not from spreadsheet                
-- 06/12/2019 Vijay G: Remove wrong validation code of BUY part                 
-- 06/12/2019 Vijay G: change Code Position out Side from cursor Code               
-- 08/29/2019 Vijay G: Remove wrong validation code of MAKE part               
--09/27/2019 Vijay G: Selecting row id where partsource is CONSG and BUY             
-- 09/27/2019 Vijay G: Used @isAutoNumber buy part auto partnumbering for CONSG part                               
--01/16/2020 Vijay G Replace name of columns/variable sid with mtc                                 
-- 02/12/2020 Vijay G : Added a validation for itemno field if has entered alphanumeric value                           
-- 02/27/2020 Vijay G : Removed code of auto parnumber setting    
-- 02/27/2020 Vijay G : Added block of code to part number validating base on partclass number setup     
--02/27/2020 Vijay G: Made some changes to see SP in proper format  
--03/19/2020 Sachin B: Added aditional block to populate part no if numbergenrator setup is Customer part as IPN      
--05/14/2020 Sachin B: Removed unwanted code and deleted records to avoid validation if match the part 
-- 07/02/2020 Sachin B First Match in Active Parts if Not Found then check in the inActive Parts  
-- 07/22/2020 Sachin B Match AVL with the Internal part that having consign Part With Same Provided Cust
-- 07/22/2020 Sachin B If the Match is not found then it will work as previous
-- 10/05/2020 Sachin B Remove If Block for the Parts AVL Match Fixes
-- importBOMVldtnCheckManExNumAll '5adc233e-ad0b-41cc-97e0-ddaa8d00aef3'          
-- =============================================                
CREATE PROCEDURE [dbo].[importBOMVldtnCheckManExNumAll]                
 -- Add the parameters for the stored procedure here                
 @importId uniqueIdentifier,                
 @rowId uniqueidentifier = null                
AS                
BEGIN                
 -- SET NOCOUNT ON added to prevent extra result sets from                
 -- interfering with SELECT statements.                
 SET NOCOUNT ON;                
                
    -- Insert statements for procedure here                
 /*                
  SP PROCESS                
  1. Get Field Def Ids                
  2. Build a list of possible matches                
  3. Count how many matches were found (and identify if one of the matches is selected)                 
  4. Update importBOMFields records with results                  
 */                
 -- 02/13/18: Vijay G: Declared the ModulId variable                
    DECLARE /*@rowId uniqueidentifier,*/@descId uniqueidentifier,@revId uniqueidentifier,@mpnId uniqueidentifier,@cpartId uniqueidentifier,                
    @crevId uniqueidentifier,@partId uniqueidentifier, @qty varchar(MAX), @workCenter varchar(MAX),                
   @partSource varchar(max),@custno varchar(10),@itemno varchar(MAX),@used varchar(MAX),                
   --@uniq_key varchar(10),@partnum varchar(max),@rev varchar(max),@providedpn varchar(max),                
   -- @descript varchar(max),@cpartno varchar(max),@selected bit,                
   -- 02/27/2020 Vijay G : Removed code of auto parnumber setting    
   --@isMakeAuto bit, @isAutoNumber bit,                
   @manexMatch int, @custMatch int, @AVLMatch int, @descriptMatch int, @skipBlankRev bit = 1, @fastCheck bit = 0,                
   @rCount int, @matchRevSort varchar(4),@WarehsId uniqueidentifier,                
   @white varchar(20)='i00white',@lock varchar(20)='i00lock',@green varchar(20)='i01green',@blue varchar(20)='i03blue',                
    @orange varchar(20)='i04orange',@red varchar(20)='i05red',                
   @sys varchar(20)='01system',@usr varchar(20)='03user', @moduleId int                
                  
 -- 04/20/18 Vijay G : Moved the Auto Number and Auto Make No setting value from MICSSYS,InvtSetup table to MnxSettingsManagement and wmSettingsManagement table                
 --SELECT @isAutoNumber = XXPTNOSYS FROM MICSSYS                
 -- 04/20/18 Vijay G : Check Auto Number setting value from wmSettingsManagement                
 -- 06/01/18 Vijay G : Get the AutoPartNumber setting value by setting name if exist in wmSettingsManagement otherwise from MnxSettingsManagement                
  -- 02/27/2020 Vijay G : Removed code of auto parnumber setting    
  --SELECT @isAutoNumber= isnull(w.settingValue,m.settingValue)            
  --FROM MnxSettingsManagement M left outer join wmSettingsManagement W on m.settingId=w.settingId                  
  --WHERE settingName ='AutoPartNumber'                
                
 -- 04/20/18 Vijay G : Check Auto Make Number setting value from wmSettingsManagement                
 -- 06/01/18 Vijay G : Get the AutoMakePartNumber setting value by setting name if exist in wmSettingsManagement otherwise from MnxSettingsManagement                
 --SELECT @isMakeAuto = lAutoMakeNo FROM INVTSETUP                
 -- 02/27/2020 Vijay G : Removed code of auto parnumber setting    
 --SELECT @isMakeAuto= isnull(w.settingValue,m.settingValue)                     
 -- FROM MnxSettingsManagement M left outer join wmSettingsManagement W on m.settingId=w.settingId                  
 -- WHERE settingName ='AutoMakePartNumber'                
                  
 /* 1. Get field Def Ids and @custno */                
 SELECT @partSource = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'partSource'                
 SELECT @itemno = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'itemno'                
 SELECT @workCenter = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'workCenter'                
 SELECT @qty = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'qty'                
 SELECT @used = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'used'                
 SELECT @partId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'partNo'                
 SELECT @revId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'rev'                
 SELECT @descId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'descript'                
 SELECT @mpnId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'mpn'                
 SELECT @cpartId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'custPartNo'               
 SELECT @crevId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'crev'                
 select @WarehsId= fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'warehouse'                
 SELECT @custno = custno FROM importBOMHeader WHERE importId = @importId                 
                 
 -- 02/13/18: Vijay G: Used the ModulId of the Bill of Material & Import (BOM) to get setting values                
 -- 06/01/18 Vijay G : Get the module id using ModuleDesc resource key                
 SELECT @moduleId = ModuleId FROM mnxModule WHERE ModuleDesc = 'MnxM_EngProdBOMImport'                
                    
 -- 10/30/13 DS store the import bom fields for faster comparison                 
 DECLARE  @tPartsAll importBom                
 INSERT INTO @tPartsAll EXEC [dbo].[sp_getImportBOMItems] @importId,0,null,0,@rowId                
 DECLARE @tAvlAll tImportBomAvl                 
 INSERT INTO @tAvlAll EXEC [ImportBomGetAvlToComplete] @importID                 
                
                
 /* Get the user settings for the match weight */                
 DECLARE @sTable mnxSettings                
 INSERT INTO @sTable                
 -- 02/13/18: Vijay G: Used the ModulId of the Bill of Material & Import (BOM) to get setting values                
 -- 06/01/18 Vijay G : Used the same settingName which are present in the MnxSettingsManagement table.                
 EXEC [settingsGetValues] @moduleId,0,1                
 SELECT @AVLMatch=COALESCE(settingValue,70) FROM @sTable WHERE settingName='ImpAVLMatch'                
 SELECT @manexMatch=COALESCE(settingValue,100) FROM @sTable WHERE settingName='ImpManexPartMatch'                
 SELECT @custMatch=COALESCE(settingValue,80) FROM @sTable WHERE settingName='ImpCustPartMatch'                
 SELECT @descriptMatch=COALESCE(settingValue,10) FROM @sTable WHERE settingName='ImpDescMatch'                
 SELECT @skipBlankRev=COALESCE(settingValue,1) FROM @sTable WHERE settingName='ImpSkipBlankRev'                
 SELECT @matchRevSort=COALESCE(settingValue,'desc') FROM @sTable WHERE settingName='MatchRevSort'                
 DELETE FROM @sTable      
                
 /*                 
 * Tried to prepopulate a table variable with all parts for the selected customer to improve performance.                  
 * This is the slowest part of the whole process.                
 */                 
 IF @custMatch <> 0                
 BEGIN                
 -- 08/31/15 YS/DS change varchar(4) to varchar(8) for the revision column                
 DECLARE @cInvTable TABLE (uniq_key varchar(10),part_no varchar(50),revision varchar(8),descript varchar(50),custpartno varchar(50),CUSTREV varchar(8),[status] varchar(20))                
 INSERT INTO @cInvTable                
 SELECT int_uniq,PART_NO,REVISION,DESCRIPT,CUSTPARTNO,CUSTREV,[STATUS] FROM INVENTOR WHERE CUSTNO = @custno                
 --SET @rCount = @@ROWCOUNT /* Get row count for max number of matches to find */                
 END                
                
 DECLARE @iAvlTable TABLE(rowId uniqueidentifier,cleanMpn varchar(max),mfg varchar(100))                
 INSERT INTO @iAvlTable                
 SELECT fkRowId,UPPER(dbo.fnKeepAlphaNumeric(adjusted)),ta.PartMfgr                
 FROM importBOMAvl ia 
 INNER JOIN @tAvlAll ta ON ia.fkRowId=ta.rowId                
 WHERE fkImportId = @importId AND fkFieldDefId = @mpnId AND adjusted<>''                 
 --01/19/15 YS added @rowid, if null or rows                
 and (@rowid is null or ia.fkRowId=@rowid)                
                
 -- 10/23/13 DS implemented the use of the InvtMpnClean table for performance improvements                
 -- 02/20/17 YS if 2 parts with the same AVLs pay attention to is_deleted    
 -- 07/02/2020 Sachin B First Match in Active Parts if Not Found then check in the inActive Parts            
 DECLARE @eAvlTable TABLE(uniq_key varchar(10),cleanMpn varchar(max), mfg varchar(100),is_deleted bit)                
 INSERT INTO @eAvlTable                
 --10/13/14 YS removed invtmfhd table and replaced with 2 new tables                
 -- 02/20/17 YS if 2 parts with the same AVLs pay attention to is_deleted                
 SELECT DISTINCT l.UNIQ_KEY,c.cleanMpn,m.PARTMFGR,l.is_deleted                
  --10/13/14 YS removed invtmfhd table and replaced with 2 new tables                
  --FROM INVTMFHD m INNER JOIN INVENTOR i ON i.UNIQ_KEY = m.UNIQ_KEY                 
  FROM InvtMPNLink L                 
  INNER JOIN MfgrMaster m ON L.mfgrMasterId=M.MfgrMasterId                
  INNER JOIN INVENTOR i ON i.UNIQ_KEY = l.UNIQ_KEY  and STATUS ='Active'               
  -- 05/15/2019 Vijay G: Add and condition in the join with invtmpnlink table INNER JOIN InvtMpnClean c ON c.mfgr_pt_no = m.MFGR_PT_NO AND c.partMfgr = m.PartMfgr                
  INNER JOIN InvtMpnClean c ON c.mfgr_pt_no = m.MFGR_PT_NO AND c.partMfgr = m.PartMfgr                
  WHERE CUSTNO = '' AND c.MFGR_PT_NO<>'' AND cleanMpn IN (select cleanmpn from @iAvlTable)  
  
  -- 07/02/2020 Sachin B First Match in Active Parts if Not Found then check in the inActive Parts
  INSERT INTO @eAvlTable                               
  SELECT DISTINCT l.UNIQ_KEY,c.cleanMpn,m.PARTMFGR,l.is_deleted                       
  FROM InvtMPNLink L                 
  INNER JOIN MfgrMaster m ON L.mfgrMasterId=M.MfgrMasterId                
  INNER JOIN INVENTOR i ON i.UNIQ_KEY = l.UNIQ_KEY  and STATUS ='Inactive'                              
  INNER JOIN InvtMpnClean c ON c.mfgr_pt_no = m.MFGR_PT_NO AND c.partMfgr = m.PartMfgr                
  WHERE CUSTNO = '' AND c.MFGR_PT_NO<>'' AND cleanMpn IN (select cleanmpn from @iAvlTable) AND cleanMpn NOT IN (SELECT cleanmpn FROM @eAvlTable)              
                
 /* Add table variable to store updates until the end */                
 -- 08/31/15 YS/DS change varchar(4) to varchar(8) for the revision column                
 -- 02/20/17 YS if 2 parts with the same AVLs pay attention to is_deleted                
 DECLARE @matchTbl TABLE (rowId uniqueidentifier,uniq_key varchar(10),selected bit,partno varchar(50),rev varchar(8),descript varchar(50),                
        [status] varchar(10),score int,C bit,M int,D bit,color varchar(20),vldtn varchar(20),is_deleted bit,match varchar(500))                
 DECLARE @matchTblOther TABLE (rowId uniqueidentifier,uniq_key varchar(10),selected bit,partno varchar(50),rev varchar(8),descript varchar(50),                
        [status] varchar(10),score int,C bit,M int,D bit,color varchar(20),vldtn varchar(20),match varchar(500))                
 /*                 
* 2. Build possible match list                
 * Check for existing record matches                
 */                
 -- 06/25/15 DS Skipped MANEX number matches if not provided.                
 IF @manexMatch <> 0                
 BEGIN                
 INSERT INTO @matchTbl (rowId,uniq_key,selected,partno,rev,descript,[status],score,C,M,D,color,vldtn,match)                
 SELECT tp.rowId, inv.uniq_key,CAST(0 as bit),                
    inv.PART_NO,inv.REVISION,inv.DESCRIPT,inv.STATUS,@manexMatch,                
    CAST(0 as bit),0,CAST(0 as bit),                
    @blue,@sys,'manexPN'                 
 FROM @tPartsAll tp                 
 INNER JOIN INVENTOR inv ON tp.partno = inv.PART_NO                
 WHERE inv.CUSTNO='' AND inv.PART_NO <>'===== NEW =====' AND inv.PART_NO <>''                
 AND 1=CASE WHEN @skipBlankRev = 0 OR tp.rev<>'' THEN CASE WHEN tp.rev=inv.REVISION THEN 1 ELSE 0 END ELSE 1 END                
 --01/19/15 YS added @rowid, if null or rows                
 AND (@rowid IS NULL OR tp.RowId=@rowid)                
 END                
  ----IF @@ROWCOUNT > 0 BEGIN                
  -- SELECT 'manexPN'                
  -- select 1, * from @matchTbl  order by rowId                 
  ----END                
                    
 /* Check Customer Part Numbers to find possible Matches*/                
 -- 11/05/13 DS changed selected to true if rowId is new to the @matchTbl                
 IF @custMatch <> 0                
 BEGIN                
 INSERT INTO @matchTbl(rowId,uniq_key,selected,partno,rev,descript,status,score,C,M,D,color,vldtn,match)                
 SELECT tp.rowId,inv.UNIQ_KEY,CAST(0 as BIT)selected,                
    inv.PART_NO, inv.REVISION, inv.DESCRIPT,inv.STATUS,@custMatch AS Score,                
    CAST(1 AS BIT) C,0 M,CAST(0 AS BIT) D,                
    @blue,@sys,'custPN'                 
 FROM @cInvTable inv INNER JOIN @tPartsAll tp ON tp.custPartNo = inv.CUSTPARTNO                 
 -- 10/30/13 DS IF the rev is provided with the import, it MUST match existing records                
 -- 02/17/14 DS filtered out blank customer part numbers                
 WHERE 1=CASE WHEN  @skipBlankRev = 0 OR tp.crev<>'' THEN CASE WHEN tp.crev = inv.CUSTREV THEN 1 ELSE 0 END ELSE 1 END AND tp.custPartNo<>''                
 --01/19/15 YS added @rowid, if null or rows                
 AND (@rowid IS NULL OR tp.RowId=@rowid)                
 -- 05/21/2019 Vijay G: Add And Condition for rowid is not exists in @matchTbl                
 AND tp.rowId NOT IN (SELECT rowId FROM @matchTbl)                
 END                
   --AND it.rowId NOT IN (SELECT rowId FROM @matchTbl)                
                
  ----IF @@ROWCOUNT > 0 BEGIN                
  -- SELECT 'custPN'                
  -- select * from @matchTbl order by rowId                 
  ----END                
                   
 /* Check AVLs to find possible Matches */                
 IF @AVLMatch <> 0                
 BEGIN                
 -- 02/20/17 YS if 2 parts with the same AVLs pay attention to is_deleted                
   -- 01/10/18 Vijay G: Set blue color if find part with possible matches by AVLs                
 INSERT INTO @matchTbl(rowId,uniq_key,selected,partno,rev,descript,status,score,C,M,D,color,vldtn,is_deleted,match)                
 SELECT iA.rowId, e.UNIQ_KEY,CAST(0 AS BIT)selected,                
   inv.PART_NO, inv.REVISION, inv.DESCRIPT, inv.STATUS,SUM(@AVLMatch) AS Score,                
   CAST(0 AS BIT) C, COUNT(e.uniq_key) M,CAST(0 AS BIT) D,                
   @blue,@sys,e.is_deleted,'AVLExact'                
 FROM @eAvlTable e                 
 INNER JOIN @iAvlTable iA ON e.cleanMpn = iA.cleanMpn                 
 INNER JOIN INVENTOR inv ON e.uniq_key = inv.UNIQ_KEY                
 WHERE iA.cleanMpn <> '' AND 1=CASE WHEN ia.mfg<>'' AND ia.mfg<>'GENR' THEN CASE WHEN ia.mfg=e.mfg THEN 1 ELSE 0 END ELSE 1 END                
  --01/19/15 YS added @rowid, if null or rows                
 AND (@rowid IS NULL OR ia.RowId=@rowid)         
 -- 05/21/2019 Vijay G: Add And Condition for rowid is not exists in @matchTbl                
 AND iA.rowId NOT IN (SELECT rowId FROM @matchTbl)                
 GROUP BY e.UNIQ_KEY, inv.PART_NO, inv.REVISION, inv.DESCRIPT, inv.STATUS, iA.rowId,e.is_deleted                
               
  ----IF @@ROWCOUNT > 0 BEGIN                
  -- SELECT 'AVLExact'                
  -- select 1, * from @matchTbl                 
  ----END                
               
 /* Check to see if the mpn matches regardless of the mfg (if a match hasn't already been found) */                 
 -- 02/20/17 YS if 2 parts with the same AVLs pay attention to is_deleted                
 INSERT INTO @matchTbl(rowId,uniq_key,selected,partno,rev,descript,status,score,C,M,D,color,vldtn,is_deleted,match)                
 SELECT iA.rowId, e.UNIQ_KEY,CAST(0 AS bit)selected,                
   inv.PART_NO, inv.REVISION, inv.DESCRIPT, inv.STATUS,SUM(@AVLMatch/2) AS Score,                
   CAST(0 AS bit) C, COUNT(e.uniq_key) M,CAST(0 AS bit) D,                
   @blue,@sys,e.is_deleted,'AVLMPN'                
 FROM @eAvlTable e                 
 INNER JOIN @iAvlTable iA ON e.cleanMpn = iA.cleanMpn 
 INNER JOIN INVENTOR inv ON e.uniq_key = inv.UNIQ_KEY                
 WHERE iA.cleanMpn <> '' AND ia.rowId NOT IN (SELECT rowId FROM @matchTbl)                
 --01/19/15 YS added @rowid, if null or rows                
 AND (@rowid IS NULL OR ia.RowId=@rowid)                
 GROUP BY e.UNIQ_KEY, inv.PART_NO, inv.REVISION, inv.DESCRIPT, inv.STATUS, iA.rowId,e.is_deleted                
                
  ----IF @@ROWCOUNT > 0 BEGIN                
  -- SELECT 'AVLMPN'                
  -- select 2, * from @matchTbl                 
  ----END                
 END                 
                
 /* Check Description to find possible Matches*/                
 -- 06/25/15 DS skipped rows with a blank description                
 --This match happens ONLY if no other matches were found for the reow                
  -- TODO: Compare standardized and cleaned description fields                
 IF @descriptMatch <> 0                
 BEGIN                
 INSERT INTO @matchTbl(rowId,uniq_key,selected,partno,rev,descript,status,score,C,M,D,color,vldtn,match)                
 SELECT tp.rowId,inv.UNIQ_KEY,CAST(0 AS bit)selected,                
   inv.PART_NO,inv.REVISION,inv.DESCRIPT,inv.STATUS,@descriptMatch AS Score,                
   CAST(0 AS bit) C,0 M,CAST(1 AS bit) D,                
   @blue,@sys,'Descrpt'                
 FROM INVENTOR inv                 
 INNER JOIN @tPartsAll tp ON rtrim(tp.descript)=rtrim(inv.DESCRIPT)                
 WHERE inv.CUSTNO = '' AND tp.uniq_key='' AND tp.rowId NOT IN (SELECT rowId FROM @matchTbl) AND tp.descript <> ''                
 --01/19/15 YS added @rowid, if null or rows                
 AND (@rowid IS NULL OR tp.RowId=@rowid)                
 END                
  ----IF @@ROWCOUNT > 0 BEGIN                
  -- SELECT 'Descrpt'                
  -- select * from @matchTbl                 
  ----END                
                
 /* Get the current Qty on hand for all possible matches.*/                
 DECLARE @qTbl TABLE (uniq_key varchar(10),qty float)                
 INSERT INTO @qTbl                
 SELECT uniq_key, SUM(qty_oh)qty                
 FROM INVTMFGR WHERE UNIQ_KEY IN (SELECT UNIQ_KEY FROM @matchTbl) GROUP BY UNIQ_KEY                
  ----IF @@ROWCOUNT > 0 BEGIN                
  -- SELECT 'Qty'                
  -- select * from @qTbl                 
  ----END                
                
 /* 3. Count how many matches were found*/                
 -- Didn't group by uniq_key to allow a count of possible matches.                
 DECLARE @itTbl TABLE (rowId uniqueidentifier,cnt int,[selected] bit, score int)                
 INSERT INTO @itTbl                
 SELECT rowId,COUNT(rowId)[count],selected,SUM(score)[score]                
 FROM(                
  SELECT m.rowId,m.uniq_key,CAST(MAX(CAST(m.selected AS int))AS bit)selected,m.partno,m.rev,m.descript,m.status,i.qty,SUM(m.score)score,                
    CAST(MAX(CAST(m.C AS int))AS bit)C,SUM(m.M)M,CAST(MAX(CAST(m.D AS int))AS bit)D                
   FROM @matchTbl m                 
   INNER JOIN @qTbl i ON i.UNIQ_KEY = m.uniq_key                
   --01/19/15 YS added @rowid, if null or rows                
   and (@rowid is null or m.RowId=@rowid)                
   GROUP BY m.uniq_key,m.partno,m.rev,m.descript,m.status,i.qty,m.rowId)m                
 GROUP BY rowId,selected                
                
 /*                 
 * Generate a list of parts not previously selected                
 * Select the record with the highest score                
 */                
 --select * from @matchTbl                
 -- 02/20/17 YS if 2 parts with the same AVLs pay attention to is_deleted                
 INSERT INTO @matchTblOther                
 SELECT rowId,uniq_key,selected,partno,rev,descript,[status],score,c,m,d,color,vldtn,match                
  FROM 
  (
	  SELECT                 
	  --02/20/17 YS no need for order by and therefor no need for top 10000                
	   --TOP 1000                 
	  --TOP 1000                 
	  -- 03/27/2018: Vijay G: Changed the asc to Ascending and desc to Descending.                
	  -- Because from UI setting value is saved as 'Ascending' and 'Descending'.                
	  rowId,m.uniq_key,cast(1 as bit) selected,partno,rev,m.descript,m.[status],score,c,m,d,color,vldtn,match,                
	  ROW_NUMBER() 
	  OVER 
	  (
		PARTITION BY rowId ORDER BY score DESC,is_deleted,
		CASE WHEN @matchRevSort = 'Ascending' THEN rev ELSE '' END ASC,                
		CASE WHEN @matchRevSort = 'Descending' THEN rev ELSE '' END DESC
	  ) AS rn                
	   FROM @matchTbl m
	   -- 07/22/2020 Sachin B Match AVL with the Internal part that having consign Part With Same Provided Cust
	   INNER JOIN INVENTOR i on m.uniq_key =CASE WHEN @custno<>'' THEN i.INT_UNIQ ELSE m.uniq_key END and i.CUSTNO = @custno                  
	   WHERE rowId NOT IN (SELECT rowId FROM @matchTbl WHERE selected=1)                
   --02/20/17 YS no need for order by and therefor no need for top 10000                
   --TOP 1000                 
   --ORDER BY                 
   -- CASE WHEN @matchRevSort = 'asc' THEN rev ELSE '' END ASC,                
   -- CASE WHEN @matchRevSort = 'desc' THEN rev ELSE '' END DESC                
   )m                
  WHERE m.rn=1                
  --01/19/15 YS added @rowid, if null or rows                
  and (@rowid is null or RowId=@rowid)  
   
   -- 07/22/2020 Sachin B If the Match is not found then it will work as previous
   -- 10/05/2020 Sachin B Remove If Block for the Parts AVL Match Fixes
   --IF NOT EXISTS (SELECT 1 FROM @matchTblOther)  
   --BEGIN
	  INSERT INTO @matchTblOther                
	  SELECT rowId,uniq_key,selected,partno,rev,descript,[status],score,c,m,d,color,vldtn,match                
	  FROM 
	  (
		  SELECT                 	                 
		  rowId,m.uniq_key,cast(1 as bit) selected,partno,rev,m.descript,m.[status],score,c,m,d,color,vldtn,match,                
		  ROW_NUMBER() 
		  OVER 
		  (
			PARTITION BY rowId ORDER BY score DESC,is_deleted,
			CASE WHEN @matchRevSort = 'Ascending' THEN rev ELSE '' END ASC,                
			CASE WHEN @matchRevSort = 'Descending' THEN rev ELSE '' END DESC
		  ) AS rn                
		   FROM @matchTbl m
		   WHERE rowId NOT IN (SELECT rowId FROM @matchTbl WHERE selected=1) AND rowId NOT IN (SELECT rowId FROM @matchTblOther)                              
	   )m                
	   WHERE m.rn=1 AND (@rowid IS NULL OR RowId=@rowid)
   --END              
                
 UPDATE m                
  SET m.selected=1                
  FROM @matchTbl m INNER JOIN @matchTblOther o ON m.rowId=o.rowId AND m.uniq_key=o.uniq_key                
                
  --SELECT rowId,uniq_key,color,vldtn,match FROM @matchTbl WHERE selected=1 order by rowId                
 UPDATE i                
  SET i.uniq_key=m.uniq_key,i.[status]=m.color,i.[validation]=m.vldtn,                
   i.message= CASE                 
    WHEN m.match='manexPN' THEN 'Matched by Internal PN'                
    WHEN m.match='custPN' THEN 'Matched by Customer PN'                
    WHEN m.match='AVLExact' THEN 'Matched by MFG and Manufacturer PN'                 
    WHEN m.match='Descrpt' THEN 'Matched by Description'                 
    ELSE 'Other Match'                 
   END                
  FROM importBOMFields i INNER JOIN                
   (SELECT rowId,uniq_key,color,vldtn,match FROM @matchTbl WHERE selected=1)m ON i.rowId=m.rowId                
  WHERE fkFieldDefId <> @itemno AND fkFieldDefId <> @used AND fkFieldDefId <>@partSource AND fkFieldDefId <> @qty AND fkFieldDefId <> @workCenter                
  -- 05/22/2019 Vijay G: Fix the CustPartNo and Custrev Blue Color Highlighted                
  AND fkFieldDefId <> @cpartId AND fkFieldDefId <> @crevId     
                 
 /* 4. Update importBOMFields records with results */                
 UPDATE importBOMFields                
  SET [status]=@orange,[validation]=@sys, [message]='More than one possible match found'                
  WHERE fkImportId = @importId AND (fkFieldDefId = @partId OR fkFieldDefId = @revId)  AND ([status] <>@green OR adjusted='===== NEW =====')                
    AND rowId IN (SELECT rowId FROM @itTbl WHERE cnt > 1)                
                 
 /* Mark invalid provded ManEx numbers, ignore parts without a part loaded*/                
 /* 07/23/13 DS check for manual numbering separately */                
 ---- 09/27/2019 Vijay G: Selecting row id where partsource is CONSG and BUY  
 --05/14/2020 Sachin B: Removed unwanted code and deleted records to avoid validation if match the part            
 --DECLARE @buyCheck TABLE (rowId uniqueidentifier)                
 --INSERT INTO @buyCheck                
 --SELECT rowId FROM importBOMFields WHERE fkImportId=@importId AND fkFieldDefId=@partSource AND adjusted IN('BUY','CONSG')                     
                 
 --DECLARE @makeCheck TABLE (rowId uniqueidentifier)                
 --INSERT INTO @makeCheck                
 --SELECT rowId FROM importBOMFields WHERE fkImportId=@importId AND fkFieldDefId=@partSource AND adjusted='MAKE'        
 -- 02/27/2020 Vijay G : Added block of code to part number validating base on partclass number setup       
 DECLARE @tempPartDetails TABLE (rowId uniqueidentifier,partClass VARCHAR(16))            
 DECLARE @partClassId uniqueidentifier,@partTypeId uniqueidentifier,@tempRowId uniqueidentifier,@tempPartClass VARCHAR(16),@tempPartType VARCHAR(16),@numgenrator VARCHAR(20),      
  @classPrfx VARCHAR(3),@typePrfx VARCHAR(10),@custPartNo VARCHAR(35)      
 SELECT @partClassId=fielddefid FROM importBOMFieldDefinitions WHERE fieldName='PartClass'      
 SELECT @partTypeId=fielddefid FROM importBOMFieldDefinitions WHERE fieldName='PartType'    
       
 INSERT INTO @tempPartDetails (rowId,partClass)        
 SELECT rowId,adjusted FROM importBOMFields WHERE fkImportId=@importId AND fkfielddefid=@partClassId      
  DELETE FROM  @tempPartDetails where rowId IN (SELECT rowId FROM @itTbl)  
 WHILE (EXISTS (SELECT * FROM @tempPartDetails))                    
 BEGIN      
    SELECT TOP 1 @tempPartClass=partClass,@tempRowId=rowId FROM @tempPartDetails      
 SELECT @tempPartType =adjusted FROM importBOMFields WHERE fkImportId=@importId AND rowId=@tempRowId AND fkFieldDefId=@partTypeId      
 SELECT @typePrfx= PREFIX FROM PARTTYPE where PART_CLASS=@tempPartClass AND PART_TYPE=@tempPartType      
 SELECT @classPrfx= classPrefix FROM PartClass where PART_CLASS=@tempPartClass       
      
 SELECT @numgenrator= numberGenerator FROM PartClass WHERE part_class=@tempPartClass      
 IF(@numgenrator='Auto')      
 BEGIN      
  UPDATE importBOMFields                
  SET [status]=@blue,[validation]=@sys, [message] = 'New part will be created at completion',adjusted='===== NEW ====='                
  WHERE fkImportId = @importId AND (fkFieldDefId = @partId )               
  --AND NOT(rowId IN (SELECT rowId FROM @itTbl))                 
  AND rowId =@tempRowId        
 END      
--03/19/2020 Sachin B: Added aditional block to populate part no if numbergenrator setup is Customer part as IPN   
 IF(@numgenrator='CustPNasIPN')      
 BEGIN      
     SET @custPartNo=''    
     SELECT @custPartNo =imp.adjusted FROM importBOMFields imp JOIN importBOMFieldDefinitions ifd     
                     ON ifd.fieldDefId=imp.fkFieldDefId AND ifd.fieldname='custPartNo' AND imp.rowId=@tempRowId    
     IF(@custPartNo<>'' AND @custPartNo<>NULL)    
  BEGIN    
  UPDATE importBOMFields                
  SET [status]=@blue,[validation]=@sys, [message] = '',adjusted=@custPartNo                
  WHERE fkImportId = @importId AND (fkFieldDefId = @partId )               
  AND rowId =@tempRowId        
  END    
 END       
      
 --IF(@numgenrator='ManualPrfx')      
 --BEGIN      
 --  UPDATE importBOMFields                 
 --  SET [status]=@blue,[validation]=@sys, [message] = '',adjusted=IsNULL(@classPrfx,'')+IsNULL(@typePrfx,'') +adjusted                
 --  WHERE fkImportId = @importId AND (fkFieldDefId = @partId )               
 --    --AND NOT(rowId IN (SELECT rowId FROM @itTbl))                 
 --    AND rowId =@tempRowId        
 --END      
 DELETE FROM @tempPartDetails WHERE rowId=@tempRowId      
 END      
        
 /* BUY PARTS */                
 --IF @isAutoNumber = 0                 
  --SET @isAutoNumber = 0                
  --UPDATE importBOMFields                
  -- SET [status]=@red,[validation]=@sys, [message] = 'Part Number|Rev does not exist'                
  -- WHERE fkImportId = @importId AND (fkFieldDefId = @partId OR fkFieldDefId = @revId)  AND /*[status]<>@green AND */                
  --   NOT(rowId IN (SELECT rowId FROM @itTbl))AND (adjusted=''OR adjusted='===== NEW =====')                
  --   AND rowId IN (SELECT rowId FROM @buyCheck)                  
 --ELSE                
 -- 02/27/2020 Vijay G : Removed code of auto parnumber setting                
 --IF @isAutoNumber = 1                
 --BEGIN                
 --  -- 06/12/2019 Vijay G: Remove wrong validation code of BUY part                 
 -- --UPDATE importBOMFields                
 -- -- SET [status]=@red,[validation]=@sys, [message] = 'Part Number|Rev must be set'                
 -- -- WHERE fkImportId = @importId AND (fkFieldDefId = @partId OR fkFieldDefId = @revId)  AND /*[status]<>@green AND */                
 -- --   NOT(rowId IN (SELECT rowId FROM @itTbl))AND adjusted<>''AND adjusted<>'===== NEW ====='                
 -- --   AND rowId IN (SELECT rowId FROM @buyCheck)                 
 -- UPDATE importBOMFields                
 --  SET [status]=@blue,[validation]=@sys, [message] = 'New part will be created at completion'                
 --  WHERE fkImportId = @importId AND (fkFieldDefId = @partId OR fkFieldDefId = @revId)  /*AND [status]<>@green*/                
 --    AND NOT(rowId IN (SELECT rowId FROM @itTbl)) AND adjusted='===== NEW ====='                
 --    AND rowId IN (SELECT rowId FROM @buyCheck)                 
 --END                
 /* MAKE PARTS */                
 --IF @isMakeAuto = 0                
  --UPDATE importBOMFields                
  -- SET [status]=@red,[validation]=@sys, [message] = 'Part Number|Rev must be set'                
  -- WHERE fkImportId = @importId AND (fkFieldDefId = @partId OR fkFieldDefId = @revId)  AND /*[status]<>@green AND */                
  --   NOT(rowId IN (SELECT rowId FROM @itTbl))AND (adjusted='' OR adjusted='===== NEW =====')                
  --   AND rowId IN (SELECT rowId FROM @makeCheck)                 
 --ELSE                
 --IF @isMakeAuto = 1                
 --BEGIN                
 -- -- 08/29/2019 Vijay G: Remove wrong validation code of MAKE part             
 -- --UPDATE importBOMFields                
 -- -- SET [status]=@red,[validation]=@sys, [message] = 'Part Number|Rev does not exist'                
 -- -- WHERE fkImportId = @importId AND (fkFieldDefId = @partId OR fkFieldDefId = @revId)  AND /*[status]<>@green AND*/                 
 -- --   NOT(rowId IN (SELECT rowId FROM @itTbl))AND adjusted<>'' AND adjusted<>'===== NEW ====='                
 -- --   AND rowId IN (SELECT rowId FROM @makeCheck)                 
 -- UPDATE importBOMFields                
 --  SET [status]=@blue,[validation]=@sys, [message] = 'New part will be created at completion'                
 --  WHERE fkImportId = @importId AND (fkFieldDefId = @partId OR fkFieldDefId = @revId)  /*AND [status]<>@green*/                
 --    AND NOT(rowId IN (SELECT rowId FROM @itTbl)) AND (adjusted = '' OR adjusted='===== NEW =====')                
 --    AND rowId IN (SELECT rowId FROM @makeCheck)                
 --END                
                 
 /* Enter the uniq_key for all fields on row, if it exists*/               
 -- 09/09/15 DS Ensure only one uniq_key will be considered               
 ;WITH cte AS                
 (SELECT DISTINCT rowid,MIN(uniq_key)uniq_key FROM importBOMFields WHERE uniq_key <>''and fkImportId =@importId GROUP BY rowId)                
 UPDATE importBOMFields SET uniq_key=CTE.Uniq_key FROM cte WHERE cte.rowid=importBOMFields.rowId                 
 --UPDATE i                
 -- SET i.uniq_key=i2.uniq_key                
 -- FROM importBOMFields i RIGHT OUTER JOIN (SELECT DISTINCT rowId,uniq_key FROM importBOMFields WHERE uniq_key <>'')i2 ON i.rowId=i2.rowId                
 -- WHERE  i.fkImportId = @importId                
                
 /* Mark the protected cells as locked */                
 UPDATE i                
  SET i.lock = 1,i.[status]=@lock,i.[message]='Set by internal part number',i.[validation]=@sys                
  FROM importBOMFields i INNER JOIN INVENTOR inv ON i.uniq_key = inv.UNIQ_KEY                
  WHERE fkFieldDefId IN (SELECT fieldDefId FROM importBOMFieldDefinitions WHERE existLock = 1) AND                
   i.rowID IN (SELECT rowId FROM importBOMFields WHERE fkImportId = @importId AND uniq_key <> '')                
                   
 -- 11/18/12 YS changed the code to allow dynamic structure of the import fields                
 -- code to produce dynamic structure                
 -- 05/15/13 YS use import bom udf table type in place of temp db                
 -- {DELETED}                
 -- 10/30/13 DS moved to the top for use throughout                
 -- {DELETED}                
                 
 --05/15/13 YS back to @tPartsAll                
 -- 10/31/13 DS Repivot the import fields to get the latest updates prior to checking for existing values.                
 /* Copy the locked values from the existing part number */                
 DELETE FROM @tPartsAll                
 INSERT INTO @tPartsAll                
 EXEC [dbo].[sp_getImportBOMItems] @importId                
                 
 UPDATE tp                
  SET tp.partClass=RTRIM(inv.PART_CLASS),tp.partType=RTRIM(inv.PART_TYPE),tp.descript=RTRIM(inv.DESCRIPT),                
   tp.u_of_m=RTRIM(inv.U_OF_MEAS),tp.partno=RTRIM(inv.PART_NO),tp.rev=RTRIM(inv.REVISION),                
   -- 01/26/2019 Sachin B: Fix the Issue the Issue find STDCOST for the Existing Parts                
   tp.standardCost =inv.STDCOST,                
   --05/15/2019 Vijay G: Added two column for change value of adjusted if part number is existing                
   --01/16/2020 Vijay G Replace name of columns/variable sid with mtc                
   tp.[mtc] =inv.useipkey,                
   tp.serial =inv.SERIALYES                
  FROM @tPartsAll tp                 
  INNER JOIN INVENTOR inv ON tp.uniq_key = inv.UNIQ_KEY                
                  
  -- 06/08/2019 Vijay G: Fix the Issue the if the Auto Part no Setting os on and user is adding new part it will show ===== NEW ===== in Part No Fields                
  -- 06/12/2019 Vijay G: change Code Position out Side from cursor Code                
  -- 09/27/2019 Vijay G: Used @isAutoNumber buy part auto partnumbering for CONSG part        
  -- 02/27/2020 Vijay G : Removed code of auto parnumber setting                  
  --IF @isAutoNumber = 1                
  --BEGIN                
  --UPDATE p                
  --SET p.partno = CASE WHEN i.PART_NO IS NULL THEN '===== NEW =====' ELSE p.partno END                
  --FROM @tPartsAll p                
  --LEFT JOIN INVENTOR i ON i.PART_NO =p.partno AND i.REVISION =p.rev AND i.CUSTNO ='' AND i.PART_SOURC ='BUY'                
  --WHERE p.partSource ='BUY' OR  p.partSource ='CONSG'                     
  --END                
  --IF @isMakeAuto = 1                
  --BEGIN                
  --UPDATE p                
  --SET p.partno = CASE WHEN i.PART_NO IS NULL THEN '===== NEW =====' ELSE p.partno END                
  --FROM @tPartsAll p                
  --LEFT JOIN INVENTOR i ON i.PART_NO =p.partno AND i.REVISION =p.rev AND i.CUSTNO ='' AND i.PART_SOURC ='MAKE'                
  --WHERE p.partSource ='MAKE'                 
  --END                
                
  -- 01/24/2019 : Sachin B:Use the BOM Comp Part Class Warehouse if Not then Use Default Warehouse and Also If Comp Part_Class and Warehouse both are Empty then also use Default Warehouse                 
  DECLARE @PartRowId UNIQUEIDENTIFIER,@PartClassData NVARCHAR(8),@UniqWH CHAR(10)                
                
  DECLARE PartsCurosr CURSOR LOCAL FAST_FORWARD                      
  FOR  SELECT rowid,partClass FROM @tPartsAll WHERE warehouse =''                
                  
  OPEN PartsCurosr;                      
                    
  FETCH NEXT FROM PartsCurosr INTO @PartRowId,@PartClassData;                
              
  WHILE @@FETCH_STATUS = 0                      
  BEGIN                                   
 IF @PartClassData <>''                      
 BEGIN                          
  SET @UniqWH = (SELECT uniqwh FROM PartClass WHERE part_class =@PartClassData)                
  IF(@UniqWH IS NOT NULL AND @UniqWH<>'')                
  BEGIN                
   UPDATE @tPartsAll SET warehouse =(SELECT WAREHOUSE FROM WAREHOUS WHERE UNIQWH =@UniqWH)                
   WHERE rowId =@PartRowId                
  END                
  ELSE                
  BEGIN                          
   UPDATE @tPartsAll SET warehouse =(SELECT WAREHOUSE FROM WAREHOUS WHERE [DEFAULT] =1)                
   WHERE rowId =@PartRowId                           
  END                
        -- 01/06/2019 Vijay G: Add the color for warehouse if warehouse value is not from spreadsheet                  
        UPDATE importBOMFields SET [status]= @blue,[message]='System Default Warehouse'                 
  WHERE rowId =@PartRowId and fkImportId=@importId  AND uniq_key=''                
  AND fkFieldDefId=@WarehsId                
                
  FETCH NEXT FROM PartsCurosr INTO @PartRowId,@PartClassData;                   
  CONTINUE                      
 END                
    ELSE                
    BEGIN                
        UPDATE @tPartsAll SET warehouse =(SELECT WAREHOUSE FROM WAREHOUS WHERE [DEFAULT] =1)                
  WHERE rowId =@PartRowId                
                     
        -- 06/11/2019  Vijay G: Add the color for warehouse if warehouse value is not from spreadsheet                
  UPDATE importBOMFields SET [status]= @blue,[message]='System Default Warehouse'                 
  WHERE rowId =@PartRowId AND fkImportId=@importId  AND uniq_key=''                
  AND fkFieldDefId=@WarehsId                 
                
  FETCH NEXT FROM PartsCurosr INTO @PartRowId,@PartClassData;                
  CONTINUE                
    END                
  END                
  CLOSE PartsCurosr;                      
  DEALLOCATE PartsCurosr;                    
                
 UPDATE i                
  SET i.adjusted = u.adjusted,i.uniq_key=u.uniq_key                
  FROM(                
   SELECT importId,rowId,[uniq_key],[itemno],[used],[partSource],[partClass],[partType],[qty],[custPartNo],[cRev],[descript],[u_of_m],[warehouse],                
     [standardCost],[workCenter],[partno],[rev]                
   FROM @tPartsAll)p                
  UNPIVOT                
   (adjusted FOR fieldName IN                 
    ([itemno],[used],[partSource],[partClass],[partType],[qty],[custPartNo],[cRev],[descript],[u_of_m],[warehouse],[standardCost],[workCenter],[partno],[rev])                
  ) AS u                 
   INNER JOIN importBOMFieldDefinitions fd ON fd.fieldName = u.fieldName                 
   INNER JOIN importBOMFields i ON i.rowId=u.rowId AND i.fkFieldDefId=fd.fieldDefId AND i.fkImportId=u.importId                
                
 -- 02/05/18 Vijay G: Added the condition for PartNo and revision to set the validation color, if revision value updated by system           
 -- 08/10/18 Vijay G: Added the condition to do not set status white if part no is empty in template. Set status as it is i.e. red                
    UPDATE importBOMFields SET status = CASE WHEN adjusted = original AND  status <> @red THEN @white ELSE status END                 
         FROM importBOMFields where fkImportId=@importId and (fkFieldDefId=@partId OR fkFieldDefId = @revId)                
                
     -- 11/02/18 Vijay G: Set the validation color if part  part source is consign                  
  UPDATE  importBOMFields                  
  SET [status]=@red,[message]='Please enter customer part number as part source is consign.'                  
  WHERE fkFieldDefId = @cpartId AND rowId IN (SELECT rowId FROM @tPartsAll where LOWER(partSource) = 'consg' AND custPartNo = '')                
                
    -- 06/08/2019 Vijay G: Fix the Issue the if the Auto Part no Setting os on and user is adding new part it will show ===== NEW ===== in Part No Fields        
 -- 02/27/2020 Vijay G : Removed code of auto parnumber setting          
 --IF @isAutoNumber = 1 OR @isMakeAuto =1                
 --BEGIN                
 -- UPDATE importBOMFields                
 -- SET [status]=@blue,[validation]=@sys, [message] = 'New part will be created at completion'                
 -- WHERE fkImportId = @importId AND (fkFieldDefId = @partId OR fkFieldDefId = @revId)                
 -- AND adjusted='===== NEW ====='                 
 --END         
          
-- 02/12/2020 Vijay G : Added a validation for itemno field if has entered alphanumeric value       
  UPDATE i                  
   SET i.[status]=@red,i.[message]='Value is not a number',i.[validation]=@sys,i.adjusted=0              
   FROM importBOMFields AS i INNER JOIN importBOMFieldDefinitions d ON i.fkFieldDefId=d.fieldDefId              
   AND d.fieldName='itemno' AND ISNUMERIC(i.adjusted)<>1               
END