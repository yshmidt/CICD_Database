-- ============================================================================        
-- AUTHOR    : Satyawan H.        
-- DATE     : 04/02/2019        
-- DESCRIPTION : Validate the defination fields after inventor UDF Upload        
-- ============================================================================        
        
CREATE PROC sp_validateUdfInventorDefnFields        
	@ImportId uniqueidentifier,        
	@rowId uniqueidentifier = null,  
	@UserId uniqueidentifier = null      
AS        
BEGIN        
	DECLARE @SQL nvarchar(MAX),        
			@ModuleId int,         
			@FieldName Nvarchar(MAX),         
			@lSourceFields bit = 0,         
			@SourceTable VARCHAR = null,        
			@headerErrs VARCHAR(MAX)        
   
	DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))        
	DECLARE @ImportDetail TABLE(ImportId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),[Validation] VARCHAR(MAX),    
		ValidUDFs BIT,TotalUDFs bit,Custno VARCHAR(100),CustPartNo VARCHAR(100),CustRev VARCHAR(100),Descript VARCHAR(100),    
		IsImported Bit,Part_No CHAR(100),Part_Sourc CHAR(100),Revision CHAR(100),UNIQ_KEY VARCHAR(100),  
		Custname CHAR(100),PartDesc VARCHAR(200))         
  
	INSERT INTO @ImportDetail EXEC sp_getImportedInventorUDFs @ImportId=@ImportId,@rowId=@rowId,@isPartValid = 1        
  
	SELECT @ModuleId = ModuleId FROM MnxModule         
	WHERE ModuleName LIKE 'InventorUDFUpload' and FilePath = 'InventorUDFUpload'        
        
	DECLARE @white VARCHAR(20)='i00white',@green VARCHAR(20)='i01green',@orange VARCHAR(20)='i04orange',          
			@red VARCHAR(20)='i05red',@sys VARCHAR(20)='i01system'       

 /* All fields check */        
 BEGIN TRY         
  UPDATE f   
	--SELECT impt.*, f.FieldName, -- f.FieldName,InvtUnikey.*, -- invtc.*,
 SET   
 ----[message] = CASE         
 --  --      -- Part_sourc         
 --  --      WHEN  f.FieldName = 'PART_SOURC' THEN         
 --  --         --CASE WHEN (ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' AND (invt.PART_SOURC  <> '' AND impt.Part_Sourc <> ''))   
 --  --         CASE WHEN (ISNULL(InvtUnikey.UNIQ_KEY,'') <> '')   
 --  --THEN ''   
 --  --ELSE CASE WHEN (TRIM(invt.PART_SOURC) = TRIM(impt.Part_Sourc))   
 --  --  THEN '' ELSE 'Invalid Part Source.' END  
 --  --END     
  
 --  --      -- Part_No/Rev        
 --  --      WHEN f.FieldName = 'PART_NO' THEN     
 --  -- CASE WHEN (ISNULL(InvtUnikey.UNIQ_KEY,'') <> '')  
 --  -- THEN ''   
 --  -- ELSE CASE WHEN (TRIM(invt.PART_NO) = TRIM(impt.Part_No))   
 --  --   THEN '' ELSE 'Invalid Part number/Revision.' END  
 --  -- END     
  
 --  --      -- REVISION       
 --  --      WHEN f.FieldName = 'REVISION' THEN         
 --  -- CASE WHEN (ISNULL(InvtUnikey.UNIQ_KEY,'') <> '')   
 --  -- THEN ''   
 --  -- ELSE CASE WHEN (TRIM(invt.REVISION) = TRIM(impt.Revision))   
 --  --   THEN '' ELSE 'Invalid Part number/Revision.' END  
 --  -- END   
  
 --  --      -- Description                 
 --  --      WHEN f.FieldName = 'DESCRIPT' THEN         
 --  -- CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> ''   
 --  --THEN ''   
 --  --ELSE CASE WHEN (TRIM(invt.PART_NO) <> '')   
 --  --  THEN '' ELSE 'Description not found for part in inventory.' END  
 --  --END   
  
 --  --      -- Customer        
 --  --      WHEN f.FieldName = 'CUSTNO' THEN         
 --  --CASE WHEN (ISNULL(InvtUnikey.UNIQ_KEY,'') <> '')   
 --  --THEN ''   
 --  --ELSE CASE WHEN (TRIM(invtc.CUSTNO) = TRIM(impt.Custno))   
 --  --  THEN '' ELSE 'Invalid Customer Number.' END  
 --  --END  
  
 --  --      -- CustPartNo        
 --  --      WHEN f.FieldName = 'CustPartNo' THEN         
 --  --CASE WHEN (ISNULL(InvtUnikey.UNIQ_KEY,'') <> '')   
 --  --THEN ''   
 --  --ELSE CASE WHEN (TRIM(invtc.CUSTPARTNO) = TRIM(impt.CustPartNo))   
 --  --  THEN '' ELSE 'Invalid Customer Part Number/Revision.' END  
 --  --END  
  
 --  --      -- CustRev        
 --  --WHEN f.FieldName = 'CUSTREV' THEN       -- OR (TRIM(invtc.CUSTPARTNO) <> '' AND TRIM(impt.CustPartNo) <> '')  
 --  --CASE WHEN (ISNULL(InvtUnikey.UNIQ_KEY,'') <> '')   
 --  --THEN ''   
 --  --ELSE CASE WHEN (TRIM(invtc.CUSTPARTNO) = TRIM(impt.CustPartNo))   
 --  --  THEN '' ELSE 'Invalid Customer Part Number/Revision' END  
 --  --END  
  
 --  --      ELSE ''         
 --  --     END        
      --select f.fieldNAme,  
	[Status] = CASE  
		--  PART_SOURC
		WHEN f.FieldName = 'PART_SOURC' THEN   
		CASE WHEN (ISNULL(InvtUnikey.UNIQ_KEY,'') <> '') THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.PART_SOURC,'')) = TRIM(ISNULL(impt.Part_Sourc,'')) THEN   
				CASE WHEN f.Adjusted = f.Original THEN @white ELSE @green END  
			ELSE @sys END  
		ELSE @red END   
    
         -- Part_No/Rev        
		WHEN f.FieldName = 'Part_no' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.PART_NO,'')) = TRIM(ISNULL(impt.Part_No,'')) THEN   
				CASE WHEN TRIM(f.Adjusted) = TRIM(f.Original) THEN @white ELSE @green END  
			ELSE @sys END  
		ELSE @red END             
          
		-- REVISION        
		WHEN f.FieldName = 'REVISION' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.REVISION,'')) = TRIM(ISNULL(impt.Revision,'')) THEN   
				CASE WHEN f.Adjusted = f.Original THEN @white ELSE @green END  
			ELSE @sys END  
		ELSE @red END    
                  
		-- Customer        
		WHEN f.FieldName = 'CUSTNO' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' AND ((impt.Custno <> '' AND invtc.custno = impt.custno) OR ((impt.Custno IS NULL OR TRIM(impt.Custno) = '') AND 1=1)) THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.CUSTNO,'')) = TRIM(ISNULL(invtc.CUSTNO,'')) THEN   
				CASE WHEN f.Adjusted = f.Original THEN @white ELSE @green END  
			ELSE @sys END  
		ELSE @red END    
  
		-- Part_No/Rev             
		WHEN f.FieldName = 'CustPartNo' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' AND ((impt.CustPartNo <> '' AND invtc.CUSTPARTNO = impt.CustPartNo) OR ((impt.CustPartNo IS NULL OR TRIM(impt.CustPartNo) = '') AND 1=1)) THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.CustPartNo,'')) = TRIM(ISNULL(invtc.CustPartNo,'')) THEN   
				CASE WHEN f.Adjusted = f.Original THEN @white ELSE @green END  
			ELSE @sys END  
		ELSE @red END      
                 
		-- CustRev        
		WHEN f.FieldName = 'CUSTREV' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' AND ((impt.Custno <> '' AND invtc.CUSTREV = impt.CustRev) OR ((impt.CustRev IS NULL  OR TRIM(impt.CustPartNo) = '') AND 1=1)) THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.CUSTREV,'')) = TRIM(ISNULL(invtc.CUSTREV,'')) THEN   
				CASE WHEN f.Adjusted = f.Original THEN @white ELSE @green END  
			ELSE @sys END  
		ELSE @red END      
     
		-- DESCRIPT       
		WHEN f.FieldName = 'DESCRIPT' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.DESCRIPT,'')) = TRIM(ISNULL(invt.DESCRIPT,'')) THEN   
				CASE WHEN f.Adjusted = f.Original THEN @white ELSE @green END  
			ELSE @sys END  
		ELSE @red END          
		ELSE ''         
		END  
    
	,[Original] = CASE         
		-- PART_SOURC   
		WHEN f.FieldName = 'PART_SOURC' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.PART_SOURC,'')) = TRIM(ISNULL(invt.PART_SOURC,'')) THEN   
				impt.PART_SOURC  
			ELSE InvtUnikey.PART_SOURC END  
		ELSE impt.PART_SOURC END        
          
		-- Part_no  
		WHEN f.FieldName = 'Part_no' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.PART_NO,'')) = TRIM(ISNULL(invt.PART_NO,'')) THEN   
				impt.Part_No  
			ELSE InvtUnikey.PART_NO END  
		ELSE impt.Part_No END   
  
		WHEN f.FieldName = 'REVISION' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.REVISION,'')) = TRIM(ISNULL(invt.REVISION,'')) THEN   
				impt.Revision  
			ELSE InvtUnikey.Revision END  
		ELSE impt.Revision END   
  
		WHEN f.FieldName = 'CUSTNO' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.CUSTNO,'')) = TRIM(ISNULL(invtc.CUSTNO,'')) THEN   
				impt.Custno  
			ELSE InvtUnikey.CUSTNO END  
		ELSE impt.Custno END   
  
		WHEN f.FieldName = 'CustPartNo' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.CUSTPARTNO,'')) = TRIM(ISNULL(invtc.CUSTPARTNO,'')) THEN   
				impt.CustPartNo  
			ELSE InvtUnikey.CUSTPARTNO END  
		ELSE impt.CustPartNo END   
  
		WHEN f.FieldName = 'CUSTREV' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.CUSTREV,'')) = TRIM(ISNULL(invtc.CUSTREV,'')) THEN   
				impt.CustRev  
			ELSE InvtUnikey.CUSTREV END  
		ELSE impt.CustRev END   
  
		-- DESCRIPT         
		WHEN f.FieldName = 'DESCRIPT' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.DESCRIPT,'')) = TRIM(ISNULL(invt.DESCRIPT,'')) THEN   
				invt.DESCRIPT  
			ELSE InvtUnikey.DESCRIPT END  
		ELSE impt.Descript END   
     
		ELSE Original   
	END  
     
 ,[Adjusted] = CASE         
		-- PART_SOURC   
		WHEN f.FieldName = 'PART_SOURC' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.PART_SOURC,'')) = TRIM(ISNULL(invt.PART_SOURC,'')) THEN   
			impt.PART_SOURC  
			ELSE InvtUnikey.PART_SOURC END  
		ELSE impt.PART_SOURC END        
          
		-- Part_no  
		WHEN f.FieldName = 'Part_no' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.PART_NO,'')) = TRIM(ISNULL(invt.PART_NO,'')) THEN   
				impt.Part_No  
			ELSE InvtUnikey.PART_NO END  
		ELSE impt.Part_No END   
  
		WHEN f.FieldName = 'REVISION' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.REVISION,'')) = TRIM(ISNULL(invt.REVISION,'')) THEN   
				impt.Revision  
			ELSE InvtUnikey.Revision END  
		ELSE impt.Revision END   
  
		WHEN f.FieldName = 'CUSTNO' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.CUSTNO,'')) = TRIM(ISNULL(invtc.CUSTNO,'')) THEN   
				impt.Custno  
			ELSE InvtUnikey.CUSTNO END  
		ELSE impt.Custno END   
  
		WHEN f.FieldName = 'CustPartNo' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.CUSTPARTNO,'')) = TRIM(ISNULL(invtc.CUSTPARTNO,'')) THEN   
				impt.CustPartNo  
			ELSE InvtUnikey.CUSTPARTNO END  
		ELSE impt.CustPartNo END   
  
		WHEN f.FieldName = 'CUSTREV' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.CUSTREV,'')) = TRIM(ISNULL(invtc.CUSTREV,'')) THEN   
				impt.CustRev  
			ELSE TRIM(InvtUnikey.CUSTREV) END  
		ELSE impt.CustRev END   
  
		-- DESCRIPT         
		WHEN f.FieldName = 'DESCRIPT' THEN   
		CASE WHEN ISNULL(InvtUnikey.UNIQ_KEY,'') <> '' THEN    
			CASE WHEN TRIM(ISNULL(InvtUnikey.DESCRIPT,'')) = TRIM(ISNULL(invt.DESCRIPT,'')) THEN   
				TRIM(invt.DESCRIPT)  
			ELSE TRIM(InvtUnikey.DESCRIPT) END  
		ELSE impt.Descript END   
     
		ELSE Adjusted   
	END         
	FROM ImportInventorUdfFields f         
	JOIN ImportInventorUdfHeader h ON  f.FkImportId =  h.ImportId        
	JOIN importFieldDefinitions fd ON f.FieldName = fd.FieldName AND ModuleId = @ModuleId AND fd.fieldName   
	--IN ('UNIQ_KEY','Part_no')        
	IN ('CUSTREV','DESCRIPT','PART_SOURC','Part_no','REVISION','CUSTNO','CustPartNo','UNIQ_KEY')        
	LEFT JOIN @ImportDetail impt on f.RowId = impt.RowId      
	OUTER APPLY   
	(  
		SELECT TOP 1 CUSTPARTNO,CUSTNO,REVISION,PART_NO,DESCRIPT,CUSTREV,PART_SOURC   
		FROM INVENTOR part         
		WHERE  part.PART_NO = impt.PART_NO AND part.REVISION = impt.Revision AND part.PART_SOURC = impt.Part_Sourc        
	) invt         
	OUTER APPLY         
	(     
		SELECT TOP 1 CUSTPARTNO,CUSTNO,REVISION,PART_NO,DESCRIPT,CUSTREV,PART_SOURC         
		FROM INVENTOR part         
		WHERE part.CUSTNO = impt.Custno AND part.CUSTPARTNO = impt.CustPartNo AND part.PART_NO = impt.PART_NO         
		AND part.REVISION = impt.Revision AND part.CUSTREV = impt.CustRev        
	)  invtc     
	OUTER APPLY   
	(  
		SELECT TOP 1 UNIQ_KEY,CUSTPARTNO,CUSTNO,REVISION,PART_NO,DESCRIPT,CUSTREV,PART_SOURC   
		FROM INVENTOR part Where UNIQ_KEY = impt.UNIQ_KEY  
	) InvtUnikey    
	OUTER APPLY   
	(  
		SELECT TOP 1 UNIQ_KEY,CUSTPARTNO,CUSTNO,REVISION,PART_NO,DESCRIPT,CUSTREV,PART_SOURC   
		FROM INVENTOR part         
		WHERE part.PART_NO = impt.PART_NO AND part.REVISION = impt.Revision AND part.PART_SOURC = impt.Part_Sourc        
	) part_noRev         
	WHERE (NOT @rowId IS NULL AND f.RowId = @rowId) OR (@rowId IS NULL AND 1=1) AND impt.ImportId = @ImportId
	--order by f.FieldName

 --/* Length Check - Warn for any field with a length longer than the definition length */        
 BEGIN TRY -- inside begin try        
  UPDATE f SET   
 [message]='Field will be truncated to ' + CAST(fd.fieldLength AS VARCHAR(50)) + ' characters.',[status]=@orange,[validation]=@sys        
    FROM ImportInventorUdfFields f         
    INNER JOIN importFieldDefinitions fd ON f.FieldName =fd.FieldName AND fd.fieldLength>0 and ModuleId = @ModuleId         
    WHERE fkImportId= @ImportId        
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
        
 -- Update the header status in detail grid  
 EXEC UpdateHeadGridValidStatus @ImportID=@ImportId,@UserId=@UserId       
    
  --IF(NOT @rowId is null)        
  --BEGIN                
 --DECLARE @countr INT, @totUDFs INT         
 --SELECT @countr = count(*),@totUDFs = count(*) FROM ImportInventorUdfFields     
 -- WHERE FkImportId = @ImportId AND [STATUS] = @red     
 -- AND FieldName IN ('PART_SOURC','DESCRIPT','CUSTNO','CustPartNo','CUSTREV','Part_no');          
    
 --UPDATE ImportInventorUdfHeader     
 -- SET Validated = CASE WHEN @countr = 0 AND @totUDFs > 0 THEN 1 ELSE 0 END,        
 --  [Status] =  CASE WHEN @countr = 0 AND @totUDFs > 0 THEN 'No Error' ELSE 'Error' END    
 -- WHERE ImportId = @ImportId  
  --END        
          
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
  select * from @ErrTable        
 END CATCH        
END