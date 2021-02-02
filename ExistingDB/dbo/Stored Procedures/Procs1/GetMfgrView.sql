
-- ==========================================================================================  
-- Author:  <Nitesh B>  
-- Create date: <12/21/2018>  
-- Description: Get Mfgr setup View 
-- exec [GetMfgrView] 0,150,'',''
-- ==========================================================================================  
CREATE PROCEDURE [dbo].[GetMfgrView]  
    --DECLARE  
    @startRecord INT = 0,  
    @endRecord INT = 150,   
    @sortExpression NVARCHAR(1000) = NULL,
	@filter NVARCHAR(1000) = NULL
AS  
BEGIN  
	SET NOCOUNT ON;  
	DECLARE @SQL nvarchar(MAX);

	DECLARE @mfgrDetail TABLE(MfgrCode CHAR(20),Mfgr CHAR(35),UniqField CHAR(10),DeleteFlag CHAR(10));

	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'MfgrCode asc'
	END
  
	BEGIN
		INSERT INTO @mfgrDetail
		SELECT LTRIM(Text2),LTRIM(Text),UNIQFIELD As UniqField,DEL_FLAG As DeleteFlag FROM Support WHERE Fieldname = 'PARTMFGR' ORDER BY Text2 
	END

	SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @mfgrDetail

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