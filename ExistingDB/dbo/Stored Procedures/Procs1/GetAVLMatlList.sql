
-- ==========================================================================================    
-- Author:  <Sanjay B>    
-- Create date: <01/18/2019>    
-- Description: Get AVL Matl Type List 
-- exec [GetAVLMatlList] 0,150,'',''  
-- ==========================================================================================    
CREATE PROCEDURE [dbo].[GetAVLMatlList]    
    --DECLARE    
    @startRecord INT = 0,    
    @endRecord INT = 150,     
    @sortExpression NVARCHAR(1000) = NULL,  
    @filter NVARCHAR(1000) = NULL  
AS    
BEGIN    
 SET NOCOUNT ON;    
 DECLARE @SQL nvarchar(MAX);  
  
 DECLARE @avlMatlTpList TABLE(Uqavlmattp CHAR(20),Avlmatltype CHAR(35),Avlmatltypedesc CHAR(50));  
  
 IF(@sortExpression = NULL OR @sortExpression = '')  
 BEGIN  
 SET @sortExpression = 'Avlmatltype asc'  
 END  
    
 BEGIN  
  INSERT INTO @avlMatlTpList  
  SELECT LTRIM(Uqavlmattp),LTRIM(Avlmatltype),Avlmatltypedesc FROM AVLMATLTP  ORDER BY AVLMATLTYPE   
 END  
  
 SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @avlMatlTpList  
  
 IF @filter <> '' AND @sortExpression <> ''  
   BEGIN  
   SET @SQL=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE '+@filter  
   +' ORDER BY '+ @SortExpression+''+ ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'  
  END  
 ELSE IF @filter = '' AND @sortExpression <> ''  
  BEGIN  
     SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t '    
     +' ORDER BY '+ @sortExpression+'' + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'   
  END  
   
 EXEC SP_EXECUTESQL @SQL  
END