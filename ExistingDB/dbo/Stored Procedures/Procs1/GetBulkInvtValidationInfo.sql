
-- =============================================
-- Author:		Mahesh B.	
-- Create date: 09/10/2018 
-- Description:	Get the data on basis of the Import Id.
-- exec GetBulkInvtValidationInfo 'A1F5C13D-8295-440B-9056-F3B2B31CA9C1',0,null,null,null,null
-- =============================================
CREATE PROCEDURE [dbo].[GetBulkInvtValidationInfo]
(
 @importId UNIQUEIDENTIFIER = NULL,
 @lSourceFields BIT = 0,
 @SourceTable VARCHAR(50) = NULL,  
 @rowId UNIQUEIDENTIFIER = NULL,
 @columnsList VARCHAR(MAX) = NULL  ,
 @filterValue VARCHAR(100) = NULL  
)
AS
BEGIN
SET NOCOUNT ON;	
   
   EXEC GetBulkInvtItems @importId,@lSourceFields,@SourceTable,@rowId,@columnsList,@filterValue

   SELECT DISTINCT imd.SourceFieldName, imd.FieldDefId, inf.RowId FROM ImportBulkInvtFields inf INNER JOIN ImportFieldDefinitions imd 
   ON inf.FkFieldDefId= imd.FieldDefId WHERE FkInvtImportId= @importId GROUP BY inf.RowId, imd.SourceFieldName, imd.FieldDefId 
    
END