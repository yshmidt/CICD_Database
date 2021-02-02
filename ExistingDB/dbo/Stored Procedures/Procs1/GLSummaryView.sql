-- =============================================
-- Author:		<Nilesh Sa>
-- Create date: <18/08/2016>
-- Description:	<View for the GL_ACCT table to gather related information>
-- Modified : 12/29/2017 : Nilesh S :Record order by GL_NUMBER and PERIOD
-- 01/05/2018 Nilesh Sa : Fix the Sorting issue 
-- 01/22/2018 Nilesh Sa : No need to add +1 to @startRecord
--[GLSummaryView] 18,1,18,3,'posting','1','10000','',''
-- =============================================
CREATE PROCEDURE [dbo].[GLSummaryView]
    @StartSequenceNumber int=0,
	@lnStartPeriod Numeric(2,0)=0,
	@EndSequenceNumber int=0,
	@lnEndPeriod Numeric(2,0)=0,
	@lcgl_class char(7)='posting',
	@startRecord int = 1,
    @endRecord int = 50, 
    @sortExpression nvarchar(1000) = null,
    @filter nvarchar(1000) = null
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQL nvarchar(max)

	-- 01/02/2018 Nilesh Sa : Fix the Sorting Issue
	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'FISCAL_YEAR desc'
	END

    -- Insert statements for procedure here
   ;WITH GLSummaryView AS(select  glFyrsDetl.Period as PERIOD ,glfiscalyrs.FiscalYr as FISCAL_YEAR, gl_acct.gl_nbr as GL_NUMBER, Gl_nbrs.GL_DESCR , Gl_nbrs.GLTYPE,  gltypes.GLTYPEDESC , BEG_BAL,	DEBIT,	CREDIT,	END_BAL 
			from gl_acct INNER JOIN glFyrsDetl ON gl_acct.fk_fydtluniq=glFyrsDetl.FyDtlUniq 
			INNER JOIN glFiscalyrs ON  glFyrsDetl.fk_fy_uniq=glFiscalyrs.Fy_uniq
			INNER JOIN GL_NBRS ON Gl_acct.gl_nbr=Gl_nbrs.gl_nbr
			INNER JOIN GLTYPES ON GL_NBRS.GLTYPE =GLTYPEs.GLTYPE 
			where dbo.padl(rtrim(cast(SequenceNumber as char(4))),4,'0')+ dbo.padl(RTRIM(CAST(Period as CHAR(2))),2,'0')
			between dbo.padl(rtrim(cast(@startSequenceNumber as char(4))),4,'0')+ dbo.padl(RTRIM(CAST(@lnStartPeriod as CHAR(2))),2,'0')
			and dbo.padl(rtrim(cast(@endSequenceNumber as char(4))),4,'0')+ dbo.padl(RTRIM(CAST(@lnEndPeriod as CHAR(2))),2,'0')
			AND (@lcgl_class =' ' OR  Gl_nbrs.GL_CLASS = @lcgl_class )
)
SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from GLSummaryView 
-- 12/29/2017 : Nilesh S :Record order by GL_NUMBER and PERIOD
ORDER BY GL_NUMBER,PERIOD
	IF @filter <> '' AND @sortExpression <> ''
	  BEGIN
	   SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE '+@filter
		   +' ORDER BY '+ @SortExpression+''+ ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' -- 01/05/2018 Nilesh Sa : Fix the Sorting issue 
	   END-- 01/22/2018 Nilesh Sa : No need to add +1 to @startRecord
	  ELSE IF @filter = '' AND @sortExpression <> ''
	  BEGIN
		SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t '  
		+' ORDER BY '+ @sortExpression+'' + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' -- 01/05/2018 Nilesh Sa : Fix the Sorting issue 
		END-- 01/22/2018 Nilesh Sa : No need to add +1 to @startRecord
	  ELSE IF @filter <> '' AND @sortExpression = ''
	  BEGIN
		  SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+'' 
		  + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'  -- 01/22/2018 Nilesh Sa : No need to add +1 to @startRecord
	   END
	   ELSE
		 BEGIN
		  SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t '
		   + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'  -- 01/22/2018 Nilesh Sa : No need to add +1 to @startRecord
	 END
	 exec sp_executesql @SQL
END