-- =============================================      
-- Author:Sachin B      
-- Create date: 09/26/2018      
-- Description: this procedure will be called from the ECO Module for getting Document List    
-- GetEWIDocumentList 'AA89ZKD45I',0,150,null,null    
-- =============================================      
      
CREATE PROCEDURE GetEWIDocumentList       
@uniqKey CHAR(10),        
@StartRecord INT =0,      
@EndRecord INT =150,       
@SortExpression CHAR(1000) = NULL,      
@Filter NVARCHAR(1000) = NULL      
      
AS      
SET NOCOUNT ON;       
      
DECLARE @sql NVARCHAR(MAX)      
    
DECLARE @ParentId CHAR(10) = (    
        SELECT TOP 1 fc.FileId FROM INVENTOR i    
        INNER JOIN WmFileRelationShips re ON i.UNIQ_KEY =re.RecordId AND RecordType ='EWIDocuments'    
        INNER JOIN WmFileCabinet fc ON re.fkFileId = fc.FileId  and fc.IsDeleted =0  
        WHERE i.UNIQ_KEY =@uniqKey    
        )    
    
SELECT DISTINCT FileId,DocNameAndNo,[Description],Revision,UploadDate IssueDate,ExpirationDate,UploadBy as UserId,    
LTRIM(RTRIM(pf.FirstName))+' ' +LTRIM(RTRIM(pf.LastName)) Coordinator    
INTO #TEMP     
FROM WmFileTree ft    
INNER JOIN WmFileCabinet wf ON ft.ChildId= wf.FileId    
INNER JOIN aspnet_Profile pf ON wf.UploadBy =pf.UserId    
WHERE ft.ParentId =@ParentId AND wf.IsDeleted =0    
     
      
IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL            
DROP TABLE dbo.#TEMP;        
     
IF @filter <> '' AND @sortExpression <> ''      
 BEGIN      
  SET @sql=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+CONVERT(VARCHAR,@sortExpression)+') AS RowNumber,*  from #TEMP )      
  select  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount       
  from CETTemp  t  WHERE '+@filter+' and RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)      
 END      
ELSE IF @filter = '' AND @sortExpression <> ''      
 BEGIN      
  SET @sql=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+CONVERT(VARCHAR,@sortExpression)+') AS RowNumber,*  from #TEMP )      
  select  t.*,(SELECT COUNT(RowNumber) FROM CETTemp ) AS TotalCount from CETTemp  t  WHERE       
  RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)      
 END      
ELSE IF @filter <> '' AND @sortExpression = ''      
 BEGIN      
  SET @sql=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY IssueDate Desc) AS RowNumber,*  from #TEMP )      
  select  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount from CETTemp  t  WHERE  '+@filter+' and      
  RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''      
 END      
ELSE      
 BEGIN      
  SET @sql=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY IssueDate Desc) AS RowNumber,*  from #TEMP )      
  select  t.*,(SELECT COUNT(RowNumber) FROM CETTemp) AS TotalCount from CETTemp  t  WHERE       
  RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''      
 END      
EXEC SP_EXECUTESQL @sql