-- ====================================================================  
-- Create By   : Satyawan H.  
-- Description : Get inventor UDF upload Headers grid info  
-- Date     : 06/12/2019  
-- ====================================================================  
--EXEC GetInventorUdfHeaders @filter=N'',@sortExpression=N'',@startRecord=1,@endRecord=150

CREATE PROC GetInventorUdfHeaders  
 @filter NVARCHAR(1000) = null,  
 @sortExpression NVARCHAR(1000) = null,     
 @startRecord INT =1,  
 @endRecord INT =150  
AS  
BEGIN   
 DECLARE @sqlQuery NVARCHAR(MAX),@rowCount NVARCHAR(MAX)  
    
 IF OBJECT_ID(N'tempdb..#TEMP') IS NOT NULL  
  DROP TABLE #TEMP ;

  SELECT h.ImportId,h.UserId,u.UserName Username, h.ImportDt,h.[FileName],
  		 cu.UserName CompleteBy,h.CompleteBy CompleteById,h.CompleteDt,
  		 h.[Status],h.Validated,0 IsChecked--,ISNULL(total.TotalParts,0) TotalParts 
  INTO #TEMP  
	FROM ImportInventorUdfHeader h
	JOIN aspnet_Users u ON h.UserId = u.UserId 
	OUTER APPLY (
  		SELECT TOP 1 UserName FROM aspnet_Users WHERE UserId = h.CompleteBy
	) cu 
	--OUTER APPLY (
 -- 		SELECT (COUNT(f.rowid) / 15) TotalParts FROM ImportInventorUdfFields f
 -- 		WHERE f.FkImportId = h.ImportId
 -- 		GROUP BY f.FkImportId 
	--) total
  WHERE h.CompleteBy IS NULL AND h.CompleteDt IS NULL
  
 SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('select * from #TEMP',@filter,  
     @sortExpression,N'','ImportId',@startRecord,@endRecord))         
    EXEC sp_executesql @rowCount      
  
 SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('select * from #TEMP',@filter,  
     @sortExpression,N'ImportDt','',@startRecord,@endRecord))    
 EXEC sp_executesql @sqlQuery   
 
END