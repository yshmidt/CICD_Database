
-- =============================================  
-- Author:  Shrikant B  
-- Create date: 01/19/
-- Description: Get latest newly Inserted bomI Components Item No  
-- sp_getLatestBOMIComponetsItemsNo '41827b03-c779-45ad-b25f-ba7bfa1c57e1'
-- =============================================  
CREATE PROCEDURE [dbo].[sp_getLatestBOMIComponetsItemsNo]     
 @importId uniqueidentifier = null

AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
 DECLARE @SQL AS NVARCHAR(MAX)

 SELECT @SQL = N';WITH data AS(select CASE WHEN ibf.adjusted='''' THEN 0 ELSE ibf.adjusted END AS ItemNo FROM importBOMFieldDefinitions ibfd   
               JOIN importBOMFields ibf  on(ibfd.fieldDefId = ibf.fkFieldDefId)   
               JOIN importBOMHeader ibh on (ibf.fkImportId = ibh.importId)  
				WHERE ibf.fkImportId='''+ CAST(@importId AS CHAR(36))+''' and fieldName=''itemno'')
				SELECT TOP 1 MAX (itemno) AS ItemNo FROM data GROUP BY itemno 
				ORDER BY CAST(ISNULL(itemno,0)AS INT) DESC'
 --SELECT @SQL  
   EXEC sp_executesql  @SQL

END 