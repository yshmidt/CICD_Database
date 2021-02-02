-- =============================================            
-- Author:  Satish B            
-- Create date:  5/29/2018            
-- Description: Pivots import items into an import PO table            
-- Modified : Satish B: 05/15/2019 apply order by clause for display record order by item-no            
-- Modified : Vijay B: 07/12/2019 Remove header level column from resut set       
-- exec GetImportPOItems 'f7a45d8a-1eef-4814-8f7f-34121ef35bc2','7397'       
-- =============================================            
CREATE PROCEDURE [dbo].[GetImportPOItems]             
	@importId uniqueidentifier = null
   ,@moduleId char(10) = ''            
   ,@rowId uniqueidentifier = null            
   ,@lSourceFields bit = 0            
   ,@sourceTable varchar(50) = NULL            
   ,@getOriginal bit = 0            
             
AS            
BEGIN            
 SET NOCOUNT ON;            
 DECLARE @FieldName varchar(max),@SQL as nvarchar(max) ,@SQLQuery NVARCHAR(MAX)            
  SELECT @FieldName =            
  STUFF(            
 (            
     SELECT  ',[' +  CASE WHEN @lSourceFields=0 THEN F.FIELDNAME ELSE F.sourceFieldName END  + ']'            
  FROM ImportFieldDefinitions F              
  WHERE 1=CASE WHEN @lSourceFields=0 THEN 1             
      WHEN (F.sourceFieldName=' ') THEN 0 ELSE 1 END             
    AND sourceTableName = CASE WHEN @sourceTable IS NULL THEN sourceTableName Else @sourceTable END             
    AND f.moduleId=@moduleId      
--Comment  
 AND F.FieldName NOT In ('PONUM','SUPNAME','BUYER','PRIORITY','SHIPCHARGE','FOB','SHIPVIA')          
  ORDER BY CASE WHEN @lSourceFields=0 THEN F.FIELDNAME ELSE F.sourceFieldName END              
  FOR XML PATH('')            
 ),            
 1,1,'')            
 -- Modified : Vijay B: 07/12/2019 Remove header level column from resut set            
 SELECT @SQL = N'  
  --comment            
 SELECT *, CAST(PVT.ORD_QTY  AS DECIMAL(10, 2)) AS ORD_QTYF, CAST(REPLACE(PVT.COSTEACH,''Error'','''')  AS DECIMAL(13, 5)) AS COST_EACHF           
  FROM            
  (SELECT ipd.fkPOImportId AS ImportId,ipd.RowId,sub.class as CssClass,sub.Validation,ipd.UniqLnNo AS UniqLnNo,'+             
    CASE WHEN @lSourceFields=0 THEN 'pfd.fieldName' ELSE 'pfd.sourceFieldName' END +', '+            
    CASE WHEN @getOriginal=1 THEN 'RTRIM(LTRIM(ipd.original))AS original' ELSE 'RTRIM(LTRIM(REPLACE(ipd.adjusted,''Error'','''')))AS adjusted' END +            
   ' FROM ImportFieldDefinitions pfd     
 INNER JOIN ImportPODetails ipd ON pfd.FieldDefId = ipd.fkFieldDefId     
 and pfd.FieldName NOT In (''PONUM'',''SUPNAME'',''BUYER'',''PRIORITY'',''SHIPCHARGE'',''FOB'',''SHIPVIA'')             
    INNER JOIN     
 (    
  SELECT fkPOImportId,rowid,MAX(status) as Class ,MIN(validation) as Validation           
  FROM ImportPODetails pd    
  INNER JOIN ImportFieldDefinitions ipd ON ipd.FieldDefId = pd.fkFieldDefId     
  WHERE fkPOImportId ='''+ cast(@importId as CHAR(36))+'''     
  AND ipd.FieldName NOT In (''PONUM'',''SUPNAME'',''BUYER'',''PRIORITY'',''SHIPCHARGE'',''FOB'',''SHIPVIA'')    
  GROUP BY fkPOImportId,rowid    
 ) Sub            
      ON ipd.fkPOImportId=Sub.fkPOImportId and ipd.rowid=sub.rowid         
   WHERE ipd.fkPOImportId ='''+ cast(@importId as CHAR(36))+''' AND pfd.ModuleId='''+ cast(@moduleId as CHAR(10))+'''            
    AND 1='+ CASE WHEN NOT @rowId IS NULL THEN            
     'CASE WHEN '''+ cast(@rowId as CHAR(36))+'''=ipd.rowId THEN 1 ELSE 0  END'            
     ELSE '1' END+'            
   ) st             
 PIVOT            
  (            
  MAX('+CASE WHEN @getOriginal=1 THEN 'original' ELSE 'adjusted' END+') FOR '+CASE WHEN @lSourceFields=0 THEN 'fieldName' ELSE 'sourceFieldName' END +' IN ('+@FieldName+')) as PVT'                 
  --Satish B: 05/15/2019 apply order by clause for display record order by item-no            
   SET @SQLQuery = 'SELECT * FROM('+@SQL+')a  ORDER BY cast(ITEMNO AS INT)'            

   exec sp_executesql @SQLQuery              
END 