  
-- =============================================  
-- Author: ShivShankar P  
-- Create date: 02/20/2018  
-- Description: this procedure will get ImportInvtFields and Its values  
-- [GetImportInvtItems] '65986CF6-002F-4874-ADC7-38410CB595F4',0,'',null,'u_of_meas,warehouse,part_no,revision,Warehouse,Location,w_key,uniq_key,AccountNo'  
-- [GetImportInvtItems] '65986CF6-002F-4874-ADC7-38410CB595F4',@filterValue='000-0003131',0,'',null,'u_of_meas,warehouse,part_no,revision,Warehouse,Location,w_key,uniq_key,AccountNo'  
-- 03/06/2018 Shivshanker P Add join with InvtImportHeader table  
-- 03/08/2018 Shivshanker P Filter like  
-- 03/23/2018 Shivshanker P : Sheet and sheet 3 columns 
-- 09/04/2018 Rajendra K : Updated script to get records for only Invenotry Upload model   
-- 10/30/2018 Mahesh B: Getting the information on basis of the Module Id   
-- 12/06/2018 Nitesh B: Sorting the result on basis of part_no, revision, partmfgr, mfgr_pt_no, warehouse, lotcode 
-- 01/03/2018 Mahesh B: Added the new column IsUploaded for Partial Upload Functinality 
-- =============================================  
CREATE PROCEDURE [dbo].[GetImportInvtItems]   
 --@sourceTable could have multiple tablename separated with comma, like 'Inventor,Invtmfgr'  
 @importId UNIQUEIDENTIFIER = null,@lSourceFields BIT = 0,@SourceTable VARCHAR(50) = NULL,  
 @rowId UNIQUEIDENTIFIER = null,@columnsList VARCHAR(MAX) = NULL  ,@filterValue VARCHAR(100) = NULL  
 /* @lSourceFields value options  
  0 = adjusted fields  
  1 = alternate table field values  
 */  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
 DECLARE @FieldName VARCHAR(MAX),@SQL as NVARCHAR(MAX),@SQLQuery NVARCHAR(2000);  
 DECLARE @ModuleId INT = (SELECT ModuleId FROM MnxModule WHERE ModuleName = 'Upload' AND ModuleDesc = 'MnxM_Upload')  
   
 IF(ISNULL(@columnsList,'') = '')  
  SELECT @FieldName =  
  STUFF(  
 (  
     SELECT  ',[' +  CASE WHEN @lSourceFields=0 THEN F.FIELDNAME ELSE F.sourceFieldName END  + ']'  
  FROM ImportFieldDefinitions F  -- 10/30/2018 Mahesh B: Getting the information on basis of the Module Id   
  WHERE moduleid =@ModuleId  AND (f.SheetNo=1  OR f.SheetNo=3) AND 1=CASE WHEN @lSourceFields=0   -- 03/23/2018 Shivshanker P : Sheet and sheet 3 columns  
    
          AND (f.SheetNo=1 OR f.SheetNo=3)  THEN 1   
   WHEN ModuleId = @ModuleId AND (F.sourceFieldName=' ') THEN 0 ELSE 1 END -- Added @ModuleId in where clause to get records for only Invenotry Upload model   
   AND sourceTableName = CASE WHEN @SourceTable IS NULL THEN sourceTableName  
    ELSE @SourceTable END   
    AND (@columnsList IS NOT NULL AND  F.FIELDNAME  IN   
                 (select id from dbo.[fn_simpleVarcharlistToTable](@columnsList,','))   
                  OR   ((@columnsList = ' '   OR  @columnsList IS NULL)  AND   F.FIELDNAME =  F.FIELDNAME ))   
               AND ModuleId =@ModuleId  
  ORDER BY CASE WHEN @lSourceFields=0 THEN F.FIELDNAME ELSE F.sourceFieldName END      
  FOR XML PATH('')  
 ),  
 1,1,'')   
 ELSE  
   SET @FieldName = @columnsList  
  
   IF(ISNULL(@filterValue,'') = '')  
   BEGIN  
         -- 06/03/2018 Shivshanker P Add join with InvtImportHeader table  
   -- 03/23/2018 Shivshanker P : Sheet and sheet 3 columns  
   -- 01/03/2018 Mahesh B: Added the new column IsUploaded for Partial Upload Functinality 
   SELECT @SQL = N'  
   SELECT *  
    FROM  
    (SELECT ibf.fkImportId AS importId,ibf.rowId,sub.class as CssClass,sub.Validation,'+   
      CASE WHEN @lSourceFields=0 THEN 'fd.fieldName' ELSE 'fd.sourceFieldName' END +', adjusted'  
      +' FROM ImportFieldDefinitions fd   
      INNER JOIN ImportInvtFields ibf ON fd.fieldDefId = ibf.fkFieldDefId AND (fd.SheetNo=''1'' OR fd.SheetNo=''3'')  
      INNER JOIN InvtImportHeader h ON h.InvtImportId = ibf.FkImportId AND ibf.IsUploaded=''0'' AND h.ImportComplete=''0'' 
      INNER JOIN (SELECT fkImportId,rowid,MAX(status) as Class ,MIN(validation) as Validation  
         FROM ImportInvtFields WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''  
          GROUP BY fkImportId,rowid) Sub  
      ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid  
      WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''   
      AND 1='+ CASE WHEN NOT @rowId IS NULL THEN  
       'CASE WHEN '''+ CAST(@rowId as CHAR(36))+'''=ibf.rowId THEN 1 ELSE 0  END'  
       ELSE '1' END+'  
     ) st  
			PIVOT (MAX(adjusted) FOR ' +CASE WHEN @lSourceFields=0 THEN 'fieldName' ELSE 'sourceFieldName' END +' IN ('+@FieldName+')) as PVT
			ORDER BY [part_no],[revision],[partmfgr],[mfgr_pt_no],[warehouse],[lotcode]'
			-- 12/06/2018 Nitesh B : Sorting the result on basis of part_no, revision, partmfgr, mfgr_pt_no, warehouse, lotcode
   EXEC SP_EXECUTESQL @SQL    
   END  
  
   ELSE IF(ISNULL(@filterValue,'') <> '')  
   BEGIN  
   SELECT @SQL = N'  
   SELECT *  
    FROM  
    (SELECT ibf.fkImportId AS importId,ibf.rowId,sub.class as CssClass,sub.Validation,'+   
      CASE WHEN @lSourceFields=0 THEN 'fd.fieldName' ELSE 'fd.sourceFieldName' END +', adjusted'  
      +' FROM ImportFieldDefinitions fd   
      INNER JOIN ImportInvtFields ibf ON fd.fieldDefId = ibf.fkFieldDefId AND (fd.SheetNo=''1''  OR fd.SheetNo=''3'')  
      INNER JOIN InvtImportHeader h ON h.InvtImportId = ibf.FkImportId AND ibf.IsUploaded =''0'' AND h.ImportComplete=''0''  
      INNER JOIN (SELECT fkImportId,rowid,MAX(status) as Class ,MIN(validation) as Validation  
         FROM ImportInvtFields WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''  
           AND adjusted LIKE ''%'+ CAST(@filterValue AS VARCHAR(100))+'%''  
          GROUP BY fkImportId,rowid) Sub  
      ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid  
      WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''   
      AND 1='+ CASE WHEN NOT @rowId IS NULL THEN  
       'CASE WHEN '''+ CAST(@rowId as CHAR(36))+'''=ibf.rowId THEN 1 ELSE 0  END'  
       ELSE '1' END+'  
     ) st  
			PIVOT (MAX(adjusted) FOR ' +CASE WHEN @lSourceFields=0 THEN 'fieldName' ELSE 'sourceFieldName' END +' IN ('+@FieldName+')) as PVT
			ORDER BY [part_no],[revision],[partmfgr],[mfgr_pt_no],[warehouse],[lotcode]'
			-- 12/06/2018 Nitesh B : Sorting the result on basis of part_no, revision, partmfgr, mfgr_pt_no, warehouse, lotcode
   EXEC SP_EXECUTESQL @SQL    
   END  
END