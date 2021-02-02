  
-- =============================================      
-- Author: Shivshankar P      
-- Create date: 02/20/2012      
-- Description: checks the standard values for import record      
-- 08/03/2018 Shivshanker P :Increased the column size and validated      
-- 09/03/2018 Shivshanker P : Added QtyPerPackage and validated the fields      
-- 03/16/2018 Shivshanker P :  Validated lot and removed joins      
-- 06/14/2018 Shivshanker P :  Removed QtyPerPackage validation      
-- 09/27/2018 Rajendra K : Changed Reference required condition      
-- 09/28/2018 Rajendra K : Updated condition for Int data type      
-- 10/15/2018 Shivshankar P: Removed SheetNo Column  and removed expDate      
-- 10/17/2018 Shivshankar P: Removed validate reference      
-- 11/27/2018 Mahesh B: Dynamic warehouse location   
-- 12/08/2018 Nitesh B : Change 'Part number/Uniq_key' to 'Part number/Revision'   
-- 12/26/2016 Mahesh B : IF SID is 1 validate QtyPerPackage field  
-- Nitesh B 2/5/2019: Added a condition  AND REC_TYPE = 'R'
-- Nitesh B 6/12/2019 : Added a condition i.ImportType = 'C' OR i.ImportType = 'S' for IPC/IPS
-- Nitesh B 6/13/2019 : Added a condition to get CONSG Part details for IPC
-- Nitesh B 6/17/2019 : Added custpartno and validated the fields
-- Nitesh B 6/19/2019 : Add new parameter @rowId for update validation against selected row
-- Nitesh B 8/2/2019 : Update IsValidate with the ImportType 'C' and 'S'
-- Nitesh B 8/23/2019 : Added OUTER APPLY and condition to check lotcode exist for part
-- Nitesh B 9/03/2019 : Added a condition to get BUY Part details for IPS (Contract)
-- Nitesh B 10/9/2019 : Added validation for custpartno Field
-- Nitesh B 11/7/2019 : Added a condition for apply orange color for part no field when ImportType = 'C'
-- Nitesh B 12/4/2019 : Remove a condition mfgr.Netable = 1 to receive qty in Non-Netable location
-- Shivshankar P 04/16/2020 : Add CASE to get Instore location for Supplier Bonded upload
-- Shivshankar P 05/15/2020 : Change INNER to LEFT JOIN and conditions if MFGR, MPN is available and warehose, location not for part  
-- Shivshnakar P 11/10/2020 : Updated condition and change INT to VARCHAR for fractional quantity 
-- Shivshankar P 11/20/2020 : Add the validation for the QtyPerPackage and recv_qty field for U_OF_MEAS 
-- EXEC ImportInvtCheckValues @importId ='F759F4CE-2B28-4BD9-95FB-F31EA950E7EB'      
-- =============================================      
CREATE PROCEDURE [dbo].[ImportInvtCheckValues]         
 -- Add the parameters for the stored procedure here      
 @importId UNIQUEIDENTIFIER,  
 @rowId UNIQUEIDENTIFIER = NULL  -- 6/19/2019 Nitesh B : Add new parameter @rowId for update validation against selected row 
AS      
BEGIN      
 -- SET NOCOUNT ON added to prevent extra result sets from      
 -- interfering with SELECT statements.      
 SET NOCOUNT ON;      
      
    -- Insert statements for procedure here      
     DECLARE @headerErrs VARCHAR(MAX),@Uniqkey CHAR(10),@partNo CHAR(35),@rev CHAR(8) ,@custNo Char(10)  
          
  	 Select @custNo = CompanyNo from InvtImportHeader where InvtImportId=@importId and importComplete=0
          
     DECLARE @NewLocation TABLE (Uniq_key CHAR(10), Uniqmfgrhd CHAR(10), uniqwh CHAR(10), Location CHAR(17), w_key CHAR(10))      
      
  
     DECLARE @white VARCHAR(20)='i00white',@green VARCHAR(20)='i01green',@blue VARCHAR(20)='i03blue',@orange VARCHAR(20)='i04orange',    
           @red VARCHAR(20)='i05red',@sys VARCHAR(20)='01system',@usr VARCHAR(20)='03user'        
  
      
     DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))      
     
	 -- Shivshnakar P 11/10/2020 : Updated condition and change INT to VARCHAR for fractional quantity 
     DECLARE @ImportDetail TABLE (ImportId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER, CssClass varchar(100),[Validation] varchar(MAX),AccountNo VARCHAR(100), -- 10/15/2018 Shivshankar P: Removed SheetNo Column      
                                Location VARCHAR(100),MfgrPtNo  VARCHAR(100), PartClass CHAR(100),PartNo  CHAR(100),PartSourc CHAR(100),PartType CHAR(100),     
           PartMfgr  VARCHAR(100), RecQty VARCHAR(100) ,Revision VARCHAR(100),UofMeas VARCHAR(100),Uniqkey CHAR(100),WKey VARCHAR(100),Warehouse VARCHAR(100),    
			Lotcode CHAR(100),Reference CHAR(100),IsLotCode BIT,IsSerial BIT,IsIpKey BIT      
                                ,QtyPerPackage VARCHAR(100),ExpDate DateTime,CustPartNo  CHAR(100) ) -- 09/03/2018 Shivshanker P : Added QtyPerPackage and validated the fields      
           
 DECLARE @columnList VARCHAR(MAX)='AccountNo,Location,mfgr_pt_no,part_class,part_no,part_sourc,part_type,PartMfgr,recv_qty,revision,u_of_meas,uniq_key,w_key,warehouse      
 ,lotcode,reference,IsLotCode,IsSerial,IsIpKey,QtyPerPackage,ExpDate,custpartno';     
      
      if @importId is null or not exists (select 1 from InvtImportHeader where InvtImportId=@importId and importComplete=0)   --Not Done      
       RAISERROR ('Cannot find a record in the InvtImportHeader table with the given import Id.', -- Message text.      
       16, -- Severity.      
       1 -- State.      
      );      
    /* Length Check - Warn for any field with a length longer than the definition length */      
  --Added filter by importid      
 BEGIN TRY -- inside begin try      
  UPDATE f      
   SET [message]='Field will be truncated to ' + CAST(fd.fieldLength AS varchar(50)) + ' characters.',[status]=@orange,[validation]=@sys      
   FROM ImportInvtFields f       
   INNER JOIN importFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength>0      
   WHERE fkImportId=@importId  AND (f.RowId = @rowId OR @rowId IS NULL)   -- 6/19/2019 Nitesh B : Add new parameter @rowId for update validation against selected row 
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
      
 /* Reset all status to white to start fresh, unless it is blue, green, or lock */       
 --Added filter by importid      
 BEGIN TRY -- inside begin try      
  UPDATE f      
   SET [message] = '',[status]=@white,[validation]=@sys      
   FROM ImportInvtFields f       
   INNER JOIN importFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength>0      
   WHERE fkimportid = @importId AND (f.RowId = @rowId OR @rowId IS NULL)     -- 6/19/2019 Nitesh B : Add new parameter @rowId for update validation against selected row
   AND LEN(adjusted)<fd.fieldLength AND original=adjusted AND [status] NOT IN (@blue ,@green)      
        
  UPDATE f      
   SET [message] = '',[status]=@green,[validation]=@usr      
   FROM ImportInvtFields f       
   INNER JOIN importFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength>0      
   WHERE fkImportId=@importId AND (f.RowId = @rowId OR @rowId IS NULL)     -- 6/19/2019 Nitesh B : Add new parameter @rowId for update validation against selected row
   and LEN(adjusted)<fd.fieldLength AND original<>adjusted AND [status]<>@blue      
   END TRY      
 BEGIN CATCH       
  INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)      
  SELECT      
   ERROR_NUMBER() AS ErrorNumber      
   ,ERROR_SEVERITY() AS ErrorSeverity      
   ,ERROR_PROCEDURE() AS ErrorProcedure      
   ,ERROR_LINE() AS ErrorLine      
   ,ERROR_MESSAGE() AS ErrorMessage;      
  SET @headerErrs = 'There are issues resetting the status to white to start fresh (starting on line:67)'      
 END CATCH      
       
  /*verfify all required fields are not empty*/      
 BEGIN TRY -- inside begin try      
  UPDATE ImportInvtFields       
   SET [message]='Field Cannot Be Blank',[status]=@red,[validation]=@sys      
   FROM importFieldDefinitions fd INNER JOIN ImportInvtFields f ON fd.fieldDefId=f.FkFieldDefId       
   WHERE fd.[required] = 1       
    AND f.adjusted=''      
    AND f.fkImportId=@importId  AND (f.RowId = @rowId OR @rowId IS NULL)      -- 6/19/2019 Nitesh B : Add new parameter @rowId for update validation against selected row
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
      
  /****** non string checks ******/      
 BEGIN TRY -- inside begin try      
  DECLARE @notQty TABLE (importId uniqueidentifier,rowid uniqueidentifier,fieldDefId uniqueidentifier)      
   --Added filter by importid, otherwise the update goes over all the records that fit the criteria      
  INSERT INTO @notQty  --value is not a number      
   SELECT f.fkImportId,f.rowId,f.fkFieldDefId      
   FROM ImportInvtFields f INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId      
   WHERE d.dataType='numeric' AND f.fkImportId=@importId AND ISNUMERIC(f.adjusted)<>1 AND f.adjusted<>''      
   and fkImportId=@importId  AND (f.RowId = @rowId OR @rowId IS NULL)  -- 6/19/2019 Nitesh B : Add new parameter @rowId for update validation against selected row  
  UPDATE i      
   SET i.[status]=@red,i.[message]='Value is not a number',i.[validation]=@sys      
   FROM ImportInvtFields AS i INNER JOIN @notQty AS nq ON nq.rowid = i.rowId AND i.fkFieldDefId=nq.fieldDefId      
       
  DELETE FROM @notQty      
  INSERT INTO @notQty  --value is empty      
  SELECT f.fkImportId,f.rowId,f.fkFieldDefId      
   FROM ImportInvtFields f INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId      
   WHERE d.dataType='numeric' AND f.fkImportId=@importId AND (f.RowId = @rowId OR @rowId IS NULL) AND f.adjusted=''      
  UPDATE i      
   SET i.[status]=@blue,i.[message]='Value was empty',i.[validation]=@sys,i.adjusted=0      
   FROM ImportInvtFields AS i INNER JOIN @notQty AS nq ON nq.rowid = i.rowId AND i.fkFieldDefId=nq.fieldDefId      
         
  DELETE FROM @notQty      
  -- Added a Table variable to reduce the number of records in the evaluation of ISNUMERIC      
  DECLARE @noQtyTable TABLE (fkImportId uniqueidentifier,rowId uniqueidentifier,fkFieldDefId uniqueidentifier,adjusted varchar(MAX))      
  INSERT INTO @noQtyTable      
  SELECT f.fkImportId,f.rowId,f.fkFieldDefId,f.adjusted      
   FROM ImportInvtFields f INNER JOIN importFieldDefinitions d ON f.fkFieldDefId=d.fieldDefId      
   WHERE d.dataType='int' AND f.fkImportId=@importId  AND (f.RowId = @rowId OR @rowId IS NULL)    -- 6/19/2019 Nitesh B : Add new parameter @rowId for update validation against selected row
  
  -- 11/10/2020 Shivshnakar P : Updated condition for fractional quantity      
  INSERT INTO @notQty  --value is not an integer         
  SELECT fkImportId,rowId,fkFieldDefId      
   FROM @noQtyTable      
   WHERE adjusted!='' AND (ISNUMERIC(adjusted)<>1 OR CAST(adjusted AS numeric(12,2))<>adjusted) -- 09/28/2018 Rajendra K : Updated condition for Int data type      
  UPDATE i      
   SET i.[status]=@red,i.[message]='Value is not an integer',i.[validation]=@sys      
   FROM ImportInvtFields AS i INNER JOIN @notQty AS nq ON nq.rowid = i.rowId AND i.fkFieldDefId=nq.fieldDefId      
               
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
      
  --Validate Header Data      
    BEGIN TRY         
     Update invt SET IsValidate=       
                            CASE WHEN (NOT EXISTS (SELECT 1 FROM INVTHDEF WHERE TYPE ='R'  AND LTRIM(RTRIM(REASON)) =  LTRIM(RTRIM(invt.Reason)))       
                                          OR NOT EXISTS (SELECT  1 FROM SUPPORT WHERE FIELDNAME ='SHIPVIA'        
               AND  ((ISNULL(invt.Carrier,'') <> '' AND LTRIM(RTRIM(TEXT))  = LTRIM(RTRIM(invt.Carrier)))       
                   OR  (ISNULL(invt.Carrier,'') = ''  AND TEXT=TEXT))      
               OR  ISNUll(RecPklNo,'') ='')
			   OR ((invt.ImportType = 'S' OR invt.ImportType = 'C') AND (ISNUll(invt.CompanyName,'') ='' OR ISNUll(invt.CompanyNo,'') =''))) THEN 0 ELSE 1 END
			    -- Nitesh B 8/2/2019 : Update IsValidate with the ImportType 'C' and 'S'      
      
     FROM InvtImportHeader invt where InvtImportId= @importId       
      
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
   select * from @ErrTable      
  END CATCH       
      
    /****** Used to validate Column Data ******/      
    INSERT INTO @ImportDetail EXEC [GetImportInvtItems] @importId ,0,'',null,@columnList      
      
 --COUNT(CASE WHEN  f.DetailId  IS NULL then 1 ELSE 0 END)      
 /****** Used to validate Column Data ******/      
 BEGIN TRY           ----UNIQ_KEY      
          UPDATE f SET        
      
                  f.[Message]=       
                                CASE WHEN  imf.FieldName = 'AccountNo'  THEN 
					  CASE WHEN  (GL_NBR  <> ' '   AND REC_TYPE = 'R' OR i.ImportType = 'C' OR i.ImportType = 'S' )      
                 THEN '' ELSE  'Account Number does not exists.Please select a valid account number.' END      
              -- Nitesh B 6/12/2019 : Added a condition i.ImportType = 'C' OR i.ImportType = 'S' for IPC/IPS
      
              --Part_no,uniq_key not Available in the sysytem      
			  -- Nitesh B 6/13/2019 : Added a condition to get CONSG Part details for IPC    
			  -- Nitesh B 9/03/2019 : Added a condition to get BUY Part details for IPS (Contract)
           WHEN  imf.FieldName = 'Part_no'  THEN CASE WHEN  ((invt.PART_NO  <> ''   AND impt.PartNo <> '') AND ( i.ImportType = 'R' OR (i.ImportType = 'S'  AND invt.PART_SOURC = 'BUY') OR (i.ImportType = 'C'  AND invt.PART_SOURC = 'CONSG' AND invt.CUSTNO = @custNo)))      
                 THEN '' ELSE  'Part number/Revision can not be found in inventory.' END        
           -- 12/08/2018 Nitesh B : Change 'Part number/Uniq_key' to 'Part number/Revision'  
              
		   --custpartno      
		   -- Nitesh B 06/17/2019 : Added custpartno and validated the fields
		   WHEN  imf.FieldName = 'custpartno' THEN CASE WHEN  ((i.ImportType = 'R' OR (i.ImportType = 'C' AND invt.CUSTPARTNO  <> ''   AND impt.CustPartNo <> '' AND invt.PART_SOURC = 'CONSG' AND invt.CUSTNO = @custNo)))     
                 THEN '' ELSE  'Customer Part number/Revision can not be found in inventory.' END 
		   
		   --Partmfgr   
           WHEN  imf.FieldName = 'Partmfgr' THEN        
                  CASE WHEN  (IsNull(impt.PartMfgr,'') =  '') THEN  'Please enter valid MFGR Part Number.'       
                 WHEN   ISNULL(mfgrPart.PartMfgr,'') <> ''      
              THEN ''       
                 ELSE 'Partmfgr can not be found in system.'       
           END      
      
           --Mfgr_pt_no      
           WHEN  imf.FieldName = 'Mfgr_pt_no' THEN        
                  CASE WHEN  mfgrPart.mfgr_pt_no IS NOT NULL  THEN ''  ELSE 'Mfgr_pt_no can not be found in system.'       
            END      
      
           --Warehouse      
           WHEN  imf.FieldName = 'Warehouse'   THEN CASE WHEN  (warehuose.WAREHOUSE =impt.Warehouse     
            OR ( whautoloc.AUTOLOCATION =1 AND  mfgrPart.mfgrLoc=1)) THEN       
                    ''  ELSE 'Please enter valid Warehouse.'       
            END    --11/27/2018 Mahesh B: Dynamic warehouse location  
      
           --location      
           WHEN  imf.FieldName = 'location' THEN        
                  CASE WHEN (location.LOCATION IS NOT NULL      
              OR  (  whautoloc.AUTOLOCATION =1 AND  mfgrPart.mfgrLoc=1))  THEN ''       
                 ELSE 'Please enter valid Location.'       
           END    --11/27/2018 Mahesh B: Dynamic warehouse location  
      
               --IsSerial      
           WHEN  imf.FieldName = 'IsSerial'  THEN      
                                             CASE WHEN  (impt.IsSerial =1)       
                                                        AND (SerialNoCnt.SerialNo < 1  OR RecQty !=SerialNoCnt.SerialNo)       
                                                  THEN  'Serial No have to be entered.'       
                    WHEN   (impt.IsSerial = 0)        
                          AND SerialNoCnt.SerialNo > 0 THEN  'NO Serial No have to be entered.'      
                    ELSE '' END      
                       		   
           -- --Lotcode      
           WHEN  imf.FieldName = 'lotcode' THEN        
                  CASE WHEN  (IsNull(impt.Lotcode,'') =  '') AND impt.IsLotCode = 1 THEN  'Lotcode have to be entered.'       
                 WHEN  ((IsNull(impt.Lotcode,'')  <>  '')  AND len(impt.Lotcode) > 25  AND impt.IsLotCode = 1)  THEN 'Lotcode can not greater than 25.'       
              WHEN  ((IsNull(impt.Lotcode,'')  <>  '')  AND  impt.IsLotCode = 0)  THEN 'Part is not Lotted.'       
                 ELSE CASE WHEN islotcode.LOTCODE<> '' OR islotcode.LOTCODE IS NOT NULL  THEN 'The lotcode is exist in the system for the part.' ELSE '' END  -- Nitesh B 8/23/2019 : Added OUTER APPLY and condition to check lotcode exist for part       
           END      
      
                                           --Reference -- 10/17/2018 Shivshankar P: Removed reference      
           --WHEN  imf.FieldName = 'reference' THEN        
           -- --09/27/2018 Rajendra K : removed Reference required condition      
           --       CASE --WHEN  (IsNull(impt.Reference,'') =  '') AND impt.IsLotCode = 1 THEN  'Reference have to be entered.'       
           --      WHEN  ((IsNull(impt.Reference,'')  <>  '')  AND len(impt.Lotcode) > 12  AND impt.IsLotCode = 1)  THEN 'Reference can not greater than 45.'       
           --      WHEN  ((IsNull(impt.Reference,'')  <>  '')  AND   impt.IsLotCode = 0)  THEN 'Part is not Lotted.'       
           --   ELSE ''       
           --END      
      
            --ExpDate  -- 10/15/2018 Shivshankar P: Removed SheetNo Column  and removed expDate      
           --WHEN  imf.FieldName = 'expDate' THEN        
           --       CASE WHEN  (IsNull(impt.ExpDate,'') =  '') AND impt.IsLotCode = 1 THEN  'ExpDate have to be entered.'       
           --      WHEN  ((IsNull(impt.ExpDate,'')  <>  '')  AND   impt.IsLotCode = 0)  THEN 'Part is not Lotted.'       
           --   ELSE ''       
           --END      
      
             --Lotcode      
           WHEN imf.FieldName = 'location' THEN        
                  CASE WHEN (location.LOCATION IS NOT NULL      
              OR  ( whautoloc.AUTOLOCATION =1 AND  mfgrPart.mfgrLoc=1))   THEN ''       
                 ELSE 'Please enter valid Location.'       
           END      
           ELSE ''      
          END,      
				-- Nitesh B 6/12/2019 : Added a condition i.ImportType = 'C' OR i.ImportType = 'S' for IPC/IPS
                 f.[status]=        
                  CASE WHEN  imf.FieldName = 'AccountNo' THEN  CASE WHEN  (GL_NBR  <> ' '   AND REC_TYPE = 'R' OR i.ImportType = 'C' OR i.ImportType = 'S' )      
                                 THEN  CASE WHEN  f.Adjusted =f.Original THEN  @white WHEN f.Adjusted <> ''THEN @green      
                               ELSE  @red END ELSE  @red END      
          
              --Warehous     
              WHEN  imf.FieldName = 'Warehouse'   THEN  CASE WHEN  (warehuose.WAREHOUSE =impt.Warehouse       
            OR ( whautoloc.AUTOLOCATION =1 AND  mfgrPart.mfgrLoc=1))     --11/27/2018 Mahesh B: Dynamic warehouse location  
            THEN  CASE WHEN  f.Adjusted =f.Original THEN  @white WHEN ISNULL(f.Adjusted,'')='' OR f.Adjusted <> f.Original THEN @green      
                              ELSE  @red END ELSE  @red END      
      
              --Part_no,uniq_key not Available in the sysytem      
			  -- Nitesh B 6/13/2019 : Added a condition to get CONSG Part details for IPC  
			  -- Nitesh B 9/03/2019 : Added a condition to get BUY Part details for IPS (Contract) 
			  -- Nitesh B 11/7/2019 : Added a condition for apply orange color for part no field when ImportType = 'C'  
              WHEN  imf.FieldName = 'Part_no' THEN CASE WHEN ((invt.PART_NO  <> ''   AND impt.PartNo <> '') AND (i.ImportType = 'R' OR (i.ImportType = 'S'  AND invt.PART_SOURC = 'BUY') OR (i.ImportType = 'C'  AND invt.PART_SOURC = 'CONSG' AND invt.CUSTNO = @custNo)))      
                                                 THEN CASE WHEN f.Adjusted = f.Original THEN  CASE WHEN i.ImportType = 'C' THEN @orange ELSE @white END WHEN f.Adjusted <> '' THEN @green      
                    ELSE  @red END ELSE  @red END      
      
			-- Nitesh B 10/9/2019 : Added validation for custpartno Field
			WHEN  imf.FieldName = 'custpartno' AND i.ImportType = 'C' THEN CASE WHEN ((invt.CUSTPARTNO  <> ''   AND impt.CustPartNo <> '') AND (i.ImportType = 'C'  AND invt.PART_SOURC = 'CONSG' AND invt.CUSTNO = @custNo))        
                                                 THEN CASE WHEN f.Adjusted =f.Original THEN  @white WHEN f.Adjusted <> ''THEN @green        
                    ELSE  @red END ELSE  @red END  

              --Partmfgr      
             WHEN  imf.FieldName = 'Partmfgr'  THEN CASE WHEN  (IsNull(impt.PartMfgr,'') <>  '') AND      
                      ISNULL(mfgrPart.PartMfgr,'') <> ''      
                                                  THEN  CASE WHEN  f.Adjusted =f.Original THEN  @white WHEN f.Adjusted <> '' THEN @green      
                    ELSE  @red END ELSE  @red END      
              --location      
            WHEN  imf.FieldName = 'location' THEN  CASE WHEN  (location.LOCATION IS NOT NULL      
              OR  (whautoloc.AUTOLOCATION =1 AND  mfgrPart.mfgrLoc=1))    --11/27/2018 Mahesh B: Dynamic warehouse location  
                                                   THEN  CASE WHEN f.Adjusted =f.Original THEN  @white       
                                WHEN ISNULL(f.Adjusted,'')='' OR f.Adjusted <> f.Original THEN @green      
                    ELSE  @red END ELSE  @red END      
                --Mfgr_pt_no      
            WHEN imf.FieldName = 'Mfgr_pt_no' THEN CASE WHEN  mfgrPart.mfgr_pt_no IS NOT NULL       
                                                 THEN  CASE WHEN  f.Adjusted =f.Original THEN  @white WHEN       
                                      ISNULL(f.Adjusted,'')='' OR f.Adjusted <> f.Original THEN @green      
                    ELSE  @red END ELSE  @red END      
      
  
        --IsIpKey  
             --12/26/2016 Mahesh B  IF SID is 1 validate QtyPerPackage field 
			 -- Shivshankar P 11/20/2020 : Add the validation for the QtyPerPackage and recv_qty field for U_OF_MEAS 
           WHEN  imf.FieldName = 'QtyPerPackage'  THEN CASE   
                                                  WHEN  impt.IsIpKey =1 AND ISNULL(impt.QtyPerPackage ,'') = '' THEN  @red  
												  WHEN invt.U_OF_MEAS = 'EACH' AND ABS(CAST(f.Adjusted  AS decimal)- CAST(f.Adjusted AS numeric(12,2))) > 0 THEN @red
												  ELSE @white END      
            
	       --recv_qty      
           WHEN  imf.FieldName = 'recv_qty' THEN        
                  CASE WHEN  invt.U_OF_MEAS <> 'EACH' AND ABS(CAST(f.Adjusted  AS decimal)- CAST(f.Adjusted AS numeric(12,2))) >= 0  THEN @green 
				       WHEN invt.U_OF_MEAS = 'EACH' AND ABS(CAST(f.Adjusted  AS decimal)- CAST(f.Adjusted AS numeric(12,2))) = 0 THEN @green
				  ELSE @red        
            END 
			
           -- 03/16/2018 Shivshanker P :  Validated lot and removed joins      
           -- Lotcode        
           WHEN  imf.FieldName = 'lotcode' THEN        
                  CASE WHEN  (((IsNull(impt.Lotcode,'')  <>  '')  AND len(impt.Lotcode) <= 25  AND impt.IsLotCode = 1) OR ((IsNull(impt.Lotcode,'')  =  '')  AND   impt.IsLotCode = 0))  			
					AND (f.Adjusted = f.Original  OR  ISNULL(f.Adjusted,'')='')      
                 THEN CASE WHEN islotcode.LOTCODE<> '' OR islotcode.LOTCODE IS NOT NULL  THEN @orange ELSE @white END  -- Nitesh B 8/23/2019 : Added OUTER APPLY and condition to check lotcode exist for part    
              WHEN  impt.IsLotCode = 1 AND f.Adjusted <> f.Original THEN @green      
              ELSE @red       
           END      
      
                                           --Reference -- 10/17/2018 Shivshankar P: Removed reference      
           --WHEN  imf.FieldName = 'reference' THEN        
           --       --09/27/2018 Rajendra K : Changed condition for Reference      
           --       CASE WHEN  ((ISNULL(len(impt.Reference),0) <= 12  AND impt.IsLotCode = 1)   OR      
           --      ((IsNull(impt.Reference,'')  =  '')  AND   impt.IsLotCode = 0))  AND (f.Adjusted = f.Original  OR  ISNULL(f.Adjusted,'')='') THEN       
           --    @white       
           --   WHEN  impt.IsLotCode = 1 AND f.Adjusted <> f.Original THEN @green      
           --     ELSE @red       
                
           --END      
      
              --Expdate  -- 10/15/2018 Shivshankar P: Removed SheetNo Column  and removed expDate      
           --WHEN  imf.FieldName = 'expdate' THEN        
           --       CASE WHEN  (((IsNull(impt.Expdate,'')  <>  '')  AND impt.IsLotCode = 1)   OR      
           --         ((IsNull(impt.Expdate,'')  =  '')  AND   impt.IsLotCode = 0))   AND (f.Adjusted = f.Original  OR  ISNULL(f.Adjusted,'')='') THEN       
           --    @white       
           --   WHEN  impt.IsLotCode = 1 AND f.Adjusted <> f.Original THEN @green      
           --     ELSE @red       
                
           --END      
      
           -- 09/03/2018 Shivshanker P : Added QtyPerPackage and validated the fields      
                 --IsSerial      
           WHEN  imf.FieldName = 'IsSerial'  THEN      
                                             CASE WHEN  (impt.IsSerial =1      
                         AND (SerialNoCnt.SerialNo < 1  OR RecQty !=SerialNoCnt.SerialNo))       
                                                  THEN @red      
                    WHEN   (impt.IsSerial =0)        
                          AND SerialNoCnt.SerialNo > 0 THEN  @red      
                    ELSE @white END      
      
      
      
          ELSE @white END,      
      
      
        f.[validation]=       
                  CASE WHEN (GL_NBR IS NULL OR REC_TYPE <> 'R') AND imf.FieldName = 'AccountNo' THEN  @sys       
                    
           ELSE '' END      
      
      FROM ImportInvtFields f       
      JOIN InvtImportHeader i ON  f.FkImportId =  i.InvtImportId      
      JOIN importFieldDefinitions imf ON f.FkFieldDefId = imf.FieldDefId      
      LEFT JOIN @ImportDetail impt on f.RowId=impt.RowId      
      LEFT JOIN InvtGls ON GL_NBR =AccountNo AND REC_TYPE = 'R'     -- Nitesh B 2/5/2019: Added a condition  AND REC_TYPE = 'R'
      OUTER APPLY 
	  (            
			 SELECT TOP 1 SERIALYES,useipkey,UNIQ_KEY,PART_NO,U_OF_MEAS,PART_SOURC,CUSTNO,CUSTPARTNO  FROM        
                   INVENTOR part WHERE part.PART_NO = impt.PartNo AND      
             part.REVISION = impt.Revision 
			 AND ((i.ImportType = 'R' OR i.ImportType = 'S' AND 1=1) OR (i.ImportType = 'C' AND part.PART_SOURC = 'CONSG' AND part.CUSTNO = @custNo)) -- Nitesh B 6/13/2019 : Added a condition to get CONSG Part details for IPC
	   ) invt        
       OUTER APPLY 
	   (
			select   COUNT(SerialDetailId) SerialNo from ImportInvtSerialFields  JOIN  -- 09/03/2018 Shivshanker P : Added QtyPerPackage and validated the fields      
                                     importFieldDefinitions ON FkFieldDefId=FieldDefId WHERE ImportInvtSerialFields.FkRowId= f.RowId       
                                        and importFieldDefinitions.FIELDNAME ='serialno'      
                                ) SerialNoCnt        
              
      OUTER APPLY (select mas.PartMfgr,mfgr_pt_no,i.DESCRIPT,i.U_OF_MEAS,W_KEY,mfgr.UNIQMFGRHD       
       ,mas.autolocation as mfgrLoc from INVENTOR i    --11/27/2018 Mahesh B: Dynamic warehouse location   
      INNER JOIN InvtMPNLink mp on i.UNIQ_KEY =mp.uniq_key      
      INNER JOIN MfgrMaster mas on mp.MfgrMasterId = mas.MfgrMasterId      
      LEFT JOIN INVTMFGR mfgr on mp.uniqmfgrhd = mfgr.UNIQMFGRHD      
      LEFT JOIN WAREHOUS w on mfgr.UNIQWH =w.UNIQWH    
	  -- Shivshankar P 05/15/2020 : Change INNER to LEFT JOIN and conditions if MFGR, MPN is available and warehose, location not for part            
      WHERE ((w.WAREHOUSE != 'WIP' AND w.WAREHOUSE != 'WO-WIP' AND w.WAREHOUSE != 'MRB' AND w.WAREHOUSE IS NOT NULL) OR 1=1) 
      AND ((mfgr.Is_Deleted = 0 AND mfgr.Is_Deleted IS NOT NULL) OR 1=1)  -- Nitesh B 12/4/2019 : Remove a condition mfgr.Netable = 1 to receive qty in Non-Netable location  
      AND mp.is_deleted = 0 AND mas.is_deleted = 0 
	  AND ((mfgr.Instore = CASE WHEN ImportType = 'S' THEN mfgr.Instore ELSE 0 END AND mfgr.Instore IS NOT NULL) OR 1=1) -- Shivshankar P 04/16/2020 : Add CASE to get Instore location for Supplier Bonded upload     
      AND ((mfgr.uniqsupno = CASE WHEN ImportType = 'S' THEN @custNo ELSE mfgr.uniqsupno END AND mfgr.uniqsupno IS NOT NULL) OR 1=1) 
	  AND i.PART_NO = impt.PartNo      
      AND i.REVISION = impt.Revision      
      AND  mas.PartMfgr =impt.PartMfgr      
      AND  mas.mfgr_pt_no = impt.MfgrPtNo) mfgrPart       
      
      OUTER APPLY (select w.WAREHOUSE from INVTMFGR mfgr       
      INNER JOIN WAREHOUS w on mfgr.UNIQWH =w.UNIQWH                
      WHERE  w.WAREHOUSE != 'WIP' AND w.WAREHOUSE != 'WO-WIP' AND w.WAREHOUSE != 'MRB'       
      AND mfgr.Is_Deleted = 0      
      AND mfgr.Instore = CASE WHEN ImportType = 'S' THEN mfgr.Instore ELSE 0 END -- Shivshankar P 04/16/2020 : Add CASE to get Instore location for Supplier Bonded upload  
	  AND mfgr.uniqsupno = CASE WHEN ImportType = 'S' THEN @custNo ELSE mfgr.uniqsupno END 
	  AND mfgr.UNIQMFGRHD =mfgrPart.UNIQMFGRHD       
      AND w.WAREHOUSE=impt.Warehouse) warehuose       
         
   OUTER APPLY(select WAREHOUS.AUTOLOCATION from     
   WAREHOUS  where WAREHOUS.WAREHOUSE=impt.Warehouse AND  WAREHOUSE != 'WIP'    
    AND WAREHOUSE != 'WO-WIP' AND WAREHOUSE != 'MRB'  and IS_DELETED =0 ) whautoloc   --11/27/2018 Mahesh B: Dynamic warehouse location   
   
   OUTER APPLY (select  mfgr.LOCATION from INVTMFGR mfgr                 
      WHERE mfgr.Is_Deleted = 0      
      AND mfgr.Instore = CASE WHEN ImportType = 'S' THEN mfgr.Instore ELSE 0 END   -- Shivshankar P 04/16/2020 : Add CASE to get Instore location for Supplier Bonded upload      
      AND mfgr.uniqsupno = CASE WHEN ImportType = 'S' THEN @custNo ELSE mfgr.uniqsupno END 
	  AND mfgr.UNIQMFGRHD =mfgrPart.UNIQMFGRHD AND mfgr.LOCATION=impt.Location) location     --11/27/2018 Mahesh B: Dynamic warehouse location       

		OUTER APPLY ( select Lotcode from INVTLOT join INVTMFGR on INVTLOT.W_KEY = INVTMFGR.W_KEY and invt.UNIQ_KEY = INVTMFGR.UNIQ_KEY
		where INVTLOT.LOTCODE = impt.Lotcode) islotcode -- Nitesh B 8/23/2019 : Added OUTER APPLY and condition to check lotcode exist for part
			               
       where InvtImportId= @importId AND (f.RowId = @rowId OR @rowId IS NULL) --AND REC_TYPE='R' -- 6/19/2019 Nitesh B : Add new parameter @rowId for update validation against selected row      
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
   select * from @ErrTable      
  END CATCH       
        
 -- /****** Used to validate Serial number Column Data ******/      
 BEGIN TRY      
  ;WITH SerialData AS (      
    SELECT DISTINCT invt.RowId,f.Adjusted,f.SerialDetailId FROM ImportInvtSerialFields f      
    JOIN importFieldDefinitions ON f.FkFieldDefId = importFieldDefinitions.FieldDefId      
    JOIN ImportInvtFields invt ON  invt.RowId =  f.FkRowId      
    JOIN InvtImportHeader ON invt.FkImportId =  InvtImportId      
    where InvtImportId=@importId  and FieldName = 'Serialno')      
      
    UPDATE f SET   f.[original]  = CASE WHEN  len (f.[original]) !=30 AND  f.[original]   <>''      
                                       THEN  RIGHT(replicate('0', 30) + ltrim(f.Original), 30) ELSE f.Original  END,      
                         f.[Adjusted]  = CASE WHEN  len (f.Adjusted) !=30  AND f.Adjusted   <>''      
                           THEN  RIGHT(replicate('0', 30) + ltrim(f.Adjusted), 30)  ELSE f.Adjusted END,      
          
        f.[Message]=       
            CASE WHEN   ISNULL(invtSe.SERIALUNIQ,'') = ''      
               THEN   ''      
             ELSE 'Serial number already exists in the system.  Can not add it again.'      
            END,      
        f.[status]=   CASE WHEN   ISNULL(invtSe.SERIALUNIQ,'') = ''      
             THEN  CASE WHEN  f.Adjusted =f.Original THEN  @white WHEN       
             ISNULL(f.Adjusted,'')='' OR f.Adjusted <> f.Original THEN @green      
             ELSE  @red END ELSE  @red END,      
        f.[validation]=       
          CASE WHEN   ISNULL(invtSe.SERIALUNIQ,'') = ''  THEN  @sys       
           ELSE '' END              
                 
                   FROM  ImportInvtSerialFields f       
                JOIN SerialData invt ON  invt.SerialDetailId= f.SerialDetailId      
                         OUTER APPLY (SELECT top 1 SERIALUNIQ from INVTSER where SERIALNO =RIGHT(REPLICATE('0', 30) + ltrim(f.Adjusted), 30)) invtSe      
      
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
       
 END 