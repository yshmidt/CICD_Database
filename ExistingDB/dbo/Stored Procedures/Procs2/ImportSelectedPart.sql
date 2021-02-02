-- ================================================================================================================================
-- Author       : Satyawan H   
-- Date           : 05/15/2019        
-- Description : Import Selected Parts from Inventor UDF Upload  
-- Satyawan H 08/02/2019 - Code Commented because the value of Adjusted was not printing with dynamic query  
-- Satyawan H 09/20/2019 - turn OFF/ON the warning for truncate error we are showing Warning on UI side for this will truncate      
-- Satyawan H 11/08/2019 - Added Joins with sys.columns & sys.tables to ignore columns that doesn't belongs to the UDF table 
-- Satyawan H 11/08/2019 - Optimized code by adding @IsExists in SELECT CASE statement instead of creating seprate IF else block on @IsExists
-- ================================================================================================================================  
  
CREATE PROC ImportSelectedPart        
 @ImportID UNIQUEIDENTIFIER=null,        
 @UserId UNIQUEIDENTIFIER=null,        
 @tRowIds tRowIds READONLY      
AS        
BEGIN        
 SET NOCOUNT ON         
 DECLARE @RowId UNIQUEIDENTIFIER, @id int = 0      
 DECLARE @ValidRows tRowIds        
 DECLARE @AllRows TABLE (Id int,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(50),ValidUDFs bit,IsImported bit)      
      
 IF EXISTS(select 1 FROM @tRowIds)      
 BEGIN      
  INSERT INTO @ValidRows select * from @tRowIds      
 END      
 ELSE      
 BEGIN      
  INSERT INTO @AllRows EXEC sp_getImportedInventorUDFs @ImportID,@GetImportRows = 1      
  INSERT INTO @ValidRows SELECT Id, RowId FROM @AllRows       
    WHERE CssClass = 'i00white' OR CssClass = 'i01system' AND ValidUDFs = 1 AND IsImported = 0      
 END      
       
 WHILE(1=1)      
 BEGIN      
  SELECT TOP 1 @id = id,@RowId = RowId FROM @ValidRows WHERE id > @id ORDER BY id      
  IF @@ROWCOUNT = 0 BREAK;      
        
  BEGIN TRY        
   DECLARE @IFieldName VARCHAR(MAX),@SQL NVARCHAR(MAX),@tUFieldName NVARCHAR(MAX),@isUDFSetup bit = 0,        
   @UFieldNames NVARCHAR(MAX),@part_class VARCHAR(MAX),@fkUNIQ_KEY VARCHAR(15),@IsExists int      
         
   
   DECLARE @ImportDetail TABLE(ImportId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),[Validation] VARCHAR(MAX),        
     ValidUDFs BIT,TotalUDFs BIT,Custno VARCHAR(100),CustPartNo VARCHAR(100),CustRev VARCHAR(100),Descript VARCHAR(100),        
     IsImported Bit,Part_No CHAR(100),Part_Sourc CHAR(100),Revision CHAR(100),UNIQ_KEY VARCHAR(100),      
     Custname CHAR(100),PartDesc VARCHAR(200))         
      
   INSERT INTO @ImportDetail         
   EXEC [sp_getImportedInventorUDFs] @importId=@ImportID,@rowId=@RowId,@isPartValid=1        
    
   SELECT TOP 1 @fkUNIQ_KEY = I.UNIQ_KEY, @part_class = I.PART_CLASS         
   FROM @ImportDetail Id      
   JOIN INVENTOR I ON  id.UNIQ_KEY = I.UNIQ_KEY AND id.rowid = @RowId       
           
   IF(@part_class <> '')        
   BEGIN        
    -- Check if UDF setup is available for selected part part_class        
    DECLARE @UdfTable VARCHAR(100) = N'UdfINVENTOR_'+ REPLACE(REPLACE(RTRIM(@part_class),'-','_'),' ','_')        
    IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @UdfTable)        
    BEGIN  
     SET @isUDFSetup = 1         
    END  
    ELSE        
    BEGIN  
     RAISERROR (N'No UDF setup found for Part. (UK: %s, PC: %s)',16,1,@fkUNIQ_KEY,@part_class);         
    END  
  
    SELECT @IFieldName = STUFF        
    (          
     (          
     SELECT  ',''' +  F.FIELDNAME + '''' FROM ImportFieldDefinitions F           
     JOIN MnxModule M ON M.ModuleId = F.ModuleId         
     WHERE M.ModuleName = 'InventorUDFUpload' AND M.FilePath = 'InventorUDFUpload'        
     FOR XML PATH('')          
     ),          
    1,1,'')           
           
    -- IF UDF setup exists      
    IF(@isUDFSetup = 1)        
    BEGIN        
     SET @SQL =  'SELECT TOP 1  * FROM '+@UdfTable+ ' WHERE fkUniq_key = ''' + @fkUNIQ_KEY + ''''      
     EXEC Sp_executesql @SQL      
     SET @IsExists = CASE WHEN @@ROWCOUNT > 0 THEN 1 ELSE 0 END      
      
     DECLARE @UDFFields TABLE(FieldName NVARCHAR(MAX))        
    
	 -- Satyawan H 11/08/2019 - Optimized code by adding @IsExists in SELECT CASE statement instead of creating seprate IF else block on @IsExists 
      INSERT INTO @UDFFields     
      SELECT STUFF        
      (          
		  (          
			SELECT CASE WHEN @IsExists = 0 THEN ',' + TRIM(I.FieldName) + '' ELSE ',' + TRIM(I.FieldName) + ' = ' +'''' + TRIM(I.Adjusted) +'''' END 
			FROM ImportInventorUDFFields I       
			JOIN ImportInventorUDFHeader H ON I.FkImportId = H.ImportId    
			-- Satyawan H 11/08/2019 - Added Joins with sys.columns & sys.tables to ignore columns that doesn't belongs to the UDF table
			JOIN sys.all_columns c ON c.[name] = I.FieldName
			join sys.tables t on t.object_id = c.object_id AND t.name = @UdfTable    
			WHERE RTRIM(FieldName) 
			NOT IN ('UNIQ_KEY','PART_NO','REVISION','DESCRIPT','CUSTNO','CUSTPARTNO','CUSTREV','PART_SOURC','IsImported','UDF')         
			AND I.FkImportId=cast(@ImportID AS nvarchar(100))      
			AND I.RowId=cast(@RowId AS nvarchar(100))      
			AND (I.[Status] = 'i00white' AND I.[Message] = '') OR (I.[Status] = 'i04orange' AND I.RowId=cast(@RowId AS nvarchar(100)))           
			FOR XML PATH('')         
		  ),          
      1,1,'')     

   --  IF @IsExists=0      
   --  BEGIN      
   --   INSERT INTO @UDFFields     
   --   SELECT STUFF        
   --   (          
		 -- (          
			--SELECT ',' + I.FIELDNAME + ''  FROM ImportInventorUDFFields I       
			--JOIN ImportInventorUDFHeader H ON I.FkImportId = H.ImportId    
			---- Satyawan H 11/08/2019 - Added Joins with sys.columns & sys.tables to ignore columns that doesn't belongs to the UDF table
			--JOIN sys.all_columns c ON c.[name] = I.FieldName
			--join sys.tables t on t.object_id = c.object_id AND t.name = @UdfTable    
			--WHERE RTRIM(FieldName) 
			--NOT IN ('UNIQ_KEY','PART_NO','REVISION','DESCRIPT','CUSTNO','CUSTPARTNO','CUSTREV','PART_SOURC','IsImported','UDF')         
			--AND I.FkImportId=cast(@ImportID AS nvarchar(100))      
			--AND I.RowId=cast(@RowId AS nvarchar(100))      
			--AND (I.[Status] = 'i00white' AND I.[Message] = '') 
			--OR (I.[Status] = 'i04orange' AND I.RowId=cast(@RowId AS nvarchar(100)))           
			--FOR XML PATH('')         
		 -- ),          
   --   1,1,'')      
   --  END      
   --  ELSE      
   --  BEGIN      
   --   INSERT INTO @UDFFields       
   --   SELECT STUFF        
   --   (          
		 -- (          
			--SELECT ',' + I.FIELDNAME + ' = ' +'''' +I.Adjusted +'''' FROM ImportInventorUDFFields I       
			--JOIN ImportInventorUDFHeader H ON I.FkImportId = H.ImportId  
			---- Satyawan H 11/08/2019 - Added Joins with sys.columns & sys.tables to ignore columns that doesn't belongs to the UDF table
			--JOIN sys.all_columns c ON c.[name] = I.FieldName
			--join sys.tables t on t.object_id = c.object_id AND t.name = @UdfTable      
			--WHERE RTRIM(FieldName) 
			--NOT IN ('UNIQ_KEY','PART_NO','REVISION','DESCRIPT','CUSTNO','CUSTPARTNO','CUSTREV','PART_SOURC','IsImported','UDF')         
			--AND I.FkImportId=cast(@ImportID AS nvarchar(100))      
			--AND I.RowId=cast(@RowId AS nvarchar(100))      
			--AND (I.[Status] = 'i00white' AND I.[Message] = '') 
			--OR (I.[Status] = 'i04orange' AND I.RowId=cast(@RowId AS nvarchar(100)))       
			--FOR XML PATH('')         
		 -- ),          
   --   1,1,'')      
   --  END      
   
     -- Satyawan H 09/20/2019 - turn OFF/ON the warning for truncate error we are showing Warning on UI side for this will truncate      

     SET ANSI_WARNINGS OFF   
     SELECT @UFieldNames= FieldName FROM @UDFFields        
     IF @IsExists > 0      
     BEGIN      
      SET @SQL = 'UPDATE '+ @UdfTable + ' SET ' + @UFieldNames + ' WHERE fkUNIQ_KEY = ''' + @fkUNIQ_KEY + ''''      
     END      
     ELSE       
     BEGIN      
      SET @SQL =       
      'INSERT INTO '+@UdfTable+'(udfId,fkUNIQ_KEY,'+@UFieldNames+')          
       SELECT RowId udfId,''' + @fkUNIQ_KEY + ''',' + @UFieldNames +'        
      FROM           
      (        
      SELECT I.RowId,I.FieldName,I.Adjusted Adjusted  FROM ImportInventorUDFFields I         
       JOIN ImportInventorUDFHeader H ON I.FkImportId = H.ImportId        
      WHERE RTRIM(FieldName) NOT IN ('+@IFieldName +',''UDF'')        
       AND I.FkImportId = '''+CAST(@ImportID as nvarchar(100))+'''         
       AND I.RowId = '''+CAST(@RowId as nvarchar(100))+'''        
       AND (I.[Status] = ''i00white''  AND I.[Message] = '''') OR I.[Status] = ''i04orange''         
      ) AS Tab1        
      PIVOT          
      (          
      MAX(Adjusted) FOR FieldName IN ('+@UFieldNames+')        
      ) AS Tab2       
      WHERE RowId = '''+CAST(@RowId as nvarchar(100))+'''    
      ORDER BY [Tab2].RowId'        
     END      
       
     EXEC Sp_executesql @SQL     
     SET ANSI_WARNINGS ON   
     -- Satyawan H 09/20/2019 - turn OFF/ON the warning for truncate error we are showing Warning on UI side for this will truncate     
  
     -- Update the part after its UDFs are imported       
     UPDATE ImportInventorUdfFields         
      SET Original = 1, Adjusted = 1         
     WHERE RowId = @RowId AND FieldName ='IsImported'        
      
     -- Clear UDF fields table       
     Delete from @UDFFields      
    END              
    ELSE        
    BEGIN        
     RAISERROR (N'No part found.',16, 1);         
    END   
   END       
  END TRY        
  BEGIN CATCH      
    -- Satyawan H 09/20/2019 - turn OFF/ON the warning for truncate error we are showing Warning on UI side for this will truncate   
     SET ANSI_WARNINGS ON    
     SELECT ERROR_MESSAGE() AS ErrorMessage        
     ,ERROR_SEVERITY() AS ErrorSeverity         
     ,ERROR_STATE() As ErrorState          
  END CATCH          
 END    
   
   -- Update the header table complete info. for importId if import is complete.       
   EXEC UpdateHeadGridValidStatus @ImportID=@ImportID,@UserId=@UserId       
END