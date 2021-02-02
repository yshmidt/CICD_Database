-- ============================================================================================================  
-- Date   : 07/15/2019  
-- Author  : Sachin B  
-- Description : Used for Validate routing upload data  
-- 10/09/2020 Sachin B Remove the Column WorkInstruction
-- ValidateRoutingUploadRecords '46DCE6C1-B95F-47E8-B966-845635B7C078','6B581088-2D41-4B21-ACBD-3C9E341B58ED'  
-- ============================================================================================================  
  
CREATE PROC ValidateRoutingUploadRecords  
 @ImportId UNIQUEIDENTIFIER,  
 @RowId UNIQUEIDENTIFIER =NULL  
AS  
BEGIN  
   
 SET NOCOUNT ON    
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName varchar(max)--,@uniq_key VARCHAR(10)  
 
 -- 10/09/2020 Sachin B Remove the Column WorkInstruction  
 DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,ImportTemplateId UNIQUEIDENTIFIER,rowId UNIQUEIDENTIFIER,  
                              PartNo NVARCHAR(MAX),Revision NVARCHAR(MAX),TemplateName NVARCHAR(MAX),TemplateType NVARCHAR(MAX),UniqKey NVARCHAR(MAX),  
         CssClass VARCHAR(100),[Validation] VARCHAR(100),   
         DEPT_ID VARCHAR(100),NUMBER VARCHAR(100),RUNTIMESEC VARCHAR(100),SERIALSTRT VARCHAR(100),  
         SETUPSEC VARCHAR(100))   --,WorkInstruction VARCHAR(100)
  
 -- Insert statements for procedure here    
 SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleName = 'Routing Setup' and FilePath = 'RoutingSetup'  
 SELECT @FieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId AND FieldName in ('RUNTIMESEC','SERIALSTRT','DEPT_ID','SETUPSEC','NUMBER') --,'WorkInstruction' 
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')     
  
 SELECT @SQL = N'    
  SELECT PVT.*  
  FROM    
  (   SELECT ibf.fkImportId AS importId,ibf.FKImportTemplateId,ibf.rowId,ti.partNo,ti.revision,ti.templateName,ti.templateType,ti.uniq_Key AS UniqKey ,sub.class as CssClass,sub.Validation,fd.fieldName,adjusted'    
   +' FROM ImportFieldDefinitions fd      
   INNER JOIN importRoutingFields ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))+  
     'INNER JOIN importRoutingAssemblyInfo ti ON ti.ImportTemplateId = ibf.FKImportTemplateId     
     INNER JOIN importRoutingHeader h ON h.ImportId = ibf.FkImportId   
   INNER JOIN   
   (   SELECT fkImportId,rowid,MAX(status) as Class ,MIN(Message) as Validation    
    FROM importRoutingFields fd  
    INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
    WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''    
    AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')  
    GROUP BY fkImportId,rowid  
   ) Sub    
   ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid    
   WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''     
  ) st    
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')  
  ) as PVT   
  ORDER BY [NUMBER]'  
   
 --Print @SQL  
 INSERT INTO @ImportDetail EXEC sp_executesql @SQL     
 --SELECT * FROM @ImportDetail  
   
 UPDATE f  
  SET [message] =   
  -- DeptId   
  CASE           
   WHEN  ifd.FieldName = 'DEPT_ID' THEN   
       CASE   
        WHEN (dept.DEPT_ID IS NULL)  THEN 'DeptId Provided in the Sheet is not Exists.'  --impt.DEPT_ID <> '' AND   
        ELSE  '' END    
   WHEN  ifd.FieldName = 'NUMBER' THEN   
       CASE   
      WHEN (impt.NUMBER <> '' AND ISNUMERIC(impt.NUMBER)=1)  THEN ''   
      ELSE  'Number column must be numeric' END   
   WHEN  ifd.FieldName = 'RUNTIMESEC' THEN   
       CASE   
      WHEN (impt.RUNTIMESEC <> '' AND ISNUMERIC(impt.RUNTIMESEC)=1)  THEN ''   
      ELSE  'RUNTIMESEC column must be numeric' END   
   WHEN  ifd.FieldName = 'SETUPSEC' THEN   
       CASE   
      WHEN (impt.SETUPSEC <> '' AND ISNUMERIC(impt.SETUPSEC)=1)  THEN ''   
      ELSE  'SETUPSEC column must be numeric' END                 
     ELSE '' END,  
  
  [Status] =   
  CASE       
   WHEN  ifd.FieldName = 'DEPT_ID' THEN   
    CASE   
        WHEN (dept.DEPT_ID IS NULL)  THEN 'i05red' --impt.DEPT_ID <> '' AND  
        ELSE  '' END    
   WHEN  ifd.FieldName = 'NUMBER' THEN   
       CASE   
         WHEN (impt.NUMBER <> ''AND ISNUMERIC(impt.NUMBER)=1)  THEN ''   
         ELSE  'i05red' END  
   WHEN  ifd.FieldName = 'RUNTIMESEC' THEN   
       CASE   
         WHEN (impt.RUNTIMESEC <> ''AND ISNUMERIC(impt.RUNTIMESEC)=1)  THEN ''   
         ELSE  'i05red' END   
      WHEN  ifd.FieldName = 'SETUPSEC' THEN   
       CASE   
         WHEN (impt.SETUPSEC <> ''AND ISNUMERIC(impt.SETUPSEC)=1)  THEN ''   
         ELSE  'i05red' END         
  ELSE '' END   
 --select *  
  FROM importRoutingFields f   
  JOIN ImportFieldDefinitions ifd  on f.FKFieldDefId =ifd.FieldDefId AND ModuleId = @ModuleId   
  JOIN importRoutingAssemblyInfo ai  on f.FKImportTemplateId =ai.ImportTemplateId  
  JOIN importRoutingHeader h  on f.FkImportId =h.ImportId  
  LEFT JOIN @ImportDetail impt on f.RowId = impt.RowId  
  OUTER APPLY (  
   SELECT TOP 1 DEPT_ID   
   FROM DEPTS d   
   WHERE  RTRIM(LTRIM(d.DEPT_ID)) = CASE WHEN RTRIM(LTRIM(impt.DEPT_ID)) = ''   
                               THEN RTRIM(LTRIM(d.DEPT_ID))  
                               ELSE RTRIM(LTRIM(impt.DEPT_ID))  
          END    
  ) dept   
  WHERE (@RowId IS NULL OR f.RowId=@RowId)   
END