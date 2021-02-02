
-- ==========================================================================================
-- Author:		<Nilesh Sa>
-- Create date: <12/28/2018>
-- Description:	Get Pre pay main memo 
-- exec [GetPrePayMainGrid] '0000000001',0,100,'',''
-- ==========================================================================================
CREATE PROCEDURE [dbo].[GetPrePayMainGrid]
	--DECLARE
	@custNo char(10) = '',
	@startRecord int = 0,
      @endRecord int = 150,
	@sortExpression NVARCHAR(1000) = NULL,
      @filter NVARCHAR(1000) = NULL,
	@currencyType CHAR(10) ='', -- Empty - Functional Currency,P - Presentation Currency, F - Multi Currency    
      @lLatestRate BIT = 0, -- @lLatestRate = 0 => Original Exchange Rate and @lLatestRate = 1 => Most Recent Exchange Rate    
      @fcUsedUniq CHAR(10)=null 
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQL nvarchar(MAX),@lFCInstalled bit;  
	
	DECLARE @prepayTable TABLE(BankName CHAR(10),ReferenceNo CHAR(10),PrepayAmount NUMERIC(12,2),ReceiveDate SMALLDATETIME,Balance NUMERIC(12,2)
		,UniqueAr CHAR(10),CustNo CHAR(10));  

	-- Nilesh Sa 11/30/2018 Created a table to store FCUsedView  
	 DECLARE @fcUsedViewTable TABLE(FcUsedUniq CHAR(10),Country VARCHAR(60),CURRENCY VARCHAR(40), Symbol VARCHAR(3) ,Prefix VARCHAR(7),UNIT VARCHAR(10),Subunit VARCHAR(10),  
	 Thou_sep VARCHAR(1),Deci_Sep VARCHAR(1),Deci_no NUMERIC(2,0),AskPrice NUMERIC(13,5),AskPricePR NUMERIC(13,5),FcHist_key CHAR(10),FcdateTime SMALLDATETIME);    
    
	 SELECT @lFCInstalled = dbo.fn_IsFCInstalled()    
    
	IF @lFCInstalled = 1
	BEGIN
		  -- Fetch FCUsed data and inserting to temp table  
		  INSERT INTO @fcUsedViewTable  EXEC FcUsedView;  
	END

	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'ReferenceNo asc'
	END

     IF @lFCInstalled = 1 AND @currencyType = 'P'    
	     BEGIN  
			IF @lLatestRate = 0   
				BEGIN
					INSERT INTO @prepayTable
					SELECT ac.BANKCODE AS BankName
						,ac.INVNO AS ReferenceNo
						,ac.REC_AMOUNTPR AS PrepayAmount
						,ac.REC_DATE As ReceiveDate 
						,ar.ARCREDITSPR AS Balance
						,ac.UNIQUEAR AS UniqueAr
						,ac.CUSTNO as CustNo
					FROM ARCREDIT ac
					JOIN ACCTSREC ar ON ac.uniquear = ar.UNIQUEAR
					WHERE ar.lPrepay = 1 
					AND ac.REC_TYPE ='PrePay'
					AND ar.ARCREDITSPR > 0 
					AND ar.CUSTNO = @custNo		
				END
			 ELSE  
				BEGIN  
					INSERT INTO @prepayTable
					SELECT ac.BANKCODE AS BankName
						,ac.INVNO AS ReferenceNo
						,CAST(ac.REC_AMOUNTFC/FcUsed.AskPricePR AS numeric(20,2)) AS PrepayAmount
						,ac.REC_DATE As ReceiveDate 
						,CAST(ar.ARCREDITSFC/FcUsed.AskPricePR AS numeric(20,2)) AS Balance
						,ac.UNIQUEAR AS UniqueAr
						,ac.CUSTNO as CustNo
					FROM ARCREDIT ac
					JOIN ACCTSREC ar ON ac.uniquear = ar.UNIQUEAR
					JOIN CUSTOMER ON ar.CUSTNO = CUSTOMER.CUSTNO
					LEFT OUTER JOIN @fcUsedViewTable FcUsed ON  FcUsed.FcUsedUniq = CUSTOMER.FcUsed_uniq
					WHERE ar.lPrepay = 1 
					AND ac.REC_TYPE ='PrePay'
					AND ar.ARCREDITSFC > 0 
					AND ar.CUSTNO = @custNo	
				END
	     END  
     ELSE IF @lFCInstalled = 1 AND @currencyType = 'F'    
	     BEGIN  
			INSERT INTO @prepayTable
			SELECT ac.BANKCODE AS BankName
				,ac.INVNO AS ReferenceNo
				,ac.REC_AMOUNTFC AS PrepayAmount
			      ,ac.REC_DATE As ReceiveDate 
			      ,ar.ARCREDITSFC AS Balance
                        ,ac.UNIQUEAR AS UniqueAr
			      ,ac.CUSTNO as CustNo
			FROM ARCREDIT ac
			JOIN ACCTSREC ar ON ac.uniquear = ar.UNIQUEAR
			WHERE ar.lPrepay = 1 
			AND ac.REC_TYPE ='PrePay'
			AND ar.ARCREDITSFC > 0 
			AND ar.CUSTNO = @custNo
	     END
       ELSE   
	     BEGIN  
			IF @lLatestRate = 0   
			     BEGIN  
					INSERT INTO @prepayTable
					SELECT ac.BANKCODE AS BankName
						,ac.INVNO AS ReferenceNo
						,ac.REC_AMOUNT AS PrepayAmount
						,ac.REC_DATE As ReceiveDate 
						,ar.ARCREDITS AS Balance
						,ac.UNIQUEAR AS UniqueAr
						,ac.CUSTNO as CustNo
					FROM ARCREDIT ac
					JOIN ACCTSREC ar ON ac.uniquear = ar.UNIQUEAR
					WHERE ar.lPrepay = 1 
					AND ac.REC_TYPE ='PrePay'
					AND ar.ARCREDITS > 0 
					AND ar.CUSTNO = @custNo
			     END
                  ELSE
				 BEGIN  
					INSERT INTO @prepayTable
					SELECT ac.BANKCODE AS BankName
						,ac.INVNO AS ReferenceNo
						,CAST(ac.REC_AMOUNTFC/FcUsed.AskPrice AS numeric(20,2)) AS PrepayAmount
						,ac.REC_DATE As ReceiveDate 
						,CAST(ar.ARCREDITSFC/FcUsed.AskPrice AS numeric(20,2)) AS Balance
						,ac.UNIQUEAR AS UniqueAr
						,ac.CUSTNO as CustNo
					FROM ARCREDIT ac
					JOIN ACCTSREC ar ON ac.uniquear = ar.UNIQUEAR
					JOIN CUSTOMER ON ar.CUSTNO = CUSTOMER.CUSTNO
					LEFT OUTER JOIN @fcUsedViewTable FcUsed ON  FcUsed.FcUsedUniq = CUSTOMER.FcUsed_uniq
					WHERE ar.lPrepay = 1 
					AND ac.REC_TYPE ='PrePay'
					AND ar.ARCREDITSFC > 0 
					AND ar.CUSTNO = @custNo	
			     END
		END

	SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @prepayTable

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
			  + ' ORDER BY ReferenceNo OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' 
		   END
		   ELSE
			 BEGIN
			  SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t'
			   + ' ORDER BY ReferenceNo OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'
	END
	EXEC SP_EXECUTESQL @SQL
END