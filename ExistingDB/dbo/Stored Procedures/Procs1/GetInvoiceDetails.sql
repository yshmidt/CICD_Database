
-- =============================================
-- Author:		<Nilesh Sa>
-- Create date: <10/05/2018>
-- Description:	Get summary expand details
-- exec GetInvoiceDetails '0000000001','0000000242',0,100,'',''
-- Nilesh Sa 1/18/2019 Added PaymentType Column in selection
-- Nilesh Sa 4/17/2019 Modify the Payment Type logic
-- Nitesh B 8/7/2019 AddedAppliedAmtBank Column in selection
-- =============================================

CREATE PROCEDURE [dbo].[GetInvoiceDetails]
	--DECLARE
	@custNo char(10) = '',
	@invNo char(10) = '',
	@startRecord int = 0,
      @endRecord int = 150,
	@sortExpression NVARCHAR(1000) = NULL,
      @filter NVARCHAR(1000) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SQL nvarchar(MAX);
	DECLARE @invoiceDetailTable TABLE(Reference VARCHAR(MAX),DateApplied SMALLDATETIME,AmountApplied NUMERIC(12,2),AppliedAmtTrans NUMERIC(12,2)
	,PaymentType NVARCHAR(400)
	,AppliedAmtBank NUMERIC(12,2)); 
	-- Nilesh Sa 1/18/2019 Added PaymentType Column in selection
	-- Nitesh B 8/7/2019 AddedAppliedAmtBank Column in selection

	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'DateApplied asc'
	END
	
	BEGIN
			INSERT INTO @invoiceDetailTable
			SELECT 
			REC_ADVICE AS Reference
			,REC_DATE AS DateApplied
			,ABS(REC_AMOUNT) AS AmountApplied
			,ABS(REC_AMOUNTFC) AS AppliedAmtTrans
			-- Nilesh Sa 1/18/2019 Added PaymentType Column in selection
			,PaymentInfo.PaymentType 
			,ABS(REC_AMOUNTBK) AS AppliedAmtBank
			-- Nitesh B 8/7/2019 AddedAppliedAmtBank Column in selection
			FROM ARCREDIT 
			INNER JOIN  ACCTSREC on ARCREDIT.uniquear = ACCTSREC.UNIQUEAR
			-- Nilesh Sa 1/18/2019 Added PaymentType Column in selection
			-- Nilesh Sa 4/17/2019 Modify the Payment Type logic
			OUTER APPLY(
				SELECT PaymentType FROM DEPOSITS 
				--JOIN PaymentTypes on PaymentTypes.PaymentId = DEPOSITS.FkPaymentId
				where Dep_No = ARCREDIT.DEP_NO
			) AS PaymentInfo
			WHERE ARCREDIT.CUSTNO =@custNo 	AND ARCREDIT.INVNO =@invNo
		UNION 
			SELECT 
			PpayCmDetails.INVNO AS Reference
			,AROFFSET.DATE AS DateApplied
			,ABS(AROFFSET.AMOUNT) AS AmountApplied
			,ABS(AROFFSET.AMOUNTFC) AS AppliedAmtTrans
			-- Nilesh Sa 1/18/2019 Added PaymentType Column in selection
			,PaymentInfo.PaymentType
			,ABS(AROFFSET.AmountBk) AS AppliedAmtBank
			-- Nitesh B 8/7/2019 AddedAppliedAmtBank Column in selection
			FROM AROFFSET  
			INNER JOIN  ACCTSREC on AROFFSET.uniquear = ACCTSREC.UNIQUEAR
			OUTER APPLY(
				   SELECT arOff.INVNO,ar.Dep_NO
				   FROM  AROFFSET arOff  
				   JOIN ACCTSREC acRec ON acRec.UNIQUEAR = arOff.uniquear AND  (acRec.lPrepay = 1 OR acRec.isManualCm = 1)
				   JOIN ARCREDIT ar ON acRec.UNIQUEAR = ar.uniquear
				   WHERE arOff.CTRANSACTION = AROFFSET.CTRANSACTION  
			) AS PpayCmDetails
			-- Nilesh Sa 1/18/2019 Added PaymentType Column in selection
			-- Nilesh Sa 4/17/2019 Modify the Payment Type logic
			OUTER APPLY(
				SELECT PaymentType FROM DEPOSITS 
				--JOIN PaymentTypes on PaymentTypes.PaymentId = DEPOSITS.FkPaymentId
				where Dep_No = PpayCmDetails.Dep_NO
			) AS PaymentInfo
			WHERE AROFFSET.CUSTNO = @custNo AND AROFFSET.INVNO = @invNo
	END

	SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @invoiceDetailTable

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