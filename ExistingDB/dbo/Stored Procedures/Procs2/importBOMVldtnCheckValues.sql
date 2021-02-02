-- =============================================                
-- Author:  David Sharp                
-- Create date: 4/24/2012                
-- Description: checks the standard values for import record                
-- 05/15/13 YS use import bom udf table type in place of temp db                
-- 06/25/13 DS last change to remove extra reset to white                
-- 07/02/13 DS verify that the part number/rev does not match the assembly number                
-- 07/15/13 DS Added table variable to int check to reduce the number of records evaluated and prevent errors when accidentally evaluating non-int fields                
-- 08/05/13 DS Changed 'New' part number value to '===== NEW ====='                
-- 12/18/13 DS Convert all standardCosts to a float if they contain E-                
-- 04/02/14 DS removed autonumber validation because it is part of check values                
-- 05/17/15 YS add new test for part type , removed valueSQL value from parttype field definiton                
-- 05/27/15 YS added filter by importid. Was missing during some valdation and the update                
-- 07/23/15 DS added error logging                
-- 12/02/15 YS remove '-' from like '%E-%' Hi-Tek had an issue uploading there was an invisible character between E and '-' and it would fail                
-- 03/27/2018: Vijay G: Added the rowId parameter also passed the rowId parameter to SP importBOMVldtnPartTypeValues to update record using rowId                
-- 04/20/18 Vijay G : Moved the Auto Number and Auto Make No setting value from MICSSYS,InvtSetup table to MnxSettingsManagement and wmSettingsManagement table                
-- 04/20/18 Vijay G : Check Auto Part Number and Make Part No setting value from wmSettingsManagement                
-- 06/01/18 Vijay G : Get the setting value by setting name if exist in wmSettingsManagement otherwise from MnxSettingsManagement                
-- 08/16/18: Vijay G: If the Ref Designator is not provided from template then set validation message as "No Ref Desg Loaded".                
-- 08/20/18: Vijay G: Added condition to avoid validation of same workcenter for those Part with empty part no and rev for more than one item number in the same work center.              
-- 10/25/18: Vijay G: Fix the Issue for the Ref Des Validation for the Parts having U_OF_M 'EACH'              
-- 11/02/18 Vijay G: Set the validation color if part  part source is consign              
-- 01/12/19 Vijay G: Add Code for the in Active Part validation            
-- 05/21/19 Vijay G: Add red color error validation if itemno is duplicate            
-- 05/23/19 Vijay G: Change In Active Part Color legend            
-- 05/24/19 Vijay G: Duplicate Part No Color Validation is not removing          
-- 05/24/2019 Vijay G : modify sp for remove blue color of standard cost field if part not exist         
-- 08/29/2019 Vijay G:Update existing code for update importBOMFields if buy parts auto numbering is on          
-- 08/29/2019 Vijay G:Commented existing code for updating records base on there auto part numbering setting  base partSource           
-- 08/29/2019 Vijay G:Added new block for update importBOMFields if make or phantom parts auto numbering is on        
--09/27/2019 Vijay G:Change the case from @makeNum=0 to @autoNum=0 AND added one more filter adjusted='CONSG'                   
-- 02/12/2020 Vijay G : Added a validation for itemno field if has entered alphanumeric value         
-- 02/12/2020 Vijay G : Use to avoid repeat validation of itemNo field        
-- 02/27/2020 Vijay G : Removed code of auto parnumber setting    
-- 02/27/2020 Vijay G : Added part number validation base part class number setup    
--02/27/2020 Vijay G: Made some changes to see SP in proper format   
--03/19/2020 Sachin B: Added aditional block to populate part no if numbergenrator setup is Customer part as IPN   
-- 03/06/2020 Sachin B : Added validation on part if user has entered part which exists in the system but partsource which user has enterd is not match with part details 
-- =============================================                
CREATE PROCEDURE [dbo].[importBOMVldtnCheckValues]            
 -- Add the parameters for the stored procedure here                
 -- 03/27/2018: Vijay G: Added the rowId parameter                
 @importId UNIQUEIDENTIFIER,                
 @rowId UNIQUEIDENTIFIER = NULL                
AS                
BEGIN                
 -- SET NOCOUNT ON added to prevent extra result sets from                
 -- interfering with SELECT statements.                
 SET NOCOUNT ON;                
                
    -- Insert statements for procedure here                
    DECLARE @fdid uniqueidentifier,@rCount int,@adjusted varchar(MAX),@dSql varchar(MAX),@erMsg varchar(max),          
 @headerErrs varchar(MAX), @stdCostId  uniqueidentifier           
             
    DECLARE @white varchar(20)='i00white',@lock varchar(20)='i00lock',@green varchar(20)='i01green',@blue varchar(20)='i03blue',@orange varchar(20)='i04orange',@red varchar(20)='i05red',                
 @sys varchar(20)='01system',@usr varchar(20)='03user'                
          
 SELECT @stdCostId= fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'standardCost'          
                          
 DECLARE @ErrTable TABLE (ErrNumber int,ErrSeverity int,ErrProc varchar(MAX),ErrLine int,ErrMsg varchar(MAX))                
                    
    /* Length Check - Warn for any field with a length longer than the definition length */                
 -- 05/27/15 YS added filter by importid. Was missing during some valdation and the update                
 BEGIN TRY -- inside begin try                
  UPDATE f                
  SET [message]='Field will be truncated to ' + CAST(fd.fieldLength AS varchar(50)) + ' characters.',[status]=@orange,[validation]=@sys                
  FROM importBOMFields f                 
  INNER JOIN importBOMFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength>0                
  WHERE fkImportId=@importId                
  AND LEN(f.adjusted)>fd.fieldLength                  
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
  ERROR_NUMBER() AS ErrorNumber                
  ,ERROR_SEVERITY() AS ErrorSeverity                
  --,ERROR_STATE() AS ErrorState                
  ,ERROR_PROCEDURE() AS ErrorProcedure                
  ,ERROR_LINE() AS ErrorLine                
  ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues in the fields to be truncated (starting on line:44)'                
 END CATCH                
                
                
 /* Reset all status to white to start fresh, unless it is blue, green, or lock */                 
 -- 05/27/15 YS added filter by importid. Was missing during some valdation and the update                 
 BEGIN TRY -- inside begin try                
  UPDATE f                
   SET [message] = '',[status]=@white,[validation]=@sys                
   FROM importBOMFields f                 
   INNER JOIN importBOMFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength>0                
   WHERE fkimportid = @importId                
   AND LEN(adjusted)<fd.fieldLength AND original=adjusted AND [status]<>@blue AND [status]<>@green AND [status]<>@lock                
   -- 05/27/15 YS added filter by importid. Was missing during some valdation and the update                 
  UPDATE f                
   SET [message] = '',[status]=@green,[validation]=@usr                
   FROM importBOMFields f                 
   INNER JOIN importBOMFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength>0                
   WHERE fkImportId=@importId      
   AND fd.fieldName<>'ItemNo'   -- 02/12/2020 Vijay G : Use to avoid repeat validation of itemNo field               
   and LEN(adjusted)<fd.fieldLength AND original<>adjusted AND [status]<>@blue AND [status]<>@lock AND uniq_key=''                
   END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
   ERROR_NUMBER() AS ErrorNumber                
   ,ERROR_SEVERITY() AS ErrorSeverity                
   --,ERROR_STATE() AS ErrorState                
   ,ERROR_PROCEDURE() AS ErrorProcedure                
   ,ERROR_LINE() AS ErrorLine                
   ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues resetting the status to white to start fresh (starting on line:67)'                
 END CATCH                
                   
 /* Ensure the adjusted standard cost is a number */                
 -- 12/02/15 YS remove '-' from like '%E-%' Hi-Tek had an issue uploading there was an invisible character between E and '-' and it would fail                
 BEGIN TRY -- inside begin try                
  UPDATE f                
   SET adjusted = CAST(adjusted as float)                
   FROM importBOMFields f                 
   INNER JOIN importBOMFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldName='standardCost'                
   WHERE fkImportId=@importId                
      and adjusted like '%E%'                
   -- and adjusted like '%E-%'                
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
   ERROR_NUMBER() AS ErrorNumber                
   ,ERROR_SEVERITY() AS ErrorSeverity                
   --,ERROR_STATE() AS ErrorState                
   ,ERROR_PROCEDURE() AS ErrorProcedure                
   ,ERROR_LINE() AS ErrorLine                
   ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues verifying the standard cost is a number (starting on line:95)'                
 END CATCH                
                 
 /* Get a list of field definitions to be processed with this sp and with a valueSQL set */                
    /* Description length, qty vs ref count, and customer part number are processed separately */                
    BEGIN TRY -- inside begin try                
 BEGIN                    
  DECLARE fd_cursor CURSOR LOCAL FAST_FORWARD                
  FOR                
  SELECT  fieldDefId,valueSQL,errMsg                
  FROM  importBOMFieldDefinitions                
  WHERE  validationSP = 'importBOMCheckValues' AND valueSQL <>''                
  OPEN  fd_cursor;                
 END                
 FETCH NEXT FROM fd_cursor INTO @fdid,@dSql,@erMsg                
 --SELECT * FROM importBOMFieldDefinitions                
                    
 WHILE @@FETCH_STATUS = 0                
 BEGIN                
  /* Get a list of bom import records related to the current field definition id */                
  BEGIN                    
   DECLARE rt_cursor CURSOR LOCAL FAST_FORWARD                
   FOR                
   SELECT DISTINCT adjusted                
   FROM  importBOMFields                
   WHERE  fkFieldDefId = @fdid AND fkImportId = @importId                
   OPEN  rt_cursor;                
  END                
  FETCH NEXT FROM rt_cursor INTO @adjusted                
                   
  /* Get the preset error message (if any) and the SQL to check for matching values */                
  --SELECT @dSql = valueSQL, @erMsg = errMsg FROM importBOMFieldDefinitions WHERE fieldDefId = @fdid                
  IF @erMsg = '' SET @erMsg = 'Incorrect Value'                
  DECLARE @cTable TABLE (matches varchar(max))                
  INSERT INTO @cTable                 
  EXEC(@dSql)                     
                   
  WHILE @@FETCH_STATUS = 0                
  BEGIN                
   /* Determine if the DB contains matching values as currently set in the import adjusted column */                
   SELECT @rCount = count(matches) FROM @cTable WHERE matches = @adjusted                 
                  
   /* Check the CheckValue alias table for possible matches */                
   DECLARE @alias varchar(max)=''                
   IF @rCount=0          
   BEGIN                
    SET @alias=@adjusted                
    SELECT @rCount = COUNT(*),@adjusted=systemValue                 
     FROM importBOMCheckValueAliases                 
     WHERE fkFieldDefId=@fdid AND rtrim(ltrim(alias))=RTRIM(ltrim(@alias))                
     GROUP BY systemValue,fkFieldDefId                
   END                
                 
   EXEC importBOMVldtnUpdateField @adjusted=@adjusted,@rcount=@rCount,@fieldDefId=@fdid,@importId=@importId,@messageValue=@erMsg,@alias=@alias                
   FETCH NEXT FROM rt_cursor INTO @adjusted                
  END                
  DELETE @cTable                 
  CLOSE rt_cursor                
  DEALLOCATE rt_cursor                
  FETCH NEXT FROM fd_cursor INTO @fdid,@dSql,@erMsg                
 END                
 CLOSE fd_cursor                
 DEALLOCATE fd_cursor          
           
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
   ERROR_NUMBER() AS ErrorNumber                
   ,ERROR_SEVERITY() AS ErrorSeverity                
   --,ERROR_STATE() AS ErrorState                
   ,ERROR_PROCEDURE() AS ErrorProcedure                
   ,ERROR_LINE() AS ErrorLine                
   ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues verifying the standard fields (starting on line:117)'                
 END CATCH                
 /* 05/17/15 YS add new test for part type */                
 BEGIN TRY -- inside begin try                
  -- 03/27/2018: Vijay G: Passed the rowId parameter to SP importBOMVldtnPartTypeValues to update record using rowId                
  EXEC [importBOMVldtnPartTypeValues] @importId,@rowId                
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
   ERROR_NUMBER() AS ErrorNumber                
   ,ERROR_SEVERITY() AS ErrorSeverity                
   --,ERROR_STATE() AS ErrorState                
   ,ERROR_PROCEDURE() AS ErrorProcedure                
   ,ERROR_LINE() AS ErrorLine                
   ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues checking the part type values (line:189)'                
 END CATCH                
                
 /* 06/25/13 DS Adjusted so ALL required fields have a value */                
 -- 05/27/15 YS added filter by importid. Was missing during some valdation and the update                
 BEGIN TRY -- inside begin try                
  UPDATE f                
   SET [message] = 'Required Field',[status]=@red,[validation]=@sys                
   FROM importBOMFields f INNER JOIN importBOMFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                
   WHERE fkImportId=@importId                 
   and adjusted='' AND d.[required]=1                
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
   ERROR_NUMBER() AS ErrorNumber                
   ,ERROR_SEVERITY() AS ErrorSeverity                
   --,ERROR_STATE() AS ErrorState                
   ,ERROR_PROCEDURE() AS ErrorProcedure                
   ,ERROR_LINE() AS ErrorLine                
   ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                
 END CATCH                
                    
    /****** MANEX PART NUMBER ******/                
 /* Set blank parno fields to "NEW", if auto numbered status is blue, if manual, status is red */                
 BEGIN TRY -- inside begin try                
  DECLARE @partnoId uniqueidentifier ,@partSourceId uniqueidentifier            
  SELECT @partnoId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='partno'                
  SELECT @partSourceId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='partSource'              
        
        
  /* Check if the system is set for auto or manual numbering */                
  DECLARE @autoNum bit,@PNStatus varchar(50)=@blue,@partSource VARCHAR(50), @PNMessage varchar(100)='New part will be created at completion',@makeNum bit                
                  
  -- 04/20/18 Vijay G : Moved the Auto Number and Auto Make No setting value from MICSSYS,InvtSetup table to MnxSettingsManagement and wmSettingsManagement table                
  --SELECT @autoNum=XXPTNOSYS FROM MICSSYS                
  -- 04/20/18 Vijay G : Check Auto Number setting value from wmSettingsManagement                
  -- 06/01/18 Vijay G : Get the AutoPartNumber setting value by setting name if exist in wmSettingsManagement otherwise from MnxSettingsManagement                  
  -- 02/27/2020 Vijay G : Removed code of auto parnumber setting    
  --SELECT @autoNum= isnull(w.settingValue,m.settingValue)                     
  --FROM MnxSettingsManagement M left outer join wmSettingsManagement W on m.settingId=w.settingId                  
  --WHERE settingName ='AutoPartNumber'                
                
                
  /***** TODO: add validation for NEW and MAKE parts *****/                    
  -- 04/20/18 Vijay G : Check Auto Make Number setting value from wmSettingsManagement                
  -- 06/01/18 Vijay G : Get the AutoMakePartNumber setting value by setting name if exist in wmSettingsManagement otherwise from MnxSettingsManagement                
  --SELECT @makeNum=lAutoMakeNo FROM INVTSETUP                
  -- 02/27/2020 Vijay G : Removed code of auto parnumber setting    
  --SELECT @makeNum= isnull(w.settingValue,m.settingValue)                     
  --FROM MnxSettingsManagement M left outer join wmSettingsManagement W on m.settingId=w.settingId                  
  --WHERE settingName ='AutoMakePartNumber'                
        
  -- 02/27/2020 Vijay G : Added part number validation base part class number setup    
  DECLARE @tempPartDetails TABLE (rowId uniqueidentifier,partClass VARCHAR(16))          
  DECLARE @partClassId uniqueidentifier,@tempRowId uniqueidentifier,@tempPartClass VARCHAR(16),@numgenrator VARCHAR(20),@custPartNoValue VARCHAR(35)    
  select @partClassId=fielddefid from importBOMFieldDefinitions where fieldName='PartClass'    
    
  INSERT INTO @tempPartDetails (rowId,partClass)      
  SELECT rowId,adjusted FROM importBOMFields WHERE fkImportId=@importId AND fkfielddefid=@partClassId    
  WHILE (EXISTS (SELECT * FROM @tempPartDetails))                  
  BEGIN    
   SELECT TOP 1 @tempPartClass=partClass,@tempRowId=rowId FROM @tempPartDetails    
   SELECT @numgenrator= numberGenerator FROM PartClass WHERE part_class=@tempPartClass    
   IF(@numgenrator <>'Auto' AND @numgenrator<>'CustPNasIPN')    
   BEGIN    
      UPDATE importBOMFields              
      SET [status]=@red,[validation]=@sys, [message] = 'Part Number must be added before record can be saved'              
      WHERE fkImportId = @importId AND (fkFieldDefId = @partnoId)                
        AND adjusted='' AND rowId =@tempRowId      
   END    
--03/19/2020 Sachin B: Added aditional block to populate part no if numbergenrator setup is Customer part as IPN   
   IF(@numgenrator='CustPNasIPN')      
   BEGIN      
       SET @custPartNoValue=''    
       SELECT @custPartNoValue =imp.adjusted FROM importBOMFields imp JOIN importBOMFieldDefinitions ifd     
                       ON fkImportId = @importId AND ifd.fieldDefId=imp.fkFieldDefId AND ifd.fieldname='custPartNo' AND imp.rowId=@tempRowId    
     
    UPDATE importBOMFields                
    SET [status]=@blue,[validation]=@sys, [message] = '',adjusted=@custPartNoValue                
    WHERE fkImportId = @importId AND (fkFieldDefId = @partnoId )               
    AND rowId =@tempRowId        
        
   END      
   ELSE    
   BEGIN    
    UPDATE importBOMFields              
     SET [status]=@blue,[validation]=@sys, [message] = 'New part will be created at completion'              
     WHERE fkImportId = @importId AND (fkFieldDefId = @partnoId)               
       AND adjusted='===== NEW =====' AND rowId =@tempRowId      
   END    
   DELETE FROM @tempPartDetails WHERE rowId=@tempRowId    
  END        
        
  -- SELECT @partSource = adjusted FROM importBOMFields WHERE fkImportId=@importId AND fkFieldDefId=@partSourceId          
  --08/29/2019 Vijay G:Update existing code for update importBOMFields if buy parts auto numbering is on                 
  --IF @autoNum=0                
  --BEGIN                
  --SET @PNStatus=@red                
  --SET @PNMessage='Part Number must be added before record can be saved'          
    ---- 05/27/15 YS added filter by importid. Was missing during some valdation and the update                
  --09/27/2019 Vijay G:Change the case from @makeNum=0 to @autoNum=0 AND added one more filter adjusted='CONSG'     
  -- 02/27/2020 Vijay G : Removed code of auto parnumber setting                  
  --UPDATE importBOMFields                
  --SET [message] = CASE WHEN @autoNum=0  THEN 'Part Number must be added before record can be saved' ELSE ''END,                
  --[status]= CASE WHEN @autoNum=0  THEN  @red ELSE @blue END,[validation]=@sys,                 
  --adjusted=CASE WHEN @autoNum=0  THEN '' ELSE '===== NEW =====' END                  
  --WHERE fkImportId=@importId                  
  --and fkFieldDefId = @partnoId AND adjusted=''         
  --AND rowId IN (SELECT rowId from importBOMFields WHERE fkImportId=@importId AND fkFieldDefId=@partSourceId and adjusted='BUY' OR adjusted='CONSG')                     
  --END           
  --08/29/2019 Vijay G:Commented existing code for updating records base on there auto part numbering setting  base partSource        
   ---- 05/27/15 YS added filter by importid. Was missing during some valdation and the update                
  --UPDATE importBOMFields                
  -- SET [message] = CASE @PNMessage,[status]=@PNStatus,[validation]=@sys,         
  -- adjusted=CASE WHEN @autoNum=0 AND @partSource='BUY' THEN '' ELSE '===== NEW =====' END          
        
  --08/29/2019 Vijay G:Added new block for update importBOMFields if make or phantom parts auto numbering is on         
  --IF @makeNum=0                
  --BEGIN    
  -- 02/27/2020 Vijay G : Removed code of auto parnumber setting                        
   --UPDATE importBOMFields                
   --SET [message] = CASE WHEN @makeNum=0  THEN 'Part Number must be added before record can be saved' ELSE ''END,        
   --[status]= CASE WHEN @makeNum=0  THEN  @red ELSE @blue END,[validation]=@sys,         
   --adjusted=CASE WHEN @makeNum=0  THEN '' ELSE '===== NEW =====' END          
   --WHERE fkImportId=@importId                  
   --and fkFieldDefId = @partnoId AND adjusted=''         
   --AND rowId IN (SELECT rowId from importBOMFields WHERE fkImportId=@importId AND fkFieldDefId=@partSourceId and adjusted IN('MAKE','PHANTOM'))              
  --END                
  -- WHERE fkImportId=@importId          
                  
  -- and fkFieldDefId = @partnoId AND adjusted=''                
  DECLARE @revId uniqueidentifier                
  SELECT @revId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='rev'                
  UPDATE importBOMFields                
   SET [message] = @PNMessage,[status]=@PNStatus,[validation]=@sys                
   WHERE fkFieldDefId = @revId AND rowId IN (SELECT rowId FROM importBOMFields WHERE fkFieldDefId=@partnoId AND fkImportId=@importId AND adjusted='===== NEW =====')                
  --05/27/15 YS added filter by importid, otherwise the update goes over all records in importbomfileds with 'NP' in adjusted and fkFieldDefId = @partnoId                 
  UPDATE importBOMFields                
   SET [message] = 'NP is skipped in the upload',[status]=@red,[validation]=@sys                
   WHERE fkImportId=@importId                
   and fkFieldDefId = @partnoId AND adjusted='NP'                
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
  ERROR_NUMBER() AS ErrorNumber                
  ,ERROR_SEVERITY() AS ErrorSeverity                
  --,ERROR_STATE() AS ErrorState                
  ,ERROR_PROCEDURE() AS ErrorProcedure                
  ,ERROR_LINE() AS ErrorLine                
  ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues updating the internal part number fields (starting on line:227)'                
 END CATCH                
                    
 /****** STANDARD COST - Mark 'standardCost' as verified.  We do not need to validate this field so it is skipped ******/                
 BEGIN TRY -- inside begin try                
  EXEC importBOMVldtnUpdateField '%',1,'E25F76FA-0788-E111-B197-1016C92052BC',@importId,'',0                
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
   ERROR_NUMBER() AS ErrorNumber                
   ,ERROR_SEVERITY() AS ErrorSeverity                
   --,ERROR_STATE() AS ErrorState                
  ,ERROR_PROCEDURE() AS ErrorProcedure                
  ,ERROR_LINE() AS ErrorLine                
  ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues marking the standard cost field as validated (line:272)'                
 END CATCH                
                
 /****** REF DESG ******/                
 /* Compare qty with ref desg count (if exists) */                
 BEGIN TRY -- inside begin try                
  DECLARE @qtyId uniqueidentifier                
  SELECT @qtyId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='qty'                
  -- 08/16/18: Vijay G: If the Ref Designator is not provided from template then set validation message as "No Ref Desg Loaded".                
  DECLARE @iRefDesg TABLE (importId uniqueidentifier,rowid uniqueidentifier)                
  INSERT INTO @iRefDesg                
  SELECT DISTINCT i.fkImportId,i.rowId                
   FROM importBOMFields AS i INNER JOIN importBOMRefDesg AS rd ON rd.fkRowId = i.rowId                
   WHERE i.fkImportId=@importId AND rd.refdesg <>''                
                
  UPDATE importBOMFields                
   SET [status]=@white,[message]='No Ref Desg Loaded',[validation]=@sys                
   WHERE (fkFieldDefId = @qtyId) AND fkImportId=@importId AND [status]<>@green AND rowId not in (select rowid from @iRefDesg)                
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
   ERROR_NUMBER() AS ErrorNumber                
   ,ERROR_SEVERITY() AS ErrorSeverity                
   --,ERROR_STATE() AS ErrorState                
   ,ERROR_PROCEDURE() AS ErrorProcedure                
   ,ERROR_LINE() AS ErrorLine                
   ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues comparing ref desg count to qty (starting on line:289)'                
 END CATCH                
                 
 /****** non string checks ******/                
 BEGIN TRY -- inside begin try                
  DECLARE @notQty TABLE (importId uniqueidentifier,rowid uniqueidentifier,fieldDefId uniqueidentifier)                
   --05/27/15 YS added filter by importid, otherwise the update goes over all the records that fit the criteria                
  INSERT INTO @notQty  --value is not a number                
   SELECT f.fkImportId,f.rowId,f.fkFieldDefId                
   FROM importBOMFields f INNER JOIN importBOMFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                
   WHERE d.dataType='numeric' AND f.fkImportId=@importId AND ISNUMERIC(f.adjusted)<>1 AND f.adjusted<>''                
   and fkImportId=@importId                
UPDATE i                
   SET i.[status]=@red,i.[message]='Value is not a number',i.[validation]=@sys                
   FROM importBOMFields AS i INNER JOIN @notQty AS nq ON nq.rowid = i.rowId AND i.fkFieldDefId=nq.fieldDefId                
                 
                  
  DELETE FROM @notQty                
  INSERT INTO @notQty  --value is empty                
  SELECT f.fkImportId,f.rowId,f.fkFieldDefId                
   FROM importBOMFields f INNER JOIN importBOMFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                
   WHERE d.dataType='numeric' AND f.fkImportId=@importId AND f.adjusted=''                
            
  -- 05/24/2019 Vijay G : modify sp for remove blue color of standard cost field if part not exist           
  UPDATE i                
   SET i.[status]=@blue,i.[message]='Value was empty',i.[validation]=@sys,i.adjusted=0                
   FROM importBOMFields AS i INNER JOIN @notQty AS nq ON nq.rowid = i.rowId AND i.fkFieldDefId=nq.fieldDefId           
    and i.fkFieldDefId<> @stdCostId            
           
  -- 02/12/2020 Vijay G : Added a validation for itemno field if has entered alphanumeric value      
  UPDATE i                
   SET i.[status]=@red,i.[message]='Value is not a number',i.[validation]=@sys,i.adjusted=0                
   FROM importBOMFields AS i INNER JOIN importBOMFieldDefinitions d ON i.fkFieldDefId=d.fieldDefId            
   AND d.fieldName='itemno' AND ISNUMERIC(i.adjusted)<>1    
      
  DELETE FROM @notQty                
  -- 07/15/13 DS Added a Table variable to reduce the number of records in the evaluation of ISNUMERIC                
  DECLARE @noQtyTable TABLE (fkImportId uniqueidentifier,rowId uniqueidentifier,fkFieldDefId uniqueidentifier,adjusted varchar(MAX))                
  INSERT INTO @noQtyTable               
  SELECT f.fkImportId,f.rowId,f.fkFieldDefId,f.adjusted                
   FROM importBOMFields f INNER JOIN importBOMFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                
   WHERE d.dataType='int' AND f.fkImportId=@importId                
                  
  INSERT INTO @notQty  --value is not an integer                   
  SELECT fkImportId,rowId,fkFieldDefId                
   FROM @noQtyTable                
   WHERE ISNUMERIC(adjusted)<>1 OR CAST(adjusted AS BIGINT)<>adjusted                
  UPDATE i               
   SET i.[status]=@red,i.[message]='Value is not an integer',i.[validation]=@sys                
   FROM importBOMFields AS i INNER JOIN @notQty AS nq ON nq.rowid = i.rowId AND i.fkFieldDefId=nq.fieldDefId                
                  
  DECLARE @badQty TABLE (importId uniqueidentifier,rowid uniqueidentifier)                
  INSERT INTO @badQty  --Qty does not match count                
   SELECT i.fkImportId,i.rowId                
   FROM importBOMFields AS i LEFT OUTER JOIN importBOMRefDesg AS rd ON rd.fkRowId = i.rowId                
   WHERE NOT i.adjusted LIKE '%[^0-9]%'                
   GROUP BY i.fkImportId, i.adjusted, i.fkFieldDefId,i.rowId                
   HAVING (i.fkFieldDefId = @qtyId)AND i.fkImportId=@importId AND i.adjusted<>''AND (COUNT(rd.refdesg) <> CAST(ISNULL(i.adjusted,0) AS decimal(18, 5)))AND COUNT(rd.refdesg)>0                
                
  UPDATE i                
   SET i.[status]=@orange,i.[message]='Ref Desg Count may not match Qty',i.[validation]=@sys                
   FROM importBOMFields AS i INNER JOIN @badQty AS bq ON bq.rowid = i.rowId AND i.fkFieldDefId=@qtyId                
              
   -- 10/25/18: Vijay G: Fix the Issue for the Ref Des Validation for the Parts having U_OF_M 'EACH'              
   DECLARE @UOMFieldDefId uniqueidentifier                
   SELECT @UOMFieldDefId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='u_of_m'              
              
   DECLARE @eachUOMData TABLE (importId uniqueidentifier,rowid uniqueidentifier)              
                 
   INSERT INTO @eachUOMData              
   SELECT i.fkImportId,i.rowId                
   FROM importBOMFields i              
   WHERE fkImportId =@importId AND fkFieldDefId =@UOMFieldDefId and (ISNULL(adjusted,original) ='each' OR ISNULL(adjusted,original) ='ea')              
              
   UPDATE i                
   SET i.[status]=@red,i.[message]='Ref Desg Count may not match Qty',i.[validation]=@sys               
   FROM importBOMFields AS i                
   INNER JOIN (              
    SELECT i.rowId,i.fkImportId,i.fkFieldDefId              
    FROM importBOMFields AS i               
    LEFT OUTER JOIN               
    importBOMRefDesg AS rd ON rd.fkRowId = i.rowId                
    INNER JOIN @badQty AS bq ON bq.rowid = i.rowId AND i.fkFieldDefId=@qtyId              
    INNER JOIN @eachUOMData ea ON ea.rowid = bq.rowid              
    GROUP BY i.rowId,i.fkImportId,i.fkFieldDefId, i.adjusted--,i.[status],i.[message],i.[validation],              
    HAVING i.adjusted<>''AND  (COUNT(rd.refdesg) > CAST(ISNULL(i.adjusted,0) AS decimal(18, 5)))              
   ) t on t.rowId =i.rowId and i.fkImportId =t.fkImportId and i.fkFieldDefId =t.fkFieldDefId              
                
  DECLARE @goodQty TABLE (importId uniqueidentifier,rowid uniqueidentifier)                
  INSERT INTO @goodQty                
   SELECT i.fkImportId,i.rowId                
   FROM importBOMFields AS i INNER JOIN importBOMRefDesg AS rd ON rd.fkRowId = i.rowId                
   WHERE NOT i.adjusted LIKE '%[^0-9]%'                
   GROUP BY i.fkImportId, i.rowId, i.adjusted, i.fkFieldDefId                
   HAVING (i.fkFieldDefId = @qtyId)AND i.fkImportId=@importId AND (COUNT(rd.refdesg) = CAST(i.adjusted AS decimal(18, 5)))AND i.adjusted<>''                
                 
  /* 6/25/13 DS Removed since the sp resets all to white before validation*/                 
  --UPDATE i                
  -- SET i.[status]=@white,i.[message]='',i.[validation]=@sys                
  -- FROM importBOMFields AS i INNER JOIN @goodQty AS gq ON gq.rowid = i.rowId AND i.fkFieldDefId=@qtyId AND adjusted=original                
  UPDATE i                
   SET i.[status]=@green,i.[message]='',i.[validation]=@usr                
   FROM importBOMFields AS i INNER JOIN @goodQty AS gq ON gq.rowid = i.rowId AND i.fkFieldDefId=@qtyId AND adjusted<>original                
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
   ERROR_NUMBER() AS ErrorNumber                
   ,ERROR_SEVERITY() AS ErrorSeverity                
   --,ERROR_STATE() AS ErrorState                
   ,ERROR_PROCEDURE() AS ErrorProcedure                
   ,ERROR_LINE() AS ErrorLine                
   ,ERROR_MESSAGE() AS ErrorMessage;            SET @headerErrs = 'There are issues validating the non-string fields (starting on line:310)'                
 END CATCH                
                  
                  
 /****** Check for duplicate Ref Desg ******/                
 BEGIN TRY -- inside begin try                
  DECLARE @redDesId uniqueidentifier                
  SELECT @redDesId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='refdesg'                
                    
  DECLARE @dupRefs TABLE (refdesg varchar(MAX),cnt int)                
  INSERT INTO @dupRefs                
  SELECT refdesg,COUNT(refdesId)[count]                  
   FROM importBOMRefDesg                 
   WHERE fkImportId=@importId                
   GROUP BY refdesg                 
   HAVING COUNT(refdesId)>1                
                  
  UPDATE i                
   SET i.[status]=@orange,i.[message]='Ref appears to be duplicated in another line item'                
   FROM importBOMRefDesg i                
   WHERE i.refdesg IN (SELECT refdesg FROM @dupRefs) AND i.fkImportId=@importId                
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
   ERROR_NUMBER() AS ErrorNumber                   ,ERROR_SEVERITY() AS ErrorSeverity                
   --,ERROR_STATE() AS ErrorState                
   ,ERROR_PROCEDURE() AS ErrorProcedure                
   ,ERROR_LINE() AS ErrorLine                
   ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues checking for duplicated ref desg (starting on line:388)'                
 END CATCH                
                 
                 
 /****** ITEM NO - Validate itemno to make sure it isn't duplicated on this bom import ******/                
 /* get the id for the itemno field */                 
 BEGIN TRY -- inside begin try                
  DECLARE @itemnoId uniqueidentifier                
  SELECT @itemnoId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='itemno'                
                    
  /* get a count of how many times the itemno value is repeated */                
  DECLARE @itmnoTbl TABLE (itemno varchar(MAX),rCnt int)                
  INSERT INTO @itmnoTbl                
  SELECT  adjusted, COUNT(adjusted)                
   FROM importBOMFields                
   WHERE fkImportId = @importId AND fkFieldDefId = @itemnoId              
   GROUP BY fkImportId,adjusted                
  /* no itemno entered */                
  UPDATE importBOMFields                
   SET [status]=@red,[validation]=@sys, [message]='Item number field is blank'                
   WHERE fkFieldDefId = @itemnoId AND adjusted='' AND fkImportId=@importId                
  /* itemno used more than once */                
   --05/27/15 YS added filter by importid, otherwise the update goes over all the records that fit the criteria               
   -- 05/21/19 Vijay G: Add red color error validation if itemno is duplicate              
  UPDATE importBOMFields                
   SET [status]=@red,[validation]=@sys, [message]='Item number appears to be repeated'                
   WHERE fkimportid = @importId                 
   and adjusted IN (SELECT itemno FROM @itmnoTbl WHERE rCnt>1) AND fkFieldDefId = @itemnoId AND adjusted<>''                  
                   
  /* itemno changed by the user and NOT duplicated */                 
   --05/27/15 YS added filter by importid, otherwise the update goes over all the records that fit the criteria                
  UPDATE importBOMFields                
   SET [status]=@green,[validation]=@usr, [message]=''                
   WHERE fkimportid = @importId      
   AND ISNUMERIC(original)=1  -- 02/12/2020 Vijay G : Use to avoid repeat validation of itemNo field                    
   and adjusted IN (SELECT itemno FROM @itmnoTbl WHERE rCnt=1) AND fkFieldDefId = @itemnoId AND adjusted<>original             
               
   -- 05/24/19 Vijay G: Duplicate Part No Color Validation is not removing          
   UPDATE importBOMFields                
   SET [status]=@white,[validation]=@usr, [message]=''                
   WHERE fkimportid = @importId                  
   AND original IN (SELECT itemno FROM @itmnoTbl WHERE rCnt=1) AND fkFieldDefId = @itemnoId AND original IN (SELECT itemno FROM @itmnoTbl WHERE rCnt=1)                          
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
   ERROR_NUMBER() AS ErrorNumber                
   ,ERROR_SEVERITY() AS ErrorSeverity                
   --,ERROR_STATE() AS ErrorState                
   ,ERROR_PROCEDURE() AS ErrorProcedure                
   ,ERROR_LINE() AS ErrorLine                
   ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues validating the itemno (starting on line:420)'                
 END CATCH                
 /* itemno originally entered and NOT duplicated */                
 /* 6/25/13 DS Removed since the sp resets all to white before validation*/                 
 --UPDATE importBOMFields                
 -- SET [status]=@white,[validation]=@sys, [message]=''                
 -- WHERE adjusted IN (SELECT itemno FROM @itmnoTbl WHERE rCnt=1) AND fkFieldDefId = @itemnoId AND adjusted=original AND [status]<>@red AND [status]<>@orange                
                 
 /****** DUPLICATE PART NUMBER IN WC - ensure that the part number is not under two itemno but the same work center ******/                 
                 
 -- 11/18/12 YS changed the code to allow dynamic structure of the import fields                
 --DECLARE @iTable importBOM                
 --INSERT INTO @iTable                
 --SELECT * FROM [dbo].[fn_getImportBOMItems] (@importId)                
 -- code to produce dynamic structure                
 -- 05/15/13 YS use import bom udf table type in place of temp db                
                 
 --DECLARE @SQL as nvarchar(max),@Structure as varchar(max)                
 -- build dynamic structure                
                 
 --SELECT @Structure =                
 --STUFF(                
 --(                
 --    select  ',' +  F.FIELDNAME  + ' varchar(max) '                 
 --   from importBOMFieldDefinitions F                  
 --   ORDER BY FIELDNAME                 
 --   for xml path('')                
 --),                
 --1,1,'')                
 ---- now create global temp table                
                 
 --IF OBJECT_ID('TempDB..##GlobalT') IS NOT NULL                
 -- DROP TABLE ##GlobalT;                
 --SELECT @SQL = N'                
 --create table ##GlobalT (importId uniqueidentifier,rowId uniqueidentifier,uniq_key char(10),'+@Structure+')'                
 --exec sp_executesql @SQL                  
 -- temp table ##GlobalT with the structure based on the importBOMFieldDefinitions is created                 
 -- now insert return from the sp_getImportBOMItems into the global temp table                
                 
 BEGIN TRY -- inside begin try                
  DECLARE  @iTable importBom                
  --INSERT INTO ##GlobalT EXEC sp_getImportBOMItems @importId                
  INSERT INTO @iTable                
  EXEC [dbo].[sp_getImportBOMItems] @importId                
                 
  -- now use ##GlobalT in place of @iTable                
                 
  DECLARE @partRepeatedTbl TABLE (partno varchar(MAX))          
  INSERT INTO @partRepeatedTbl                 
  --05/15/13 YS back to iTable                
  --SELECT partno FROM ##GlobalT GROUP BY partno,rev,custPartNo,crev,workCenter HAVING COUNT(*)>1 AND partno<>'NEW'                
  --SELECT * FROM @partRepeatedTbl                
  -- 08/20/18: Vijay G: Added condition to avoid validation of same workcenter                 
  -- for those Part with empty part no and rev for more than one item number in the same work center.                
  SELECT partno FROM @iTable GROUP BY partno,rev,custPartNo,crev,workCenter HAVING COUNT(*)>1 AND partno<>'===== NEW =====' AND partno <> ''                
                 
  DECLARE @workCenterId uniqueidentifier                
  SELECT @workCenterId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='workCenter'                
                    
  UPDATE importBOMFields                
  SET [status]=@red,[validation]=@sys,[message]='Part Number is used on more than one item number in the same work center'                
  WHERE fkFieldDefId = @workCenterId AND rowId IN (SELECT rowId FROM importBOMFields WHERE fkFieldDefId=@partnoId AND adjusted IN (SELECT partno FROM @partRepeatedTbl))                
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
   ERROR_NUMBER() AS ErrorNumber                
   ,ERROR_SEVERITY() AS ErrorSeverity                
   --,ERROR_STATE() AS ErrorState         
   ,ERROR_PROCEDURE() AS ErrorProcedure                
   ,ERROR_LINE() AS ErrorLine                
   ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues checking for duplicated part numbers (starting on line:496)'                
 END CATCH           
              
 -- 11/02/18 Vijay G: Set the validation color if part  part source is consign              
 DECLARE @consgTbl TABLE (rowId uniqueidentifier)              
              
 INSERT INTO @consgTbl              
 SELECT rowId FROM @iTable WHERE LOWER(partSource) = 'consg' and custPartNo = ''              
              
 BEGIN TRY              
  DECLARE @custPartNo uniqueidentifier              
  SELECT @custPartNo=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='custPartNo'              
                
  UPDATE  importBOMFields              
   SET [status]=@red,[validation]=@sys,[message]='Please enter customer part number as part source is consign.'              
   WHERE fkFieldDefId = @custPartNo AND rowId IN (SELECT rowId FROM @consgTbl)              
 END TRY              
 BEGIN CATCH              
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)              
   SELECT              
    ERROR_NUMBER() AS ErrorNumber              
    ,ERROR_SEVERITY() AS ErrorSeverity              
    --,ERROR_STATE() AS ErrorState              
    ,ERROR_PROCEDURE() AS ErrorProcedure              
    ,ERROR_LINE() AS ErrorLine              
    ,ERROR_MESSAGE() AS ErrorMessage;              
  SET @headerErrs = 'There are issues checking for Cust part numbers for CONSG part source (starting on line:550)'              
 END CATCH              
                    
    /* 07/02/13 check for partno/rev matches */                
 BEGIN TRY -- inside begin try                
  UPDATE importBOMFields                
   SET [message]='Part Number/Rev matches assembly number/rev',[status]=@red,[validation]=@sys                
   --SELECT f.adjusted, fd.*                
   FROM importBOMFields f                 
   WHERE f.rowId IN (SELECT pn.rowId                
        FROM                
         (SELECT rowId                 
          FROM importBOMFields f INNER JOIN importBOMHeader h ON f.fkImportId=h.importId AND h.assyNum=f.adjusted                 
          WHERE fkFieldDefId=@partnoId)pn                
         INNER JOIN                 
         (SELECT rowId                 
          FROM importBOMFields f INNER JOIN importBOMHeader h ON f.fkImportId=h.importId AND h.assyRev=f.adjusted                 
          WHERE fkFieldDefId=@revId)rv                
         ON pn.rowId=rv.rowId)              
     AND (f.fkFieldDefId = @partnoId OR f.fkFieldDefId=@revId)                
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
   ERROR_NUMBER() AS ErrorNumber                
   ,ERROR_SEVERITY() AS ErrorSeverity                
   --,ERROR_STATE() AS ErrorState                
   ,ERROR_PROCEDURE() AS ErrorProcedure                
   ,ERROR_LINE() AS ErrorLine                
   ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues checking for duplicated part numbers and revs (starting on line:531)'                
 END CATCH                
                     
 /*verfify all required fields are not empty*/                
 BEGIN TRY -- inside begin try                
  UPDATE importBOMFields                 
   SET [message]='Field Cannot Be Blank',[status]=@red,[validation]=@sys                
   --SELECT f.adjusted, fd.*                
   FROM importBOMFieldDefinitions fd INNER JOIN importBOMFields f ON fd.fieldDefId=f.fkFieldDefId                 
   WHERE fd.[required] = 1                 
    AND f.adjusted=''                
    AND f.fkImportId=@importId                  
 END TRY                
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                
  SELECT                
   ERROR_NUMBER() AS ErrorNumber                
   ,ERROR_SEVERITY() AS ErrorSeverity                
   --,ERROR_STATE() AS ErrorState                
   ,ERROR_PROCEDURE() AS ErrorProcedure                
   ,ERROR_LINE() AS ErrorLine                
   ,ERROR_MESSAGE() AS ErrorMessage;                
  SET @headerErrs = 'There are issues verifying required fields contain a value (starting on line:561)'                
 END CATCH                      
 -- 01/12/19 Vijay G: Add Code for the in Active Part validation            
 -- 05/23/19 Vijay G: Change In Active Part Color legend            
 Declare @partId uniqueidentifier,@purple varchar(20)='b942f4'            
 SELECT @partId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'partNo'            
             
 DECLARE  @tPartsAll importBom            
 INSERT INTO @tPartsAll            
 EXEC [dbo].[sp_getImportBOMItems] @importId            
             
  UPDATE  importBOMFields              
   SET [status]=@purple,[message]='In Active Part'              
   WHERE fkFieldDefId = @partId AND             
   rowId IN (            
   SELECT rowId FROM @tPartsAll p             
   INNER JOIN INVENTOR i on p.partno =i.PART_NO AND p.rev=i.REVISION AND ISNULL(p.custno,'') =i.CUSTNO AND p.custPartNo =i.CUSTPARTNO AND p.crev =i.CUSTREV            
   WHERE i.STATUS ='Inactive'            
   )             
  -- 03/06/2020 Sachin B : Added validation on part if user has entered part which exists in the system but partsource which user has enterd is not match with part details
   UPDATE  importBOMFields            
  SET [status]=@red,[message]='This Part_No with different part source is exists.please change part no'            
  WHERE fkFieldDefId = @partId AND uniq_key<>'' and           
  rowId IN (          
  SELECT rowId FROM @tPartsAll p           
  INNER JOIN INVENTOR i on rtrim(p.partno) =i.PART_NO AND p.rev=i.REVISION  AND ISNULL(p.custno,'') =i.CUSTNO AND p.custPartNo =i.CUSTPARTNO AND p.crev =i.CUSTREV  AND i.PART_SOURC<>p.partSource      
  )       
                 
  /* Record the list of errors into the error log */                
  INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg)                
  SELECT DISTINCT @importId,ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg FROM @ErrTable                
                 
     -- David Sharp                
     -- I removed the items below, but left the code.  If all works properly it can be deleted.                
                     
  --DECLARE @sourceId uniqueidentifier = '320B6EEA-0588-E111-B197-1016C92052BC'                
  --DECLARE @uOFmId uniqueidentifier = 'FEBEA9B5-0688-E111-B197-1016C92052BC'                
  --DECLARE @classId uniqueidentifier = 'c41a2e15-0788-e111-b197-1016c92052bc'                
  --DECLARE @typeId uniqueidentifier = '2e9fb279-0788-e111-b197-1016c92052bc'                
  --DECLARE @warehouseId uniqueidentifier = '56150c96-0788-e111-b197-1016c92052bc'                
  --DECLARE @wcId uniqueidentifier = '92ca69d8-0788-e111-b197-1016c92052bc'                
  --DECLARE @used uniqueidentifier = 'f42923c3-0588-e111-b197-1016c92052bc'                
  --DECLARE @desc uniqueidentifier = 'ea336a94-0688-e111-b197-1016c92052bc'                
END