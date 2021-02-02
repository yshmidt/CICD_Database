-- ==================================================================================================================================================    
-- Author:  Satish B                              
-- Create date: 6/11/2018                              
-- Description: checks the standard values for import record                              
--Modified  05/14/2019 Satish B : populating the default GLNBR                               
--Modified  05/15/2019 Satish B : change in revision column validation                              
--Modified  05/16/2019 Satish B : Add validation for Order qty and Schedule qty validation if schedule qty is more order qty                              
--Modified  05/20/2019 Satish B : Add validation for PO Number                               
--Modified Vijay G :07/26/2019 Select PoNumber from ImportPOMain                              
--Modified Vijay G :07/26/2019 Remove Unwanted conversion code                               
--Modified  08/09/2019 Shiv P : Add validation for WareHouse not able to save if uploaded in small case                               
--Modified  09/13/2019 Nitesh B : Add validation for INVT RECV, MRO and Services for RequestType                              
--Modified  09/16/2019 Shiv P : To give the specific msg for invalid date format                              
--Modified  09/17/2019 Nitesh B : Add validation for INVT RECV, MRO and Services for Warehouse                              
--Modified  09/30/2019 Shiv P : To validate the mfgr_pt_no if upload it wrong                              
--Modified  11/05/2019 Shiv P : Removed the length conditions and changed the message.                              
--Modified  11/05/2019 Shiv P : Populate the last genrated PO when setting is auto other wise provide error message if number is already exist                          
--Modified  11/12/2019 Mahesh B : Added one more condtion which update the tool tip message.                        
--Modified  11/14/2019 Nitesh B : Change validation for INVT RECV, MRO and Services for RequestType                         
--Modified  12/06/2019 Shiv P : Add validation for GL Numbers that are listed in INVTGLS as REC_TYPE 'M' For MRP and Service Parts                       
--Modified  12/06/2019 Shiv P : Add validation for provided GL Number that doesn't match with warehouse for Invt Part                      
--Modified  12/09/2019 Shiv P : Modifid the condition to check validation of Glnumber                     
--Modified  12/17/2019 Shiv P : Modifid to check if warehouse exists for the provided Mfgr when importing from template                   
--Modified  12/17/2019 Shiv P : Checked the autolocation setting for MFGR                    
--Modified  01/03/2020 Shiv P : Added validation if User has entered the different price for same item.         
--Modified  01/16/2020 Shiv P : Rmoved validation avoidation code for Glnumber field         
--Modified  01/23/2020 Shiv P : Check the selected MPN is associated with selected partmfgr or not          
--Modified  01/28/2020 Vijay G : Commented the old code of Po numbering    
--Modified  01/28/2020 Vijay G : Added new block of code as per new implementation     
--Modified  02/12/2020 Shiv P : Change the code to validate and update error message for partmfgr    
--Modified  03/19/2020 Shiv P : Get uniqkey of only Buy and Make part for validating PartMfgr and Mfgr Part Number    
-- 04/21/2020 Satyawan H: Commented Part No, Revision, Part Mfgr validation code for performace issue    
-- 04/22/2020 Satyawan H: Modified validation for Part No/Revision and Part Mfgr    
-- 04/29/2020 Satyawan H: The system will ignore validation for MPN field of PO item type MRO and Service items        
-- 05/06/2020 Satyawan H: Modified condition to verify the given Warehouse on the basis of autolocation                  
-- 05/07/2020 Satyawan H: Added Condition to check if the part is active and modified message    
-- 06/04/2020 Satyawan H: validation of the duplicate item nomber for same part    
-- 06/08/2020 Satyawan H: if item no. is empty update it with error and message as required    
-- 06/08/2020 Satyawan H: Added condition to check if the part is make/buy true    
-- 06/17/2020 Satyawan H: check if the fields are 'PARTNO','REVISION','PARTMFGR' only   
-- 09/15/2020 Rajendra K: Used fremoveLeadingZeros to remove leading 0 of  item number in validation   
-- 11/30/2020 Rajendra K: Added contition and join to skip if the SHIPCHARGE,SHIPVIA and FOB having error
-- 01/15/21 YS check if the Requestor empty when MRO or Service 
-- ==================================================================================================================================================    
CREATE PROCEDURE [dbo].[ImportPOVldtnCheckValues]                            
 -- Add the parameters for the stored procedure here                              
 @importId UNIQUEIDENTIFIER                              
AS                              
BEGIN                              
 -- SET NOCOUNT ON added to prevent extra result sets from                              
 -- interfering with SELECT statements.                              
 SET NOCOUNT ON;                              
                              
 -- Insert statements for procedure here                              
 DECLARE @red varchar(20)='i05red',@sys varchar(20)='01system',@white varchar(20)='i00white',                
   @blue varchar(20)='i03blue',@rev varchar(10),@headerErrs varchar(MAX)                              
 DECLARE @Adjusted nvarchar(max),@ModuleId INT                              
 DECLARE @ErrTable TABLE (ErrNumber int,ErrSeverity int,ErrProc varchar(MAX),ErrLine int,ErrMsg varchar(MAX))                              
 DECLARE @TempTable TABLE (TRowId UNIQUEIDENTIFIER, TAdjusted nvarchar(max), isUpdate bit);                        
 DECLARE @TempRowId UNIQUEIDENTIFIER, @TempAdjusted nvarchar(max);                        
                                 
    /* Length Check - Warn for any field with a length longer than the definition length */                              
 BEGIN TRY -- inside begin try                              
  UPDATE f                              
   SET [message]='Field will be truncated to ' + CAST(fd.fieldLength AS varchar(50)) + ' characters.',                
    [status]=@red,[validation]=@sys                     
  FROM ImportPODetails f                               
  INNER JOIN importFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength>0                              
  WHERE fkPOImportId=@importId                              
  AND LEN(f.adjusted)>fd.fieldLength                                
 END TRY                              
 BEGIN CATCH                               
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                            
  SELECT                              
  ERROR_NUMBER() AS ErrorNumber                              
  ,ERROR_SEVERITY() AS ErrorSeverity                              
  ,ERROR_PROCEDURE() AS ErrorProcedure                              
  ,ERROR_LINE() AS ErrorLine                              
  ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues in the fields to be truncated (starting on line:44)'                              
 END CATCH                              
                  
 /*verfify all required fields are not empty*/                              
 BEGIN TRY -- inside begin try                              
  UPDATE ImportPODetails                               
   SET [message]='Field Cannot Be Blank',[status]=@red,[validation]=@sys                              
  FROM importFieldDefinitions fd INNER JOIN ImportPODetails f ON fd.fieldDefId=f.FkFieldDefId                               
  WHERE fd.[required] = 1                               
  AND f.adjusted=''                              
  AND f.fkPOImportId=@importId                               
  AND (fd.FieldName ='CONFTO'AND adjusted<>'')                              
  AND fd.FieldName <>'NOTE1'                              
  AND fd.FieldName <>'MFGR_PT_NO'                       
  --AND fd.FieldName <> 'GLNBR'                                
  AND (fd.FieldName ='REVISION' AND adjusted<>'')                              
  AND (fd.FieldName = 'SHIPCHARGE' AND adjusted<>'')                              
  AND (fd.FieldName = 'SHIPVIA' AND adjusted<>'')                              
  AND (fd.FieldName = 'FOB' AND adjusted<>'')                              
 END TRY                           
 BEGIN CATCH                               
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
  SELECT                              
  ERROR_NUMBER() AS ErrorNumber                              
  ,ERROR_SEVERITY() AS ErrorSeverity                              
  ,ERROR_PROCEDURE() AS ErrorProcedure                              
  ,ERROR_LINE() AS ErrorLine                              
  ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues verifying required fields contain a value (starting on line:561)'                              
 END CATCH                                
                              
 /* Ensure the adjusted 'COSTEACHFC','SCHDQTY','ORD_QTY','COSTEACH' is a number */                              
 BEGIN TRY -- inside begin try                              
  UPDATE f                              
   SET adjusted = CAST(adjusted as float)                              
  FROM ImportPODetails f                               
  INNER JOIN importFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldName in('COSTEACHFC','SCHDQTY','ORD_QTY','COSTEACH')                              
  WHERE fkPOImportId=@importId                              
  AND adjusted LIKE '%E%'                              
 END TRY                              
 BEGIN CATCH                               
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
  SELECT                              
  ERROR_NUMBER() AS ErrorNumber                              
  ,ERROR_SEVERITY() AS ErrorSeverity                              
  ,ERROR_PROCEDURE() AS ErrorProcedure                              
  ,ERROR_LINE() AS ErrorLine                              
  ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues verifying the standard cost is a number (starting on line:95)'                       
 END CATCH                              
                 
 BEGIN TRY -- inside begin try                              
  UPDATE f                              
   SET [message] = 'Required Field',[status]=@red,[validation]=@sys                   
  FROM ImportPODetails f INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
  WHERE fkPOImportId=@importId                              
  AND adjusted='' AND d.[required]=1                  
  AND (d.FieldName ='CONFTO'AND adjusted<>'')                               
  AND d.FieldName <>'NOTE1'                               
  AND(d.FieldName ='REVISION' AND adjusted<>'')                              
  AND (d.FieldName ='MFGR_PT_NO' AND  adjusted<>'')                            
  AND (d.FieldName = 'SHIPCHARGE' AND adjusted<>'')                              
  AND (d.FieldName = 'SHIPVIA' AND adjusted<>'')                              
  AND (d.FieldName = 'FOB' AND adjusted<>'')                              
 END TRY                              
 BEGIN CATCH                               
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
  SELECT                              
  ERROR_NUMBER() AS ErrorNumber                              
  ,ERROR_SEVERITY() AS ErrorSeverity                              
  ,ERROR_PROCEDURE() AS ErrorProcedure                              
  ,ERROR_LINE() AS ErrorLine                              
  ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                              
 END CATCH                              
                                  
                              
 /****** non string value validations ******/                              
 BEGIN TRY -- inside begin try                              
  DECLARE @nonNumeric TABLE (importId uniqueidentifier,rowid uniqueidentifier,fieldDefId uniqueidentifier)                              
  --Added filter by importid, otherwise the update goes over all the records that fit the criteria                              
                  
  INSERT INTO @nonNumeric  --value is not a number                              
  SELECT f.fkPOImportId,f.rowId,f.fkFieldDefId                              
  FROM ImportPODetails f                 
  INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
  WHERE d.dataType='numeric'                 
   AND f.fkPOImportId=@importId                 
   AND ISNUMERIC(f.adjusted)<>1 AND f.adjusted<>''                              
   AND fkPOImportId=@importId                              
                  
  UPDATE i                              
  SET i.[status]=@red,i.[message]='Value is not a number',i.[validation]=@sys                              
  FROM ImportPODetails AS i                 
  INNER JOIN @nonNumeric AS nq ON nq.rowid = i.rowId                 
  AND i.fkFieldDefId=nq.fieldDefId                              
                               
  DELETE FROM @nonNumeric                              
                  
  INSERT INTO @nonNumeric  --value is empty                              
  SELECT f.fkPOImportId,f.rowId,f.fkFieldDefId                              
  FROM ImportPODetails f                 
  INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
  WHERE d.dataType='numeric'                 
  AND f.fkPOImportId=@importId                 
  AND f.adjusted=''                              
                 
  UPDATE i                              
   SET i.[status]=@blue,                
    i.[message]='Value was empty',                
    i.[validation]=@sys,                
    i.adjusted=0                              
  FROM ImportPODetails AS i                 
  INNER JOIN @nonNumeric AS nq ON nq.rowid = i.rowId                 
  AND i.fkFieldDefId=nq.fieldDefId                              
                    
  DELETE FROM @nonNumeric                              
  -- Added a Table variable to reduce the number of records in the evaluation of ISNUMERIC                              
  DECLARE @noQtyTable TABLE (fkImportId uniqueidentifier,rowId uniqueidentifier,                
          fkFieldDefId uniqueidentifier,adjusted varchar(MAX))               
                 
  INSERT INTO @noQtyTable                              
  SELECT f.fkPOImportId,f.rowId,f.fkFieldDefId,f.adjusted                              
  FROM ImportPODetails f                 
  INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
  WHERE d.dataType='int' AND f.fkPOImportId=@importId                              
                      
  INSERT INTO @nonNumeric  --value is not an integer                                 
  SELECT fkImportId,rowId,fkFieldDefId                              
  FROM @noQtyTable                              
  WHERE ISNUMERIC(adjusted)<>1 OR CAST(adjusted AS BIGINT)<>adjusted                              
                 
  UPDATE i                              
   SET i.[status]=@red,i.[message]='Value is not an integer',i.[validation]=@sys                              
  FROM ImportPODetails AS i                 
  INNER JOIN @nonNumeric AS nq ON nq.rowid = i.rowId                 
  AND i.fkFieldDefId=nq.fieldDefId                              
 END TRY                  
 BEGIN CATCH                               
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
  SELECT                            
  ERROR_NUMBER() AS ErrorNumber                              
  ,ERROR_SEVERITY() AS ErrorSeverity                              
  ,ERROR_PROCEDURE() AS ErrorProcedure                              
  ,ERROR_LINE() AS ErrorLine                              
  ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues validating the non-string fields (starting on line:310)'                              
 END CATCH                              
                              
  /****** Schedule grid validations ******/                              
 BEGIN TRY -- inside begin try                              
  UPDATE f                              
  SET [message]='Field will be truncated to ' + CAST(fd.fieldLength AS varchar(50)) + ' characters.',                
   [status]=@red,[validation]=@sys                              
  FROM ImportPOSchedule f                               
  INNER JOIN importFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength>0                          
  WHERE fkPOImportId=@importId                              
  AND LEN(f.adjusted)>fd.fieldLength                                
 END TRY                              
 BEGIN CATCH                               
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
  SELECT                              
  ERROR_NUMBER() AS ErrorNumber                              
  ,ERROR_SEVERITY() AS ErrorSeverity                              
  ,ERROR_PROCEDURE() AS ErrorProcedure                              
  ,ERROR_LINE() AS ErrorLine                              
  ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues in the fields to be truncated (starting on line:44)'                              
 END CATCH                              
                               
 --Modified  09/16/2019 Shiv P : To give the specific msg for invalid date format                                
 --Modified  11/05/2019 Shiv P : removed the length conditions and changed the message.                              
 --Modified  11/12/2019 Mahesh B : Added one more condtion which update the tool tip message.                        
 /* To give the specific msg for invalid format of date*/                                
 BEGIN TRY -- inside begin try                                
  UPDATE f                                
  SET [message]='Invalid date format.Please enter valid date format as MM/DD/YYYY.',                
   [status]=@red,[validation]=@sys                                
  FROM ImportPOSchedule f                             
  INNER JOIN importFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId                                 
  WHERE fkPOImportId=@importId                                
  AND (fd.FieldName ='SCHDDATE' AND [Message] LIKE '%Required Field%')                        
  OR  (fd.FieldName ='ORIGCOMMITDT' AND [Message] LIKE '%Required Field%')                        
  OR  (fd.FieldName in ('SCHDDATE') AND [Message] LIKE '%Required Field%')                        
 END TRY                        
 BEGIN CATCH                                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                                
  SELECT                                
  ERROR_NUMBER() AS ErrorNumber                                
  ,ERROR_SEVERITY() AS ErrorSeverity                                
  ,ERROR_PROCEDURE() AS ErrorProcedure                                
  ,ERROR_LINE() AS ErrorLine                                
  ,ERROR_MESSAGE() AS ErrorMessage;                                
  SET @headerErrs = 'There are issues in the fields to be truncated (starting on line:44)'                                
 END CATCH                               
                               
  /*verfify all required fields are not empty*/                              
 BEGIN TRY -- inside begin try                
  UPDATE f                               
  SET [message]='Field Cannot Be Blank',[status]=@red,[validation]=@sys                              
  from ImportPOSchedule f                              
  OUTER APPLY                 
  (                
   SELECT f.ScheduleRowId, f.fkFieldDefId FROM ImportPOSchedule f                 
   INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
   WHERE d.[required] = 1                               
   AND d.FieldName <>'REQDATE'                  
   AND d.FieldName <> 'WAREHOUSE' AND d.FieldName <>'LOCATION'                 
   AND d.FieldName <>'REQUESTOR' AND d.FieldName <>'WOPRJNUMBER'                              
   AND f.adjusted='' AND fkPOImportId=@importId                
   --Modified  01/16/2020 Shiv P : Rmoved validation avoidation code for Glnumber field           
   --AND d.FieldName <> 'GLNBR'            
  ) s                              
  WHERE f.ScheduleRowId = s.ScheduleRowId AND f.fkFieldDefId = s.fkFieldDefId                               
 END TRY                              
 BEGIN CATCH                               
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
  SELECT                              
  ERROR_NUMBER() AS ErrorNumber                              
  ,ERROR_SEVERITY() AS ErrorSeverity                              
  ,ERROR_PROCEDURE() AS ErrorProcedure                              
  ,ERROR_LINE() AS ErrorLine                              
  ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues verifying required fields contain a value (starting on line:561)'                              
 END CATCH                                
                              
 /* Ensure the adjusted 'COSTEACHFC','SCHDQTY','ORD_QTY','COSTEACH' is a number */                              
 BEGIN TRY -- inside begin try                              
  UPDATE f                              
  SET adjusted = CAST(adjusted as float)                              
  FROM ImportPOSchedule f                               
  INNER JOIN importFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId                 
  AND fd.fieldName in('COSTEACHFC','SCHDQTY','ORD_QTY','COSTEACH')                              
  WHERE fkPOImportId=@importId                              
  AND adjusted LIKE '%E%'                              
 END TRY                              
 BEGIN CATCH                               
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
  SELECT                              
  ERROR_NUMBER() AS ErrorNumber                              
  ,ERROR_SEVERITY() AS ErrorSeverity                              
  ,ERROR_PROCEDURE() AS ErrorProcedure                              
  ,ERROR_LINE() AS ErrorLine                              
  ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues verifying the standard cost is a number (starting on line:95)'                              
 END CATCH                              
                               
 BEGIN TRY -- inside begin try                              
  UPDATE f                              
  SET [message] = 'Required Field',[status]=@red,[validation]=@sys                              
  from ImportPOSchedule f                              
  OUTER APPLY (                    
   SELECT f.ScheduleRowId, f.fkFieldDefId FROM ImportPOSchedule f                     
   INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
   WHERE d.[required] = 1                               
   AND d.FieldName <>'REQDATE' AND d.FieldName <> 'GLNBR' AND d.FieldName <>'WAREHOUSE'                       
   AND d.FieldName <>'LOCATION' AND d.FieldName <>'REQUESTOR' AND d.FieldName <>'WOPRJNUMBER'                              
   AND (f.adjusted='' OR f.adjusted='1900-01-01') AND fkPOImportId=@importId                    
  ) s                              
  --AND f.adjusted='' AND fkPOImportId=@importId) s                              
  WHERE f.ScheduleRowId = s.ScheduleRowId AND f.fkFieldDefId = s.fkFieldDefId                                 
 END TRY                              
 BEGIN CATCH                 
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
  SELECT                              
  ERROR_NUMBER() AS ErrorNumber                              
  ,ERROR_SEVERITY() AS ErrorSeverity                              
  ,ERROR_PROCEDURE() AS ErrorProcedure                              
  ,ERROR_LINE() AS ErrorLine                              
  ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                              
 END CATCH                              
                                  
                              
 /****** non string value validations ******/                              
 BEGIN TRY -- inside begin try                              
  INSERT INTO @nonNumeric  --value is not a number                              
  SELECT f.fkPOImportId,f.fkRowId,f.fkFieldDefId                              
  FROM ImportPOSchedule f                 
  INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
  WHERE d.dataType='numeric' AND f.fkPOImportId=@importId AND ISNUMERIC(f.adjusted)<>1 AND f.adjusted<>''                              
  and fkPOImportId=@importId                              
                  
  UPDATE i                              
  SET i.[status]=@red,i.[message]='Value is not a number',i.[validation]=@sys                              
  FROM ImportPOSchedule AS i                 
  INNER JOIN @nonNumeric AS nq ON nq.rowid = i.fkRowId AND i.fkFieldDefId=nq.fieldDefId                              
                               
  DELETE FROM @nonNumeric                              
  INSERT INTO @nonNumeric  --value is empty                              
  SELECT f.fkPOImportId,f.fkRowId,f.fkFieldDefId                              
  FROM ImportPOSchedule f INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
  WHERE d.dataType='numeric' AND f.fkPOImportId=@importId AND f.adjusted=''                              
                  
  UPDATE i                              
  SET i.[status]=@blue,i.[message]='Value was empty',i.[validation]=@sys,i.adjusted=0                              
  FROM ImportPOSchedule AS i                 
  INNER JOIN @nonNumeric AS nq ON nq.rowid = i.fkRowId AND i.fkFieldDefId=nq.fieldDefId                              
                                 
  DELETE FROM @nonNumeric                              
  INSERT INTO @noQtyTable                              
  SELECT f.fkPOImportId,f.fkRowId,f.fkFieldDefId,f.adjusted                              
  FROM ImportPOSchedule f                 
  INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
  WHERE d.dataType='int' AND f.fkPOImportId=@importId                              
                         
  INSERT INTO @nonNumeric  --value is not an integer                                 
  SELECT fkImportId,rowId,fkFieldDefId                              
  FROM @noQtyTable                              
  WHERE ISNUMERIC(adjusted)<>1 OR CAST(adjusted AS BIGINT)<>adjusted                              
                  
  UPDATE i                              
  SET i.[status]=@red,i.[message]='Value is not an integer',i.[validation]=@sys                              
  FROM ImportPOSchedule AS i INNER JOIN @nonNumeric AS nq ON nq.rowid = i.fkRowId AND i.fkFieldDefId=nq.fieldDefId                              
 END TRY                              
 BEGIN CATCH                               
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
  SELECT                              
  ERROR_NUMBER() AS ErrorNumber                              
  ,ERROR_SEVERITY() AS ErrorSeverity                              
  ,ERROR_PROCEDURE() AS ErrorProcedure                              
  ,ERROR_LINE() AS ErrorLine                              
  ,ERROR_MESSAGE() AS ErrorMessage;                          
  SET @headerErrs = 'There are issues validating the non-string fields (starting on line:310)'                              
 END CATCH                              
                              
   --   /****** Supplier Validation ******/                              
 IF NOT EXISTS (SELECT SUPNAME FROM SUPINFO s INNER JOIN ImportPODetails d ON s.SUPNAME = d.Adjusted                              
  INNER JOIN ImportFieldDefinitions f ON d.fkFieldDefId=f.fieldDefId AND fkPOImportId = @importId                              
  WHERE s.STATUS NOT IN('DISQUALIFIED','INACTIVE'))                           
 BEGIN                              
  BEGIN TRY -- inside begin try                              
   UPDATE f                              
    SET [message] = 'Invalid Supplier',[status]=@red,[validation]=@sys                              
    FROM ImportPODetails f                 
    INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
    WHERE fkPOImportId=@importId                               
    AND d.FieldName='SUPNAME'                              
  END TRY                              
  BEGIN CATCH                               
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
   SELECT                            
    ERROR_NUMBER() AS ErrorNumber                              
    ,ERROR_SEVERITY() AS ErrorSeverity                              
    ,ERROR_PROCEDURE() AS ErrorProcedure                              
    ,ERROR_LINE() AS ErrorLine                              
    ,ERROR_MESSAGE() AS ErrorMessage;                              
   SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                              
  END CATCH                              
 END                              
                              
    --   /****** Priority Validation ******/                              
 IF NOT EXISTS (SELECT f.Adjusted FROM ImportPODetails f                 
       INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
       WHERE fkPOImportId=@importId AND d.FieldName='PRIORITY'                 
       AND (f.Adjusted ='Hot'or f.Adjusted ='Priority' OR f.Adjusted ='Standard'))                              
 BEGIN                              
  BEGIN TRY -- inside begin try                              
   UPDATE f                              
    SET [message] = 'Invalid Priority',[status]=@red,[validation]=@sys                              
    FROM ImportPODetails f INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
    WHERE fkPOImportId=@importId                               
    AND d.FieldName='PRIORITY'                              
  END TRY                              
  BEGIN CATCH                               
   INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
   SELECT                              
    ERROR_NUMBER() AS ErrorNumber                              
    ,ERROR_SEVERITY() AS ErrorSeverity                              
    ,ERROR_PROCEDURE() AS ErrorProcedure                              
    ,ERROR_LINE() AS ErrorLine                              
    ,ERROR_MESSAGE() AS ErrorMessage;                              
   SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                              
  END CATCH                              
 END                              
                              
   --   /****** Buyer Validation ******/                              
 IF NOT EXISTS (SELECT DISTINCT users.UserName FROM aspnet_Profile p                              
  INNER JOIN Aspnet_Users users ON p.UserId = users.UserId                              
  INNER JOIN ImportPODetails d ON users.UserName = d.Adjusted          
  INNER JOIN ImportFieldDefinitions f ON d.fkFieldDefId=f.fieldDefId AND fkPOImportId = @importId                   
  LEFT JOIN AspMnx_GroupUsers g on p.UserId=g.FkUserId                              
  LEFT JOIN AspMnx_GroupRoles r  on g.FkGroupId=r.fkGroupId                              
  LEFT JOIN aspnet_Roles aspneRoles on r.fkRoleId=aspneRoles.RoleId                              
  WHERE (aspneRoles.ModuleId = 25 AND f.FieldName='BUYER'                 
  AND (aspneRoles.RoleName='Add' OR aspneRoles.RoleName='Edit')) OR (p.ScmAdmin=1) OR (p.CompanyAdmin=1))                                
 BEGIN                              
 BEGIN TRY -- inside begin try                              
  UPDATE f          
   SET [message] = 'Invalid Buyer',[status]=@red,[validation]=@sys                              
   FROM ImportPODetails f                 
   INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
   WHERE fkPOImportId=@importId                               
   AND d.FieldName='BUYER'                              
 END TRY                              
 BEGIN CATCH                               
 INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
  SELECT                              
   ERROR_NUMBER() AS ErrorNumber                              
   ,ERROR_SEVERITY() AS ErrorSeverity                              
   ,ERROR_PROCEDURE() AS ErrorProcedure                              
   ,ERROR_LINE() AS ErrorLine                              
   ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                              
 END CATCH                              
 END                              
                               
  --   /****** Type Validation ******/                              
 IF NOT EXISTS (SELECT Adjusted FROM ImportPODetails f                 
    INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
    WHERE fkPOImportId=@importId AND d.FieldName='POITTYPE' AND f.Adjusted IN('Invt Part','MRO','Services'))                              
 BEGIN                              
 BEGIN TRY -- inside begin try                              
  UPDATE f                              
   SET [message] = 'Invalid PO Item Type',[status]=@red,[validation]=@sys                              
   FROM ImportPODetails f                 
   INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
   WHERE fkPOImportId=@importId                               
   AND d.FieldName='POITTYPE'                              
 END TRY                              
 BEGIN CATCH                               
  SELECT                              
   ERROR_NUMBER() AS ErrorNumber                              
   ,ERROR_SEVERITY() AS ErrorSeverity                              
   ,ERROR_PROCEDURE() AS ErrorProcedure                              
   ,ERROR_LINE() AS ErrorLine                   
   ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                              
 END CATCH                              
 END                              
                              
-- 04/21/2020 Satyawan H: Commented Part No, Revision, Part Mfgr validation code for performace issue    
 ----   /****** Part Number Validation ******/                                
--BEGIN                                
 -- BEGIN TRY -- inside begin try                                
 --  UPDATE f                                
 --   SET [message] = 'Invalid Part Number',[status]=@red,[validation]=@sys                                
 --   FROM ImportPODetails f                   
 --   INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                                
 --   WHERE fkPOImportId=@importId AND d.FieldName='PARTNO' AND f.RowId                   
 --    NOT IN (                  
 --     SELECT DISTINCT d.RowId FROM Inventor i                                
 --      LEFT JOIN POITEMS p on i.Uniq_Key=p.UNIQ_KEY                                
 --      INNER JOIN ImportPODetails d ON i.PART_NO= d.Adjusted                                 
 --      INNER JOIN ImportFieldDefinitions f ON d.fkFieldDefId=f.fieldDefId AND d.fkPOImportId = @importId                               
 --      WHERE F.FieldName='PARTNO' AND i.Status='Active' AND i.Part_Sourc ='Buy')                                
 --    AND f.RowId NOT IN(                  
 --      SELECT rowid FROM ImportPODetails f                                 
 --      INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                                
 --      WHERE fkPOImportId=@importId AND d.FieldName='POITTYPE' AND f.Adjusted IN('MRO','Services'))                                
 -- END TRY                                
 -- BEGIN CATCH                                 
 --  SELECT                                
 --   ERROR_NUMBER() AS ErrorNumber                                
 --   ,ERROR_SEVERITY() AS ErrorSeverity                                
 --   ,ERROR_PROCEDURE() AS ErrorProcedure                                
 --   ,ERROR_LINE() AS ErrorLine                                
 --   ,ERROR_MESSAGE() AS ErrorMessage;                                
 --  SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                                
 -- END CATCH                                
 --END          
                              
 -- --05/15/2019 Satish B : change in revision column validation                                                                     
 --BEGIN                                
 -- BEGIN TRY -- inside begin try                                
 --  UPDATE f                                
 --  SET [message] = 'Invalid Revision',[status]=@red,[validation]=@sys                                
 --  FROM ImportPODetails f INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                                
 --  WHERE fkPOImportId=@importId                                 
 --   AND d.FieldName = 'REVISION' AND f.RowId                   
 --   NOT IN (SELECT d.RowId FROM Inventor i                                
 --    LEFT JOIN POITEMS p on i.Uniq_Key=p.UNIQ_KEY                                
 --    INNER JOIN ImportPODetails d ON i.REVISION= d.Adjusted                                 
 --    INNER JOIN ImportFieldDefinitions f ON d.fkFieldDefId=f.fieldDefId AND d.fkPOImportId = @importId                                
 --    WHERE i.UNIQ_KEY IN (                  
 --     SELECT DISTINCT UNIQ_KEY FROM Inventor i                   
 --join importpodetails im on i.PART_NO=im.adjusted                                
 --     join ImportFieldDefinitions ifd on ifd.FieldDefId=im.fkFieldDefId                                
 --     where im.fkPOImportId = @importId AND ifd.FieldName='PARTNO') ANd f.FieldName='REVISION'                  
 --   )                                
 --   AND f.RowId NOT IN(                  
 --    SELECT rowid FROM ImportPODetails f                                 
 --    INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                                
 --    WHERE fkPOImportId=@importId AND d.FieldName='POITTYPE' AND f.Adjusted IN('MRO','Services'))                                
 -- END TRY              
 -- BEGIN CATCH                               
 --  SELECT                                
 --  ERROR_NUMBER() AS ErrorNumber                                
 --  ,ERROR_SEVERITY() AS ErrorSeverity                                
 --  ,ERROR_PROCEDURE() AS ErrorProcedure                                
 --  ,ERROR_LINE() AS ErrorLine                                
 --  ,ERROR_MESSAGE() AS ErrorMessage;                                
 --  SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                                
 -- END CATCH                                
 --END                                
   --   /****** PARTMFGR Validation ******/                                
                                                                        
 --BEGIN                                
 -- BEGIN TRY -- inside begin try                                
 --  UPDATE f                                
 --  SET [message] = 'Invalid Part Mfgr',[status]=@red,[validation]=@sys                                
 --  FROM ImportPODetails f INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                                
 --  WHERE fkPOImportId=@importId                                 
 --   AND d.FieldName = 'PARTMFGR' AND f.RowId                   
 --   NOT IN (                  
 --     SELECT d.RowId  FROM MfgrMaster m                                
 --     LEFT JOIN InvtMPNLink l on m.MfgrMasterId=l.MfgrMasterId                                
 --     INNER JOIN ImportPODetails d ON m.PartMfgr = d.Adjusted                                
 --     INNER JOIN ImportFieldDefinitions f ON d.fkFieldDefId=f.fieldDefId AND d.fkPOImportId = @importId                                
 --     WHERE l.UNIQ_KEY IN (                  
 --      SELECT DISTINCT UNIQ_KEY FROM Inventor i                   
 --      join importpodetails im on i.PART_NO=im.adjusted                                
 --      join ImportFieldDefinitions ifd on ifd.FieldDefId=im.fkFieldDefId                                
 --      where im.fkPOImportId = @importId ) AND f.FieldName='PARTMFGR'                  
 --      )                           
 --   AND f.RowId NOT IN(                  
 --    SELECT rowid FROM ImportPODetails f                                 
 --    INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                                
 --    WHERE fkPOImportId=@importId AND d.FieldName='POITTYPE' AND f.Adjusted IN('MRO','Services')                  
 --   )                                
 -- END TRY                                
 -- BEGIN CATCH                                 
 --  SELECT                                
 --   ERROR_NUMBER() AS ErrorNumber                                
 --   ,ERROR_SEVERITY() AS ErrorSeverity                                
 --   ,ERROR_PROCEDURE() AS ErrorProcedure                                
 --   ,ERROR_LINE() AS ErrorLine                                
 --   ,ERROR_MESSAGE() AS ErrorMessage;                                
 --   SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                                
 -- END CATCH                                
 --END                                
 -- 04/22/2020 Satyawan H: Modified validation for Part No/Revision and Part Mfgr    
 DECLARE @tPODetailstbl [tPODetails]    
 SELECT @ModuleId = ModuleId from MnxModule where ModuleName ='PO Upload'    
 INSERT INTO @tPODetailstbl    
 EXEC [GetImportPOItems] @importId=@importId,@ModuleId=@ModuleId    
    
 Update f     
  SET f.[message] =     
  CASE      
   -- PART_NO     
   WHEN d.FieldName = 'PARTNO' THEN     
    CASE WHEN RTRIM(invtP.PART_NO) = RTRIM(dtl.PARTNO) THEN ''     
    ELSE  'Invalid Part number/Revision or Part is inactive or not make/buy . '+ TRIM(dtl.PARTNO)+' / '+TRIM(dtl.REVISION) END    
           
   -- REVISION     
   WHEN d.FieldName = 'REVISION' THEN     
    CASE WHEN RTRIM(invtP.PART_NO) = RTRIM(dtl.PARTNO) THEN ''     
    ELSE  'Invalid Part number/Revision or Part is inactive or not make/buy. '+ TRIM(dtl.PARTNO)+' / '+TRIM(dtl.REVISION) END    
    
   -- PARTMFGR    
   WHEN d.FieldName = 'PARTMFGR' THEN     
    CASE WHEN ISNULL(tPartMfgr.PartMfgr,'')<>''THEN ''    
    ELSE 'Invalid Part Mfgr' END    
   ELSE ''    
  END    
  ,[Status] =     
  CASE      
    -- PART_NO     
   WHEN d.FieldName = 'PARTNO' THEN     
    CASE WHEN RTRIM(invtP.PART_NO) = RTRIM(dtl.PARTNO) THEN ''     
    ELSE @red END    
           
   -- REVISION     
   WHEN d.FieldName = 'REVISION' THEN     
    CASE WHEN RTRIM(invtP.PART_NO) = RTRIM(dtl.PARTNO) THEN ''     
    ELSE @red END    
    
   -- PARTMFGR    
   WHEN d.FieldName = 'PARTMFGR' THEN     
    CASE WHEN ISNULL(tPartMfgr.PartMfgr,'')<>'' THEN ''    
    ELSE @red END    
   ELSE ''    
    END     
    FROM ImportPODetails f     
    INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId AND d.FieldName IN ('PARTNO','REVISION','PARTMFGR') -- 06/17/2020 Satyawan H: check if the fields are 'PARTNO','REVISION','PARTMFGR' only                                 
    JOIN @tPODetailstbl dtl ON dtl.RowId = f.RowId AND f.fkPOImportId = @importId     
         AND dtl.ImportId = @importId AND dtl.POITTYPE NOT IN('MRO','Services')      
    LEFT JOIN INVENTOR inv ON inv.PART_NO = dtl.PARTNO AND TRIM(inv.REVISION) = TRIM(dtl.REVISION)     
    OUTER APPLY (    
   SELECT TOP 1 invtpart.UNIQ_KEY,REVISION,PART_NO    
   FROM INVENTOR invtpart WHERE invtpart.UNIQ_KEY = inv.UNIQ_KEY     
          AND invtpart.[STATUS] = 'Active' -- 05/07/2020 Satyawan H: Added Condition to check if the part is active and modified message    
          AND (invtpart.PART_SOURC = 'BUY' OR (invtpart.PART_SOURC='MAKE' AND invtpart.MAKE_BUY = 1)) -- 06/08/2020 Satyawan H: Added condition to check if the part is make/buy true    
    ) invtP    
    OUTER APPLY (    
  select TOP 1 m.PartMfgr from MfgrMaster m                                
    JOIN InvtMPNLink l on m.MfgrMasterId=l.MfgrMasterId and l.is_deleted = 0                               
    AND m.PartMfgr = dtl.PARTMFGR AND l.uniq_key=invtp.UNIQ_KEY    
    ) tPartMfgr      
                             
                              
    --   /****** Mfgr Part Number Validation ******/                              
 BEGIN                              
  BEGIN TRY -- inside begin try     
  --Modified  02/12/2020 Shiv P : Change the code to validate and update error message for partmfgr                             
--   UPDATE f                              
--   SET [message] = 'Invalid Mfgr Part Number',[status]=@red,[validation]=@sys                              
--   FROM ImportPODetails f INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
----Modified  01/23/2020 Shiv P : Check the selected MPN is associated with selected partmfgr or not        
--    OUTER APPLY (        
--     SELECT m.adjusted, m.RowId from  ImportPODetails m INNER JOIN ImportFieldDefinitions dd ON m.fkFieldDefId=dd.fieldDefId      
--   WHERE m.fkPOImportId=@importId AND dd.FieldName='PARTMFGR'       
--    ) s                      
--   WHERE fkPOImportId=@importId                               
--    AND d.FieldName = 'MFGR_PT_NO' AND (f.Adjusted <>'' AND f.RowId NOT IN (SELECT DISTINCT d.RowId  FROM MfgrMaster m                              
--       LEFT JOIN InvtMPNLink l on m.MfgrMasterId=l.MfgrMasterId                              
--       INNER JOIN ImportPODetails d ON m.mfgr_pt_no = d.Adjusted AND m.PartMfgr=s.Adjusted                     
--       INNER JOIN ImportFieldDefinitions f ON d.fkFieldDefId=f.fieldDefId AND d.fkPOImportId = @importId AND d.RowId=s.RowId                        
--       WHERE l.UNIQ_KEY IN (SELECT UNIQ_KEY FROM Inventor i join importpodetails im on i.PART_NO=im.adjusted                              
--                 join ImportFieldDefinitions ifd on ifd.FieldDefId=im.fkFieldDefId          
--                 where im.fkPOImportId = @importId ) AND f.FieldName='MFGR_PT_NO'))                                          
--    AND f.RowId  IN (SELECT rowid FROM ImportPODetails f                               
--       INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
--       WHERE fkPOImportId=@importId AND d.FieldName='POITTYPE' AND f.Adjusted IN('Invt Part'))                              
--       --Modified  09/30/2019 Shiv P : To validate the mfgr_pt_no if upload it wrong             
    
      --Modified  02/12/2020 Shiv P : Change the code to validate and update error message for partmfgr    
    DECLARE @TempTbl TABLE (TRowId UNIQUEIDENTIFIER, TPartNo nvarchar(max), isUpdate bit);    
    DECLARE @TempPartNo nvarchar(max), @TempPartMfgr nvarchar(max), @TempUniqKey nvarchar(max);    
    
    INSERT INTO @TempTbl (TRowId, TPartNo, ISUPDATE)                        
    select p.Rowid, p.Adjusted, 0 as ISUPDATE from ImportPODetails p     
    INNER JOIN importFieldDefinitions d ON p.fkFieldDefId=d.fieldDefId AND d.FieldName ='PARTNO' AND fkPOImportId=@importId                        
                        
    DECLARE @rowCnt INT                        
    SELECT @rowCnt = COUNT(TRowId) FROM @TempTbl                        
                  
    WHILE(@rowCnt > 0)                        
    BEGIN                        
      SELECT top 1 @TempRowId = TRowId, @TempPartNo = TPartNo from @TempTbl where ISUPDATE = 0;    
     SET @rowCnt = @rowCnt -1;                            
     UPDATE @TempTbl SET ISUPDATE = 1 WHERE TRowId =  @TempRowId                
    
    -- 04/29/2020 Satyawan H: The system will ignore validation for MPN field of PO item type MRO and Service items        
     IF EXISTS(SELECT 1 from  ImportPODetails m INNER JOIN ImportFieldDefinitions dd ON m.fkFieldDefId = dd.fieldDefId          
      WHERE m.fkPOImportId=@importId AND dd.FieldName = 'POITTYPE' AND (m.Adjusted = 'MRO' OR m.Adjusted = 'SERVICES')      
      AND m.Rowid= @TempRowId)      
     BEGIN    
    CONTINUE;      
     END    
     ELSE    
     BEGIN               
       SELECT top 1 @TempPartMfgr = m.adjusted from ImportPODetails m     
       INNER JOIN ImportFieldDefinitions dd ON m.fkFieldDefId = dd.fieldDefId      
       WHERE m.fkPOImportId=@importId AND dd.FieldName = 'PARTMFGR' AND m.Rowid= @TempRowId;    
               
       --Modified  03/19/2020 Shiv P : Get uniqkey of only Buy and Make part for validating PartMfgr and Mfgr Part Number    
       SELECT top 1 @TempUniqKey = i.UNIQ_KEY FROM Inventor i     
       WHERE i.PART_NO = @TempPartNo AND (i.PART_SOURC='MAKE' OR i.PART_SOURC='BUY');    
      
       IF NOT EXISTS (SELECT DISTINCT m.mfgr_pt_no FROM ImportPODetails f    
         INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId    
         INNER JOIN MfgrMaster m on f.Adjusted =  m.mfgr_pt_no    
         INNER JOIN InvtMPNLink l on m.MfgrMasterId = l.MfgrMasterId     
         WHERE UNIQ_KEY = @TempUniqKey AND m.PartMfgr = @TempPartMfgr AND d.FieldName = 'MFGR_PT_NO')    
       BEGIN    
       UPDATE f SET [message] = 'Invalid Mfgr Part Number',[status]=@red,[validation]=@sys     
       FROM ImportPODetails f INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId    
       WHERE fkPOImportId = @importId AND d.FieldName = 'MFGR_PT_NO' AND f.Rowid = @TempRowId     
       END    
      END                                   
   END                     
  END TRY                              
  BEGIN CATCH                               
   SELECT                              
   ERROR_NUMBER() AS ErrorNumber                              
   ,ERROR_SEVERITY() AS ErrorSeverity                              
   ,ERROR_PROCEDURE() AS ErrorProcedure                              
   ,ERROR_LINE() AS ErrorLine                              
   ,ERROR_MESSAGE() AS ErrorMessage;                              
   SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                              
  END CATCH                              
 END                              
                              
   --   /****** shipCharge  Validation ******/                              
 IF NOT EXISTS (SELECT Adjusted FROM ImportPODetails f INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
  WHERE fkPOImportId=@importId AND d.FieldName='SHIPCHARGE' AND f.Adjusted IN(SELECT Text FROM Support WHERE Fieldname = 'SHIPCHARGE'))                              
 BEGIN                              
  BEGIN TRY                               
   UPDATE f                              
   SET [message] = CASE WHEN f.Adjusted  = '' THEN '' ELSE 'Invalid shipcharge' END,                              
   [status]  = CASE WHEN f.Adjusted  = '' THEN @white ELSE @red END, [validation]=@sys                              
   FROM ImportPODetails f INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
   WHERE fkPOImportId=@importId AND d.FieldName='SHIPCHARGE'                               
                                   
  END TRY                              
  BEGIN CATCH                               
   SELECT                              
    ERROR_NUMBER() AS ErrorNumber                              
    ,ERROR_SEVERITY() AS ErrorSeverity                              
    ,ERROR_PROCEDURE() AS ErrorProcedure                              
    ,ERROR_LINE() AS ErrorLine                              
    ,ERROR_MESSAGE() AS ErrorMessage;                              
   SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                              
  END CATCH                     
 END                              
                              
    --   /****** shipVia  Validation ******/                              
 IF NOT EXISTS (SELECT Adjusted FROM ImportPODetails f INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
  WHERE fkPOImportId=@importId AND d.FieldName='SHIPVIA' AND f.Adjusted IN(SELECT Text FROM Support WHERE Fieldname = 'SHIPVIA'))                              
 BEGIN                              
  BEGIN TRY                               
   UPDATE f                              
    SET [message] = CASE WHEN f.Adjusted  = '' THEN '' ELSE 'Invalid SHIPVIA' END,                              
    [status]  = CASE WHEN f.Adjusted  = '' THEN @white ELSE @red END, [validation]=@sys                              
    FROM ImportPODetails f                 
    INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
    WHERE fkPOImportId=@importId                               
    AND d.FieldName='SHIPVIA' --AND f.Adjusted<>''                              
  END TRY                              
  BEGIN CATCH                               
   SELECT                              
    ERROR_NUMBER() AS ErrorNumber                              
    ,ERROR_SEVERITY() AS ErrorSeverity                              
    ,ERROR_PROCEDURE() AS ErrorProcedure                              
    ,ERROR_LINE() AS ErrorLine                              
    ,ERROR_MESSAGE() AS ErrorMessage;                              
   SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                              
  END CATCH                              
 END                              
                              
   --   /****** fob  Validation ******/                              
 IF NOT EXISTS (SELECT Adjusted FROM ImportPODetails f INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
  WHERE fkPOImportId=@importId AND d.FieldName='FOB' AND f.Adjusted IN(SELECT Text FROM Support WHERE Fieldname = 'FOB'))                              
 BEGIN    
  BEGIN TRY -- inside begin try                              
   UPDATE f                              
    SET [message] = CASE WHEN f.Adjusted  = '' THEN '' ELSE 'Invalid FOB' END,                              
    [status]  = CASE WHEN f.Adjusted  = '' THEN @white ELSE @red END, [validation]=@sys                              
    FROM ImportPODetails f INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
    WHERE fkPOImportId=@importId                               
    AND d.FieldName='FOB' --                              
  END TRY                              
  BEGIN CATCH                         
 SELECT                              
    ERROR_NUMBER() AS ErrorNumber                              
    ,ERROR_SEVERITY() AS ErrorSeverity                              
    ,ERROR_PROCEDURE() AS ErrorProcedure                              
    ,ERROR_LINE() AS ErrorLine                              
    ,ERROR_MESSAGE() AS ErrorMessage;                              
   SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                              
  END CATCH                              
 END                                
--END                              
                              
 IF NOT EXISTS (SELECT c.CID FROM Ccontact c INNER JOIN SUPINFO s ON c.CUSTNO=s.Supid                              
  WHERE c.TYPE='S' AND c.STATUS='ACTIVE' AND s.Uniqsupno=(SELECT TOP 1 Uniqsupno FROM SUPINFO s INNER JOIN ImportPODetails d ON s.SUPNAME = d.Adjusted                              
     INNER JOIN ImportFieldDefinitions f ON d.fkFieldDefId=f.fieldDefId AND fkPOImportId = @importId                              
     WHERE s.STATUS NOT IN('DISQUALIFIED','INACTIVE')))                              
 BEGIN                              
  BEGIN TRY -- inside begin try                              
   UPDATE f                              
    SET [message] = 'Invalid Conf Name',[status]=@red,[validation]=@sys                              
    FROM ImportPODetails f INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
    WHERE fkPOImportId=@importId                               
    AND (d.FieldName='CONFTO' AND  f.Adjusted<>'')                              
  END TRY                              
  BEGIN CATCH                               
   INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
   SELECT                              
    ERROR_NUMBER() AS ErrorNumber                              
    ,ERROR_SEVERITY() AS ErrorSeverity                              
    ,ERROR_PROCEDURE() AS ErrorProcedure                              
    ,ERROR_LINE() AS ErrorLine                              
    ,ERROR_MESSAGE() AS ErrorMessage;                              
   SET @headerErrs = 'There are issues verifying the empty adjusted values for the required fields (starting on line:206)'                              
  END CATCH                              
 END                              
                              
 BEGIN TRY -- inside begin try                              
  --Modified 09/13/2019 Nitesh B : Add validation for INVT RECV, MRO and Services for RequestType                         
  --Modified 11/14/2019 Nitesh B : Change validation for INVT RECV, MRO and Services for RequestType                             
  INSERT INTO @TempTable (TRowId, TAdjusted, ISUPDATE)                        
  select p.Rowid, p.Adjusted, 0 as ISUPDATE from ImportPODetails p INNER JOIN importFieldDefinitions d ON p.fkFieldDefId=d.fieldDefId AND d.FieldName ='POITTYPE' AND fkPOImportId=@importId                        
                        
  DECLARE @rowCount INT                        
  SELECT @rowCount = COUNT(TRowId) FROM @TempTable                        
                  
  WHILE(@rowCount > 0)                        
  BEGIN                        
   Select top 1 @TempRowId = TRowId, @TempAdjusted = TAdjusted from @TempTable where ISUPDATE = 0;                        
   /* 01/15/21 YS check if the Requestor empty when MRO or Service */
   if(@TempAdjusted = 'MRO') or (@TempAdjusted = 'Service')
   BEGIN
    UPDATE f                               
    SET [message]='Cannot omit ''Requestor/Distribute To'' value for '+@TempAdjusted+'.' ,[status]=@red,[validation]=@sys                              
    from ImportPOSchedule f                              
    OUTER APPLY (                
     SELECT f.ScheduleRowId, f.fkFieldDefId FROM ImportPOSchedule f                 
     INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
     WHERE d.FieldName ='REQUESTOR'                              
     AND f.adjusted ='' AND fkPOImportId=@importId                 
     AND fkRowId=@TempRowId                
    ) s                              
    WHERE f.ScheduleRowId = s.ScheduleRowId AND f.fkFieldDefId = s.fkFieldDefId AND f.FkRowId = @TempRowId    
   END
   /* end of 01/15/21 YS */
   if(@TempAdjusted = 'MRO')                              
   BEGIN                              
    UPDATE f                               
    SET [message]='Invalid RequestType',[status]=@red,[validation]=@sys                              
    from ImportPOSchedule f                              
    OUTER APPLY (                
     SELECT f.ScheduleRowId, f.fkFieldDefId FROM ImportPOSchedule f                 
     INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
     WHERE d.FieldName ='REQUESTTP'                              
     AND f.adjusted NOT IN('MRO','WO ALLOC','PRJ ALLOC') AND fkPOImportId=@importId                 
     AND fkRowId=@TempRowId                
    ) s                              
    WHERE f.ScheduleRowId = s.ScheduleRowId AND f.fkFieldDefId = s.fkFieldDefId AND f.FkRowId = @TempRowId                       
    
	


    UPDATE f                               
    SET [message]='',[status]='',[validation]=''                              
    from ImportPOSchedule f                              
    OUTER APPLY (                    
     SELECT f.ScheduleRowId, f.fkFieldDefId FROM ImportPOSchedule f                     
     INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
     WHERE d.[required] = 1 AND d.FieldName = 'WAREHOUSE'                     
     AND fkPOImportId=@importId AND fkRowId=@TempRowId                
    ) s                              
    WHERE f.ScheduleRowId = s.ScheduleRowId AND f.fkFieldDefId = s.fkFieldDefId                      
   END                              
                                
   IF(@TempAdjusted = 'INVT PART')                              
   BEGIN                              
    UPDATE f                               
    SET [message]='Invalid RequestType',[status]=@red,[validation]=@sys                              
    from ImportPOSchedule f                              
    OUTER APPLY (                    
     SELECT f.ScheduleRowId, f.fkFieldDefId FROM ImportPOSchedule f                     
     INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
     WHERE d.FieldName ='REQUESTTP'                              
     AND f.adjusted NOT IN('INVT RECV','WO ALLOC','PRJ ALLOC') AND fkPOImportId=@importId                 
     AND fkRowId=@TempRowId                   
    ) s                              
    WHERE f.ScheduleRowId = s.ScheduleRowId AND f.fkFieldDefId = s.fkFieldDefId AND f.FkRowId = @TempRowId                        
                        
    UPDATE f                               
    SET [message]='Field Cannot Be Blank',[status]=@red,[validation]=@sys                              
    from ImportPOSchedule f                              
    OUTER APPLY (                    
     SELECT f.ScheduleRowId, f.fkFieldDefId FROM ImportPOSchedule f                     
     INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
     WHERE d.[required] = 1 AND d.FieldName = 'WAREHOUSE'                     
     AND f.adjusted='' AND fkPOImportId=@importId AND fkRowId=@TempRowId                
    ) s                              
    WHERE f.ScheduleRowId = s.ScheduleRowId AND f.fkFieldDefId = s.fkFieldDefId                          
   END                               
                           
   if(@TempAdjusted = 'Services')                              
   BEGIN                              
    UPDATE f                               
    SET [message]='Invalid RequestType',[status]=@red,[validation]=@sys                 
    from ImportPOSchedule f                              
    OUTER APPLY (                
     SELECT f.ScheduleRowId, f.fkFieldDefId FROM ImportPOSchedule f                 
     INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId     
     WHERE d.FieldName ='REQUESTTP'                              
     AND f.adjusted NOT IN('Services','WO ALLOC','PRJ ALLOC') AND fkPOImportId=@importId                
     AND fkRowId=@TempRowId                
    ) s                              
    WHERE f.ScheduleRowId = s.ScheduleRowId AND f.fkFieldDefId = s.fkFieldDefId AND f.FkRowId = @TempRowId                    
                      
    UPDATE f                               
    SET [message]='',[status]='',[validation]=''                              
    from ImportPOSchedule f                              
    OUTER APPLY (                    
     SELECT f.ScheduleRowId, f.fkFieldDefId FROM ImportPOSchedule f                     
     INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
     WHERE d.[required] = 1 AND d.FieldName = 'WAREHOUSE'                     
     AND fkPOImportId=@importId   AND fkRowId=@TempRowId                 
    ) s                              
    WHERE f.ScheduleRowId = s.ScheduleRowId AND f.fkFieldDefId = s.fkFieldDefId                                 
   END                  
                              
  SET @rowCount = @rowCount -1;                        
  UPDATE @TempTable SET ISUPDATE = 1 WHERE TRowId =  @TempRowId                               
 END                        
 END TRY                              
 BEGIN CATCH                               
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
  SELECT                              
  ERROR_NUMBER() AS ErrorNumber                              
  ,ERROR_SEVERITY() AS ErrorSeverity                              
  ,ERROR_PROCEDURE() AS ErrorProcedure                              
  ,ERROR_LINE() AS ErrorLine                              
  ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues verifying required fields contain a value (starting on line:561)'                              
 END CATCH                               
 DELETE FROM @TempTable;                        
                
   --   /****** Warehouse Validation ******/                               
 BEGIN                              
  BEGIN TRY -- inside begin try             
   ----Modified  08/09/2019 Shiv P : Add validation for WareHouse not able to save if uploaded in small case                               
   --Modified  09/17/2019 Nitesh B : Add validation for INVT RECV, MRO and Services for Warehouse                              
   --Modified  11/14/2019 Nitesh B : Change validation for INVT RECV, MRO and Services for Warehouse                        
                        
   INSERT INTO @TempTable (TRowId, TAdjusted, ISUPDATE)                        
   select p.Rowid, p.Adjusted, 0 as ISUPDATE from ImportPODetails p INNER JOIN importFieldDefinitions d ON p.fkFieldDefId=d.fieldDefId AND d.FieldName ='POITTYPE' AND fkPOImportId=@importId                        
                    
   DECLARE @tmoduleId VARCHAR(10), @tpartNo  VARCHAR(100), @trev VARCHAR(100),                     
   @tpartmfgr VARCHAR(100), @tmfgr_pt_no VARCHAR(100), @tuniqKey VARCHAR(10)                     
   SET @tmoduleId=(SELECT ModuleId FROM MnxModule WHERE modulename='PO Upload')                       
   SELECT @rowCount = COUNT(TRowId) FROM @TempTable                        
                   
   WHILE(@rowCount > 0)                        
   BEGIN                        
    Select top 1 @TempRowId = TRowId, @TempAdjusted = TAdjusted from @TempTable where ISUPDATE = 0;                        
    if(@TempAdjusted = 'INVT PART')                              
    BEGIN                        
     --Modified  12/17/2019 Shiv P : Modifid to check if warehouse exists for the provided Mfgr when importing from template                    
     select @tpartNo = pd.Adjusted from ImportPODetails pd                    
     JOIN ImportFieldDefinitions ifd ON ifd.FieldDefId = pd.fkFieldDefId                    
   where fkPOImportId=@importId  AND RowId=@TempRowId AND FieldName ='PARTNO' AND ModuleId =@tmoduleId                    
                    
     select @trev = pd.Adjusted from ImportPODetails pd                    
     JOIN ImportFieldDefinitions ifd ON ifd.FieldDefId = pd.fkFieldDefId                    
     where fkPOImportId=@importId  AND RowId=@TempRowId AND FieldName ='REVISION' AND ModuleId =@tmoduleId                           
     select @tpartmfgr = pd.Adjusted from ImportPODetails pd                    
     JOIN ImportFieldDefinitions ifd ON ifd.FieldDefId = pd.fkFieldDefId                    
     where fkPOImportId=@importId  AND RowId=@TempRowId AND ModuleId =@tmoduleId  AND FieldName = 'PARTMFGR'                    
                    
     select @tmfgr_pt_no = pd.Adjusted from ImportPODetails pd                    
     JOIN ImportFieldDefinitions ifd ON ifd.FieldDefId = pd.fkFieldDefId                    
     where fkPOImportId=@importId  AND RowId=@TempRowId AND ModuleId =@tmoduleId  AND FieldName = 'MFGR_PT_NO'                    
                           
     SELECT TOP 1 @tuniqKey = UNIQ_KEY FROM INVENTOR where TRIM(PART_NO) = TRIM(@tpartNo) AND TRIM(REVISION) = TRIM(@trev)                    
                    
     UPDATE f                               
     --SET [message]= CASE WHEN inv.WAREHOUSE IN ('')  OR inv.WAREHOUSE IS NOT NULL THEN '' ELSE 'Invalid Warehouse' END,                              
     -- [status]= CASE WHEN inv.WAREHOUSE <>'' OR inv.WAREHOUSE IS NOT NULL THEN '' ELSE @red END,                              
     -- [validation]= CASE WHEN inv.WAREHOUSE <>'' OR inv.WAREHOUSE  IS NOT NULL THEN '' ELSE @sys END,                          
     --    [Adjusted] = CASE WHEN inv.WAREHOUSE <>'' OR inv.WAREHOUSE IS NOT NULL THEN inv.WAREHOUSE ELSE f.Adjusted END                              
     --original = CASE WHEN s.Warehouse <>'' OR s.Warehouse IS NOT NULL THEN s.Warehouse ELSE Adjusted END                   
     --Modified  12/17/2019 Shiv P : Checked the autolocation setting for MFGR                        
     SET [message]= CASE WHEN (inv.autolocation =0 AND inv.WAREHOUSE <> '' OR inv.WAREHOUSE IS NOT NULL)                   
         OR (inv.autolocation =1 AND s.WAREHOUSE <>'' AND s.WAREHOUSE IS NOT NULL) THEN '' ELSE 'Invalid Warehouse' END,         
      [status]= CASE WHEN (inv.autolocation =0 AND inv.WAREHOUSE <> '' OR inv.WAREHOUSE IS NOT NULL)                   
         OR (inv.autolocation =1 AND s.WAREHOUSE <>'' AND s.WAREHOUSE IS NOT NULL) THEN '' ELSE @red END,                              
      [validation]= CASE WHEN (inv.autolocation =0 AND inv.WAREHOUSE <> '' OR inv.WAREHOUSE IS NOT NULL)                   
         OR (inv.autolocation =1 AND s.WAREHOUSE <>'' AND s.WAREHOUSE IS NOT NULL) THEN '' ELSE @sys END,                               
      [Adjusted] = CASE WHEN (inv.autolocation =0 AND inv.WAREHOUSE <> '' OR inv.WAREHOUSE IS NOT NULL)                   
         OR (inv.autolocation =1 AND s.WAREHOUSE <>'' AND s.WAREHOUSE IS NOT NULL) THEN inv.WAREHOUSE ELSE f.Adjusted END                       
     from ImportPOSchedule f                          
     JOIN ImportFieldDefinitions ifd ON ifd.FieldDefId=f.fkFieldDefId AND ifd.FieldName='WAREHOUSE' AND ModuleId=@tmoduleId                        
     OUTER APPLY (                    
   SELECT f.ScheduleRowId, f.fkFieldDefId,wh.Warehouse     
   FROM ImportPOSchedule f                     
   INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
         OUTER APPLY (    
   SELECT Warehouse  FROM WAREHOUS where WAREHOUSE = f.adjusted    
   ) wh                              
   WHERE d.FieldName ='WAREHOUSE' AND fkPOImportId=@importId  AND  fkRowId=@TempRowId                      
     ) s                      
     OUTER APPLY                    
     (                    
      SELECT distinct                      
  ps.adjusted,                    
  tt.WAREHOUSE,                    
  ps.ScheduleRowId,    
  ps.fkFieldDefId,    
  mfMaster.autolocation    
      FROM Inventor i                    
      INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY AND mpn.Is_deleted = 0                        
      INNER JOIN MfgrMaster mfMaster ON mfMaster.MfgrMasterId = mpn.MfgrMasterId                     
       AND mfMaster.PartMfgr=@tpartmfgr                       
       AND mfmaster.mfgr_pt_no=@tmfgr_pt_no     
    AND mfMaster.IS_DELETED=0                     
      JOIN ImportPOSchedule ps ON ps.fkRowId = @TempRowId                    
      JOIN ImportFieldDefinitions ifd ON ifd.FieldDefId=ps.fkFieldDefId                     
      AND ifd.FieldName='WAREHOUSE' AND ModuleId=@tmoduleId                     
      OUTER APPLY (                       
       SELECT WAREHOUSE  FROM  WAREHOUS wa                     
       JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY                     
        AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd                     
        AND imfgr.Is_Deleted = 0       
    -- 05/06/2020 Satyawan H: Modified condition to verify the given Warehouse on the basis of autolocation    
       WHERE ((mfMaster.autolocation = 1) OR (mfMaster.autolocation = 0 AND imfgr.UNIQWH = wa.UNIQWH))                       
       AND wa.Warehouse <> 'WIP' AND Warehouse <> 'WO-WIP'                      
       AND Warehouse <> 'MRB'                    
       AND wa.Warehouse  in (ps.adjusted)                    
      ) tt                      
      WHERE i.UNIQ_KEY= @tuniqKey                     
     ) inv                         
        --AND f.adjusted NOT IN(SELECT Warehouse FROM WAREHOUS) AND fkPOImportId=@importId) s                              
     WHERE f.ScheduleRowId = inv.ScheduleRowId AND f.fkFieldDefId = inv.fkFieldDefId   AND  fkRowId=@TempRowId                          
                      
                         
     --05/14/2019 Satish B : populating the default GLNBR                               
     UPDATE f                               
      SET Adjusted= CASE WHEN  (ISNULL(f.Adjusted,'')=''  OR f.Adjusted ='' )         
                         and (w.WH_GL_NBR<>'' OR w.WH_GL_NBR IS NOT NULL) THEN w.WH_GL_NBR                 
             ELSE  f.Adjusted END,                       
      --Modified  12/09/2019 Shiv P : Modifid the condition to check validation of Glnumber                           
      [status]=  CASE WHEN  (ISNULL(f.Adjusted,'')<>''  OR f.Adjusted <>'')AND w.WH_GL_NBR<>f.Adjusted THEN @red ELSE '' END,                          
      --Modified  12/06/2019 Shiv P : Add validation for provided GL Number that doesn't match with warehouse for Invt Part                      
      [message]= CASE WHEN(ISNULL(f.Adjusted,'')<>''  OR f.Adjusted <>'')AND w.WH_GL_NBR<>f.Adjusted THEN 'Invalid GL Number' ELSE '' END                        
     from ImportPOSchedule f                              
     OUTER APPLY (                        
      SELECT f.ScheduleRowId, f.fkFieldDefId,f.adjusted, d.FieldName FROM ImportPOSchedule f                         
      INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                                
      WHERE d.FieldName in ('WAREHOUSE') AND fkPOImportId= @importId AND fkRowId=@TempRowId                              
     ) s                              
     OUTER APPLY (                        
      SELECT f.ScheduleRowId, f.fkFieldDefId,f.adjusted, d.FieldName FROM ImportPOSchedule f                         
      INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                                
      WHERE d.FieldName in ('GLNBR') AND fkPOImportId= @importId AND fkRowId=@TempRowId                               
      AND   f.ScheduleRowId= s.ScheduleRowId                              
     ) s1                              
     OUTER APPLY (                        
      SELECT WAREHOUSE ,WH_GL_NBR FROM WAREHOUS WHERE WAREHOUSE = S.ADJUSTED                        
     ) w                                
     WHERE f.ScheduleRowId = s1.ScheduleRowId AND f.fkFieldDefId = s1.fkFieldDefId  AND fkRowId=@TempRowId                           
    END                       
    --Modified  12/06/2019 Shiv P : Add validation for GL Numbers that are listed in INVTGLS as REC_TYPE 'M' For MRP and Service Parts                        
   ELSE                        
   BEGIN                        
    UPDATE f                                 
     SET [message]= CASE WHEN f.Adjusted <> '' AND (s.GL_NBR ='' OR s.GL_NBR IS NULL) THEN 'Invalid GL Number' ELSE '' END,                                
      [status]= CASE WHEN f.Adjusted <> '' AND (s.GL_NBR ='' OR s.GL_NBR IS NULL) THEN @red ELSE '' END,                                
      --[validation]= CASE WHEN f.Adjusted <> '' AND (s.GL_NBR ='' OR s.GL_NBR IS NULL) THEN @sys ELSE '' END,                                 
      Adjusted = CASE WHEN f.Adjusted <> '' AND (s.GL_NBR ='' OR s.GL_NBR IS NULL) THEN Adjusted ELSE s.GL_NBR END                                    
    FROM ImportPOSchedule f                                
    OUTER APPLY(                        
     SELECT f.ScheduleRowId, f.fkFieldDefId,GLN.GL_NBR FROM ImportPOSchedule f                         
     INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId AND f.fkRowId=@TempRowId                                
     OUTER APPLY (                        
      select TOP 1 GN.GL_NBR from GL_NBRS GN                         
      JOIN INVTGLS IG ON GN.GL_NBR = IG.GL_NBR where IG.REC_TYPE ='M'                         
      AND GN.GL_NBR = f.Adjusted                        
     ) GLN WHERE d.FieldName ='GLNBR' AND fkPOImportId=@importId AND f.fkRowId=@TempRowId                 
    ) s                                
    WHERE f.ScheduleRowId = s.ScheduleRowId AND f.fkFieldDefId = s.fkFieldDefId  AND f.fkRowId=@TempRowId                            
   END                        
   SET @rowCount = @rowCount -1;                        
   UPDATE @TempTable SET ISUPDATE = 1 WHERE TRowId =  @TempRowId                         
  END                        
  END TRY                         
  BEGIN CATCH                               
   INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
   SELECT                              
   ERROR_NUMBER() AS ErrorNumber                              
   ,ERROR_SEVERITY() AS ErrorSeverity                         
   ,ERROR_PROCEDURE() AS ErrorProcedure                              
   ,ERROR_LINE() AS ErrorLine                              
   ,ERROR_MESSAGE() AS ErrorMessage;                              
   SET @headerErrs = 'There are issues verifying the order qty and schedule qty values for the required fields'                 
   select * from @ErrTable                             
  END CATCH                              
 END                    
 DELETE FROM @TempTable;                             
                              
  --05/16/2019 Satish B : Add validation for Order qty and Schedule qty validation if schedule qty is more order qty                              
 BEGIN                               
  BEGIN TRY                    
  --Modified  01/03/2020 Shiv P : Added validation if User has entered the different price for same item.          
 UPDATE f                              
  SET [message] = 'User has entered the different price for same item.',[status]=@red,[validation]=@sys                              
 FROM ImportPODetails f INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
    WHERE fkPOImportId=@importId                               
    AND d.FieldName='COSTEACH' AND f.Adjusted like '%Error'                 
                         
   update f                  
     SET [message] = CASE  WHEN QtyValidate = 1  THEN '' ELSE 'Schedule qty is more Order qty' END,                              
      [status]=CASE  WHEN QtyValidate = 1  THEN '' ELSE @red END,                              
      [validation]=CASE WHEN QtyValidate = 1  THEN '' ELSE @sys END                                 
   from ImportPODetails f                               
   outer apply (                              
    select   CASE WHEN SUM(cast(importposchedule.adjusted as int)) > ordQty  THEN 0 ELSE 1 END QtyValidate,                              
    SUM(cast(importposchedule.adjusted as int)) as SCHDQTY, ordQty,rowid,PODetailId from importposchedule                 
    join ImportFieldDefinitions on fkFieldDefId =ImportFieldDefinitions.FieldDefId                              
    outer apply (                
     select rowid  ,SUM(CAST(adjusted as int)) ordQty,PODetailId from ImportPODetails                  
     join ImportFieldDefinitions on fkFieldDefId = ImportFieldDefinitions.FieldDefId                               
     where ImportPODetails.fkPOImportId =@importId                              
     AND ImportFieldDefinitions.FieldName='ORD_QTY'                               
     group by rowid,PODetailId                
    ) t                              
    where FieldName='SCHDQTY' and fkPOImportId = @importId                              
    and fkrowid =t.rowid                               
    group by fkrowid,t.ordQty,rowid,PODetailId                
   ) t1                              
   where  f.PODetailId= t1.PODetailId                              
  END TRY                              
  BEGIN CATCH                               
   INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
   SELECT                              
   ERROR_NUMBER() AS ErrorNumber                              
   ,ERROR_SEVERITY() AS ErrorSeverity                              
   ,ERROR_PROCEDURE() AS ErrorProcedure                              
   ,ERROR_LINE() AS ErrorLine                              
   ,ERROR_MESSAGE() AS ErrorMessage;                              
   SET @headerErrs = 'There are issues verifying the order qty and schedule qty values for the required fields'                              
  END CATCH                              
 END                              
                                  
 -- 05/20/2019 Satish B : Add validation for PO Number                               
 DECLARE @pONum nvarchar(MAX)='', @pNum nvarchar(MAX)='', @NewPONum nvarchar(MAX)=''                             
 DECLARE @autoNum table (pnum varchar (15))                     
 -- Vijay G :07/26/2019 Select PoNumber from ImportPOMain                              
 SET @poNum = COALESCE((SELECT poNumber from ImportPOMain where POImportId = @importId),'noPO' )                              
                              
 -- Vijay G :07/26/2019 Remove Unwanted conversion code                               
  --SELECT @pNum = 'T' + CASE WHEN (PATINDEX('%[a-z]%' ,@pONum) > 0)               
  --    OR (PATINDEX('%[-,~,@,#,$,%,&,*,(,),!,?,.,,,+,\,/,?,`,=,;,:,{,},^,_,|]%',@pONum) > 0)                                 
  --   THEN  RIGHT('000000000000000' + CONVERT(VARCHAR(15), RTRIM(@pONum)), 14) ELSE REPLACE(STR(CAST(@pONum AS INT),14), SPACE(1), '0')  END                               
  --SELECT @pNum = 'T' + REPLACE(STR(CONVERT(VARCHAR(15), RTRIM(@pONum)),14), SPACE(1), '0')                              
               
                         
 DECLARE @isAutoPONumbering BIT                                                    
 SELECT @isAutoPONumbering = CASE WHEN  w.settingId IS NULL THEN m.settingValue ELSE w.settingValue END                 
 FROM mnxSETtingsmanagement m                                               
 LEFT JOIN wmSETtingsmanagement w ON m.SETtingid=w.SETtingid                                               
 WHERE  SETtingName ='AutoManualPO'                                              
        
--Modified  01/28/2020 Vijay G : Commented the old code of Po numbering    
--IF(@isAutoPONumbering=1)                                      
-- BEGIN                                   
--  SELECT @autoNum= dbo.padl(convert(bigint,ISNULL(w.settingValue,m.settingValue))+1,15,DEFAULT)                      
--  FROM MnxSettingsManagement  m             
--  LEFT JOIN wmsettingsmanagement w ON w.settingId = m.settingId             
--  where m.settingName='LastPONumber'                              
                                      
--  SET @autoNum = (SELECT REPLACE(LEFT(@autoNum,1),'0','T')+RIGHT(@autoNum,Len(@autoNum)-1));                                
--  SET @pNum = @autoNum;                    
--  SET @NewPONum = @autoNum;                       
              
--  UPDATE f                               
--  SET adjusted =@autoNum ,[status]='',[validation]=''                              
--  FROM ImportPODetails f             
--  INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
--  WHERE fkPOImportId=@importId                               
--  AND d.FieldName='PONUM'                               
                               
--  Update ImportPOMain SET PONumber= @autoNum WHERE POImportId=@importId                             
-- END     
    
--Modified  01/28/2020 Vijay G : Added new block of code as per new implementation                          
 IF(@isAutoPONumbering=1 AND (@poNum='' OR @poNum=NULL))                                          
 BEGIN                                                                  
  INSERT INTO ImportPoNum (EmptyValue) OUTPUT inserted.PONUM into @autoNum values('')         
            
  UPDATE f                                   
  SET adjusted =(SELECT TOP 1 pnum FROM @autoNum) ,[status]='',[validation]=''                                  
  FROM ImportPODetails f                 
  INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                                  
  WHERE fkPOImportId=@importId                                   
  AND d.FieldName='PONUM'                                   
              
  Update ImportPOMain SET PONumber= (SELECT TOP 1 pnum FROM @autoNum) WHERE POImportId=@importId               
  DELETE FROM ImportPoNum WHERE PONUM<>(SELECT TOP 1 pnum FROM @autoNum)          
 delete from @autoNum                     
 END          
     
 IF(@isAutoPONumbering=0 AND (@poNum='' OR @poNum=NULL))                                          
 BEGIN                                       
    UPDATE f                              
    SET [message] = 'PO Number Required',[status]=@red,[validation]=@sys                              
    FROM ImportPODetails f INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
    WHERE fkPOImportId=@importId                               
    AND d.FieldName='PONUM'                     
 END                                 
           
 SELECT @pNum = 'T' +RIGHT('000000000000000' + CONVERT(VARCHAR(15), RTRIM(@pONum)), 14)                                
                                  
 SET @NewPONum=(SELECT REPLACE(LEFT(Rtrim(@pNum),1),'T','0'))+ RIGHT(Rtrim(@pNum),Len(Rtrim(@pNum))-1)                
                            
 IF  EXISTS(SELECT PONUM FROM POMAIN WHERE PONUM = @pNum OR PONUM = @NewPONum)                              
 BEGIN                              
 --Modified  11/05/2019 Shiv P : Populate the last genrated PO when setting is auto other wise provide error message if number is already exist                              
  BEGIN TRY                                
   BEGIN                                
    UPDATE f                              
    SET [message] = 'PO Number already exist',[status]=@red,[validation]=@sys                              
    FROM ImportPODetails f INNER JOIN ImportFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId                              
    WHERE fkPOImportId=@importId                               
    AND d.FieldName='PONUM'                               
   END                             
  END TRY                              
  BEGIN CATCH                               
   INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                     
   SELECT                              
    ERROR_NUMBER() AS ErrorNumber       ,ERROR_SEVERITY() AS ErrorSeverity                                  
    ,ERROR_PROCEDURE() AS ErrorProcedure                              
    ,ERROR_LINE() AS ErrorLine                              
    ,ERROR_MESSAGE() AS ErrorMessage;                              
   SET @headerErrs = 'There are issues verifying the existing PoNumber adjusted values for the required fields'                              
  END CATCH                              
 END                              
                    
     
 -- 06/04/2020 Satyawan H: validation of the duplicate item nomber for same part    
 -- 06/08/2020 Satyawan H: if item no. is empty update it with error and message as required    
 BEGIN TRY    
  UPDATE d     
   SET MESSAGE = '',    
    [status]=  '',    
    [validation]= ''    
   FROM ImportPODetails d     
   JOIN importFieldDefinitions fd ON d.fkFieldDefId = fd.fieldDefId     
  WHERE FieldName = 'ItemNo' AND fkPoImportId = @importId    
    
  UPDATE det     
   SET MESSAGE = 'Item number is duplicated for same part.',    
    [status]=  @red,    
    [validation]= @sys    
   FROM ImportPODetails det     
   JOIN importFieldDefinitions fd1 ON fd1.FieldDefId = det.fkFieldDefId WHERE PODetailId IN (    
   SELECT DISTINCT PODetailId FROM ImportPODetails dd    
    JOIN importFieldDefinitions fd ON fd.FieldDefId = dd.fkFieldDefId    
    WHERE  dbo.fremoveLeadingZeros(adjusted)  IN (  -- 09/15/2020 Rajendra K: Used fremoveLeadingZeros to remove leading 0 of  item number in validation    
    SELECT dbo.fremoveLeadingZeros(adjusted)        
    FROM ImportPODetails d     
     JOIN importFieldDefinitions fd ON d.fkFieldDefId = fd.fieldDefId     
    GROUP BY fkPOImportId,fkFieldDefId,FieldName,dbo.fremoveLeadingZeros(adjusted)       
    HAVING FieldName = 'ItemNo' AND count(adjusted) >1    
    AND fkPOImportId = @importId    
   ) AND fkPOImportId = @importId    
     AND fd.FieldName = 'ItemNo'    
  ) AND fd1.FieldName = 'ItemNo'     
    
  UPDATE d     
   SET MESSAGE = 'Item No. is required.',    
    [status]=  @red,    
    [validation]= @sys    
   FROM ImportPODetails d     
   JOIN importFieldDefinitions fd ON d.fkFieldDefId = fd.fieldDefId     
  WHERE FieldName = 'ItemNo'     
   AND TRIM(d.Adjusted) = ''     
   AND fkPoImportId = @importId    
      
 END TRY    
 BEGIN CATCH    
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
  SELECT                              
  ERROR_NUMBER() AS ErrorNumber                              
  ,ERROR_SEVERITY() AS ErrorSeverity                              
  ,ERROR_PROCEDURE() AS ErrorProcedure                              
  ,ERROR_LINE() AS ErrorLine                              
  ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues validating the item nomber at line No: ' +  CAST(ERROR_LINE() as varchar(100))                             
  SELECT * FROM @ErrTable     
 END CATCH     
               
  --Validate Main Header Data                              
 BEGIN TRY                                
  UPDATE p                 
   SET IsValidated=                               
   CASE WHEN (                              
   NOT EXISTS (SELECT * FROM SUPINFO WHERE STATUS NOT IN('DISQUALIFIED','INACTIVE')                                
   AND  (ISNULL(p.Supplier,'') <> '' AND LTRIM(RTRIM(SUPNAME)) = LTRIM(RTRIM(p.Supplier))))                                --For detail fields                              
   OR EXISTS(SELECT 1 FROM ImportPODetails -- 11/30/2020 Rajendra K: Added contition and join to skip if the SHIPCHARGE,SHIPVIA and FOB having error
				INNER JOIN importFieldDefinitions fd ON fkFieldDefId=fd.fieldDefId WHERE STATUS = 'i05red' AND fkPOImportId=@importId
				AND fd.FieldName != 'SHIPCHARGE'
				AND fd.FieldName != 'SHIPVIA'
				AND fd.FieldName != 'FOB') -- For item details                                              
   OR EXISTS(SELECT 1 FROM ImportPOSchedule WHERE STATUS = 'i05red' AND fkPOImportId=@importId) -- For item Schedule                                             
   OR EXISTS(SELECT 1 FROM ImportPOTax WHERE STATUS = 'i05red' AND fkPOImportId=@importId) -- For item Tax                            
   )                              
   THEN 0 ELSE 1 END                              
  FROM ImportPOMain p WHERE POImportId= @importId                               
 END TRY                              
 BEGIN CATCH                               
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)                              
  SELECT                              
  ERROR_NUMBER() AS ErrorNumber                              
  ,ERROR_SEVERITY() AS ErrorSeverity                              
  ,ERROR_PROCEDURE() AS ErrorProcedure                              
  ,ERROR_LINE() AS ErrorLine                              
  ,ERROR_MESSAGE() AS ErrorMessage;                              
  SET @headerErrs = 'There are issues validating the header fields (starting on line:310)'                              
  SELECT * FROM @ErrTable                              
 END CATCH                
END