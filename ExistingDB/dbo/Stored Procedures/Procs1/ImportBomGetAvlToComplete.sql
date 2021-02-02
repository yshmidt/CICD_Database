-- =============================================    
-- Author:  Yelena Shmidt    
-- Create date: 05/06/2013    
-- Description: Get AVL information to complete BOM import    
-- use sourceTable and sourceFieldName to get AVL information to load    
--  05/16/13 added [Bom] and [Load] columns     
-- 07/02/2013 YS make sure all [load] are in []     
-- Vijay G: 03/15/2018: Removed INVTMFHD table and replaced with MfgrMaster, invtmpnlink  
-- Sachin B 01/07/2021 Add the Location Column in the Select Statement  
-- [ImportBomGetAvlToComplete] '1c95a3c8-4432-48e7-9f5a-f0b2d21a66d6'  
-- =============================================    
CREATE PROCEDURE [dbo].[ImportBomGetAvlToComplete]     
 -- Add the parameters for the stored procedure here    
 @importID uniqueidentifier = null     
        
AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
    
    -- Insert statements for procedure here    
 DECLARE @FieldName varchar(max),@SQL as nvarchar(max)    
     
  SELECT @FieldName =    
  STUFF(    
 (    
     select  ',[' +  F.sourceFieldName  + ']'    
  from importBOMFieldDefinitions F      
  where sourceTableName = 'MfgrMaster'  -- Vijay G: 03/15/2018: Removed INVTMFHD table and replaced with MfgrMaster, invtmpnlink    
  ORDER BY F.sourceFieldName       
  for xml path('')    
 ),    
 1,1,'')    
     
 --SELECT  @FieldName    
 --05/16/13 added [Bom] and [Load] columns   
 -- Sachin B 01/07/2021 Add the Location Column in the Select Statement  
 SELECT @SQL = N'    
 SELECT *    
  FROM    
  (SELECT iba.fkImportId AS importId,iba.fkRowId as rowId,iba.AvlRowId,sub.class,sub.Validation,CAST('' '' as char(10)) as UniqWh,CAST('' '' as char(10)) as Uniq_key,UniqMfgrhd,iba.Bom,iba.[Load],'+    
   'fd.sourceFieldName'+',iba.adjusted,'''' as location    
     FROM importBOMFieldDefinitions fd INNER JOIN importBOMAvl ibA ON fd.fieldDefId = iba.fkFieldDefId    
     INNER JOIN (SELECT fkImportId,fkRowId,AvlRowId,MAX(status) as Class ,MIN(validation) as Validation      
      from importBOMAvl where fkImportId ='''+ cast(@importId as CHAR(36))+''' group by fkImportId,fkrowid,AvlRowId) Sub    
      ON iba.fkImportid=Sub.FkImportId and iba.Fkrowid=sub.fkrowid and iba.AvlRowid=sub.AvlRowId    
   WHERE iba.fkImportId ='''+ cast(@importId as CHAR(36))+''' ) st    
 PIVOT    
  (    
  MAX(adjusted) FOR '+'sourceFieldName' +' IN ('+@FieldName+')) as PVT'    
      
 --SELECT @SQL    
 exec sp_executesql @SQL      
END 