-- =============================================
-- Author:		Mahesh B.	
-- Create date: 09/10/2018 
-- Description:	Get the data on basis of the Import Id.
-- exec GetBulkInvtItems '607224C3-6ABF-4825-B85B-9284F9EA4A46'
-- =============================================
CREATE PROCEDURE [dbo].[GetBulkInvtItems]
(
 @importId UNIQUEIDENTIFIER = null,
 @lSourceFields BIT = 0,
 @SourceTable VARCHAR(50) = NULL,  
 @rowId UNIQUEIDENTIFIER = null,
 @columnsList VARCHAR(MAX) = NULL  ,
 @filterValue VARCHAR(100) = NULL  
)
AS
BEGIN
SET NOCOUNT ON;	
DECLARE @FieldName VARCHAR(MAX),@SQL as NVARCHAR(MAX),@SQLQuery NVARCHAR(2000); 
 DECLARE @ModuleId INT = (SELECT ModuleId FROM MnxModule WHERE ModuleName = 'Part Master &  AML Control (PM)' AND ModuleDesc = 'MnxM_PartMasterAMLControl')  
 
 SELECT @FieldName =  
  STUFF((SELECT  ',[' +  CASE 
	                          WHEN @lSourceFields=0 THEN F.FIELDNAME 
						      ELSE F.sourceFieldName 
						 END  + ']'  
                         FROM ImportFieldDefinitions F  -- 10/30/2018 Mahesh B: Getting the information on basis of the Module Id   
                          WHERE moduleid =@ModuleId  
						  AND UploadType = 'BulkPartMasterPropertyUpdate'
						  AND (f.SheetNo=1) 
		                  AND (@columnsList IS NOT NULL AND  F.FIELDNAME  IN (SELECT id from dbo.[fn_simpleVarcharlistToTable](@columnsList,','))   
                               OR ((@columnsList = ' ' OR @columnsList IS NULL)  AND   F.FIELDNAME =  F.FIELDNAME ))   
                          ORDER BY 
						          CASE 
								      WHEN @lSourceFields=0 THEN F.FIELDNAME 
									  ELSE F.sourceFieldName 
									  END      
                          FOR XML PATH('')),1,1,'')   

 IF(ISNULL(@filterValue,'') = '')
  BEGIN
   SELECT @SQL = N'
     SELECT *   
     FROM  
       (SELECT ibf.FkInvtImportId AS importId,
	         ibf.rowId,
			 sub.class as CssClass,'+
			 CASE 
			     WHEN @lSourceFields=0 THEN 'fd.fieldName' 
				 ELSE 'fd.sourceFieldName' 
			 END +', adjusted'  
       +' FROM ImportFieldDefinitions fd   
	   INNER JOIN ImportBulkInvtFields ibf ON fd.fieldDefId = ibf.fkFieldDefId AND fd.SheetNo=''1''	 
	   INNER JOIN ImportBulkInvtHeader h ON h.InvtImportId = ibf.FkInvtImportId AND h.ImportComplete=''0'' 
       INNER JOIN (SELECT FkInvtImportId,
	                      rowid,
						  MAX(status) AS Class
						  FROM ImportBulkInvtFields 
						  WHERE FkInvtImportId = '''+CAST(@importId AS VARCHAR(36)) +'''  
                          GROUP BY FkInvtImportId,rowid) Sub  
                          ON ibf.FkInvtImportId=Sub.FkInvtImportId 
						  AND ibf.rowid=sub.rowid  
       WHERE ibf.FkInvtImportId ='''+ CAST(@importId as VARCHAR(36))+''' 
           AND 1= '+CASE WHEN NOT @rowId IS NULL THEN  
                                                 'CASE 
									                 WHEN '''+ CAST(@rowId as VARCHAR(36)) +'''=ibf.rowId THEN 1
										             ELSE 0 
									              END'  
                     ELSE '1' 
			     END+' GROUP BY ibf.FkInvtImportId,ibf.RowId,sub.class,adjusted,fd.FIELDNAME,fd.sourceFieldName) st 
	   PIVOT (MAX(adjusted) FOR '+ 
		                        CASE 
								    WHEN @lSourceFields=0 THEN 'fieldName' 
									ELSE 'sourceFieldName' 
								END +' IN ('+ @FieldName +')) as PVT'

   EXEC SP_EXECUTESQL @SQL    
 END		
ELSE IF(ISNULL(@filterValue,'') <> '')
 BEGIN
  SELECT @SQL = N'
     SELECT *   
     FROM  
       (SELECT ibf.FkInvtImportId AS importId,
	         ibf.rowId,
			 sub.class as CssClass,'+
			 CASE 
			     WHEN @lSourceFields=0 THEN 'fd.fieldName' 
				 ELSE 'fd.sourceFieldName' 
			 END +', adjusted'  
       +' FROM ImportFieldDefinitions fd   
	   INNER JOIN ImportBulkInvtFields ibf ON fd.fieldDefId = ibf.fkFieldDefId AND fd.SheetNo=''1''	 
	   INNER JOIN ImportBulkInvtHeader h ON h.InvtImportId = ibf.FkInvtImportId AND h.ImportComplete=''0'' 
       INNER JOIN (SELECT FkInvtImportId,
	                      rowid,
						  MAX(status) AS Class
						  FROM ImportBulkInvtFields 
						  WHERE FkInvtImportId = '''+CAST(@importId AS VARCHAR(36)) +'''
						  AND adjusted LIKE ''%'+ CAST(@filterValue AS VARCHAR(100))+'%''  
                          GROUP BY FkInvtImportId,rowid) Sub  
                          ON ibf.FkInvtImportId=Sub.FkInvtImportId 
						  AND ibf.rowid=sub.rowid  
        WHERE ibf.FkInvtImportId ='''+ CAST(@importId as VARCHAR(36))+''' 
         AND 1= '+CASE WHEN NOT @rowId IS NULL THEN  
                                                 'CASE 
									                 WHEN '''+ CAST(@rowId as VARCHAR(36)) +'''=ibf.rowId THEN 1
										             ELSE 0 
									              END'  
                     ELSE '1' 
			     END+' GROUP BY ibf.FkInvtImportId,ibf.RowId,sub.class,adjusted,fd.FIELDNAME,fd.sourceFieldName) st 
	   PIVOT (MAX(adjusted) FOR '+ 
		                        CASE 
								    WHEN @lSourceFields=0 THEN 'fieldName' 
									ELSE 'sourceFieldName' 
								END +' IN ('+ @FieldName +')) as PVT'

  EXEC SP_EXECUTESQL @SQL 
 END							   
END
