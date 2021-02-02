-- =============================================  
-- Author:  Satyawan H.  
-- Create date: 05/20/2019  
-- Description: Get current errors for selected importId for inventor UDF Upload  
-- EXEC InventorUDFUploadErrorGet '563c9865-c0c3-4b41-95da-009f716a8f19'  
-- =============================================  
  
CREATE PROCEDURE [dbo].[InventorUDFUploadErrorGet]   
 -- Add the parameters for the stored procedure here  
 @importId uniqueidentifier  
AS  
BEGIN  
 SET NOCOUNT ON;  
 DECLARE @ModuleId int   
  
 SELECT @ModuleId = ModuleId FROM MnxModule   
  WHERE ModuleName LIKE 'InventorUDFUpload' and FilePath = 'InventorUDFUpload'  
  
 SELECT f.rowId,fd.fieldName,f.message AS title, f.status AS class   
  FROM ImportInventorUdfFields f   
    INNER JOIN importFieldDefinitions fd ON f.FieldName = fd.FieldName AND fd.fieldLength > 0 and ModuleId = @ModuleId   
  WHERE fkImportId= @importId  
END