-- =============================================
-- Author:		<Shripati>
-- Create date: <03/20/2018>
-- Description:	Get contact list
-- exec [dbo].[GetContactView] 0,150,'','','0000000003','C'
-- =============================================
CREATE PROCEDURE [dbo].[GetContactView]
	--DECLARE
	@startRecord int = 0,
    @endRecord int = 150, 
    @sortExpression nvarchar(1000) = null,
    @filter nvarchar(1000) = null,
	@custNo char(10) = '',
	@type char(1)=''
AS
BEGIN
 SET NOCOUNT ON;

	DECLARE @SQL nvarchar(max);
	DECLARE @contactTable TABLE(Name varchar(100),Title varchar(50),Department varchar(25),Phone varchar(25),Mobile varchar(25),Email varchar(100),[Status] char(25));
  
	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'Name DESC'
	END

	BEGIN
		INSERT INTO @contactTable
		SELECT  RTRIM(FIRSTNAME)+ ' ' + RTRIM(LASTNAME) AS Name,TITLE,DEPARTMENT,WORKPHONE,MOBILE,EMAIL,[Status] 
		FROM CCONTACT
		WHERE CUSTNO =@custNo AND type=@type
	END

	SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @contactTable

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
	ELSE 
	    IF @filter <> '' AND @sortExpression = ''
		  BEGIN
			  SET @SQL=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+'' 
			  + ' ORDER BY Name DESC OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' 
		  END
		ELSE
		  BEGIN
			  SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t'
			   + ' ORDER BY Name DESC OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'
		  END
	EXEC SP_EXECUTESQL @SQL
END