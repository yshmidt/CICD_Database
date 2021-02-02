-- =============================================        
-- Author:  David Sharp        
-- Create date: 4/18/2012        
-- Description: get the import header information        
-- 7/31/15 Raviraj Added useSetUp and StdBldQty for Assembly        
-- 09/19/16 YS add error trap        
-- 09/20/16 Shivshankar P Return Error to display on UI        
-- 04/20/18 Vijay G : Check Auto Number and Auto Make Part No setting exist or not        
-- 04/20/18 Vijay G : Moved the Auto Number and Auto Make No setting value from MICSSYS,InvtSetup table to MnxSettingsManagement and wmSettingsManagement table        
-- 07/18/18 Vijay G : Get the setting value by setting name if exist in wmSettingsManagement otherwise from MnxSettingsManagement        
-- 01/11/2019 Vijay G : Checking errors at part level , avl level and ref desg level          
-- 01/11/2019 Vijay G : Change the status condition @impId=@importId to @cnt=0           
-- 01/16/2019 Vijay G : Add And Condition completedate is not null       
-- 01/21/2019 Sachin B Update the Customer if the BOM_Det Table Don't have component        
-- 02/27/2020 Vijay G : Removed code of auto parnumber setting 
--02/27/2020 Vijay G: Made some changes to see SP in proper format       
-- =============================================        
CREATE PROCEDURE [dbo].[importBOMHeaderGet]         
 -- Add the parameters for the stored procedure here        
 @importId uniqueidentifier,@userId uniqueidentifier        
AS        
BEGIN        
	-- SET NOCOUNT ON added to prevent extra result sets from        
	-- interfering with SELECT statements.        
	SET NOCOUNT ON;        
	-- TODO        
	-- 1. verify the provided userID has permission to access an assembly for the customer linked to the import        
	        
	-- provide autonumber settings for the system    
    -- 02/27/2020 Vijay G : Removed code of auto parnumber setting     
	--DECLARE @AutoNumber bit,@AutoMakeNo bit          
	--09/19/16 YS Error trap        
	DECLARE @ERRORNUMBER Int= 0        
	 ,@ERRORSEVERITY int=0        
	 ,@ERRORPROCEDURE varchar(max)=''        
	 ,@ERRORLINE int =0        
	 ,@ERRORMESSAGE varchar(max)=' '        
	--09/19/16 YS Error trap, and begin transaction        
	BEGIN TRY        
	BEGIN TRANSACTION        
		--09/19/16 YS added validation for micsSys table        
		-- 04/20/18 Vijay G : Check Auto Number setting exist or not     
		-- 02/27/2020 Vijay G : Removed code of auto parnumber setting    
		--IF NOT EXISTS (SELECT 1             
		--FROM MnxSettingsManagement M LEFT OUTER JOIN wmSettingsManagement W ON m.settingId=w.settingId          
		--WHERE settingName ='AutoPartNumber' AND settingModule = 'PartMasterSetting')        
		-- RAISERROR ('AutoPartNumber setting is not exist in MnxSettingsManagement Table. Cannot proceed.', -- Message text.        
		--     16, -- Severity.        
		--   1 -- State.        
		--  );        
        
		-- 04/20/18 Vijay G : Moved the Auto Number and Auto Make No setting value from MICSSYS,InvtSetup table to MnxSettingsManagement and wmSettingsManagement table        
		--SELECT @AutoNumber =MicsSys.XxPtNoSys FROM MICSSYS        
		-- 04/20/18 Vijay G : Check Auto Number setting value from wmSettingsManagement        
		-- 07/18/18 Vijay G : Get the AutoPartNumber setting value by setting name if exist in wmSettingsManagement otherwise from MnxSettingsManagement        
		-- 02/27/2020 Vijay G : Removed code of auto parnumber setting 
		--SELECT @AutoNumber = ISNULL(w.settingValue,m.settingValue)             
		--FROM MnxSettingsManagement M LEFT OUTER JOIN wmSettingsManagement W ON m.settingId=w.settingId          
		--WHERE settingName ='AutoPartNumber' AND settingModule = 'PartMasterSetting'        
		        
		--09/19/16 YS added validation for InvtSetup table        
		-- 04/20/18 Vijay G : Check Auto Make Part Number setting exist or not        
		-- 02/27/2020 Vijay G : Removed code of auto parnumber setting 
		--IF NOT EXISTS (SELECT 1            
		--FROM MnxSettingsManagement M LEFT OUTER JOIN wmSettingsManagement W ON m.settingId=w.settingId          
		--WHERE settingName ='AutoMakePartNumber' AND settingModule = 'PartMasterSetting')        
		-- RAISERROR ('AutoMakePartNumber setting is not exist in MnxSettingsManagement Table. Cannot proceed.', -- Message text.        
		--     16, -- Severity.        
		--   1 -- State.        
		--  );        
		      
		-- 04/20/18 Vijay G : Check Auto Make Number setting value from wmSettingsManagement        
		-- SELECT @AutoMakeNo =InvtSetup.lAutoMakeNo FROM InvtSetup        
		-- 07/18/18 Vijay G : Get the AutoMakePartNumber setting value by setting name if exist in wmSettingsManagement otherwise from MnxSettingsManagement        
		-- 02/27/2020 Vijay G : Removed code of auto parnumber setting 
		--SELECT @AutoMakeNo = ISNULL(w.settingValue,m.settingValue)             
		--FROM MnxSettingsManagement M LEFT OUTER JOIN wmSettingsManagement W ON m.settingId=w.settingId          
		--WHERE settingName ='AutoMakePartNumber' AND settingModule = 'PartMasterSetting'        
         
        
		-- Get the Header information for the import         
		DECLARE @eUniq_key varchar(10)='',@custNo varchar(MAX)='',@msg varchar(MAX)='',@assyNo varchar(MAX)='',@assyRev varchar(MAX)='',@uniqKey varchar(10)='',        
		 @partSource varchar(10)='',@assyDesc varchar(45)='',@bomCustNo varchar(MAX)='',@partClass varchar(8)='',@partType varchar(8)='',@impId uniqueidentifier        
		        
		SELECT @assyNo=assyNum,@assyRev=assyRev,@uniqKey=uniq_key,@custno=custNo FROM importBOMHeader WHERE importId=@importId        
		SELECT @eUniq_key=UNIQ_KEY,@partSource=PART_SOURC,@assyDesc=DESCRIPT,@partClass=PART_CLASS,@partType=PART_TYPE,@bomCustNo=BOMCUSTNO ,@impId=importid        
		 FROM INVENTOR WHERE rtrim(ltrim(PART_NO))=rtrim(ltrim(@assyNo))AND rtrim(ltrim(REVISION))=rtrim(ltrim(@assyRev)) AND CUSTNO=''        
		      
		-- 01/11/2019 Vijay G : Checking errors at part level , avl level and ref desg level            
		Declare @cnt as int;         
                 
		;WITH importBomErrorCount AS (              
			SELECT status  from importBOMFields  WHERE importBOMFields.fkImportId = @importId AND status ='i05red'              
		UNION                
			SELECT status  from importBOMAvl  WHERE fkImportId = @importId AND status ='i05red'              
		UNION               
			SELECT status  from importBOMRefDesg  WHERE fkImportId = @importId AND status ='i05red')
		SELECT @cnt = COUNT(Status) FROM importBomErrorCount            
        
		-- 01/21/2019 Sachin B Update the Customer if the BOM_Det Table Don't have component      
		DECLARE @count INT = (SELECT COUNT(*) FROM BOM_DET WHERE BOMPARENT =@eUniq_key)      
        
		IF @eUniq_key<>''         
		BEGIN        
			IF (@bomCustNo<>'' AND @custNo<>@bomCustNo AND @bomCustNo<>'000000000~' AND @count > 0 )        
			BEGIN        
				SET @custNo=@bomCustNo         
				SET @msg='Assembly and Rev exist under another customer.  Assigned customer was adjusted.'        
			END           
			SET @uniqKey=@eUniq_key        
			UPDATE importBOMHeader SET assyNum=@assyNo, assyRev=@assyRev, assyDesc=@assyDesc, [source]=@partSource,partClass=@partClass,partType=partType,        
			-- 01/11/2019 Vijay G : Change the status condition @impId=@importId to @cnt=0           
			-- 01/16/2019 Vijay G : Add And Condition completedate is not null           
			custNo=@custNo,uniq_key=@uniqKey,[message]=@msg, [status]=CASE WHEN @cnt=0 and completeDate is not null THEN 'Loaded' ELSE [status] END         
			WHERE importId=@importId           
		END        
            
		-- 7/31/15 Raviraj Added useSetUp and StdBldQty for Assembly  
		-- 02/27/2020 Vijay G : Removed code of auto parnumber setting       
		SELECT i.[assyNum],i.[assyRev],i.[assyDesc],i.[completeDate],i.[completedBy],i.[custNo],i.[importId],rtrim(i.[partClass])partClass,rtrim(i.[partType])partType,        
		rtrim(i.[source])[source],i.[startDate],i.[startedBy],i.[status],i.[uniq_key],c.[CUSTNAME],i.[message],ISNULL(inv.BOMLOCK,0) bomlock,         
		isValidated, i.useSetUp, i.stdBldQty        
		FROM importBOMHeader i LEFT OUTER JOIN CUSTOMER c ON i.custNo = c.CUSTNO        
		LEFT OUTER JOIN INVENTOR inv ON i.uniq_key=inv.UNIQ_KEY        
		WHERE i.importId = @importId        
          
		IF @@TRANCOUNT>0        
		COMMIT        
        
	END TRY        
	BEGIN CATCH        
		--09/19/16 YS Error trap, and begin/rollback/commit transaction        
		IF @@TRANCOUNT>0        
		ROLLBACK        
		SELECT        
		@ERRORNUMBER = ERROR_NUMBER(),        
		@ErrorSeverity = ERROR_SEVERITY(),        
		@ERRORPROCEDURE=ERROR_PROCEDURE(),        
		@ErrorLine=ERROR_LINE() ,        
		@ErrorMessage=ERROR_MESSAGE() ;        
		INSERT INTO importBOMErrors (importId,errNumber,errSeverity,errProc,errLine,errMsg)        
		VALUES (@importId,@ERRORNUMBER,@ErrorSeverity,@ERRORPROCEDURE,@ErrorLine,@ErrorMessage);         
		--09/20/16 Shivshankar P Return Error to display on UI        
		RAISERROR(@ErrorMessage,  16, 1)        
	END CATCH        
END