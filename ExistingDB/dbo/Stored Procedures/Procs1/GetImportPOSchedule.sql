-- =============================================    
-- Author:  Satish B    
-- Create date:  5/30/2018    
-- Description: Pivots import items into an import PO schedule table    
-- exec GetImportPOSchedule '921afe62-eab7-4c76-b804-4e51833ab71e','7397','36f08ca5-09d6-e911-98e5-bbd6dd4a9401'    
-- Shivshankar P 9/11/2019 : Apply ORDER BY SCHDDATE for get PO Schedule in calendar order    
-- Modified  11/05/2019 Shiv P : Added '1900-01-01' this condition because SCHDDATE date is empty then it takes this default date    
-- Modified  11/29/2019 Nitesh B : Get GL_DESCR with GL Number when fieldName = 'GLNBR'    
-- =============================================    
CREATE PROCEDURE [dbo].[GetImportPOSchedule]     
 -- Add the parameters for the stored procedure here    
 @importId uniqueidentifier = null    
 ,@moduleId char(10) = ''    
 ,@rowId uniqueidentifier = null    
 ,@lSourceFields bit = 0    
 ,@sourceTable varchar(50) = NULL    
 ,@getOriginal bit = 0    
AS    
BEGIN    
 SET NOCOUNT ON;    
 DECLARE @FieldName varchar(max),@SQL as nvarchar(max)    
   
 SELECT @FieldName =    
  STUFF(    
  (    
   SELECT  ',[' +  CASE WHEN @lSourceFields=0 THEN F.FIELDNAME ELSE F.sourceFieldName END  + ']'    
   FROM ImportFieldDefinitions F      
   WHERE 1=CASE WHEN @lSourceFields=0 THEN 1     
   WHEN (F.sourceFieldName=' ') THEN 0 ELSE 1 END     
   AND sourceTableName = CASE WHEN @sourceTable IS NULL THEN sourceTableName Else @sourceTable END     
   AND f.moduleId=@moduleId AND f.FieldName   
   IN('SCHDDATE','ORIGCOMMITDT','SCHDQTY','WAREHOUSE','LOCATION','WOPRJNUMBER','REQUESTTP','REQUESTOR','GLNBR')      
   ORDER BY CASE WHEN @lSourceFields=0 THEN F.FIELDNAME ELSE F.sourceFieldName END      
   FOR XML PATH('')    
  ),    
  --Modified  11/05/2019 Shiv P : Added '1900-01-01' this condition because SCHDDATE date is empty then it takes this default date    
  --Modified  11/29/2019 Nitesh B : Get GL_DESCR with GL Number when fieldName = 'GLNBR'    
  1,1,'')    
    
 --select  @FieldName  
 SELECT *    
 FROM    
 (    
 SELECT ScheduleRowId,ips.fkPOImportId AS ImportId,ips.fkRowId,sub.class as CssClass,sub.Validation,ips.UniqDetNo,pfd.fieldName,     
     
 CASE WHEN RTRIM(LTRIM(ips.adjusted)) ='1900-01-01' THEN ''     
	WHEN pfd.fieldName = 'GLNBR' THEN 
		ISNULL((select (GL_NBR) + ' ( ' +(GL_DESCR)+ ' ) ' from GL_NBRS where GL_NBR = ips.adjusted),ips.adjusted) 
	ELSE RTRIM(LTRIM(ips.adjusted))      
 END AS adjusted     
     
 FROM ImportFieldDefinitions pfd INNER JOIN ImportPOSchedule ips ON pfd.FieldDefId = ips.fkFieldDefId      
 INNER JOIN (SELECT fkPOImportId,fkRowId,MAX(status) as Class ,MIN(validation) as Validation        
 FROM ImportPOSchedule WHERE fkPOImportId = @importId GROUP BY fkPOImportId,fkRowId) Sub      
 ON ips.fkPOImportId=Sub.fkPOImportId and ips.fkRowId=sub.fkRowId      
 WHERE ips.fkPOImportId =@importId AND (@rowId IS NULL OR ips.fkRowId = @rowId)    
 ) st    
 PIVOT    
 (    
 MAX(adjusted) FOR fieldName IN ([GLNBR],[LOCATION],[ORIGCOMMITDT],[WOPRJNUMBER],[REQUESTTP],[REQUESTOR],[SCHDDATE],[SCHDQTY],[WAREHOUSE])) as PVT     
 ORDER BY [SCHDDATE] -- Shivshankar P 9/11/2019 : Apply ORDER BY SCHDDATE for get PO Schedule in calendar order     
END    