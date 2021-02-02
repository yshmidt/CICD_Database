-- =============================================    
-- Author:  Vijay G    
-- Create date: 01/19/2019  
-- Description: Get latest newly Inserted bomI Components Item No    
-- GetLatestBOMIComponetsItemsNo '402ca31b-5e01-4fa6-992c-8eca1f2f0322'  
-- =============================================    
CREATE PROCEDURE [dbo].[GetLatestBOMIComponetsItemsNo]       
 @importId uniqueidentifier = null  
  
AS    
BEGIN   
 
 -- SET NOCOUNT ON added to prevent extra result sets from       
 SET NOCOUNT ON;    
  
;WITH BOMCompData AS
(
	SELECT CASE WHEN ibf.adjusted='' THEN 0 ELSE ibf.adjusted END AS ItemNo FROM importBOMFieldDefinitions ibfd     
    JOIN importBOMFields ibf  ON(ibfd.fieldDefId = ibf.fkFieldDefId)     
    JOIN importBOMHeader ibh ON (ibf.fkImportId = ibh.importId)    
	WHERE ibf.fkImportId=@importId AND fieldName='itemno'
)  
SELECT TOP 1 MAX (itemno) AS ItemNo 
FROM BOMCompData 
GROUP BY itemno   
ORDER BY CAST(ISNULL(itemno,0)AS INT) DESC  
  
END 