-- =============================================      
-- Author:  Nitesh B       
-- Create date: <10/14/10>      
-- Description: <This procedure will gather all the records for sales price assembly> 
-- EXEC GetSalesPriceAssembly 'active' , 'Make', 1, 1500, '', ''      
-- =============================================      
CREATE PROCEDURE GetSalesPriceAssembly
 -- Add the parameters for the stored procedure here      
 @MfgrStatus char(10)=' ',   
 @PartSource char(10)=' ', 
 @startRecord INT = 1,    
 @endRecord INT = 150,  
 @sortExpression NVARCHAR(1000) = NULL,
 @filter NVARCHAR(1000) = NULL  
AS      
BEGIN      
 -- SET NOCOUNT ON added to prevent extra result sets from      
 -- interfering with SELECT statements.      
 SET NOCOUNT ON;   
 DECLARE @SQL nvarchar(MAX),@rowCount NVARCHAR(MAX); 
 
    IF OBJECT_ID ('tempdb.dbo.#tempData') IS NOT NULL        
                    DROP TABLE #tempData 
  
  IF(@sortExpression = NULL OR @sortExpression = '')  
 BEGIN  
  SET @sortExpression = 'PART_NO asc'  
 END  
     
   CREATE TABLE #tempData ( Uniq_Key CHAR(10), Part_No CHAR(100), Descript varchar(MAX), Status CHAR(8))      
       
INSERT INTO #tempData       
 SELECT DISTINCT inv.Uniq_Key, CASE WHEN (TRIM(inv.REVISION)) <> '' THEN  TRIM(inv.PART_NO)  + '/'+ TRIM(inv.REVISION) ELSE inv.PART_NO END AS Part_No,
 (RTRIM(inv.part_class) +' /'+ RTRIM(inv.part_type) + ' /' + RTRIM(inv.descript)) AS Descript, [Status] from INVENTOR inv
 LEFT JOIN WOENTRY on inv.UNIQ_KEY = WOENTRY.UNIQ_KEY 
 WHERE inv.[Status] = CASE WHEN @MfgrStatus = 'ALL' THEN inv.[STATUS] ELSE @MfgrStatus END AND inv.PART_SOURC = @PartSource
  
SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempData',@filter,@sortExpression,'','PART_NO',@startRecord,@endRecord))           
      EXEC sp_executesql @rowCount        
  
SET @SQL =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #tempData',@filter,@sortExpression,N'PART_NO','',@startRecord,@endRecord))      
   EXEC sp_executesql @SQL      
      
END