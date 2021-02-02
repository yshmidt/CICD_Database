-- ============================================================================================================    
-- Date   : 09/24/2019    
-- Author  : Mahesh B   
-- Description : Used for Validate SOMAIN data  
-- 05/11/2020 Rajendra k : Added outer join for customer validation, changed validation also changed message and modified the red error when field truncating
-- ValidateSOMainData  '931C803C-B4B9-41F1-ACE0-68AF752F3FD2'  
-- ============================================================================================================    
    
CREATE PROC ValidateSOMainData  
 @ImportId UNIQUEIDENTIFIER    
AS    
BEGIN    
     
 SET NOCOUNT ON      
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@headerErrs VARCHAR(MAX),@orange VARCHAR(20)='i04orange',@sys VARCHAR(20)='01system',@autoSONO BIT  
 DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))        
    
 DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,RowID UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),  
          Buyer  NVARCHAR(MAX),CustNo VARCHAR(100),OrderDate VARCHAR(100),SONO VARCHAR(100))  
   
  -- Insert statements for procedure here     
 SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleName = 'Sales' AND FilePath = 'salesPrice' AND Abbreviation='PL'  
  
 SELECT @autoSONO = CASE WHEN w.settingId IS NOT NULL THEN  w.settingValue ELSE m.settingValue END   
  FROM MnxSettingsManagement m  
   LEFT JOIN wmSettingsManagement w on m.settingId = w.settingId  
  WHERE settingName = 'AutoSONumber' AND settingDescription='AutoSONumber'  
    
 SELECT @FieldName = STUFF(      
      (      
       SELECT  ',[' +  F.FIELDNAME + ']' FROM     
       ImportFieldDefinitions F        
       WHERE ModuleId = @ModuleId AND FieldName IN ('CustNo','Buyer','SONO','OrderDate')    
       ORDER BY F.FIELDNAME     
       FOR XML PATH('')      
      ),      
      1,1,'')       
    
 SELECT @SQL = N'      
  SELECT PVT.*    
  FROM      
  (    
     SELECT so.fkImportId AS importId,so.RowId,Sub.class AS CssClass,Sub.Validation,fd.fieldName,so.adjusted   
  FROM ImportFieldDefinitions fd        
     INNER JOIN ImportSOMainFields so ON so.FKFieldDefId=fd.FieldDefId  
     INNER JOIN ImportSOUploadHeader h ON h.ImportId = so.FkImportId     
  INNER JOIN     
    (     
  SELECT fd.FkImportId,fd.RowId,MAX(fd.Status) as Class ,MIN(fd.Message) AS Validation    
  FROM ImportSOMainFields fd    
   INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId   
   INNER JOIN ImportSOUploadHeader h ON h.ImportId=fd.FkImportId  
  WHERE  fd.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''     
   AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')    
   GROUP BY fd.fkImportId,fd.RowId    
    ) Sub      
   ON so.fkImportid=Sub.FkImportId AND so.RowId=Sub.RowId     
    WHERE so.fkImportId = '''+ CAST(@importId AS CHAR(36))+'''       
  ) st      
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')     
  ) AS PVT '    
  
 INSERT INTO @ImportDetail EXEC sp_executesql @SQL       
 SELECT * FROM @ImportDetail  
    
 UPDATE a    
 SET [message] =     
  CASE             
	WHEN ifd.FieldName = 'SONO' THEN   
	CASE WHEN (@autoSONO = 0 AND TRIM(ISNULL(a.Adjusted,'')) = '') THEN 'Please enter SONO.'  
	  WHEN (@autoSONO = 0 AND NoAutoSONOGen.sono IS NOT NULL) THEN 'Entered SONO already exists.'  
      ELSE '' END     
  --     CASE WHEN (a.Adjusted = '' AND   
  --   ((SELECT wm.settingValue FROM MnxSettingsManagement ms JOIN wmSettingsManagement wm ON ms.settingId=wm.settingId WHERE ms.settingName= 'ManualSONumber')='' OR  
  --   (SELECT wm.settingValue FROM MnxSettingsManagement ms JOIN wmSettingsManagement wm ON ms.settingId=wm.settingId WHERE ms.settingName= 'ManualSONumber')=0))  
  --  THEN 'Please enter SONO.'   
  --  ELSE    
  --CASE WHEN (NOT ISNULL((SELECT TOP 1 SONO FROM SOMAIN WHERE SONO=(RIGHT('0000000000'+ CONVERT(VARCHAR,a.Adjusted),10))),'')='') THEN 'Sales Order Number already exist.' ELSE ''END  
  --  END        
  
 WHEN  ifd.FieldName = 'CustNo' THEN     
       CASE WHEN (ISNULL(a.Adjusted,'') = '')    
    THEN 'Please enter CustNo.'   
   ELSE    
       CASE WHEN ISNULL(CUST.CustNo,'') = ''-- 05/11/2020 Rajendra k : Added outer join for customer validation, changed validation also changed message and modified the red error when field truncating
	  -- ((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,a.Adjusted),10)) <>  
	  --(SELECT TOP 1 TRIM(CustNo) CustNo FROM CUSTOMER WHERE TRIM(CustNo) = TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,a.Adjusted),10)))))))   --OR CUST.CustNo IS NULL))   
    --THEN 'Invalid CustNo.'
	THEN 'Please enter valid customer number.'
   ELSE'' END  
    END      
  
 WHEN  ifd.FieldName = 'OrderDate' THEN  
  CASE WHEN ((TRIM(a.Adjusted)<>'') AND (ISDATE(a.Adjusted) = 0)) THEN 'Incorrect date format of Order Date. Please enter in format MM-dd-YYYY.'   
  ELSE '' END  
    
 --WHEN ifd.FieldName = 'Buyer' THEN  
 -- CASE  
 --  WHEN (TRIM(a.Adjusted)<>'' AND TRIM(a.Adjusted) IS NOT NULL)  
 --   THEN CASE   
 --    WHEN CAST(TRIM(a.Adjusted) AS UNIQUEIDENTIFIER) NOT IN   
 --    (SELECT DISTINCT users.UserId FROM aspnet_Profile AS pro  
 --     INNER JOIN aspnet_Users AS users ON pro.UserId=users.UserId  
 --     LEFT JOIN aspmnx_groupUsers AS guser ON pro.UserId=guser.fkuserid  
 --     LEFT JOIN aspmnx_GroupRoles AS groles ON guser.fkgroupid=groles.fkGroupId  
 --     LEFT JOIN aspnet_Roles AS roles ON groles.fkRoleId=roles.RoleId  
 --     WHERE (roles.ModuleId=@ModuleId AND roles.RoleName IN ('ADD', 'EDIT')) OR pro.ScmAdmin=1 OR pro.CompanyAdmin=1  
 --    )  
 --     THEN 'Buyer is invalid please check the rights ADD or EDIT OR Admin Rights.'  
 --    ELSE '' END  
 --   ELSE '' END  

 -- WHEN ifd.FieldName = 'Buyer' THEN  
	--CASE  
	--	WHEN (TRIM(a.Adjusted)<>'' AND TRIM(a.Adjusted) IS NOT NULL )--AND TRIM(a.Adjusted)=(SELECT CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER))) 
	--		THEN CASE   
	--			--WHEN CAST(TRIM(a.Adjusted)) NOT IN (SELECT FkUserId FROm CCONTACT WHERE FkUserId=TRIM(a.Adjusted))  THEN 'Buyer is invalid.'  
	--			WHEN a.Adjusted NOT IN (SELECT FkUserId FROm CCONTACT WHERE FkUserId=TRIM(a.Adjusted))   THEN 'Buyer is invalid.'  
 --    ELSE '' END  
 --   ELSE '' END
    WHEN ifd.FieldName = 'Buyer' THEN  
		CASE  
		WHEN (TRIM(a.Adjusted)<>'' AND TRIM(a.Adjusted) IS NOT NULL  )--AND TRIM(a.Adjusted)=(SELECT CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER))) 
			THEN CASE WHEN LEN(a.Adjusted) = 36  
				THEN 
					CASE WHEN CAST(TRIM(a.Adjusted) AS UNIQUEIDENTIFIER) NOT IN (SELECT FkUserId FROm CCONTACT WHERE FkUserId=TRIM(a.Adjusted))  THEN 'Buyer is invalid.'  
				ELSE '' END  
			ELSE 'Buyer is invalid.' END  
		ELSE '' END  
 ELSE   
 CASE WHEN(NOT ISNULL(a.Message,'') = '') THEN a.Message ELSE '' END  
 END   
    
 ,[status] =     
  CASE             
 WHEN ifd.FieldName = 'SONO' THEN   
 CASE WHEN (@autoSONO = 0 AND TRIM(ISNULL(a.Adjusted,'')) = '') THEN 'i05red'  
   WHEN (@autoSONO = 0 AND NoAutoSONOGen.sono IS NOT NULL) THEN 'i05red'  
      ELSE '' END       
        
 WHEN  ifd.FieldName = 'CustNo' THEN     
       CASE WHEN  (ISNULL(a.Adjusted,'') = '')  
    THEN 'i05red'   
    ELSE    
	-- 05/11/2020 Rajendra k : Added outer join for customer validation, changed validation also changed message and modified the red error when field truncating
      CASE WHEN ISNULL(CUST.CustNo,'') = ''
	  --((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,a.Adjusted),10)) <>  
	  --(SELECT TOP 1 TRIM(CustNo) CustNo FROM CUSTOMER WHERE TRIM(CustNo) = TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,a.Adjusted),10)))))))--   OR CUST.CustNo IS NULL))   
	   --CUST.CustNo) OR CUST.CustNo IS NULL)   
    THEN 'i05red'   
   ELSE'' END  
    END      
  
 WHEN  ifd.FieldName = 'OrderDate' THEN  
  CASE WHEN ((TRIM(a.Adjusted)<>'') AND (ISDATE(a.Adjusted) = 0)) THEN 'i05red'   
  ELSE ''END  
  
 --WHEN ifd.FieldName = 'Buyer' THEN  
 --  CASE  
 --   WHEN (TRIM(a.Adjusted)<>'' AND TRIM(a.Adjusted) IS NOT NULL)  
 --    THEN CASE   
 --     WHEN Cast(TRIM(a.Adjusted) AS UNIQUEIDENTIFIER) NOT IN   
 --     (SELECT DISTINCT users.UserId FROM aspnet_Profile AS pro  
 --      INNER JOIN aspnet_Users AS users ON pro.UserId=users.UserId  
 --      LEFT JOIN aspmnx_groupUsers AS guser ON pro.UserId=guser.fkuserid  
 --      LEFT JOIN aspmnx_GroupRoles AS groles ON guser.fkgroupid=groles.fkGroupId  
 --      LEFT JOIN aspnet_Roles AS roles ON groles.fkRoleId=roles.RoleId  
 --      WHERE (roles.ModuleId=@ModuleId AND roles.RoleName IN ('ADD', 'EDIT')) OR pro.ScmAdmin=1 OR pro.CompanyAdmin=1  
 --     )  
 --      THEN 'i05red'  
 --     ELSE '' END  
 --    ELSE '' END  
  WHEN ifd.FieldName = 'Buyer' THEN  
	CASE  
		WHEN (TRIM(a.Adjusted)<>'' AND TRIM(a.Adjusted) IS NOT NULL)--AND TRIM(a.Adjusted)=(SELECT CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER))) 
			THEN CASE WHEN LEN(a.Adjusted) = 36  
				THEN 
					CASE WHEN CAST(TRIM(a.Adjusted) AS UNIQUEIDENTIFIER) NOT IN (SELECT FkUserId FROm CCONTACT WHERE FkUserId=TRIM(a.Adjusted))  THEN 'i05red'  
				ELSE '' END  
			ELSE 'i05red' END  
		ELSE '' END  

 ELSE   
	CASE WHEN(NOT ISNULL(a.Status,'') = '') THEN a.Status ELSE '' END  
 END  
 --select a.* ,CUST.* 
 FROM ImportSOMainFields a    
  JOIN ImportFieldDefinitions ifd  ON a.FKFieldDefId =ifd.FieldDefId AND UploadType = 'SalesOrderUpload'  
  JOIN ImportSOUploadHeader h  ON a.FkImportId =h.ImportId    
  LEFT JOIN @ImportDetail impt ON a.fkimportid = impt.importId  
  OUTER APPLY (  -- 05/11/2020 Rajendra k : Added outer join for customer validation, changed validation also changed message and modified the red error when field truncating      
  SELECT TOP 1 TRIM(CustNo) CustNo FROM CUSTOMER WHERE TRIM(CustNo) = TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,impt.CustNo),10))))  
  ) CUST  
  OUTER APPLY   
  (  
  SELECT TOP 1 TRIM(sono) sono FROM somain WHERE TRIM(sono) = TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,impt.sono),10))))  
  ) AS NoAutoSONOGen  
  WHERE FkImportId = @ImportId  
   
-- Check length of string entered by user in template  
 BEGIN TRY -- inside begin try        
   UPDATE a  -- 05/11/2020 Rajendra k : Added outer join for customer validation, changed validation also changed message and modified the red error when field truncating      
  SET [message]= 'Field will be truncated to ' + CAST(f.fieldLength AS VARCHAR(50)) + ' characters.',[status]= 'i05red' -- @orange   
  FROM ImportSOMainFields a     
    INNER JOIN ImportFieldDefinitions f  ON a.FKFieldDefId =f.FieldDefId AND ModuleId = @ModuleId AND f.fieldLength > 0        
   WHERE fkImportId= @ImportId        
    AND LEN(a.adjusted)>f.fieldLength          
  END TRY        
  BEGIN CATCH         
   INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)        
   SELECT        
    ERROR_NUMBER() AS ErrorNumber        
    ,ERROR_SEVERITY() AS ErrorSeverity        
    ,ERROR_PROCEDURE() AS ErrorProcedure        
    ,ERROR_LINE() AS ErrorLine        
    ,ERROR_MESSAGE() AS ErrorMessage;        
   SET @headerErrs = 'There are issues in the fields to be truncated.'        
  END CATCH       
END  