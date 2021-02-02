-- =============================================  
-- Author:  David Sharp  
-- Create date: 4/18/2012  
-- Description: add import detail  
-- 04/04/2019 Vijay G Fix the Issue After deleting the BOM Components the AVL and ref Des are not deleted
-- =============================================  
CREATE PROCEDURE [dbo].[importBOMRowDelete]  
 -- Add the parameters for the stored procedure here  
 @importId uniqueidentifier,@rowId uniqueidentifier  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
      
  DELETE FROM importBOMFields  
  WHERE rowId = @rowId AND fkImportId=@importId  
  
  -- 04/04/2019 Vijay G Fix the Issue After deleting the BOM Components the AVL and ref Des are not deleted 
  DELETE FROM [dbo].[importBOMAvl]  
  WHERE fkRowId = @rowId AND fkImportId=@importId  

  DELETE FROM [dbo].[importBOMRefDesg]  
  WHERE fkRowId = @rowId AND fkImportId=@importId  

END  