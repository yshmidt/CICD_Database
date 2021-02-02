
-- =============================================
-- Author:		<Nilesh Sa>
-- Create date:   <02/21/2019>
-- Description:	Get Prepay used details
-- exec GetInvoiceAppliedDetails '0000000001','0000000294',0,100,'','','',''
-- Nilesh Sa 3/06/2018 Check for trans balance first
-- Nilesh Sa 4/17/2019 Modify the Payment Type logic
-- Nitesh B 9/24/2019 Get discount taken of the Invoice 
-- Nitesh B 12/12/2019 Get Return Check (NSF) records
-- =============================================
CREATE PROCEDURE [dbo].[GetInvoiceAppliedDetails]
	--DECLARE
	@custNo char(10) = '',
	@invNo char(10) = '',
	@startRecord int = 0,
    @endRecord int = 150,
	@sortExpression NVARCHAR(1000) = NULL,
    @filter NVARCHAR(1000) = NULL,
	@currencyType CHAR(10) ='', -- Empty - Functional Currency,P - Presentation Currency, F - Multi Currency
	@lLatestRate BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL nvarchar(MAX),@lFCInstalled bit, @prePayTotalAmount numeric (12,2);

    DECLARE @invoiceDetailTable TABLE(Reference VARCHAR(MAX),DateApplied SMALLDATETIME,AmountApplied NUMERIC(12,2),PaymentType NVARCHAR(400), DiscTaken NUMERIC(12,2)); 

    -- Nilesh Sa Created a table to store FCUsedView  
     DECLARE @fcUsedViewTable TABLE(FcUsedUniq CHAR(10),Country VARCHAR(60),CURRENCY VARCHAR(40), Symbol VARCHAR(3) ,Prefix VARCHAR(7),UNIT VARCHAR(10),Subunit VARCHAR(10),  
     Thou_sep VARCHAR(1),Deci_Sep VARCHAR(1),Deci_no NUMERIC(2,0),AskPrice NUMERIC(13,5),AskPricePR NUMERIC(13,5),FcHist_key CHAR(10),FcdateTime SMALLDATETIME);  

    IF(@sortExpression = NULL OR @sortExpression = '')
    BEGIN
	 SET @sortExpression = 'DateApplied asc'
    END

    SELECT @lFCInstalled = dbo.fn_IsFCInstalled()    
    
    IF @lFCInstalled = 1
    BEGIN
    	  -- Fetch FCUsed data and inserting to temp table  
    	  INSERT INTO @fcUsedViewTable  EXEC FcUsedView;  
    END

    IF @lFCInstalled = 1 AND @currencyType = 'P'    
	     BEGIN  
			IF @lLatestRate = 0   
			BEGIN
				INSERT INTO @invoiceDetailTable
					SELECT 
					REC_ADVICE AS Reference
					,REC_DATE AS DateApplied
					,CASE WHEN ISNULL(ABS(REC_AMOUNTFC),0) =0 THEN 0.00 ELSE ABS(REC_AMOUNTPR) END AS AmountApplied
					,PaymentInfo.PaymentType 
					,ARCREDIT.DISC_TAKEN AS DiscTaken -- Nitesh B 9/24/2019 Get discount taken of the Invoice
					FROM ARCREDIT 
					INNER JOIN  ACCTSREC on ARCREDIT.uniquear = ACCTSREC.UNIQUEAR
					-- Nilesh Sa 4/17/2019 Modify the Payment Type logic
					OUTER APPLY(
						SELECT PaymentType FROM DEPOSITS 
						--JOIN PaymentTypes on PaymentTypes.PaymentId = DEPOSITS.FkPaymentId
						where Dep_No = ARCREDIT.DEP_NO
					) AS PaymentInfo
					WHERE ARCREDIT.CUSTNO =@custNo AND ARCREDIT.INVNO =@invNo
				UNION 
					SELECT 
					PpayCmDetails.INVNO AS Reference
					,AROFFSET.DATE AS DateApplied
					,CASE WHEN ISNULL(ABS(AROFFSET.AMOUNTFC),0) = 0 THEN 0.00 ELSE ABS(AROFFSET.AMOUNTPR) END AS AmountApplied
					,PaymentInfo.PaymentType
					,AROFFSET.DiscTaken AS DiscTaken -- Nitesh B 9/24/2019 Get discount taken of the Invoice
					FROM AROFFSET  
					INNER JOIN  ACCTSREC on AROFFSET.uniquear = ACCTSREC.UNIQUEAR
					OUTER APPLY(
						   SELECT arOff.INVNO,ar.Dep_NO
						   FROM  AROFFSET arOff  
						   JOIN ACCTSREC acRec ON acRec.UNIQUEAR = arOff.uniquear AND  (acRec.lPrepay = 1 OR acRec.isManualCm = 1)
						   JOIN ARCREDIT ar ON acRec.UNIQUEAR = ar.uniquear
						   WHERE arOff.CTRANSACTION = AROFFSET.CTRANSACTION  
					) AS PpayCmDetails
					-- Nilesh Sa 4/17/2019 Modify the Payment Type logic
					OUTER APPLY(
						SELECT PaymentType FROM DEPOSITS 
						--JOIN PaymentTypes on PaymentTypes.PaymentId = DEPOSITS.FkPaymentId
						where Dep_No = PpayCmDetails.Dep_NO
					) AS PaymentInfo
					WHERE AROFFSET.CUSTNO = @custNo AND AROFFSET.INVNO = @invNo
				UNION -- Nitesh B 12/12/2019 Get Return Check (NSF) records
					SELECT 
					c.REC_ADVICE AS reference,
					rc.ret_date AS [Date Applied],
					-r.REC_AMOUNT AS [Amount Applied],
					'NSF' AS [Payment Type],
					0.00 AS DiscTaken  
					FROM ARRETDET r 
					INNER JOIN ARRETCK rc ON r.UNIQRETNO=rc.UNIQRETNO
					INNER JOIN ARCREDIT c ON r.UNIQLNNO=c.UNIQLNNO AND r.UNIQDETNO=c.UNIQDETNO 
					where r.CUSTNO = @custNo AND r.INVNO = @invNo 
				END
			 ELSE  
				BEGIN  
					INSERT INTO @invoiceDetailTable
					SELECT 
					REC_ADVICE AS Reference
					,REC_DATE AS DateApplied
					,CAST(ABS(REC_AMOUNTFC)/FcUsed.AskPricePR AS numeric(20,2)) AS AmountApplied
					,PaymentInfo.PaymentType
					,ARCREDIT.DISC_TAKEN AS DiscTaken -- Nitesh B 9/24/2019 Get discount taken of the Invoice
					FROM ARCREDIT 
					INNER JOIN  ACCTSREC on ARCREDIT.uniquear = ACCTSREC.UNIQUEAR
					JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
					LEFT OUTER JOIN @fcUsedViewTable FcUsed ON  FcUsed.FcUsedUniq = CUSTOMER.FcUsed_uniq
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
					,CAST(ABS(AROFFSET.AMOUNTFC)/FcUsed.AskPricePR AS numeric(20,2)) AS AmountApplied
					,PaymentInfo.PaymentType
					,AROFFSET.DiscTaken AS DiscTaken -- Nitesh B 9/24/2019 Get discount taken of the Invoice
					FROM AROFFSET  
					INNER JOIN  ACCTSREC on AROFFSET.uniquear = ACCTSREC.UNIQUEAR
					JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
					LEFT OUTER JOIN @fcUsedViewTable FcUsed ON  FcUsed.FcUsedUniq = CUSTOMER.FcUsed_uniq
					OUTER APPLY(
						   SELECT arOff.INVNO,ar.Dep_NO
						   FROM  AROFFSET arOff  
						   JOIN ACCTSREC acRec ON acRec.UNIQUEAR = arOff.uniquear AND  (acRec.lPrepay = 1 OR acRec.isManualCm = 1)
						   JOIN ARCREDIT ar ON acRec.UNIQUEAR = ar.uniquear
						   WHERE arOff.CTRANSACTION = AROFFSET.CTRANSACTION  
					) AS PpayCmDetails
					-- Nilesh Sa 4/17/2019 Modify the Payment Type logic
					OUTER APPLY(
						SELECT PaymentType FROM DEPOSITS 
						--JOIN PaymentTypes on PaymentTypes.PaymentId = DEPOSITS.FkPaymentId
						where Dep_No = PpayCmDetails.Dep_NO
					) AS PaymentInfo
					WHERE AROFFSET.CUSTNO = @custNo AND AROFFSET.INVNO = @invNo
				UNION -- Nitesh B 12/12/2019 Get Return Check (NSF) records
					SELECT 
					c.REC_ADVICE AS reference,
					rc.ret_date AS [Date Applied],
					-r.REC_AMOUNT AS [Amount Applied],
					'NSF' AS [Payment Type],
					0.00 AS DiscTaken  
					FROM ARRETDET r 
					INNER JOIN ARRETCK rc ON r.UNIQRETNO=rc.UNIQRETNO
					INNER JOIN ARCREDIT c ON r.UNIQLNNO=c.UNIQLNNO AND r.UNIQDETNO=c.UNIQDETNO 
					where r.CUSTNO = @custNo AND r.INVNO = @invNo 
				END
	     END  
     ELSE IF @lFCInstalled = 1 AND @currencyType = 'F'    
	   BEGIN  
			INSERT INTO @invoiceDetailTable
			SELECT 
			REC_ADVICE AS Reference
			,REC_DATE AS DateApplied
			,ABS(REC_AMOUNTFC) AS AmountApplied
			,PaymentInfo.PaymentType
			,ARCREDIT.DISC_TAKEN AS DiscTaken -- Nitesh B 9/24/2019 Get discount taken of the Invoice
			FROM ARCREDIT 
			INNER JOIN  ACCTSREC on ARCREDIT.uniquear = ACCTSREC.UNIQUEAR
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
			,ABS(AROFFSET.AMOUNTFC) AS AmountApplied
			,PaymentInfo.PaymentType
			,AROFFSET.DiscTaken AS DiscTaken -- Nitesh B 9/24/2019 Get discount taken of the Invoice
			FROM AROFFSET  
			INNER JOIN  ACCTSREC on AROFFSET.uniquear = ACCTSREC.UNIQUEAR
			OUTER APPLY(
				   SELECT arOff.INVNO,ar.Dep_NO
				   FROM  AROFFSET arOff  
				   JOIN ACCTSREC acRec ON acRec.UNIQUEAR = arOff.uniquear AND  (acRec.lPrepay = 1 OR acRec.isManualCm = 1)
				   JOIN ARCREDIT ar ON acRec.UNIQUEAR = ar.uniquear
				   WHERE arOff.CTRANSACTION = AROFFSET.CTRANSACTION  
			) AS PpayCmDetails
			-- Nilesh Sa 4/17/2019 Modify the Payment Type logic
			OUTER APPLY(
				SELECT PaymentType FROM DEPOSITS 
				--JOIN PaymentTypes on PaymentTypes.PaymentId = DEPOSITS.FkPaymentId
				where Dep_No = PpayCmDetails.Dep_NO
			) AS PaymentInfo
			WHERE AROFFSET.CUSTNO = @custNo AND AROFFSET.INVNO = @invNo
		UNION -- Nitesh B 12/12/2019 Get Return Check (NSF) records
			SELECT 
			c.REC_ADVICE AS reference,
			rc.ret_date AS [Date Applied],
			-r.REC_AMOUNT AS [Amount Applied],
			'NSF' AS [Payment Type],
			0.00 AS DiscTaken  
			FROM ARRETDET r 
			INNER JOIN ARRETCK rc ON r.UNIQRETNO=rc.UNIQRETNO
			INNER JOIN ARCREDIT c ON r.UNIQLNNO=c.UNIQLNNO AND r.UNIQDETNO=c.UNIQDETNO 
			where r.CUSTNO = @custNo AND r.INVNO = @invNo 
	   END
       ELSE   
	     BEGIN  
			IF @lLatestRate = 0   
			     BEGIN  
					INSERT INTO @invoiceDetailTable
					SELECT 
					REC_ADVICE AS Reference
					,REC_DATE AS DateApplied
					,ABS(REC_AMOUNT) AS AmountApplied
					,PaymentInfo.PaymentType 
					,ARCREDIT.DISC_TAKEN AS DiscTaken -- Nitesh B 9/24/2019 Get discount taken of the Invoice
					FROM ARCREDIT 
					INNER JOIN  ACCTSREC ON ARCREDIT.uniquear = ACCTSREC.UNIQUEAR
					-- Nilesh Sa 4/17/2019 Modify the Payment Type logic
					OUTER APPLY(
						SELECT PaymentType FROM DEPOSITS 
						--JOIN PaymentTypes ON PaymentTypes.PaymentId = DEPOSITS.FkPaymentId
						WHERE Dep_No = ARCREDIT.DEP_NO
					) AS PaymentInfo
					WHERE ARCREDIT.CUSTNO =@custNo 	AND ARCREDIT.INVNO =@invNo
				UNION 
					SELECT 
					PpayCmDetails.INVNO AS Reference
					,AROFFSET.DATE AS DateApplied
					,ABS(AROFFSET.AMOUNT) AS AmountApplied
					,PaymentInfo.PaymentType
					,AROFFSET.DiscTaken AS DiscTaken -- Nitesh B 9/24/2019 Get discount taken of the Invoice
					FROM AROFFSET  
					INNER JOIN  ACCTSREC ON AROFFSET.uniquear = ACCTSREC.UNIQUEAR
					OUTER APPLY(
						   SELECT arOff.INVNO,ar.Dep_NO
						   FROM  AROFFSET arOff  
						   JOIN ACCTSREC acRec ON acRec.UNIQUEAR = arOff.uniquear AND  (acRec.lPrepay = 1 OR acRec.isManualCm = 1)
						   JOIN ARCREDIT ar ON acRec.UNIQUEAR = ar.uniquear
						   WHERE arOff.CTRANSACTION = AROFFSET.CTRANSACTION  
					) AS PpayCmDetails
					-- Nilesh Sa 4/17/2019 Modify the Payment Type logic
					OUTER APPLY(
						SELECT PaymentType FROM DEPOSITS 
						--JOIN PaymentTypes ON PaymentTypes.PaymentId = DEPOSITS.FkPaymentId
						where Dep_No = PpayCmDetails.Dep_NO
					) AS PaymentInfo
					WHERE AROFFSET.CUSTNO = @custNo AND AROFFSET.INVNO = @invNo
				UNION -- Nitesh B 12/12/2019 Get Return Check (NSF) records
					SELECT 
					c.REC_ADVICE AS reference,
					rc.ret_date AS [Date Applied],
					-r.REC_AMOUNT AS [Amount Applied],
					'NSF' AS [Payment Type],
					0.00 AS DiscTaken  
					FROM ARRETDET r 
					INNER JOIN ARRETCK rc ON r.UNIQRETNO=rc.UNIQRETNO
					INNER JOIN ARCREDIT c ON r.UNIQLNNO=c.UNIQLNNO AND r.UNIQDETNO=c.UNIQDETNO 
					where r.CUSTNO = @custNo AND r.INVNO = @invNo
			     END
                  ELSE
				 BEGIN  
					INSERT INTO @invoiceDetailTable
					SELECT 
					REC_ADVICE AS Reference
					,REC_DATE AS DateApplied
					,CAST(ABS(REC_AMOUNTFC)/FcUsed.AskPrice AS numeric(20,2)) AS AmountApplied
					,PaymentInfo.PaymentType 
					,ARCREDIT.DISC_TAKEN AS DiscTaken -- Nitesh B 9/24/2019 Get discount taken of the Invoice
					FROM ARCREDIT 
					INNER JOIN  ACCTSREC ON ARCREDIT.uniquear = ACCTSREC.UNIQUEAR
					JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
					LEFT OUTER JOIN @fcUsedViewTable FcUsed ON  FcUsed.FcUsedUniq = CUSTOMER.FcUsed_uniq
					-- Nilesh Sa 4/17/2019 Modify the Payment Type logic
					OUTER APPLY(
						SELECT PaymentType FROM DEPOSITS 
						--JOIN PaymentTypes on PaymentTypes.PaymentId = DEPOSITS.FkPaymentId
						WHERE Dep_No = ARCREDIT.DEP_NO
					) AS PaymentInfo
					WHERE ARCREDIT.CUSTNO =@custNo AND ARCREDIT.INVNO =@invNo
				UNION 
					SELECT 
					PpayCmDetails.INVNO AS Reference
					,AROFFSET.DATE AS DateApplied
					,CAST(ABS(AROFFSET.AMOUNTFC)/FcUsed.AskPrice AS numeric(20,2)) AS AmountApplied
					,PaymentInfo.PaymentType
					,AROFFSET.DiscTaken AS DiscTaken  -- Nitesh B 9/24/2019 Get discount taken of the Invoice
					FROM AROFFSET  
					INNER JOIN  ACCTSREC ON AROFFSET.uniquear = ACCTSREC.UNIQUEAR
					JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
					LEFT OUTER JOIN @fcUsedViewTable FcUsed ON  FcUsed.FcUsedUniq = CUSTOMER.FcUsed_uniq
					OUTER APPLY(
						   SELECT arOff.INVNO,ar.Dep_NO
						   FROM  AROFFSET arOff  
						   JOIN ACCTSREC acRec ON acRec.UNIQUEAR = arOff.uniquear AND (acRec.lPrepay = 1 OR acRec.isManualCm = 1)
						   JOIN ARCREDIT ar ON acRec.UNIQUEAR = ar.uniquear
						   WHERE arOff.CTRANSACTION = AROFFSET.CTRANSACTION  
					) AS PpayCmDetails
					-- Nilesh Sa 4/17/2019 Modify the Payment Type logic
					OUTER APPLY(
						SELECT PaymentType FROM DEPOSITS 
						--JOIN PaymentTypes ON PaymentTypes.PaymentId = DEPOSITS.FkPaymentId
						WHERE Dep_No = PpayCmDetails.Dep_NO
					) AS PaymentInfo
					WHERE AROFFSET.CUSTNO = @custNo AND AROFFSET.INVNO = @invNo
				UNION -- Nitesh B 12/12/2019 Get Return Check (NSF) records
					SELECT 
					c.REC_ADVICE AS reference,
					rc.ret_date AS [Date Applied],
					-r.REC_AMOUNT AS [Amount Applied],
					'NSF' AS [Payment Type],
					0.00 AS DiscTaken  
					FROM ARRETDET r 
					INNER JOIN ARRETCK rc ON r.UNIQRETNO=rc.UNIQRETNO
					INNER JOIN ARCREDIT c ON r.UNIQLNNO=c.UNIQLNNO AND r.UNIQDETNO=c.UNIQDETNO 
					where r.CUSTNO = @custNo AND r.INVNO = @invNo
			     END
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