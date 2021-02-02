-- =================================================================================================            
-- Author  : Satyawan H.        
-- Create date : 03/26/2019          
-- Description : Pivots import items into an ImportUDFFields table          
-- 06/05/2019 Satyawan H: Added @isPartImport parameter for part Import to ignore UDF fields if true         
-- 06/30/2020 Satyawan H: Changed to get invalid UDF's instead of valid UDF's  
-- 08/17/2020 Satyawan H: Added rowId condition to validate the UDF on line item row by row for TotalUDFs and invalidUDFs
-- =================================================================================================            
-- [sp_getImportedInventorUDFs] @ImportId = '878F9DE9-F945-4AD7-A272-36263FDC4FB5', @RowId = 'FC16F227-CAC4-42C8-91EC-80B96B9FB387',@isPartValid=1        
  
CREATE PROCEDURE [dbo].[sp_getImportedInventorUDFs]          
   @importId uniqueidentifier = null        
  ,@lSourceFields bit = 0        
  ,@SourceTable varchar(50) = NULL        
  ,@getOriginal bit = 0        
  ,@rowId uniqueidentifier = null          
  ,@isPartValid bit = 0,       
   @GetImportRows bit = 0   
 /* @lSourceFields value options          
  0 = adjusted fields, 1 = alternate table field values          
 */          
AS          
BEGIN          
 SET NOCOUNT ON;          
  
 -- Insert statements for procedure here          
 DECLARE @FieldName varchar(max),  @SQL nvarchar(max), @UDFFields nvarchar(max), @UDFSQL varchar(MAX), @ModuleId int, @UFieldName nvarchar(max)        
        
 SELECT @ModuleId = ModuleId from MnxModule where ModuleName = 'InventorUDFUpload' and FilePath = 'InventorUDFUpload'        
       
  SELECT @FieldName =          
  STUFF(          
 (          
     select  ',[' +  CASE WHEN @lSourceFields=0 THEN F.FIELDNAME ELSE F.sourceFieldName END  + ']'          
  from ImportFieldDefinitions F            
  where 1=CASE WHEN @lSourceFields=0 THEN 1           
   WHEN (F.sourceFieldName=' ') THEN 0 ELSE 1 END           
   and sourceTableName = CASE WHEN @SourceTable IS NULL THEN sourceTableName          
    Else @SourceTable END And ModuleId = @ModuleId         
  ORDER BY CASE WHEN @lSourceFields=0 THEN F.FIELDNAME ELSE F.sourceFieldName END            
            
  for xml path('')          
 ),          
 1,1,'')           
  
 -- 06/30/2020 Satyawan H: Changed to get invalid UDF's instead of valid UDF's  
 -- 08/17/2020 Satyawan H: Added rowId condition to validate the UDF on line item row by row for TotalUDFs and invalidUDFs
SET @SQL =   
 CASE WHEN @GetImportRows = 1 THEN   
 N'SELECT ROW_NUMBER() OVER(order by rowId) Id, pvt.rowId RowId,pvt.CssClass as CssClass,Pvt.invalidUDFs,Pvt.IsImported'  
 ELSE  
 N'SELECT pvt.*,c.CUSTNAME,PartDesc.Part_Desc'  
 END +  
 ' FROM          
    (  
  SELECT ibf.fkImportId AS importId,ibf.rowId,sub.class as CssClass,sub.Validation,fd.fieldName,adjusted,invalidUDFs.invalidUDFs,TotalUDFs.TotalUDFs'          
      +' FROM ImportFieldDefinitions fd            
      INNER JOIN ImportInventorUdfFields ibf ON fd.FieldName = ibf.FieldName         
   Outer APPLY (        
   select Top 1 CASE WHEN (count(FkImportId) > 0) THEN 1 ELSE 0 END TotalUDFs         
   from ImportInventorUdfFields i         
   WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+''' AND i.RowId =  ibf.RowId          
   AND FieldName NOT IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+',''UDF'')        
   AND i.rowid= ibf.rowid        
   ) TotalUDFs    
   Outer APPLY (        
   select Top 1 CASE WHEN (count(FkImportId) > 0  OR TotalUDFs.TotalUDFs =0) THEN 1 ELSE 0 END invalidUDFs         
   from ImportInventorUdfFields i         
   WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+''' AND i.RowId =  ibf.RowId       
   AND FieldName NOT IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+',''UDF'')        
   AND Status = ''i05red'' OR Status = ''i04orange''        
   --AND Status = ''i00white'' OR Status = ''i04orange''        
   AND i.rowid= ibf.rowid        
   ) invalidUDFs      
      INNER JOIN ImportInventorUdfHeader h ON h.ImportId = ibf.FkImportId    
      INNER JOIN (SELECT fkImportId,rowid,MAX(status) as Class ,MIN(validation) as Validation          
    FROM ImportInventorUdfFields WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''          
   AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')        
          GROUP BY fkImportId,rowid) Sub          
      ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid          
      WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''           
     ) st          
   PIVOT (MAX(adjusted) FOR fieldName'+         
   ' IN ('+ @FieldName +')) as PVT   
    LEFT JOIN CUSTOMER c ON c.CUSTNO = PVT.CUSTNO        
     OUTER APPLY   
  (   
   SELECT TOP 1 TRIM(PART_CLASS) + CASE WHEN PART_TYPE = '''' THEN '''' ELSE ''/'' + TRIM(PART_TYPE) END Part_Desc  
   FROM INVENTOR I WHERE   
   TRIM(PART_NO) = CASE WHEN TRIM(Pvt.PART_NO) = '''' THEN TRIM(I.PART_NO) ELSE TRIM(Pvt.PART_NO) END AND  
   TRIM(REVISION) = CASE WHEN TRIM(Pvt.REVISION) = '''' THEN TRIM(I.REVISION) ELSE TRIM(Pvt.REVISION) END AND  
   TRIM(CUSTNO) = CASE WHEN TRIM(Pvt.CUSTNO) = '''' THEN TRIM(I.CUSTNO) ELSE TRIM(Pvt.CUSTNO) END AND  
   TRIM(CUSTPARTNO) = CASE WHEN TRIM(Pvt.CUSTPARTNO) = '''' THEN TRIM(I.CUSTPARTNO) ELSE TRIM(Pvt.CUSTPARTNO) END  
  ) PartDesc   
    ORDER BY [part_no],[revision]'       
   
 IF(@rowId is NOT NULL AND @isPartValid=0)         
 BEGIN        
  SELECT @UFieldName =          
    STUFF(          
   (          
  SELECT  ',[' +  FieldName  + ']'          
  FROM ImportInventorUdfFields F            
  WHERE RowId = @rowId and FkImportId = @importId         
  FOR XML PATH('')          
   ),          
   1,1,'')         
        
  -- 06/05/2019 Satyawan H: Added @isPartImport parameter for part Import to ignore UDF fields if true     
  SELECT @SQL = N'SELECT pvt.*,c.CUSTNAME,PartDesc.Part_DESC FROM          
    (SELECT ibf.fkImportId AS importId,ibf.rowId,sub.class as CssClass,sub.Validation,ibf.fieldName,adjusted'          
      +' FROM ImportFieldDefinitions fd            
      INNER JOIN ImportInventorUdfFields ibf ON fd.FieldName <> ibf.FieldName         
      INNER JOIN ImportInventorUdfHeader h ON h.ImportId = ibf.FkImportId         
      INNER JOIN (SELECT fkImportId,rowid,MAX(status) as Class ,MIN(validation) as Validation          
      FROM ImportInventorUdfFields WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''          
       GROUP BY fkImportId,rowid) Sub          
      ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid          
      WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''           
      AND 1='+ CASE WHEN NOT @rowId IS NULL THEN          
       'CASE WHEN '''+ CAST(@rowId as CHAR(36))+'''=ibf.rowId THEN 1 ELSE 0  END'          
       ELSE '1' END+'          
     ) st          
      PIVOT (MAX(adjusted) FOR fieldName IN ('+  @UFieldName +')) as PVT         
      LEFT JOIN CUSTOMER c ON c.CUSTNO = PVT.CUSTNO        
    OUTER APPLY   
  (   
   SELECT TOP 1 TRIM(PART_CLASS) + CASE WHEN PART_TYPE = '''' THEN '''' ELSE ''/'' + TRIM(PART_TYPE) END Part_Desc  
   FROM INVENTOR I WHERE   
   TRIM(PART_NO) = CASE WHEN TRIM(Pvt.PART_NO) = '''' THEN TRIM(I.PART_NO) ELSE TRIM(Pvt.PART_NO) END AND  
   TRIM(REVISION) = CASE WHEN TRIM(Pvt.REVISION) = '''' THEN TRIM(I.REVISION) ELSE TRIM(Pvt.REVISION) END AND  
   TRIM(CUSTNO) = CASE WHEN TRIM(Pvt.CUSTNO) = '''' THEN TRIM(I.CUSTNO) ELSE TRIM(Pvt.CUSTNO) END AND  
   TRIM(CUSTPARTNO) = CASE WHEN TRIM(Pvt.CUSTPARTNO) = '''' THEN TRIM(I.CUSTPARTNO) ELSE TRIM(Pvt.CUSTPARTNO) END  
  ) PartDesc  
      ORDER BY [part_no],[revision]'        
  END         
 EXEC sp_executesql @SQL            
END 