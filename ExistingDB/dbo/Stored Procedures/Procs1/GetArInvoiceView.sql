
-- ==========================================================================================  
-- Author:  <Nilesh Sa>  
-- Create date: <14/08/2018>  
-- Description: Get invoice View 
-- exec [dbo].[GetArInvoiceView] '0000000001','49f80792-e15e-4b62-b720-21b360e3108a','','','',null,0,150,'',''
-- 09/04/2018 YS my suggestion
-- 09/28/2018 Nilesh sa : modified SP with bank and functional currency amount calcualtions and added some parameters
-- 11/05/2018 Nilesh sa : Added new parameter deposit date 
-- 08/07/2019 Nitesh B : Added LEFT JOIN ARCREDIT to get REC_DATE 
-- 09/25/2019 Nitesh B : Get OriginalBalance, OriginalDiscountAvl, IsChecked, AppliedBk,  DiscountTaken columns and Change filter operation in SP
-- 09/25/2019 Nitesh B : Remove filter operation 
-- ==========================================================================================  
CREATE PROCEDURE [dbo].[GetArInvoiceView]  
    --DECLARE  
	@custNo VARCHAR(MAX) = '' ,
	@userId uniqueidentifier = null, 
	-- 09/28/2018 Nilesh sa : modified SP with bank and functional currency amount calcualtions and added some parameters
	@currencyType VARCHAR(50) ='DepositCurrency',
	@depositFcusedUniq CHAR(10) = '',
	@bankFcusedUniq CHAR(10) = '',
	-- 11/05/2018 Nilesh sa : Added new paramter deposit date 
	@depositDate smalldatetime = null, 
      @startRecord INT = 0,  
      @endRecord INT = 150,   
      @sortExpression NVARCHAR(1000) = NULL,
	@filter NVARCHAR(1000) = NULL
AS  
BEGIN  
	SET NOCOUNT ON;  
 DECLARE @SQL nvarchar(MAX),@lFCInstalled bit,@depositFcHistoryKey CHAR(10),@bankFcHistoryKey CHAR(10),@funcFcHistoryKey CHAR(10),@rowCount NVARCHAR(MAX);    
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled();

	/*CUSTOMER LIST*/    
    DECLARE @tCustomer as tCustomer;  
    DECLARE @Customer TABLE (custno char(10));
	DECLARE @invoiceDetails TABLE(CustName CHAR(100),InvoiceNumber CHAR(10),InvoiceDate SMALLDATETIME,DueDate SMALLDATETIME
 ,InvoiceAmount NUMERIC(20,2),Balance NUMERIC(20,2), OriginalBalance NUMERIC(20,2),Applied NUMERIC(20,2),CustNo CHAR(10),UniqueAr CHAR(10), DiscountAvl NUMERIC(20,2)
 ,OriginalDiscountAvl NUMERIC(20,2),NoteCount INT);   -- 09/25/2019 Nitesh B : Get OriginalBalance, OriginalDiscountAvl

	IF(@sortExpression = NULL OR @sortExpression = '')
	BEGIN
		SET @sortExpression = 'DueDate asc'
	END
	
    -- get list of customers for @userid with access  
    INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All';  
    
	IF @custNo IS NOT NULL AND @custNo <> '' AND @custNo <> 'All'  
		BEGIN
		   INSERT INTO @Customer SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@custNo,',')  WHERE CAST (id AS CHAR(10)) IN (SELECT CustNo FROM @tCustomer)  
        END
	ELSE  
	IF @custNo='All'   
		BEGIN  
		  INSERT INTO @Customer SELECT CustNo FROM @tCustomer  
		END  

	IF @lFCInstalled = 0 
		BEGIN
			INSERT INTO @invoiceDetails
			SELECT DISTINCT CUSTOMER.CUSTNAME AS CustName
			,dbo.fRemoveLeadingZeros(A.INVNO) AS InvoiceNumber
			,A.INVDATE AS InvoiceDate
			,A.DUE_DATE AS DueDate
			,A.INVTOTAL AS InvoiceAmount
			,(A.INVTOTAL - A.ARCREDITS ) AS Balance
      ,(A.INVTOTAL - A.ARCREDITS ) AS OriginalBalance   -- 09/25/2019 Nitesh B : Get OriginalBalance, OriginalDiscountAvl
			,CAST(0.00 AS NUMERIC(20,2)) AS Applied
			,CUSTOMER.CUSTNO AS CustNo,A.UNIQUEAR AS UniqueAr
			,CASE WHEN t.DISC_PCT IS NULL OR t.DISC_PCT=0.0 THEN 0.00
			 WHEN DATEDIFF(DAY,AC.REC_DATE,DATEADD(DAY,t.DISC_DAYS,a.INVDATE)) < 0 THEN 0.00
			 --- 09/04/2018 YS my suggestion
			 WHEN ROUND((DISC_PCT*A.INVTOTAL/100),2)> A.DiscTaken THEN ROUND((DISC_PCT*A.INVTOTAL/100),2)- A.DiscTaken
			 ELSE 0.00 END AS DiscountAvl

  	-- 09/25/2019 Nitesh B : Get OriginalBalance, OriginalDiscountAvl
     ,CASE WHEN t.DISC_PCT IS NULL OR t.DISC_PCT=0.0 THEN 0.00    
      WHEN DATEDIFF(DAY,AC.REC_DATE,DATEADD(DAY,t.DISC_DAYS,a.INVDATE)) < 0 THEN 0.00      
      WHEN ROUND((DISC_PCT*A.INVTOTAL/100),2)> A.DiscTaken THEN ROUND((DISC_PCT*A.INVTOTAL/100),2)- A.DiscTaken    
      ELSE 0.00 END AS OriginalDiscountAvl 
	   
			 ,ISNULL(NoteDetails.NoteCount,0) AS NoteCount
			FROM ACCTSREC A
			LEFT JOIN ARCREDIT AC ON A.UNIQUEAR = AC.UNIQUEAR -- 08/07/2019 Nitesh B : Added LEFT JOIN ARCREDIT to get REC_DATE
			--JOIN CUSTOMER on A.CUSTNO =  CUSTOMER.CUSTNO AND 1 = CASE WHEN Customer.CUSTNO IN (SELECT CUSTNO FROM @customer) THEN 1 ELSE 0 END
			JOIN CUSTOMER on A.CUSTNO = CUSTOMER.CUSTNO 
			JOIN @customer c on customer.custno=c.custno
			LEFT OUTER JOIN PLMAIN P ON A.invno = P.invoiceno  
			LEFT OUTER JOIN PMTTERMS T ON p.TERMS = t.DESCRIPT
			OUTER APPLY (SELECT COUNT(wmNoteRelationship.NoteRelationshipId) As NoteCount
						FROM WmNotes 
						LEFT JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId
						WHERE wmNotes.RecordType='AcctsRec' AND wmNotes.RecordId = A.uniquear
				) NoteDetails
			WHERE A.lPrepay = 0 AND A.isManualCm = 0 AND (A.INVTOTAL - A.ARCREDITS) > 0
			ORDER BY A.DUE_DATE 
		END
	ELSE
		BEGIN
			-- 11/05/2018 Nilesh sa : Added new paramter deposit date 
			SELECT TOP 1 @depositFcHistoryKey = Fchist_key FROM FcHistory WHERE Fcused_Uniq= @depositFcusedUniq AND FcDateTime <= @depositDate ORDER BY FcDateTime DESC
			SELECT TOP 1 @bankFcHistoryKey = Fchist_key FROM FcHistory WHERE Fcused_Uniq= @bankFcusedUniq  AND FcDateTime <= @depositDate  ORDER BY FcDateTime DESC

			INSERT INTO @invoiceDetails
			SELECT DISTINCT CUSTOMER.CUSTNAME AS CustName
			,dbo.fRemoveLeadingZeros(A.INVNO) AS InvoiceNumber
			,A.INVDATE AS InvoiceDate
			,A.DUE_DATE AS DueDate
			-- 28/09/2018 Nilesh sa : modified SP with bank and functional currency amount calcualtions and added some parameters
			,CASE WHEN @currencyType ='FunctionalCurrency' 
					THEN dbo.fn_Convert4FCHC('F',@depositFcusedUniq,A.INVTOTALFC,dbo.fn_GetFunctionalCurrency(),@depositFcHistoryKey) 
				  WHEN @currencyType ='BankCurrency' 
					THEN dbo.fn_Convert4FCHC('H',@bankFcusedUniq,dbo.fn_Convert4FCHC('F',@depositFcusedUniq,A.INVTOTALFC,dbo.fn_GetFunctionalCurrency(),@depositFcHistoryKey) ,dbo.fn_GetFunctionalCurrency(),@bankFcHistoryKey) 
				  ELSE  A.INVTOTALFC  END AS InvoiceAmount
   
      ,CASE WHEN @currencyType ='FunctionalCurrency' 
					THEN dbo.fn_Convert4FCHC('F',@depositFcusedUniq,(A.INVTOTALFC - A.ARCREDITSFC),dbo.fn_GetFunctionalCurrency(),@depositFcHistoryKey) 
				  WHEN @currencyType ='BankCurrency' 
					THEN dbo.fn_Convert4FCHC('H',@bankFcusedUniq,dbo.fn_Convert4FCHC('F',@depositFcusedUniq,(A.INVTOTALFC - A.ARCREDITSFC),dbo.fn_GetFunctionalCurrency(),@depositFcHistoryKey) ,dbo.fn_GetFunctionalCurrency(),@bankFcHistoryKey) 
				  ELSE  (A.INVTOTALFC - A.ARCREDITSFC)  END AS Balance
  	 -- 09/25/2019 Nitesh B : Get OriginalBalance, OriginalDiscountAvl  
     ,CASE WHEN @currencyType ='FunctionalCurrency'     
       THEN dbo.fn_Convert4FCHC('F',@depositFcusedUniq,(A.INVTOTALFC - A.ARCREDITSFC),dbo.fn_GetFunctionalCurrency(),@depositFcHistoryKey)     
        WHEN @currencyType ='BankCurrency'     
       THEN dbo.fn_Convert4FCHC('H',@bankFcusedUniq,dbo.fn_Convert4FCHC('F',@depositFcusedUniq,(A.INVTOTALFC - A.ARCREDITSFC),dbo.fn_GetFunctionalCurrency(),@depositFcHistoryKey) ,dbo.fn_GetFunctionalCurrency(),@bankFcHistoryKey)     
        ELSE  (A.INVTOTALFC - A.ARCREDITSFC)  END AS OriginalBalance	
	        
			,CAST(0.0 AS NUMERIC(20,2)) AS Applied
			,CUSTOMER.CUSTNO As CustNo,A.UNIQUEAR AS UniqueAr
			,CASE WHEN @currencyType ='FunctionalCurrency' 
					THEN dbo.fn_Convert4FCHC('F',@depositFcusedUniq,CASE WHEN t.DISC_PCT IS NULL OR t.DISC_PCT=0.0 THEN 0.00
						WHEN DATEDIFF(DAY,AC.REC_DATE,DATEADD(DAY,t.DISC_DAYS,a.INVDATE))<0 THEN 0.00
						WHEN ROUND((DISC_PCT*A.INVTOTALFC/100),2)>A.DiscTakenFc THEN ROUND((DISC_PCT*A.INVTOTALFC/100),2)-A.DiscTakenFc
						ELSE 0.00 END  ,dbo.fn_GetFunctionalCurrency(),@depositFcHistoryKey) 
				  WHEN @currencyType ='BankCurrency' 
					THEN dbo.fn_Convert4FCHC('H',@bankFcusedUniq,dbo.fn_Convert4FCHC('F',@depositFcusedUniq,
						CASE WHEN t.DISC_PCT IS NULL OR t.DISC_PCT=0.0 THEN 0.00
							WHEN DATEDIFF(DAY,AC.REC_DATE,DATEADD(DAY,t.DISC_DAYS,a.INVDATE))<0 THEN 0.00
						WHEN ROUND((DISC_PCT*A.INVTOTALFC/100),2) > A.DiscTakenFc THEN ROUND((DISC_PCT*A.INVTOTALFC/100),2)-A.DiscTakenFc
						ELSE 0.00 END  
					,dbo.fn_GetFunctionalCurrency(),@depositFcHistoryKey) ,dbo.fn_GetFunctionalCurrency(),@bankFcHistoryKey) 
				  ELSE  
						CASE WHEN t.DISC_PCT IS NULL OR t.DISC_PCT=0.0 THEN 0.00
						WHEN DATEDIFF(DAY,AC.REC_DATE,DATEADD(DAY,t.DISC_DAYS,a.INVDATE))<0 THEN 0.00
							--- 09/04/2018 YS my suggestion
						WHEN ROUND((DISC_PCT*A.INVTOTALFC/100),2) > A.DiscTakenFc THEN ROUND((DISC_PCT*A.INVTOTALFC/100),2)- A.DiscTakenFc
						ELSE 0.00 END  END  AS DiscountAvl

	-- 09/25/2019 Nitesh B : Get OriginalBalance, OriginalDiscountAvl
   ,CASE WHEN @currencyType ='FunctionalCurrency'     
     THEN dbo.fn_Convert4FCHC('F',@depositFcusedUniq,CASE WHEN t.DISC_PCT IS NULL OR t.DISC_PCT=0.0 THEN 0.00    
      WHEN DATEDIFF(DAY,AC.REC_DATE,DATEADD(DAY,t.DISC_DAYS,a.INVDATE))<0 THEN 0.00    
      WHEN ROUND((DISC_PCT*A.INVTOTALFC/100),2)>A.DiscTakenFc THEN ROUND((DISC_PCT*A.INVTOTALFC/100),2)-A.DiscTakenFc    
      ELSE 0.00 END  ,dbo.fn_GetFunctionalCurrency(),@depositFcHistoryKey)     
      WHEN @currencyType ='BankCurrency'     
     THEN dbo.fn_Convert4FCHC('H',@bankFcusedUniq,dbo.fn_Convert4FCHC('F',@depositFcusedUniq,    
      CASE WHEN t.DISC_PCT IS NULL OR t.DISC_PCT=0.0 THEN 0.00    
       WHEN DATEDIFF(DAY,AC.REC_DATE,DATEADD(DAY,t.DISC_DAYS,a.INVDATE))<0 THEN 0.00    
      WHEN ROUND((DISC_PCT*A.INVTOTALFC/100),2) > A.DiscTakenFc THEN ROUND((DISC_PCT*A.INVTOTALFC/100),2)-A.DiscTakenFc    
      ELSE 0.00 END      
     ,dbo.fn_GetFunctionalCurrency(),@depositFcHistoryKey) ,dbo.fn_GetFunctionalCurrency(),@bankFcHistoryKey)     
      ELSE      
      CASE WHEN t.DISC_PCT IS NULL OR t.DISC_PCT=0.0 THEN 0.00    
      WHEN DATEDIFF(DAY,AC.REC_DATE,DATEADD(DAY,t.DISC_DAYS,a.INVDATE))<0 THEN 0.00    
       --- 09/04/2018 YS my suggestion    
      WHEN ROUND((DISC_PCT*A.INVTOTALFC/100),2) > A.DiscTakenFc THEN ROUND((DISC_PCT*A.INVTOTALFC/100),2)- A.DiscTakenFc    
      ELSE 0.00 END  END  AS OriginalDiscountAvl
	    
			,ISNULL(NoteDetails.NoteCount,0) AS NoteCount
			FROM ACCTSREC A
			LEFT JOIN ARCREDIT AC ON A.UNIQUEAR = AC.UNIQUEAR -- 08/07/2019 Nitesh B : Added LEFT JOIN ARCREDIT to get REC_DATE
			--JOIN CUSTOMER on A.CUSTNO =  CUSTOMER.CUSTNO AND 1 = CASE WHEN Customer.CUSTNO IN (SELECT CUSTNO FROM @customer) THEN 1 ELSE 0 END
			JOIN CUSTOMER on A.CUSTNO = CUSTOMER.CUSTNO 
			JOIN @customer c on customer.custno=c.custno
			LEFT OUTER JOIN PLMAIN P ON A.INVNO = P.INVOICENO  
			LEFT OUTER JOIN PMTTERMS T ON p.TERMS = t.DESCRIPT
			OUTER APPLY (SELECT COUNT(wmNoteRelationship.NoteRelationshipId) As NoteCount
						FROM WmNotes 
						LEFT JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId
						WHERE wmNotes.RecordType='AcctsRec' AND wmNotes.RecordId = A.uniquear
				) NoteDetails
			WHERE A.lPrepay = 0 AND A.isManualCm = 0 AND (A.INVTOTALFC - A.ARCREDITSFC) > 0
			ORDER BY A.DUE_DATE 
		END

 SELECT IDENTITY(INT,1,1) AS RowNumber, CAST(0 AS BIT ) AS IsChecked, CAST(0.00 AS NUMERIC(20,2)) AS AppliedBk, 
 CAST(0.00 AS NUMERIC(20,2)) AS DiscountTaken, * INTO #TEMP FROM @invoiceDetails    
  -- 09/25/2019 Nitesh B : Get IsChecked, AppliedBk,  DiscountTaken columns and Change filter operation in SP
 SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #TEMP',@filter,@sortExpression,'','DueDate',@startRecord,@endRecord))         
      EXEC sp_executesql @rowCount      

 SET @SQL =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #TEMP',@filter,@sortExpression,N'DueDate','',@startRecord,@endRecord))    
   EXEC sp_executesql @SQL  
   
 -- 09/25/2019 Nitesh B : Remove filter operation 
 --IF @filter <> '' AND @sortExpression <> ''    
 --  BEGIN    
 --       SET @SQL=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE '+@filter    
 --        +' ORDER BY '+ @SortExpression+''+ ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'    
 --  END    
 -- ELSE IF @filter = '' AND @sortExpression <> ''    
 --  BEGIN    
 --     SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t '      
 --     +' ORDER BY '+ @sortExpression+'' + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'     
 --  END  ''    
  
 --ELSE IF @filter <> '' AND @sortExpression =    BEGIN    
 --     SET @SQL=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+''     
 --     + ' ORDER BY DueDate OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'     
 --  END    
 --  ELSE    
 --  BEGIN    
 --      SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t'    
 --       + ' ORDER BY DueDate OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'    
 --  END    
 --EXEC SP_EXECUTESQL @SQL    
END