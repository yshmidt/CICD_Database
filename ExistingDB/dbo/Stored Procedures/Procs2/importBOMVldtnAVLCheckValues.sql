-- =============================================  
-- Author:  David Sharp  
-- Create date: 5/1/2012  
-- Description: check the values of the AVL  
-- 09/17/14 DS added back the default value for Material Type if it is empty  
-- 01/26/15 DS added check for repeated parts at the end  
-- 01/08/2019 Sachin B Add Length valdation for the MPN amd mfgr part no column 
-- 05/08/2019 Vijay G : apply AVL Validation for the fields length which does not have error(i05red) Add and status<>'i05red' 
-- 05/08/2019 Vijay G : modify message "Invalid mfg" to "Manufacturer does not exist in the system" when manufacture not exist
-- 09/30/2020 Sachin B : Empty the Message
-- =============================================  
CREATE PROCEDURE [dbo].[importBOMVldtnAVLCheckValues]   
 -- Add the parameters for the stored procedure here  
 @importId uniqueidentifier  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
  -- Insert statements for procedure here  
    DECLARE @fdid uniqueidentifier, @rCount int, @adjusted varchar(MAX), @dSql varchar(MAX), @erMsg varchar(max)  
      
    /* Declare status values to make it easier to update if we change the method in the future */  
    DECLARE @white varchar(50)='i00white',@skip varchar(50)='i00skipped',@green varchar(50)='i01green',@blue varchar(50)='i03blue',@orange varchar(50)='i04orange',
	@red varchar(50)='i05red',@sys varchar(50)='01system',@usr varchar(10)='03user'  
      
    /* Get a list of field definitions to be processed with this sp and with a valueSQL set */  
    DECLARE @mfgId uniqueidentifier,@matTypId uniqueidentifier,@mpnId uniqueidentifier  
      
    SELECT @mfgId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='partMfg'  
    SELECT @matTypId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='matlType'  
    SELECT @mpnId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='mpn'  
      
  
 /* CHECK MFG */   
 /* Populate the default MFG if any are blank */  
 --UPDATE i  
 -- SET i.[status]=@blue,i.[validation]=@sys,i.[message]='Default Value',i.adjusted=fd.[default]  
 -- FROM importBOMAvl i INNER JOIN importBOMFieldDefinitions fd ON fd.fieldDefId = i.fkFieldDefId  
 -- WHERE i.fkImportId=@importId AND i.fkFieldDefId=@mfgId AND i.adjusted = ''  
 /* If the provided mfg matches the mfg code validate and accept*/  
 UPDATE i  
  SET i.[status]=@white,i.[validation]=@sys  
  FROM importBOMAvl i INNER JOIN SUPPORT s ON i.adjusted = s.TEXT2 AND i.[status]<>@green AND i.[status]<>@blue AND i.[status]<>@green  
  WHERE s.FIELDNAME = 'PARTMFGR' AND i.fkImportId = @importId AND i.fkFieldDefId=@mfgId AND i.original=i.adjusted  

 -- 09/30/2020 Sachin B : Empty the Message
 UPDATE i  
  SET i.[status]=@green,i.[validation]=@usr,i.[message]=''  
  FROM importBOMAvl i INNER JOIN SUPPORT s ON i.adjusted = s.TEXT2 AND i.[status]<>@blue  
  WHERE s.FIELDNAME = 'PARTMFGR' AND i.fkImportId = @importId AND i.fkFieldDefId=@mfgId AND i.original<>i.adjusted  
 /* If provided MFG matches the existing MFG name, then update and match*/   
 UPDATE i  
  SET i.[status]=@blue,i.[validation]=@sys,i.[message]='Matched name',i.adjusted=s.TEXT2  
  FROM importBOMAvl i INNER JOIN SUPPORT s ON RTRIM(LTRIM(i.adjusted)) = RTRIM(LTRIM(s.[TEXT]))  
  WHERE s.FIELDNAME = 'PARTMFGR' AND i.fkImportId=@importId AND i.fkFieldDefId=@mfgId AND i.[status]<>@green AND i.[status]<>@white   
    AND i.original=i.adjusted  
 UPDATE i  
  SET i.[status]=@green,i.[validation]=@usr,i.[message]='Matched name',i.adjusted=s.TEXT2  
  FROM importBOMAvl i INNER JOIN SUPPORT s ON RTRIM(LTRIM(i.adjusted)) = RTRIM(LTRIM(s.[TEXT]))  
  WHERE s.FIELDNAME = 'PARTMFGR' AND i.fkImportId=@importId AND i.fkFieldDefId=@mfgId AND i.[status]<>@white   
    AND i.original<>i.adjusted  
 /* If provided MFG matches the existing MFG name, then update and match*/   
 UPDATE i  
  SET i.[status]=@blue,i.[validation]=@sys,i.[message]='Matched alias',i.adjusted=a.partMfg  
  FROM importBOMAvl i INNER JOIN importBOMAvlAliases a ON RTRIM(LTRIM(i.adjusted)) = RTRIM(LTRIM(a.alias))  
  WHERE i.fkImportId=@importId AND i.fkFieldDefId=@mfgId AND i.[status]<>@green AND i.[status]<>@white AND i.original=i.adjusted  
 UPDATE i  
  SET i.[status]=@green,i.[validation]=@usr,i.[message]='Matched alias',i.adjusted=a.partMfg  
  FROM importBOMAvl i INNER JOIN importBOMAvlAliases a ON RTRIM(LTRIM(i.adjusted)) = RTRIM(LTRIM(a.alias))  
  WHERE i.fkImportId=@importId AND i.fkFieldDefId=@mfgId AND i.[status]<>@green AND i.[status]<>@white AND i.original<>i.adjusted  
 /* If the provided MFG does not match any records, then mark it as invalid*/  
 -- 05/08/2019 Vijay G : modify message "Invalid mfg" to "Manufacturer does not exist in the system" when manufacture not exist
 UPDATE i  
  SET i.[status]=@red,i.[validation]=@sys,i.[message]='Manufacturer does not exist in the system'  
  FROM importBOMAvl i LEFT OUTER JOIN SUPPORT s ON i.adjusted = s.TEXT2  
  WHERE i.fkImportId=@importId AND i.fkFieldDefId=@mfgId AND s.TEXT2 IS NULL  
  
      
      
    /* CHECK MATL TYPE */  
    /* Populate the Default Value if Empty*/   
 UPDATE i  
  SET i.[status]=@blue,i.[validation]=@sys,i.[message]='Default Value', i.adjusted=fd.[default]  
  FROM importBOMAvl i INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId = fd.fieldDefId  
  WHERE  i.adjusted='' AND i.fkImportId = @importId AND i.fkFieldDefId=@matTypId  
 /* if the provided matltype exists, then validate */  
    UPDATE i  
  SET i.[status]=@white,i.[validation]=@sys  
  FROM importBOMAvl i INNER JOIN AVLMATLTP m ON i.adjusted = m.AVLMATLTYPE  
  WHERE  i.fkImportId = @importId AND i.fkFieldDefId=@matTypId AND i.[status]<>@green AND i.[status]<>@blue AND i.original=i.adjusted  
 UPDATE i  
  SET i.[status]=@green,i.[validation]=@usr  
  FROM importBOMAvl i INNER JOIN AVLMATLTP m ON i.adjusted = m.AVLMATLTYPE  
  WHERE  i.fkImportId = @importId AND i.fkFieldDefId=@matTypId AND i.[status]<>@blue AND i.original<>i.adjusted  
 /* if the provided matltype matches the description, then validate */  
    UPDATE i  
  SET i.[status]=@blue,i.[validation]=@sys,i.[message]='matched description',i.adjusted=m.AVLMATLTYPE  
  FROM importBOMAvl i INNER JOIN AVLMATLTP m ON i.adjusted = m.AVLMATLTYPEDESC   
  WHERE  i.fkImportId = @importId AND i.fkFieldDefId=@matTypId AND i.[status]<>@green AND i.[status]<>@white  
 /* If the value is not found, mark for error */   
 UPDATE i  
  SET i.[status]=@red,i.[validation]=@sys,i.[message]='Invalid Value'  
  FROM importBOMAvl i LEFT OUTER JOIN AVLMATLTP m ON i.adjusted = m.AVLMATLTYPE  
  WHERE  m.AVLMATLTYPE IS NULL AND i.fkImportId = @importId AND i.fkFieldDefId=@matTypId  
    
 /* Mark all MPNS as valid */  
 UPDATE importBOMAvl  
  SET [status]=@skip,[validation]=@sys,[message]='value not checked'  
  WHERE fkImportId=@importId AND fkFieldDefId=@mpnId AND [status]<>@green  
   
 /* Find exact matches with MPN and MFG and load uniqmfhd */  
 --UPDATE i  
 -- SET i.uniqmfgrhd = ''  
 -- FROM importBOMAvl i INNER JOIN   
   
 /* Mark all AVLs tied to an existing record as NULL for load */  
 UPDATe importBOMAvl  
  SET [load] = null   
  WHERE uniqmfgrhd <> ''  

 -- 01/08/2019 Sachin B Add Length valdation for the MPN amd mfgr part no column  
 -- 05/08/2019 Vijay G : apply AVL Validation for the fields length which does not have error(i05red) Add and status<>'i05red'  
 BEGIN TRY -- inside begin try  
   UPDATE f  
   SET [message]='Field will be truncated to ' + CAST(fd.fieldLength AS varchar(50)) + ' characters.',[status]=@orange,[validation]=@sys  
   FROM importBOMAvl f   
   INNER JOIN importBOMFieldDefinitions fd ON f.fkFieldDefId=fd.fieldDefId AND fd.fieldLength>0  
   WHERE fkImportId=@importId AND LEN(f.adjusted)>fd.fieldLength AND status<>'i05red'   
 END TRY  
 BEGIN CATCH   
  --INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)  
  SELECT  
   ERROR_NUMBER() AS ErrorNumber  
   ,ERROR_SEVERITY() AS ErrorSeverity  
   --,ERROR_STATE() AS ErrorState  
   ,ERROR_PROCEDURE() AS ErrorProcedure  
   ,ERROR_LINE() AS ErrorLine  
   ,ERROR_MESSAGE() AS ErrorMessage;  
  --SET @headerErrs = 'There are issues in the fields to be truncated (starting on line:44)'  
 END CATCH  
  
 --/****** DUPLICATE PART NUMBER IN WC - ensure that the part number is not under two itemno but the same work center ******/   
 EXEC importBOMVldtnCheckRepeats @importId  
END