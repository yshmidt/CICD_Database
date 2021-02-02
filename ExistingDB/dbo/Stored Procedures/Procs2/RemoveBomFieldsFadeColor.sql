-- =============================================  
-- Author:Vijay G  
-- Create date: 12/03/2018  
-- Description: This SP is Used for remove the fade color for itemno and PartType Fields
-- [RemoveBomFieldsFadeColor] '3723A134-71E1-48DE-BDF2-26F89298CC31'     
-- =============================================  
CREATE PROCEDURE [dbo].[RemoveBomFieldsFadeColor]   
 -- Add the parameters for the stored procedure here  
 @importId UNIQUEIDENTIFIER  
AS  
BEGIN  
SET NOCOUNT ON;  
  
  DECLARE @itemno VARCHAR(MAX),@partType VARCHAR(MAX),@white VARCHAR(20)='i00white'

  SELECT @itemno = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'itemno'
  SELECT @partType = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'partType'

  UPDATE importBOMFields SET [status] =@white
  WHERE fkImportId =@importId AND fkFieldDefId IN (@itemno,@partType)
  
END