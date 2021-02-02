
-- =============================================
-- Author:		<Nilesh Sa>
-- Create date: <09/26/2018>
-- Description:	Get Prepay details
-- exec GetPrepayAndCmDetails '0000000002','PPayNEW',0,100,'',''
-- =============================================

CREATE PROCEDURE [dbo].[GetPrepayAndCmDetails]
	--DECLARE
	@custNo char(10) = '',
	@prepayNo char(10) = '',
	@startRecord int = 0,
    @endRecord int = 150,
	@sortExpression NVARCHAR(1000) = NULL,
    @filter NVARCHAR(1000) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SQL nvarchar(MAX);
	DECLARE @prepayDetailTable TABLE(InvoiceNo CHAR(10),DateApplied SMALLDATETIME,AmountApplied NUMERIC(12,2),AppliedAmtTrans NUMERIC(12,2));

	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'DateApplied asc'
	END
	
	BEGIN
	    INSERT INTO @prepayDetailTable
		SELECT Dbo.fRemoveLeadingZeros(AROFFSET.INVNO) AS InvoiceNo,DATE As DateApplied,ABS(Amount) AS AppliedAmount,ABS(AMOUNTFC) AS AppliedAmtTrans
		FROM AROFFSET
		JOIN ACCTSREC ON AROFFSET.uniquear = ACCTSREC.UNIQUEAR AND isManualCm = 0 AND lPrepay = 0 
		WHERE CTRANSACTION IN (SELECT DISTINCT CTRANSACTION FROM AROFFSET WHERE INVNO =@prepayNo AND CUSTNO = @custNo)
	END

	SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @prepayDetailTable

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
	ELSE IF @filter <> '' AND @sortExpression = ''
			  BEGIN
				  SET @SQL=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+'' 
				  + ' ORDER BY DateApplied OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' 
			   END
			   ELSE
				 BEGIN
				  SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t'
				   + ' ORDER BY DateApplied OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'
	END
	EXEC SP_EXECUTESQL @SQL
END