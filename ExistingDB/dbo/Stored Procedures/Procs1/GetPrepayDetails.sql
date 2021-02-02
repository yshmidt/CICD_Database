
-- =============================================
-- Author:		<Nilesh Sa>
-- Create date: <07/17/2018>
-- Description:	Get Prepay details
-- exec GetPrepayDetails '0000000002','PPayNEW',0,100,'','','','',''
-- Nilesh Sa 3/06/2018 Check for trans balance first
-- =============================================

CREATE PROCEDURE [dbo].[GetPrepayDetails]
	--DECLARE
	@custNo char(10) = '',
	@prepayNo char(10) = '',
	@startRecord int = 0,
      @endRecord int = 150,
	@sortExpression NVARCHAR(1000) = NULL,
      @filter NVARCHAR(1000) = NULL,
	@currencyType CHAR(10) ='', -- Empty - Functional Currency,P - Presentation Currency, F - Multi Currency
	@lLatestRate BIT = 0,
	@fcUsedUniq CHAR(10)=null 
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQL nvarchar(MAX),@lFCInstalled bit, @prePayTotalAmount numeric (12,2);

	DECLARE @prepayDetailTable TABLE(InvoiceNo CHAR(10),Reference CHAR(10),DateApplied SMALLDATETIME,AmountApplied NUMERIC(12,2),Balance NUMERIC(12,2));

	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'DateApplied asc'
	END

	SELECT @lFCInstalled = dbo.fn_IsFCInstalled();

	IF @lFCInstalled = 1 
		 IF  @currencyType = 'P'
			BEGIN
				SELECT @prePayTotalAmount = CASE WHEN ISNULL(REC_AMOUNTFC,0) = 0 THEN 0.00 ELSE REC_AMOUNTPR END from ARCREDIT where INVNO= @prepayNo and REC_TYPE ='PrePay'

				INSERT INTO @prepayDetailTable
				SELECT AppliedInvoice.INVNO AS InvoiceNo
			     ,ac.REC_ADVICE AS Reference
			     ,ac.REC_DATE AS DateApplied
			     ,CASE WHEN ISNULL(ac.REC_AMOUNTPR,0)= 0 THEN 0.00 ELSE ac.REC_AMOUNTPR END AS AmountApplied
			     ,(RecAmtTilldate.TotalAmountTillDate) AS Balance
				FROM ARCREDIT AS ac 
				JOIN ACCTSREC on ac.uniquear = ACCTSREC.UNIQUEAR  AND ac.CUSTNO = ACCTSREC.CUSTNO AND ac.INVNO = ACCTSREC.INVNO
				OUTER APPLY
				(
					SELECT INVNO 
					FROM ARCREDIT
					WHERE ARCREDIT.UNIQLNNO = ac.UNIQLNNO AND REC_TYPE ='Apply PPay'
				) as AppliedInvoice
				OUTER APPLY
				(
					SELECT @prePayTotalAmount + SUM(CASE WHEN ISNULL(REC_AMOUNTFC,0) = 0 THEN 0.00 ELSE REC_AMOUNTPR END) AS TotalAmountTillDate 
							FROM ARCREDIT 
							INNER JOIN ACCTSREC ON ac.uniquear = ACCTSREC.UNIQUEAR
							WHERE  ARCREDIT.CUSTNO = @custNo
							AND lPrepay = 1 
							AND ARCREDIT.INVNO =@prepayNo
							AND REC_TYPE ='Apply PPay'
							AND ac.REC_DATE >= ARCREDIT.REC_DATE

				) as RecAmtTilldate
				WHERE  ac.CUSTNO = @custNo
				AND ac.INVNO =@prepayNo
				AND ac.REC_TYPE ='Apply PPay'
			END
         ELSE
		  	BEGIN

				SELECT @prePayTotalAmount = REC_AMOUNTFC from ARCREDIT where INVNO= @prepayNo and REC_TYPE ='PrePay';

				INSERT INTO @prepayDetailTable
				SELECT AppliedInvoice.INVNO AS InvoiceNo
			     ,ac.REC_ADVICE AS Reference
			     ,ac.REC_DATE AS DateApplied
			     ,ac.REC_AMOUNTFC  AS AmountApplied
			     ,(RecAmtTilldate.TotalAmountTillDate) AS Balance
			    	FROM ARCREDIT AS ac 
				JOIN ACCTSREC on ac.uniquear = ACCTSREC.UNIQUEAR  AND ac.CUSTNO = ACCTSREC.CUSTNO AND ac.INVNO = ACCTSREC.INVNO
				OUTER APPLY
				(
					SELECT INVNO 
					FROM ARCREDIT
					WHERE ARCREDIT.UNIQLNNO = ac.UNIQLNNO AND REC_TYPE ='Apply PPay'
				) as AppliedInvoice
				OUTER APPLY
				(
					SELECT @prePayTotalAmount + SUM(REC_AMOUNTFC) As TotalAmountTillDate 
							FROM ARCREDIT 
							INNER JOIN ACCTSREC ON ac.uniquear = ACCTSREC.UNIQUEAR
							WHERE  ARCREDIT.CUSTNO = @custNo
							AND lPrepay = 1 
							AND ARCREDIT.INVNO =@prepayNo
							AND REC_TYPE ='Apply PPay'
							AND ac.REC_DATE >= ARCREDIT.REC_DATE

				) as RecAmtTilldate
				WHERE  ac.CUSTNO = @custNo
				AND ac.INVNO =@prepayNo
				AND ac.REC_TYPE ='Apply PPay'
		END
     ELSE
		BEGIN
			SELECT @prePayTotalAmount = REC_AMOUNT from ARCREDIT where INVNO= @prepayNo and REC_TYPE ='PrePay';

			INSERT INTO @prepayDetailTable
			SELECT AppliedInvoice.INVNO AS InvoiceNo
			   ,ac.REC_ADVICE AS Reference
			   ,ac.REC_DATE AS DateApplied
			   ,ac.REC_AMOUNT  AS AmountApplied
			   ,(RecAmtTilldate.TotalAmountTillDate) AS Balance
				FROM ARCREDIT AS ac 
				JOIN ACCTSREC on ac.uniquear = ACCTSREC.UNIQUEAR  AND ac.CUSTNO = ACCTSREC.CUSTNO AND ac.INVNO = ACCTSREC.INVNO
				OUTER APPLY
				(
					SELECT INVNO 
					FROM ARCREDIT
					WHERE ARCREDIT.UNIQLNNO = ac.UNIQLNNO AND REC_TYPE ='Apply PPay'
				) as AppliedInvoice
				OUTER APPLY
				(
					SELECT @prePayTotalAmount + SUM(REC_AMOUNT) As TotalAmountTillDate 
							FROM ARCREDIT 
							INNER JOIN ACCTSREC ON ac.uniquear = ACCTSREC.UNIQUEAR
							WHERE  ARCREDIT.CUSTNO = @custNo
							AND lPrepay = 1 
							AND ARCREDIT.INVNO =@prepayNo
							AND REC_TYPE ='Apply PPay'
							AND ac.REC_DATE >= ARCREDIT.REC_DATE

				) as RecAmtTilldate
				WHERE  ac.CUSTNO = @custNo
				AND ac.INVNO =@prepayNo
				AND ac.REC_TYPE ='Apply PPay'
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