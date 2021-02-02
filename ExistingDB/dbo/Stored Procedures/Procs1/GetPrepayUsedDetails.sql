
-- =============================================
-- Author:		<Nilesh Sa>
-- Create date: <02/21/2019>
-- Description:	Get Prepay used details
-- exec GetPrepayUsedDetails '0000000002','PPayNEW',0,100,'','','','',''
-- Nilesh Sa 3/06/2018 Check for trans balance first
-- =============================================
CREATE PROCEDURE [dbo].[GetPrepayUsedDetails]
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

    DECLARE @prepayDetailTable TABLE(InvoiceNo CHAR(10),DateApplied SMALLDATETIME,AmountApplied NUMERIC(12,2));
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
					INSERT INTO @prepayDetailTable
					SELECT 
					dbo.fRemoveLeadingZeros(AROFFSET.INVNO) AS InvoiceNo
					,DATE AS DateApplied
					,CASE WHEN ISNULL(ABS(AMOUNTFC),0) = 0 THEN 0.00 ELSE ABS(AMOUNTPR) END AS AppliedAmount
					FROM AROFFSET
					JOIN ACCTSREC ON AROFFSET.uniquear = ACCTSREC.UNIQUEAR AND isManualCm = 0 AND lPrepay = 0 
					WHERE CTRANSACTION IN (SELECT DISTINCT CTRANSACTION FROM AROFFSET WHERE INVNO = @prepayNo AND CUSTNO = @custNo)
				END
			 ELSE  
				BEGIN  
					INSERT INTO @prepayDetailTable
					SELECT 
					Dbo.fRemoveLeadingZeros(AROFFSET.INVNO) AS InvoiceNo
					,DATE AS DateApplied
					,CAST(ABS(AMOUNTFC)/FcUsed.AskPricePR AS numeric(20,2)) AS AppliedAmount
					FROM AROFFSET
					JOIN ACCTSREC ON AROFFSET.uniquear = ACCTSREC.UNIQUEAR AND isManualCm = 0 AND lPrepay = 0 
					JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
					LEFT OUTER JOIN @fcUsedViewTable FcUsed ON  FcUsed.FcUsedUniq = CUSTOMER.FcUsed_uniq
					WHERE CTRANSACTION IN (SELECT DISTINCT CTRANSACTION FROM AROFFSET WHERE INVNO = @prepayNo AND CUSTNO = @custNo)
				END
	     END  
     ELSE IF @lFCInstalled = 1 AND @currencyType = 'F'    
			     BEGIN  
					INSERT INTO @prepayDetailTable
					SELECT
					Dbo.fRemoveLeadingZeros(AROFFSET.INVNO) AS InvoiceNo
					,DATE AS DateApplied
					,ABS(AMOUNTFC) AS AppliedAmount
					FROM AROFFSET
					JOIN ACCTSREC ON AROFFSET.uniquear = ACCTSREC.UNIQUEAR AND isManualCm = 0 AND lPrepay = 0 
					WHERE CTRANSACTION IN (SELECT DISTINCT CTRANSACTION FROM AROFFSET WHERE INVNO =@prepayNo AND CUSTNO = @custNo)
			     END
       ELSE   
	     BEGIN  
			IF @lLatestRate = 0   
			     BEGIN  
					INSERT INTO @prepayDetailTable
					SELECT 
					Dbo.fRemoveLeadingZeros(AROFFSET.INVNO) AS InvoiceNo
					,DATE AS DateApplied
					,ABS(AMOUNT) AS AppliedAmount
					FROM AROFFSET
					JOIN ACCTSREC ON AROFFSET.uniquear = ACCTSREC.UNIQUEAR AND isManualCm = 0 AND lPrepay = 0 
					WHERE CTRANSACTION IN (SELECT DISTINCT CTRANSACTION FROM AROFFSET WHERE INVNO =@prepayNo AND CUSTNO = @custNo)
			     END
                  ELSE
				 BEGIN  
					INSERT INTO @prepayDetailTable
					SELECT 
					Dbo.fRemoveLeadingZeros(AROFFSET.INVNO) AS InvoiceNo
					,DATE AS DateApplied
					,CAST(ABS(AMOUNTFC)/FcUsed.AskPrice AS numeric(20,2)) AS AppliedAmount
					FROM AROFFSET
					JOIN ACCTSREC ON AROFFSET.uniquear = ACCTSREC.UNIQUEAR AND isManualCm = 0 AND lPrepay = 0 
					JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
					LEFT OUTER JOIN @fcUsedViewTable FcUsed ON  FcUsed.FcUsedUniq = CUSTOMER.FcUsed_uniq
					WHERE CTRANSACTION IN (SELECT DISTINCT CTRANSACTION FROM AROFFSET WHERE INVNO =@prepayNo AND CUSTNO = @custNo)
			     END
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