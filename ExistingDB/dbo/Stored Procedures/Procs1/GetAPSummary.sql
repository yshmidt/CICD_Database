-- =============================================
-- Author:		<Nitesh B>
-- Create date: <07/04/2018>
-- Description:	Get AP Summary View
-- =============================================
CREATE PROCEDURE GetAPSummary
(
	@startRecord INT = 0,
    @endRecord INT = 150, 
    @sortExpression NVARCHAR(1000) = NULL,
    @filter NVARCHAR(1000) = NULL,
	@currencyType CHAR(10) ='', 
	@lLatestRate BIT = 0,
	@fcUsedUniq CHAR(10)='' 
)
AS
BEGIN
	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'SupName asc'
	END

	DECLARE @SQL nvarchar(MAX),@today DATE = GETDATE(),@firstDueEnd AS INT,@secondDueEnd AS INT,@lFCInstalled bit;

	-- To store invoice summary details w r to Supplier
	DECLARE @invoiceSummaryTable TABLE(SupName CHAR(35),UniqSupno CHAR(10),CreditStatus CHAR(15), FirstDue NUMERIC(20,2),SecondDue NUMERIC(20,2),
							ThirdDue NUMERIC(20,2),	CurrentDue NUMERIC(20,2), OpenSoBalance NUMERIC(20,2),CurrencyType CHAR(10),UseLatestExchangeRate BIT);

    -- To store total days late and Total Invoice Late w r to Supplier
	DECLARE @invoiceLateTable TABLE(UniqSupno CHAR(10),TotalDaysLate INT,TotalInvoiceLate INT);

    -- To store total Invoice Late and Not Late w r to Supplier
    DECLARE @totalInvoiceTable TABLE(UniqSupno CHAR(10),TotalInvoicePending INT); -- TotalInvoicePending = Late + Not Late

	-- Customer Credit Available Table
	DECLARE @SupCreditAvailableTable TABLE(SupName CHAR(35),UniqSupno CHAR(10),CreditAvailable NUMERIC(20,2));

	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

	-- Get Aging Range For First and second due based on nRange column
	SELECT @FirstDueEnd = nEnd From AgingRangeSetup WHERE cType='AR' and nRange = 1
	SELECT @SecondDueEnd = nEnd From AgingRangeSetup WHERE cType='AR' and nRange = 2

	INSERT INTO @SupCreditAvailableTable
	EXEC CalculateCustomerCreditAvailable

	IF @lFCInstalled = 1 AND @currencyType = 'P'
    BEGIN
			-- Total days late and Total Invoice Late w r to customer
			INSERT INTO @invoiceLateTable
					SELECT UniqSupno,SUM(DATEDIFF(Day,DUE_DATE,@Today)), COUNT(UniqSupno) 
					FROM APMASTER 
					WHERE INVAMOUNTPR-APPMTSPR > 0  AND DUE_DATE < @Today AND lPrepay = 0 AND APTYPE <> 'Manual'
					GROUP BY UniqSupno

			-- Total Invoice Late and Not Late w r to customer
			INSERT INTO @totalInvoiceTable
					SELECT UniqSupno,COUNT(UniqSupno) AS TotalInvoice
					FROM APMASTER 
					WHERE INVAMOUNTPR-APPMTSPR > 0  AND  lPrepay = 0 AND APTYPE <> 'Manual'
					GROUP BY UniqSupno

			;WITH APSummary AS(
					SELECT UniqSupno
						  ,SUM(CASE WHEN @lLatestRate = 0 THEN CAST((INVAMOUNTPR - APPMTSPR) AS NUMERIC(20,2)) ELSE
						   CAST((INVAMOUNTPR - APPMTSPR) * dbo.fn_CalculateFCRateVariance(Fchist_key,'P') AS NUMERIC(20,2)) END) AS FirstDue
						  ,0 AS SecondDue
						  ,0 AS ThirdDue
						  ,0 AS CurrentDue
					FROM APMASTER 
					WHERE DATEDIFF(Day,DUE_DATE,@Today) >= 1 and DATEDIFF(Day,DUE_DATE,@today) <= @firstDueEnd  
							 AND INVAMOUNT -APPMTS > 0 AND lPrepay = 0 AND  lPrepay = 0 AND APTYPE <> 'Manual' 
					GROUP BY UniqSupno
					UNION
					SELECT UniqSupno 
						  ,SUM(CASE WHEN @lLatestRate = 0 THEN CAST((INVAMOUNTPR - APPMTSPR) AS NUMERIC(20,2)) ELSE
						   CAST((INVAMOUNTPR - APPMTSPR) * dbo.fn_CalculateFCRateVariance(Fchist_key,'P') AS NUMERIC(20,2)) END) AS FirstDue
						  ,0 AS SecondDue
						  ,0 AS ThirdDue
						  ,0 AS CurrentDue
					FROM APMASTER 
					WHERE DATEDIFF(Day,DUE_DATE,@Today) >= (@firstDueEnd + 1)  and DATEDIFF(Day,DUE_DATE,@today) <= @secondDueEnd  AND INVAMOUNT-APPMTS > 0 
						  AND lPrepay = 0 AND APTYPE <> 'Manual'
					GROUP BY UniqSupno
					UNION
					SELECT UniqSupno, 0 AS FirstDue, 0 AS SecondDue
						  ,SUM(CASE WHEN @lLatestRate = 0 THEN CAST((INVAMOUNTPR - APPMTSPR) AS NUMERIC(20,2)) ELSE
						   CAST((INVAMOUNTPR - APPMTSPR) * dbo.fn_CalculateFCRateVariance(Fchist_key,'P') AS NUMERIC(20,2)) END) AS ThirdDue
						   ,0 AS CurrentDue
					FROM APMASTER 
					WHERE DATEDIFF(Day,DUE_DATE,@today) > (@secondDueEnd + 1)  AND INVAMOUNT-APPMTS > 0 AND  lPrepay = 0 AND APTYPE <> 'Manual' 
					GROUP BY UniqSupno
					UNION
					SELECT UniqSupno
						  ,0 AS FirstDue
						  ,0 AS SecondDue
						  ,0 AS ThirdDue
						  ,SUM(CASE WHEN @lLatestRate = 0 THEN CAST((INVAMOUNTPR - APPMTSPR) AS NUMERIC(20,2)) ELSE
						   CAST((INVAMOUNTPR - APPMTSPR) * dbo.fn_CalculateFCRateVariance(Fchist_key,'P') AS NUMERIC(20,2)) END) AS CurrentDue
					FROM APMASTER 
					WHERE DUE_DATE >= @today  AND INVAMOUNT-APPMTS> 0 AND lPrepay = 0 AND  lPrepay = 0 AND APTYPE <> 'Manual'
					GROUP BY UniqSupno
					) 
					INSERT INTO @invoiceSummaryTable
					(SupName,UniqSupno,CreditStatus,FirstDue,SecondDue,ThirdDue,CurrentDue,OpenSoBalance)
					SELECT S.SUPNAME AS SupName,Ap.UniqSupno AS UniqSupno,'OK' CreditStatus,
					SUM(FirstDue) AS FirstDue, SUM(SecondDue) AS SecondDue, SUM(ThirdDue) AS ThirdDue,SUM(CurrentDue) AS CurrentDue,
					--ISNULL(OpenSOInfo.Amt,0) AS OpenSoBalance
					0 AS OpenSoBalance
					FROM APSummary AP
					INNER JOIN SUPINFO S on AP.UNIQSUPNO = S.UNIQSUPNO AND S.FcUsed_uniq = ISNULL(@fcUsedUniq,S.FcUsed_uniq)
					--OUTER APPLY (
					--	 SELECT SUM(ROUND(CASE WHEN SOPRICES.FLAT = 0 and RecordType = 'P' THEN (Price * Balance) 
					--			WHEN SOPRICES.FLAT = 0 and Quantity > ShippedQty THEN (Price *(Quantity - ShippedQty)) 
					--			WHEN SOPRICES.FLAT = 1 and Sodetail.SHIPPEDQTY=0 THEN Price
					--			ELSE 0.00 END ,2)) AS Amt
					--		FROM SOMAIN
					--		INNER JOIN SODETAIL ON SOMAIN.SONO = SODETAIL.SONO AND SOMAIN.ORD_TYPE = 'Open' AND SOMAIN = ArSummary.CUSTNO
					--		INNER JOIN SOPRICES   ON SODETAIL.UNIQUELN = SOPRICES.UNIQUELN 
					--) AS OpenSOInfo
					GROUP BY AP.UNIQSUPNO,S.SUPNAME
					--,CUSTOMER.CREDITOK,OpenSOInfo.Amt
	END

	ELSE IF @lFCInstalled = 1 AND @currencyType = 'F'
    BEGIN
			-- Total days late and Total Invoice Late w r to customer
			INSERT INTO @invoiceLateTable
					SELECT UniqSupno,Sum(DATEDIFF(Day,DUE_DATE,@Today)), COUNT(UniqSupno) 
					FROM APMASTER 
					WHERE INVAMOUNTFC-APPMTSFC > 0  AND DUE_DATE < @Today AND lPrepay = 0 AND APTYPE <> 'Manual'
					GROUP BY UniqSupno

			-- Total Invoice Late and Not Late w r to customer
			INSERT INTO @totalInvoiceTable
					SELECT UniqSupno,COUNT(UniqSupno) AS TotalInvoice
					FROM APMASTER 
					WHERE INVAMOUNTFC - APPMTSFC > 0  AND  lPrepay = 0 AND APTYPE <> 'Manual'
					GROUP BY UniqSupno

			;WITH APSummary AS(
					SELECT UniqSupno, 
						SUM(CASE WHEN @lLatestRate = 0 THEN CAST((INVAMOUNTFC - APPMTSFC) AS NUMERIC(20,2)) ELSE
						CAST((INVAMOUNTFC - APPMTSFC) * dbo.fn_CalculateFCRateVariance(Fchist_key,'F') AS NUMERIC(20,2)) END) AS FirstDue,
						0 AS SecondDue, 0 AS ThirdDue,0 AS CurrentDue
						FROM APMASTER 
						WHERE DATEDIFF(Day,DUE_DATE,@Today) >= 1 and DATEDIFF(Day,DUE_DATE,@today) <= @firstDueEnd  
							 AND INVAMOUNT -APPMTS > 0 AND lPrepay = 0 AND  lPrepay = 0 AND APTYPE <> 'Manual'
						GROUP BY UniqSupno
					UNION
					SELECT UniqSupno, 
						SUM(CASE WHEN @lLatestRate = 0 THEN CAST((INVAMOUNTFC - APPMTSFC) AS NUMERIC(20,2)) ELSE
						CAST((INVAMOUNTFC - APPMTSFC) * dbo.fn_CalculateFCRateVariance(Fchist_key,'F') AS NUMERIC(20,2)) END) AS FirstDue,
						0 AS SecondDue, 0 AS ThirdDue,0 AS CurrentDue
						FROM APMASTER 
						WHERE DATEDIFF(Day,DUE_DATE,@Today) >= (@firstDueEnd + 1)  and DATEDIFF(Day,DUE_DATE,@today) <= @secondDueEnd  AND INVAMOUNT-APPMTS > 0 
						AND  lPrepay = 0 AND APTYPE <> 'Manual'
						GROUP BY UniqSupno
					UNION
					SELECT UniqSupno, 0 AS FirstDue, 0 AS SecondDue, 
						SUM(CASE WHEN @lLatestRate = 0 THEN CAST((INVAMOUNTPR - APPMTSPR) AS NUMERIC(20,2)) ELSE
						CAST((INVAMOUNTFC - APPMTSFC) * dbo.fn_CalculateFCRateVariance(Fchist_key,'F') AS NUMERIC(20,2)) END) AS ThirdDue,
						0 AS CurrentDue
						FROM APMASTER 
						WHERE DATEDIFF(Day,DUE_DATE,@today) > (@secondDueEnd + 1)  AND INVAMOUNT-APPMTS > 0 AND  lPrepay = 0 AND APTYPE <> 'Manual'
						GROUP BY UniqSupno
					UNION
					SELECT UniqSupno, 0 AS FirstDue, 0 AS SecondDue, 0 AS ThirdDue, 
						SUM(CASE WHEN @lLatestRate = 0 THEN CAST((INVAMOUNTPR - APPMTSPR) AS NUMERIC(20,2)) ELSE
						CAST((INVAMOUNTFC - APPMTSFC) * dbo.fn_CalculateFCRateVariance(Fchist_key,'F') AS NUMERIC(20,2)) END) AS CurrentDue
						FROM APMASTER 
						WHERE DUE_DATE >= @today  AND INVAMOUNT-APPMTS> 0 AND lPrepay = 0 AND  lPrepay = 0 AND APTYPE <> 'Manual'
						GROUP BY UniqSupno
					) 
					INSERT INTO @invoiceSummaryTable
					(SupName,UniqSupno,CreditStatus,FirstDue,SecondDue,ThirdDue,CurrentDue,OpenSoBalance)
					SELECT S.SUPNAME AS SupName,Ap.UniqSupno AS UniqSupno,'OK' CreditStatus,
					SUM(FirstDue) AS FirstDue, SUM(SecondDue) AS SecondDue, SUM(ThirdDue) AS ThirdDue,SUM(CurrentDue) AS CurrentDue,
					--ISNULL(OpenSOInfo.Amt,0) AS OpenSoBalance
					0 AS OpenSoBalance
					FROM APSummary AP
					INNER JOIN SUPINFO S on AP.UNIQSUPNO = S.UNIQSUPNO AND S.FcUsed_uniq = ISNULL(@fcUsedUniq,S.FcUsed_uniq)
					--OUTER APPLY (
					--	 SELECT SUM(ROUND(CASE WHEN SOPRICES.FLAT = 0 and RecordType = 'P' THEN (Price * Balance) 
					--			WHEN SOPRICES.FLAT = 0 and Quantity > ShippedQty THEN (Price *(Quantity - ShippedQty)) 
					--			WHEN SOPRICES.FLAT = 1 and Sodetail.SHIPPEDQTY=0 THEN Price
					--			ELSE 0.00 END ,2)) AS Amt
					--		FROM SOMAIN
					--		INNER JOIN SODETAIL ON SOMAIN.SONO = SODETAIL.SONO AND SOMAIN.ORD_TYPE = 'Open' AND SOMAIN = ArSummary.CUSTNO
					--		INNER JOIN SOPRICES   ON SODETAIL.UNIQUELN = SOPRICES.UNIQUELN 
					--) AS OpenSOInfo
					GROUP BY AP.UNIQSUPNO,S.SUPNAME
					--,CUSTOMER.CREDITOK,OpenSOInfo.Amt
	END

	ELSE 
    BEGIN
			-- Total days late and Total Invoice Late w r to customer
			INSERT INTO @invoiceLateTable
			SELECT UniqSupno,Sum(DATEDIFF(Day,DUE_DATE,@Today)), COUNT(UniqSupno) 
			FROM APMASTER 
			WHERE INVAMOUNT -  APPMTS > 0  AND DUE_DATE < @Today  AND lPrepay = 0 AND  lPrepay = 0 AND APTYPE <> 'Manual'
			GROUP BY UniqSupno

			-- Total Invoice Late and Not Late w r to customer
			INSERT INTO @totalInvoiceTable
			SELECT UniqSupno,COUNT(UniqSupno) AS TotalInvoice
			FROM APMASTER  
			WHERE INVAMOUNT - APPMTS  > 0  AND lPrepay = 0 AND  lPrepay = 0 AND APTYPE <> 'Manual'
			GROUP BY UniqSupno

			;WITH APSummary AS(
			SELECT UniqSupno, SUM(INVAMOUNT-APPMTS) AS FirstDue, 
			0 AS SecondDue, 0 AS ThirdDue,0 AS CurrentDue
				FROM APMASTER 
				WHERE DATEDIFF(Day,DUE_DATE,@Today) >= 1 AND DATEDIFF(Day,DUE_DATE,@today) <= @firstDueEnd AND INVAMOUNT-APPMTS  > 0 AND lPrepay = 0 AND INVAMOUNT = 0
				GROUP BY UniqSupno
			UNION
			SELECT UniqSupno,0 AS FirstDue, SUM(INVAMOUNT-APPMTS) AS SecondDue,  0 AS ThirdDue,0 AS CurrentDue
				FROM APMASTER 
				WHERE DATEDIFF(Day,DUE_DATE,@Today) >= (@firstDueEnd + 1) AND DATEDIFF(Day,DUE_DATE,@today) <= @secondDueEnd AND INVAMOUNT-APPMTS  > 0 AND lPrepay = 0 AND  lPrepay = 0 AND APTYPE <> 'Manual'
				GROUP BY UniqSupno
			UNION
			SELECT UniqSupno, 0 AS FirstDue, 0 AS SecondDue, SUM(INVAMOUNT-APPMTS) AS ThirdDue,0 AS CurrentDue
				FROM APMASTER 
				WHERE  DATEDIFF(Day,DUE_DATE,@today) > (@secondDueEnd + 1) AND INVAMOUNT-APPMTS  > 0 AND lPrepay = 0 AND  lPrepay = 0 AND APTYPE <> 'Manual'
				GROUP BY UniqSupno 
			UNION
			SELECT UniqSupno, 0 AS FirstDue, 0 AS SecondDue, 0 AS ThirdDue, SUM(INVAMOUNT-APPMTS) AS CurrentDue
				FROM APMASTER 
				WHERE DUE_DATE >= @today AND INVAMOUNT-APPMTS  > 0 AND lPrepay = 0 AND  lPrepay = 0 AND APTYPE <> 'Manual'
				GROUP BY UniqSupno
			) 
			INSERT INTO @invoiceSummaryTable
			(SupName,UniqSupno,CreditStatus,FirstDue,SecondDue,ThirdDue,CurrentDue,OpenSoBalance,CurrencyType,UseLatestExchangeRate)
			SELECT S.SUPNAME AS CustName,AP.UniqSupno AS UniqSupno,'OK' CreditStatus,
			SUM(FirstDue) AS FirstDue, SUM(SecondDue) AS SecondDue, SUM(ThirdDue) AS ThirdDue,SUM(CurrentDue) AS CurrentDue,
			0 AS OpenSoBalance, @currencyType, @lLatestRate
			FROM APSummary  AP
			INNER JOIN SUPINFO S on AP.UNIQSUPNO = S.UNIQSUPNO AND S.FcUsed_uniq = ISNULL(@fcUsedUniq,S.FcUsed_uniq)
			--OUTER APPLY (
			--	 SELECT SUM(ROUND(CASE WHEN SOPRICES.FLAT = 0 and RecordType = 'P' THEN (Price * Balance) 
			--			WHEN SOPRICES.FLAT = 0 and Quantity > ShippedQty THEN (Price *(Quantity - ShippedQty)) 
			--			WHEN SOPRICES.FLAT = 1 and Sodetail.SHIPPEDQTY=0 THEN Price
			--			ELSE 0.00 END ,2)) AS Amt
			--		FROM SOMAIN
			--		INNER JOIN SODETAIL ON SOMAIN.SONO = SODETAIL.SONO AND SOMAIN.ORD_TYPE = 'Open' AND SOMAIN.CUSTNO = ArSummary.CUSTNO
			--		INNER JOIN SOPRICES   ON SODETAIL.UNIQUELN = SOPRICES.UNIQUELN 
			--) AS OpenSOInfo
			GROUP BY AP.UNIQSUPNO,S.SUPNAME
		END

			;WITH InvoiceSummary AS(
	SELECT InvoiceSummaryTable.SupName,InvoiceSummaryTable.UniqSupno,CreditStatus,FirstDue,SecondDue,ThirdDue,CurrentDue,OpenSoBalance,
	(TotalDaysLate/TotalInvoiceLate) AS AvgDaysLate,CurrentDue + FirstDue + SecondDue + ThirdDue AS Balance,0 AS AvailableCredit,
	CONCAT(TotalInvoiceLate,' / ',TotalInvoicePending) AS InvoicePastDue,CurrencyType,UseLatestExchangeRate
	FROM @invoiceSummaryTable AS InvoiceSummaryTable
	INNER JOIN @invoiceLateTable AS InvoiceLateTable ON InvoiceSummaryTable.UniqSupno = InvoiceLateTable.UniqSupno
	LEFT JOIN @totalInvoiceTable AS TotalInvoiceTable  ON InvoiceSummaryTable.UniqSupno = TotalInvoiceTable.UniqSupno
	--INNER JOIN @customerCreditAvailableTable AS CreditAvailableTable ON InvoiceSummaryTable.UniqSupno = CreditAvailableTable.UniqSupno
	)

	SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM InvoiceSummary

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
			  + ' ORDER BY SupName OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' 
		   END
		   ELSE
			 BEGIN
			  SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t'
			   + ' ORDER BY SupName OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'
	END
	EXEC SP_EXECUTESQL @SQL
END