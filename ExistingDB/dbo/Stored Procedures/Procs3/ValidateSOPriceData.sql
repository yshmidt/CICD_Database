-- ============================================================================================================  
-- Date   : 09/26/2019  
-- Author  : Mahesh B	
-- Description : Used for Validate Price data
-- ValidateSOPriceData   '3046F0C8-113E-43EF-8D2B-6DEADE385D0C'
-- ============================================================================================================  
  
CREATE PROC ValidateSOPriceData
 @ImportId UNIQUEIDENTIFIER  
AS  
BEGIN  
   
 SET NOCOUNT ON    
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName VARCHAR(MAX),@headerErrs VARCHAR(MAX),@autoSONO BIT  
 DECLARE @ErrTable TABLE (ErrNumber INT,ErrSeverity INT,ErrProc VARCHAR(MAX),ErrLine INT,ErrMsg VARCHAR(MAX))      
  
DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,FKSODetailRowId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),
							  Price VARCHAR(100),Qty VARCHAR(100),SaleTypeId VARCHAR(100),SONO VARCHAR(100),Taxable VARCHAR(10))   

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
       WHERE ModuleId = @ModuleId AND FieldName IN ('Price','Qty','SaleTypeId','Taxable','SONO')  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')     
  
 SELECT @SQL = N'    
  SELECT PVT.*  
   FROM    
  ( SELECT isom.fkImportId AS importId,idtl.RowId  AS FKSODetailRowId, idts.RowId,Sub.class AS CssClass,Sub.Validation,fd.fieldName,idts.adjusted 
	FROM ImportFieldDefinitions fd      
    INNER JOIN ImportSOPriceFields idts ON fd.FieldDefId = idts.FKFieldDefId 
	INNER JOIN ImportSODetailFields idtl ON idtl.RowId=idts.FKSODetailRowId
	INNER JOIN ImportSOMainFields isom ON isom.RowId=idtl.SOMainRowId
	INNER JOIN   
	   (   
		SELECT iso.fkImportId,fd.FKSODetailRowId,MAX(fd.Status) AS Class ,MIN(fd.Message) AS Validation		
		FROM ImportSOPriceFields fd  
				INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId 
			INNER JOIN ImportSODetailFields isdt ON isdt.RowId=fd.FKSODetailRowId
			INNER JOIN ImportSOMainFields iso ON iso.RowId=isdt.SOMainRowId
		WHERE iso.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''   
			AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')  
			GROUP BY iso.fkImportId,fd.FKSODetailRowId
	   ) Sub    
    ON isom.fkImportid=Sub.FkImportId AND idtl.RowId=Sub.FKSODetailRowId
    WHERE isom.fkImportId = '''+ CAST(@importId AS CHAR(36))+'''     
  ) st    
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')   
  ) AS PVT '  
    
   --PRINT @SQL
 INSERT INTO @ImportDetail EXEC SP_EXECUTESQL @SQL    
 --SELECT * FROM @ImportDetail
 

 UPDATE a  
 SET [message] = 
  CASE
	 WHEN ifd.FieldName = 'SONO' THEN   
		CASE WHEN (@autoSONO = 0 AND TRIM(ISNULL(a.Adjusted,'')) = '') THEN 'Please enter SONO.'  
		  WHEN (@autoSONO = 0 AND NoAutoSONOGen.sono IS NOT NULL) THEN 'Entered SONO already exists.'  
		  ELSE '' END     
	--WHEN ifd.FieldName = 'SONO' THEN 
	--		CASE WHEN (NOT ISNULL((SELECT TOP 1 SONO FROM SOPRICES WHERE SONO=(RIGHT('0000000000'+ CONVERT(VARCHAR,a.Adjusted),10))),'')='')
	--		 THEN 'Sales Order Number already exist.' ELSE ''END    

	WHEN ifd.FieldName = 'Taxable' THEN
		CASE WHEN (TRIM(a.Adjusted)<>'' AND TRIM(a.Adjusted) IS NOT NULL)
			  THEN CASE 
			  	WHEN  TRIM(a.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
			  		THEN'Entered the invalid data into Taxable. Values can be ( Y OR N ,YES OR NO ,True or False ,1 OR 0)'
			  	ELSE '' END
			  ELSE '' END

	WHEN ifd.FieldName = 'Price' THEN
		CASE WHEN (TRIM(a.Adjusted)<>'' AND TRIM(a.Adjusted) IS NOT NULL)
				THEN CASE WHEN (ISNUMERIC(a.Adjusted)=1)   
					THEN CASE WHEN (CAST(a.Adjusted AS NUMERIC(14,5))<0)
								THEN 'Price can not be negative.' ELSE '' END
					ELSE 'Price is not numeric value.' END    
		ELSE 'Please enter Price.'END

	WHEN  ifd.FieldName = 'SaleTypeId' THEN
		CASE WHEN (ISNULL(a.Adjusted,'') = '')  THEN 'Please enter Sale Type Id.'
			 WHEN (TRIM(a.Adjusted) NOT IN (SELECT SaleTypeId FROM SALETYPE))  THEN 'Invalid Sale Type Id.'
		ELSE ''END

	WHEN  ifd.FieldName = 'Qty' THEN
		CASE WHEN (ISNULL(a.Adjusted,'') = '')  THEN 'Please enter quantity.'ELSE ''END

  ELSE 
	CASE WHEN(NOT ISNULL(a.Message,'') = '') THEN a.Message ELSE '' END
  END
  
 ,[status] =   
  CASE           
   WHEN ifd.FieldName = 'SONO' THEN   
	CASE WHEN (@autoSONO = 0 AND TRIM(ISNULL(a.Adjusted,'')) = '') THEN 'i05red'  
	  WHEN (@autoSONO = 0 AND NoAutoSONOGen.sono IS NOT NULL) THEN 'i05red'  
      ELSE '' END     
	--WHEN ifd.FieldName = 'SONO' THEN 
	--		CASE WHEN (NOT ISNULL((SELECT TOP 1 SONO FROM SOPRICES WHERE SONO=(RIGHT('0000000000'+ CONVERT(VARCHAR,a.Adjusted),10))),'')='')
	--		 THEN 'i05red' ELSE ''END    

	WHEN ifd.FieldName = 'Taxable' THEN
		CASE WHEN (TRIM(a.Adjusted)<>'' AND TRIM(a.Adjusted) IS NOT NULL)
			  THEN CASE 
			  	WHEN  TRIM(a.Adjusted) NOT IN ('1','0','true','false','yes','no','y','n')
			  		THEN 'i05red'
			  	ELSE '' END
			  ELSE '' END

	WHEN ifd.FieldName = 'Price' THEN
		CASE WHEN (TRIM(a.Adjusted)<>'' AND TRIM(a.Adjusted) IS NOT NULL)
				THEN CASE WHEN (ISNUMERIC(a.Adjusted)=1)   
					THEN CASE WHEN (CAST(a.Adjusted AS NUMERIC(14,5))<0)
								THEN 'i05red' ELSE '' END
					ELSE 'i05red' END    
		ELSE 'i05red'END

	WHEN  ifd.FieldName = 'SaleTypeId' THEN
		CASE WHEN (ISNULL(a.Adjusted,'') = '')  THEN 'i05red'
			 WHEN (TRIM(a.Adjusted) NOT IN (SELECT SaleTypeId FROM SALETYPE))  THEN 'i05red'
		ELSE ''END

	WHEN  ifd.FieldName = 'Qty' THEN
		CASE WHEN (ISNULL(a.Adjusted,'') = '')  THEN 'i05red'ELSE ''END

 ELSE 
	CASE WHEN(NOT ISNULL(a.Status,'') = '') THEN a.Status ELSE '' END
 END
 
  FROM ImportSOPriceFields a  
	 JOIN ImportFieldDefinitions ifd  ON a.FKFieldDefId = ifd.FieldDefId AND UploadType = 'SalesOrderUpload' 
	 --JOIN ImportSODetailFields d ON d.RowId=a.FKSODetailRowId
	 --JOIN ImportSOMainFields m ON m.RowId=d.SOMainRowId
	 JOIN @ImportDetail impt ON impt.FKSODetailRowId = a.FKSODetailRowId AND impt.importId = @ImportId --m.fkimportid = impt.importId
	 OUTER APPLY   
	 (  
		SELECT TOP 1 TRIM(sono) sono FROM somain WHERE TRIM(sono) = TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,impt.sono),10))))  
	 ) AS NoAutoSONOGen  
	 
-- Check length of string entered by user in template
	BEGIN TRY
	  UPDATE a      
		SET [message]='Field will be truncated to ' + CAST(f.fieldLength AS VARCHAR(50)) + ' characters.',[status]='i05red' 
		FROM ImportSOPriceFields a 	 
		  INNER JOIN ImportFieldDefinitions f  ON a.FKFieldDefId =f.FieldDefId AND ModuleId = @ModuleId AND f.fieldLength > 0      
		  --INNER JOIN ImportSODetailFields d ON d.RowId=a.FKSODetailRowId
		  --INNER JOIN ImportSOMainFields m ON m.RowId=d.SOMainRowId
		  INNER JOIN @ImportDetail impt ON impt.FKSODetailRowId=a.FKSODetailRowId AND a.RowId= impt.RowId
		WHERE impt.importId= @ImportId AND LEN(a.adjusted)>f.fieldLength        
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
