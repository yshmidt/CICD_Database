
-- =============================================
-- Author:		<Nilesh Sa>
-- Create date: <12/31/2018>
-- Description:	Get Credit memo 
-- exec GetCreditMemo '0000000001',1,100,'',''
-- Nilesh Sa 3/06/2018 Check for trans balance first
-- =============================================

CREATE PROCEDURE [dbo].[GetCreditMemo]
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
	 
	DECLARE @creditMemoTable TABLE(CreditMemoNo CHAR(10),MemoAmount NUMERIC(12,2),ReceiveDate SMALLDATETIME,Balance NUMERIC(12,2)
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
		SET @sortExpression = 'CreditMemoNo asc'
	END

	SELECT @lFCInstalled = dbo.fn_IsFCInstalled();

	    IF @lFCInstalled = 1 AND @currencyType = 'P'    
	     BEGIN  
			IF @lLatestRate = 0   
				BEGIN
					INSERT INTO @creditMemoTable
					SELECT DISTINCT 
					     ACCTSREC.INVNO AS CreditMemoNo
					    ,CASE WHEN ISNULL(CMMAIN.CMTOTALFC,0) = 0 THEN 0.00 ELSE CMMAIN.CMTOTALPR END AS MemoAmount
					    ,CMMAIN.CMDATE As ReceiveDate 
					    ,CASE WHEN ISNULL(ACCTSREC.ARCREDITSFC,0) = 0 THEN 0.00 ELSE ACCTSREC.ARCREDITSPR END AS Balance
					    ,ACCTSREC.UNIQUEAR AS UniqueAr  
					    ,ACCTSREC.CUSTNO as CustNo  
					FROM  ACCTSREC
					JOIN CMMAIN ON ACCTSREC.INVNO = CMMAIN.INVOICENO 
					WHERE ACCTSREC.CUSTNO =@custNo AND ACCTSREC.ARCREDITSPR > 0 AND ACCTSREC.isManualCm = 1;
				END
			 ELSE  
				BEGIN  
					INSERT INTO @creditMemoTable
					SELECT DISTINCT 
					     ACCTSREC.INVNO AS CreditMemoNo
					    ,CAST(CMMAIN.CMTOTALFC/FcUsed.AskPricePR AS numeric(20,2)) AS MemoAmount
					    ,CMMAIN.CMDATE As ReceiveDate 
					    ,CAST(ACCTSREC.ARCREDITSFC/FcUsed.AskPricePR AS numeric(20,2))  AS Balance  
					    ,ACCTSREC.UNIQUEAR AS UniqueAr  
					    ,ACCTSREC.CUSTNO as CustNo  
					FROM  ACCTSREC
					JOIN CMMAIN ON ACCTSREC.INVNO = CMMAIN.INVOICENO
					JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
					LEFT OUTER JOIN @fcUsedViewTable FcUsed ON  FcUsed.FcUsedUniq = CUSTOMER.FcUsed_uniq
					WHERE ACCTSREC.CUSTNO =@custNo AND ACCTSREC.isManualCm = 1 AND ACCTSREC.ARCREDITSFC > 0; 
				END
	     END  
     ELSE IF @lFCInstalled = 1 AND @currencyType = 'F'    
	     BEGIN  
			INSERT INTO @creditMemoTable
			SELECT DISTINCT 
				     ACCTSREC.INVNO AS CreditMemoNo
				    ,CMMAIN.CMTOTALFC AS MemoAmount
				    ,CMMAIN.CMDATE As ReceiveDate 
				    ,ACCTSREC.ARCREDITSFC AS Balance  
				    ,ACCTSREC.UNIQUEAR AS UniqueAr  
				    ,ACCTSREC.CUSTNO as CustNo  
			FROM  ACCTSREC
			JOIN CMMAIN ON ACCTSREC.INVNO = CMMAIN.INVOICENO
			WHERE ACCTSREC.CUSTNO =@custNo AND ACCTSREC.isManualCm = 1 AND ACCTSREC.ARCREDITSFC > 0;
	     END
       ELSE   
	     BEGIN  
			IF @lLatestRate = 0   
			     BEGIN  
					 INSERT INTO @creditMemoTable
					 SELECT DISTINCT 
					 ACCTSREC.INVNO AS CreditMemoNo
				      ,CMMAIN.CMTOTAL AS MemoAmount
				      ,CMMAIN.CMDATE As ReceiveDate 
				      ,ACCTSREC.ARCREDITS AS Balance  
				      ,ACCTSREC.UNIQUEAR AS UniqueAr  
				      ,ACCTSREC.CUSTNO as CustNo  
					 FROM  ACCTSREC
					 JOIN CMMAIN on ACCTSREC.INVNO = CMMAIN.INVOICENO
					 WHERE ACCTSREC.CUSTNO =@custNo AND ACCTSREC.isManualCm = 1 AND ACCTSREC.ARCREDITS > 0;
			     END
                  ELSE
				 BEGIN  
					 INSERT INTO @creditMemoTable
					 SELECT DISTINCT 
					 ACCTSREC.INVNO AS CreditMemoNo
				      ,CAST(CMMAIN.CMTOTALFC/FcUsed.AskPrice AS numeric(20,2)) AS MemoAmount
					,CMMAIN.CMDATE As ReceiveDate 
					,CAST(ACCTSREC.ARCREDITSFC/FcUsed.AskPrice AS numeric(20,2)) AS Balance  
				      ,ACCTSREC.UNIQUEAR AS UniqueAr  
				      ,ACCTSREC.CUSTNO as CustNo  
				      FROM  ACCTSREC
				      JOIN CMMAIN on ACCTSREC.INVNO = CMMAIN.INVOICENO
					JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
					LEFT OUTER JOIN @fcUsedViewTable FcUsed ON  FcUsed.FcUsedUniq = CUSTOMER.FcUsed_uniq
				      WHERE ACCTSREC.CUSTNO =@custNo AND ACCTSREC.isManualCm = 1 AND ACCTSREC.ARCREDITSFC > 0;
			     END
		END
		

		SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @creditMemoTable

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
				  + ' ORDER BY CreditMemoNo OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;' 
			   END
			   ELSE
				 BEGIN
				  SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t'
				   + ' ORDER BY CreditMemoNo OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'
		END
		EXEC SP_EXECUTESQL @SQL
END