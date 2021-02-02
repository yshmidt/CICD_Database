
-- =============================================      
-- Author:  <Nilesh Sa>      
-- Create date: <16/01/2018>      
-- Description: Get AR Summary View      
-- exec [dbo].[GetARSummaryView] 0,150,null,null,'',0,null     
-- Nilesh Sa 11/30/2018 No need of conversion for multi currency   
-- Nilesh Sa 03/05/2019 : Fetch customer based on user id   
-- Nilesh Sa 3/06/2018 Check for trans balance first  
-- Nilesh Sa 5/27/2019 Update initial to username
-- 06/20/19 provide customer list to the SP CalculateCustomerCreditAvailable. See modifications in the SP  
-- 06/20/19 @customerCreditAvailableTable already limited to the requested customers  
-- Nilesh Sa 7/2/2019 Updated inner join to left join
-- Nilesh Sa 7/2/2019 Check null & put 0
-- Nitesh B 01/31/2020 If the customer only has a prepay or Credit Memo with balance need to display in the Invoice Summary Screen
-- Nitesh N 01/31/2020 Added CustDepositCreditMemo to get the prepay and customer memo total for the customer 
-- 03/25/20 YS remove @userid from the parameter list when calling CalculateCustomerCreditAvailable 
-- Shivshnakar P: 08/18/2020 Get IS_INPRINT AS IsInvPrint from PLMAIN to show invoice printed or not on UI
-- EXEC GetARSummaryView 0, 150, null, null, '', 0, '49F80792-E15E-4B62-B720-21B360E3108A'
-- =============================================      
CREATE PROCEDURE [dbo].[GetARSummaryView]      
  --DECLARE      
  @startRecord INT = 0,      
  @endRecord INT = 150,       
  @sortExpression NVARCHAR(1000) = NULL,      
  @filter NVARCHAR(1000) = NULL,      
  @currencyType CHAR(10) ='', -- Empty - Functional Currency,P - Presentation Currency, F - Multi Currency      
  @lLatestRate BIT = 0, -- @lLatestRate = 0 => Original Exchange Rate and @lLatestRate = 1 => Most Recent Exchange Rate      
  @userId uniqueidentifier  = null -- 3/5/2019 Nilesh Added  @userId parameter   
AS      
BEGIN      
 SET NOCOUNT ON;      
      
 IF(@sortExpression = NULL OR @sortExpression = '')      
 BEGIN      
   SET @sortExpression = 'CustName asc'      
 END      
      
 DECLARE @SQL nvarchar(MAX),@today DATE = GETDATE(),@firstDueEnd AS INT,@secondDueEnd AS INT,@lFCInstalled bit;      
  
 -- To store invoice summary details w r to customer      
 DECLARE @invoiceSummaryTable TABLE(CustName CHAR(50),-- 7/16/2018 Nilesh Added  Modified custName column size      
 CustNo CHAR(10),CreditStatus CHAR(15), FirstDue NUMERIC(20,2),SecondDue NUMERIC(20,2),      
       ThirdDue NUMERIC(20,2), CurrentDue NUMERIC(20,2), OpenSoBalance NUMERIC(20,2),CurrencyType CHAR(10),UseLatestExchangeRate BIT,Currency VARCHAR(40),  
	   LastStmtSent DATETIME2(7), Initials nvarchar(512)-- Nilesh Sa 5/27/2019 Update initial to username
    ,CreditAvailable NUMERIC(20,2), CustDepositCreditMemo NUMERIC(20,2));  -- Nitesh N 01/31/2020 Added CustDepositCreditMemo to get the prepay and customer memo total for the customer     
      
 -- To store total days late and Total Invoice Late w r to customer      
 DECLARE @invoiceLateTable TABLE(CUSTNO CHAR(10),TotalDaysLate INT,TotalInvoiceLate INT);      
      
 -- To store total Invoice Late and Not Late w r to customer  
 -- Shivshnakar P: 08/18/2020 Get IS_INPRINT AS IsInvPrint from PLMAIN to show invoice printed or not on UI
 DECLARE @totalInvoiceTable TABLE(CUSTNO CHAR(10),TotalInvoicePending INT, IsInvPrint BIT); -- TotalInvoicePending = Late + Not Late      
      
 -- Nilesh sa 2/26/2019 Modified table bu using Type  
 DECLARE @customerCreditAvailableTable tCustomerCreditAvailable;     
   
 -- Nilesh Sa 11/30/2018 Created a table to store FCUsedView    
 DECLARE @fcUsedViewTable TABLE(FcUsedUniq CHAR(10),Country VARCHAR(60),CURRENCY VARCHAR(40), Symbol VARCHAR(3) ,Prefix VARCHAR(7),UNIT VARCHAR(10),Subunit VARCHAR(10),    
 Thou_sep VARCHAR(1),Deci_Sep VARCHAR(1),Deci_no NUMERIC(2,0),AskPrice NUMERIC(13,5),AskPricePR NUMERIC(13,5),FcHist_key CHAR(10),FcdateTime SMALLDATETIME);      
      
 SELECT @lFCInstalled = dbo.fn_IsFCInstalled()      
      
 -- Get Aging Range For First and second due based on nRange column      
 SELECT @FirstDueEnd = nEnd From AgingRangeSetup WHERE cType='AR' and nRange = 1      
 SELECT @SecondDueEnd = nEnd From AgingRangeSetup WHERE cType='AR' and nRange = 2      
 -- 06/20/19 YS get customer list for the @userid, provide that list to the [CalculateCustomerCreditAvailable] SP  
 DECLARE  @tCustomer as tCustomer  
-- get list of customers for @userid with access  
INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All';    
  
INSERT INTO @customerCreditAvailableTable      
 -- 06/20/19 provide customer list to the SP  
 -- 03/25/20 YS remove @userid from the parameter list when calling CalculateCustomerCreditAvailable  
 EXEC CalculateCustomerCreditAvailable @currencyType,@lLatestRate,@tCustomer  
 --,@userId -- Nilesh Sa 03/05/2019 : Fetch customer based on user id     
  
 IF @lFCInstalled = 1  
 BEGIN  
    -- Fetch FCUsed data and inserting to temp table    
    INSERT INTO @fcUsedViewTable  EXEC FcUsedView;    
 END  
    
IF @lFCInstalled = 1 AND @currencyType = 'P'      
  BEGIN    
  -- Total days late and Total Invoice Late w r to customer     
  INSERT INTO @invoiceLateTable      
  SELECT CUSTNO,ISNULL(Sum(DATEDIFF(Day,DUE_DATE,@Today)),0), COUNT(CUSTNO)       
  FROM ACCTSREC       
  WHERE INVTOTALFC-ARCREDITSFC > 0 AND INVTOTALPR-ARCREDITSPR > 0  AND DUE_DATE < @Today AND lPrepay = 0 AND ISMANUALCM = 0   
  GROUP BY CUSTNO;    
      
  -- Total Invoice Late and Not Late w r to customer 
  -- Shivshnakar P: 08/18/2020 Get IS_INPRINT AS IsInvPrint from PLMAIN to show invoice printed or not on UI
  INSERT INTO @totalInvoiceTable      
  SELECT CUSTNO,COUNT(CUSTNO) AS TotalInvoice, ISNULL(PackListInfo.IS_INPRINT, 1) AS IsInvPrint      
  FROM ACCTSREC 
  OUTER APPLY(SELECT TOP 1 IS_INPRINT FROM PLMAIN WHERE PLMAIN.CUSTNO = ACCTSREC.CUSTNO AND IS_INPRINT = 0 
					AND INV_DUPL = 1 AND PRINT_INVO = 1 AND IS_INVPOST = 1 AND IS_PKPRINT = 1) AS PackListInfo
  WHERE INVTOTALFC-ARCREDITSFC > 0 AND INVTOTALPR-ARCREDITSPR > 0  AND lPrepay = 0 AND ISMANUALCM = 0   
  GROUP BY CUSTNO, PackListInfo.IS_INPRINT;

  -- Nitesh N 01/31/2020 Added CustDepositCreditMemo to get the prepay and customer memo total for the customer 
  IF @lLatestRate = 0     
     BEGIN    
     ;WITH ArSummary AS(    
       SELECT CUSTNO,       
       SUM(CAST(CASE WHEN ISNULL((Acctsrec.INVTOTALFC-Acctsrec.ARCREDITSFC),0) = 0 THEN 0.00  
       ELSE (Acctsrec.InvtotalPR-Acctsrec.ArcreditsPR) END AS NUMERIC(20,2))) AS FirstDue,      
       0 AS SecondDue, 0 AS ThirdDue,0 AS CurrentDue,0 AS CustDepositCreditMemo      
       FROM ACCTSREC       
       WHERE DATEDIFF(Day,DUE_DATE,@Today) >= 1 and DATEDIFF(Day,DUE_DATE,@today) <= @firstDueEnd     
       AND InvtotalPR-ArcreditsPR > 0 AND lPrepay = 0 AND ISMANUALCM = 0     
       GROUP BY CUSTNO      
    UNION      
       SELECT CUSTNO,0 AS FirstDue,       
       SUM(CAST(CASE WHEN ISNULL((Acctsrec.INVTOTALFC-Acctsrec.ARCREDITSFC),0) = 0 THEN 0.00  
       ELSE (Acctsrec.InvtotalPR-Acctsrec.ArcreditsPR) END AS NUMERIC(20,2))) AS SecondDue,      
       0 AS ThirdDue,0 AS CurrentDue,0 AS CustDepositCreditMemo      
       FROM ACCTSREC       
       WHERE DATEDIFF(Day,DUE_DATE,@Today) >= (@firstDueEnd + 1)  and DATEDIFF(Day,DUE_DATE,@today) <= @secondDueEnd      
       AND InvtotalPR-ArcreditsPR > 0 AND lPrepay = 0 AND ISMANUALCM = 0       
       GROUP BY CUSTNO      
    UNION      
       SELECT CUSTNO, 0 AS FirstDue, 0 AS SecondDue,       
       SUM(CAST(CASE WHEN ISNULL((Acctsrec.INVTOTALFC-Acctsrec.ARCREDITSFC),0) = 0 THEN 0.00  
       ELSE (Acctsrec.InvtotalPR-Acctsrec.ArcreditsPR) END AS NUMERIC(20,2))) AS ThirdDue,      
       0 AS CurrentDue,0 AS CustDepositCreditMemo       
       FROM ACCTSREC       
       WHERE DATEDIFF(Day,DUE_DATE,@today) > (@secondDueEnd + 1)  AND InvtotalPR-ArcreditsPR > 0 AND lPrepay = 0     
       AND ISMANUALCM = 0     
       GROUP BY CUSTNO      
    UNION      
       SELECT CUSTNO, 0 AS FirstDue, 0 AS SecondDue, 0 AS ThirdDue,       
       SUM(CAST(CASE WHEN ISNULL((Acctsrec.INVTOTALFC-Acctsrec.ARCREDITSFC),0) = 0 THEN 0.00  
       ELSE (Acctsrec.InvtotalPR-Acctsrec.ArcreditsPR) END AS NUMERIC(20,2))) AS CurrentDue,0 AS CustDepositCreditMemo       
       FROM ACCTSREC       
       WHERE DUE_DATE >= @today      
       AND InvtotalPR-ArcreditsPR > 0 AND lPrepay = 0 AND ISMANUALCM = 0    
       GROUP BY CUSTNO 
	UNION   -- Nitesh B 01/31/2020 If the customer only has a prepay or Credit Memo with balance need to display in the Invoice Summary Screen     
       SELECT CUSTNO, 0 AS FirstDue, 0 AS SecondDue, 0 AS ThirdDue,        
       0 AS CurrentDue, 
	   SUM(CAST(CASE WHEN ISNULL((ARCREDITSFC),0) = 0 THEN 0.00  
       ELSE (ARCREDITSPR) END AS NUMERIC(20,2))) AS CustDepositCreditMemo        
       FROM ACCTSREC        
       WHERE (ARCREDITSPR  > 0 AND INVTOTALPR = 0 AND (lPrepay = 1 OR ISMANUALCM = 1))        
       GROUP BY CUSTNO      
        )       
        INSERT INTO @invoiceSummaryTable      
        (CustName,CustNo,CreditStatus,FirstDue,SecondDue,ThirdDue,CurrentDue,CustDepositCreditMemo,OpenSoBalance,CurrencyType,UseLatestExchangeRate,Currency,LastStmtSent,Initials,CreditAvailable)    
        SELECT CUSTOMER.CUSTNAME AS CustName,ArSummary.CUSTNO AS CustNo,CUSTOMER.CREDITOK AS CreditStatus,      
        SUM(FirstDue) AS FirstDue, SUM(SecondDue) AS SecondDue, SUM(ThirdDue) AS ThirdDue,SUM(CurrentDue) AS CurrentDue,SUM(CustDepositCreditMemo) AS CustDepositCreditMemo,      
        ISNULL(OpenSOInfo.Amt,0) AS OpenSoBalance , @currencyType,@lLatestRate  ,FcConverted.Symbol,   
				 CUSTOMER.LastStmtSent AS LastStmtSent, ISNULL(aspnet_users.UserName,'') AS Initials  -- Nilesh Sa 5/27/2019 Update initial to username
     ,CAST(CreditAvailableTable.CreditAvailable/FcConverted.AskPricePR AS numeric(20,2)) AS AvailableCredit  
        FROM ArSummary       
        INNER JOIN CUSTOMER on ArSummary.CUSTNO = CUSTOMER.CUSTNO   
      -- 06/20/19 @customerCreditAvailableTable already limited to the requested customers  
        --INNER JOIN aspmnx_UserCustomers ON  aspmnx_UserCustomers.fkCustno=Customer.CUSTNO  AND fkUserId = @userId  -- Nilesh Sa 3/5/2019 : Fetch customer based on user id  
        INNER JOIN @customerCreditAvailableTable AS CreditAvailableTable ON ArSummary.CustNo = CreditAvailableTable.CustNo      
        LEFT OUTER JOIN @fcUsedViewTable FcConverted ON  FcConverted.FcUsedUniq = CUSTOMER.FcUsed_uniq  
			     LEFT JOIN  aspnet_users ON CUSTOMER.LastStmtSentUserId = aspnet_users.UserId
        OUTER APPLY (     
      SELECT SUM(ROUND(CASE WHEN SOPRICES.FLAT = 0 and RecordType = 'P' THEN (CASE WHEN ISNULL(PRICEFC,0) = 0 THEN 0 ELSE PRICEPR END * Balance)       
           WHEN SOPRICES.FLAT = 0 and Quantity > ShippedQty THEN (CASE WHEN ISNULL(PRICEFC,0) = 0 THEN 0 ELSE PRICEPR END *(Quantity - ShippedQty))       
           WHEN SOPRICES.FLAT = 1 and Sodetail.SHIPPEDQTY=0 THEN CASE WHEN ISNULL(PRICEFC,0) = 0 THEN 0 ELSE PRICEPR END      
           ELSE 0.00 END ,2)) AS Amt      
      FROM SOMAIN      
      INNER JOIN SODETAIL ON SOMAIN.SONO = SODETAIL.SONO AND SOMAIN.ORD_TYPE = 'Open' AND SOMAIN.CUSTNO = ArSummary.CUSTNO      
      INNER JOIN SOPRICES   ON SODETAIL.UNIQUELN = SOPRICES.UNIQUELN       
        ) AS OpenSOInfo      
        GROUP BY ArSummary.CUSTNO,CUSTOMER.CUSTNAME,CUSTOMER.CREDITOK,OpenSOInfo.Amt ,  
			     FcConverted.Symbol,CUSTOMER.LastStmtSent, aspnet_users.UserName ,CreditAvailableTable.CreditAvailable ,FcConverted.AskPricePR 
     END    
     ELSE    
     BEGIN    
      -- Nitesh N 01/31/2020 Added CustDepositCreditMemo to get the prepay and customer memo total for the customer  
      ;WITH ArSummary AS(    
       SELECT ACCTSREC.CUSTNO,       
       SUM(CAST((INVTOTALFC-ARCREDITSFC) / fc.AskPricePR AS NUMERIC(20,2))) AS FirstDue,      
       0 AS SecondDue, 0 AS ThirdDue,0 AS CurrentDue,0 AS CustDepositCreditMemo      
       FROM ACCTSREC       
       JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO  
       LEFT OUTER JOIN @fcUsedViewTable fc ON CUSTOMER.FcUsed_uniq = fc.FcUsedUniq    
       WHERE DATEDIFF(Day,DUE_DATE,@Today) >= 1 and DATEDIFF(Day,DUE_DATE,@today) <= @firstDueEnd      
       AND INVTOTALFC-ARCREDITSFC > 0 AND lPrepay = 0 AND ISMANUALCM = 0     
       GROUP BY ACCTSREC.CUSTNO      
    UNION      
       SELECT ACCTSREC.CUSTNO,0 AS FirstDue,       
       SUM(CAST((INVTOTALFC-ARCREDITSFC) / fc.AskPricePR AS NUMERIC(20,2))) AS SecondDue,      
       0 AS ThirdDue,0 AS CurrentDue,0 AS CustDepositCreditMemo      
       FROM ACCTSREC       
       JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO  
       LEFT OUTER JOIN @fcUsedViewTable fc ON CUSTOMER.FcUsed_uniq = fc.FcUsedUniq    
       WHERE DATEDIFF(Day,DUE_DATE,@Today) >= (@firstDueEnd + 1)  and DATEDIFF(Day,DUE_DATE,@today) <= @secondDueEnd      
       AND INVTOTALFC-ARCREDITSFC > 0 AND lPrepay = 0 AND ISMANUALCM = 0       
       GROUP BY ACCTSREC.CUSTNO      
    UNION      
       SELECT ACCTSREC.CUSTNO, 0 AS FirstDue, 0 AS SecondDue,       
       SUM(CAST((INVTOTALFC-ARCREDITSFC) / fc.AskPricePR AS NUMERIC(20,2))) AS ThirdDue,      
       0 AS CurrentDue,0 AS CustDepositCreditMemo      
       FROM ACCTSREC       
       JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO  
       LEFT OUTER JOIN @fcUsedViewTable fc ON CUSTOMER.FcUsed_uniq = fc.FcUsedUniq    
       WHERE DATEDIFF(Day,DUE_DATE,@today) > (@secondDueEnd + 1)      
       AND INVTOTALFC-ARCREDITSFC > 0 AND     
       lPrepay = 0 AND ISMANUALCM = 0     
       GROUP BY ACCTSREC.CUSTNO      
    UNION      
       SELECT ACCTSREC.CUSTNO, 0 AS FirstDue, 0 AS SecondDue, 0 AS ThirdDue,       
       SUM(CAST((INVTOTALFC-ARCREDITSFC) / fc.AskPricePR AS NUMERIC(20,2))) AS CurrentDue,0 AS CustDepositCreditMemo      
       FROM ACCTSREC       
       JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO  
       LEFT OUTER JOIN @fcUsedViewTable fc ON CUSTOMER.FcUsed_uniq = fc.FcUsedUniq    
       WHERE DUE_DATE >= @today    
       AND INVTOTALFC-ARCREDITSFC > 0     
       AND lPrepay = 0 AND ISMANUALCM = 0     
       GROUP BY ACCTSREC.CUSTNO 
	UNION    -- Nitesh B 01/31/2020 If the customer only has a prepay or Credit Memo with balance need to display in the Invoice Summary Screen    
       SELECT ACCTSREC.CUSTNO, 0 AS FirstDue, 0 AS SecondDue, 0 AS ThirdDue,        
       0 AS CurrentDue, 
	   SUM(CAST((ARCREDITSFC) / fc.AskPricePR AS NUMERIC(20,2))) AS CustDepositCreditMemo        
       FROM ACCTSREC
	   JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO  
       LEFT OUTER JOIN @fcUsedViewTable fc ON CUSTOMER.FcUsed_uniq = fc.FcUsedUniq         
       WHERE (ARCREDITSFC  > 0 AND INVTOTALFC = 0 AND (lPrepay = 1 OR ISMANUALCM = 1))        
       GROUP BY ACCTSREC.CUSTNO      
        )       
        INSERT INTO @invoiceSummaryTable      
        (CustName,CustNo,CreditStatus,FirstDue,SecondDue,ThirdDue,CurrentDue,CustDepositCreditMemo,OpenSoBalance,CurrencyType,UseLatestExchangeRate,Currency,LastStmtSent,Initials,CreditAvailable)   
     SELECT CUSTOMER.CUSTNAME AS CustName,ArSummary.CUSTNO AS CustNo,CUSTOMER.CREDITOK AS CreditStatus,      
        SUM(FirstDue) AS FirstDue, SUM(SecondDue) AS SecondDue, SUM(ThirdDue) AS ThirdDue,SUM(CurrentDue) AS CurrentDue,SUM(CustDepositCreditMemo) AS CustDepositCreditMemo,      
        ISNULL(OpenSOInfo.Amt,0) AS OpenSoBalance, @currencyType,@lLatestRate  ,FcUsed.Symbol,  
				 CUSTOMER.LastStmtSent AS LastStmtSent, ISNULL(aspnet_users.UserName,'') AS Initials   -- Nilesh Sa 5/27/2019 Update initial to username
    ,CAST(CreditAvailableTable.CreditAvailable/FcUsed.AskPricePR AS numeric(20,2)) AS AvailableCredit   
        FROM ArSummary       
        INNER JOIN CUSTOMER on ArSummary.CUSTNO = CUSTOMER.CUSTNO    
          -- 06/20/19 @customerCreditAvailableTable already limited to the requested customers  
     --INNER JOIN aspmnx_UserCustomers ON  aspmnx_UserCustomers.fkCustno=Customer.CUSTNO  AND fkUserId = @userId  -- Nilesh Sa 3/5/2019 : Fetch customer based on user id  
        INNER JOIN @customerCreditAvailableTable AS CreditAvailableTable ON ArSummary.CustNo = CreditAvailableTable.CustNo    
			     LEFT JOIN  aspnet_users ON CUSTOMER.LastStmtSentUserId = aspnet_users.UserId 
        LEFT OUTER JOIN @fcUsedViewTable FcUsed ON CUSTOMER.FcUsed_uniq = FcUsed.FcUsedUniq   
        OUTER APPLY (      
         SELECT SUM(CAST(ROUND(CASE WHEN SOPRICES.FLAT = 0 and RecordType = 'P' THEN (PriceFC * Balance)       
         WHEN SOPRICES.FLAT = 0 and Quantity > ShippedQty THEN (PriceFC *(Quantity - ShippedQty))       
         WHEN SOPRICES.FLAT = 1 and Sodetail.SHIPPEDQTY=0 THEN PriceFC      
         ELSE 0.00 END ,2) / fc.AskPricePR AS NUMERIC(20,2))) AS Amt      
         FROM SOMAIN      
         INNER JOIN SODETAIL ON SOMAIN.SONO = SODETAIL.SONO AND SOMAIN.ORD_TYPE = 'Open' AND SOMAIN.CUSTNO = ArSummary.CUSTNO      
         INNER JOIN SOPRICES   ON SODETAIL.UNIQUELN = SOPRICES.UNIQUELN       
         JOIN CUSTOMER ON SOMAIN.CUSTNO = CUSTOMER.CUSTNO  
         LEFT OUTER JOIN @fcUsedViewTable fc ON FcUsed.FcUsedUniq = CUSTOMER.FcUsed_uniq  
        ) AS OpenSOInfo      
        GROUP BY ArSummary.CUSTNO,CUSTOMER.CUSTNAME,CUSTOMER.CREDITOK,OpenSOInfo.Amt  ,FcUsed.Symbol ,CUSTOMER.LastStmtSent,   
			     aspnet_users.UserName,  CreditAvailableTable.CreditAvailable,FcUsed.AskPricePR 
     END    
 END      
ELSE IF @lFCInstalled = 1 AND @currencyType = 'F'      
  BEGIN    
     -- Total days late and Total Invoice Late w r to customer      
     INSERT INTO @invoiceLateTable      
     SELECT CUSTNO,ISNULL(Sum(DATEDIFF(Day,DUE_DATE,@Today)),0), COUNT(CUSTNO)       
     FROM ACCTSREC       
     WHERE INVTOTALFC-ARCREDITSFC > 0  AND DUE_DATE < @Today   
     AND lPrepay = 0 AND ISMANUALCM = 0   
     GROUP BY CUSTNO       
      
     -- Total Invoice Late and Not Late w r to customer 
	 -- Shivshnakar P: 08/18/2020 Get IS_INPRINT AS IsInvPrint from PLMAIN to show invoice printed or not on UI
     INSERT INTO @totalInvoiceTable      
     SELECT CUSTNO,COUNT(CUSTNO) AS TotalInvoice, ISNULL(PackListInfo.IS_INPRINT, 1) AS IsInvPrint     
     FROM ACCTSREC
	 OUTER APPLY(SELECT TOP 1 IS_INPRINT FROM PLMAIN WHERE PLMAIN.CUSTNO = ACCTSREC.CUSTNO AND IS_INPRINT = 0 
					AND INV_DUPL = 1 AND PRINT_INVO = 1 AND IS_INVPOST = 1 AND IS_PKPRINT = 1) AS PackListInfo
     WHERE INVTOTALFC-ARCREDITSFC > 0   
     AND lPrepay = 0 AND ISMANUALCM = 0   
     GROUP BY CUSTNO, PackListInfo.IS_INPRINT; 
      
   -- 11/30/2018 No need of conversion for multi currency
   -- Nitesh N 01/31/2020 Added CustDepositCreditMemo to get the prepay and customer memo total for the customer     
     ;WITH ArSummary AS(    
        SELECT CUSTNO,       
        SUM(CAST((INVTOTALFC-ARCREDITSFC) AS numeric(20,2))) AS FirstDue,    
        0 AS SecondDue, 0 AS ThirdDue,0 AS CurrentDue,0 AS CustDepositCreditMemo      
        FROM ACCTSREC       
        WHERE DATEDIFF(Day,DUE_DATE,@Today) >= 1 and DATEDIFF(Day,DUE_DATE,@today) <= @firstDueEnd    
        AND INVTOTALFC-ARCREDITSFC > 0 AND lPrepay = 0 AND ISMANUALCM = 0       
        GROUP BY CUSTNO      
     UNION      
        SELECT CUSTNO,0 AS FirstDue,       
        SUM(CAST((INVTOTALFC-ARCREDITSFC) AS numeric(20,2))) AS SecondDue,    
        0 AS ThirdDue,0 AS CurrentDue,0 AS CustDepositCreditMemo      
        FROM ACCTSREC       
        WHERE DATEDIFF(Day,DUE_DATE,@Today) >= (@firstDueEnd + 1)  and DATEDIFF(Day,DUE_DATE,@today) <= @secondDueEnd    
         AND INVTOTALFC-ARCREDITSFC > 0 AND lPrepay = 0 AND ISMANUALCM = 0       
        GROUP BY CUSTNO      
     UNION      
        SELECT CUSTNO, 0 AS FirstDue, 0 AS SecondDue,       
        SUM(CAST((INVTOTALFC-ARCREDITSFC) AS numeric(20,2))) AS ThirdDue,    
        0 AS CurrentDue,0 AS CustDepositCreditMemo      
        FROM ACCTSREC       
        WHERE DATEDIFF(Day,DUE_DATE,@today) > (@secondDueEnd + 1)   AND INVTOTALFC-ARCREDITSFC > 0   
        AND lPrepay = 0 AND ISMANUALCM = 0   
        GROUP BY CUSTNO      
     UNION      
        SELECT CUSTNO, 0 AS FirstDue, 0 AS SecondDue, 0 AS ThirdDue,       
        SUM(CAST((INVTOTALFC-ARCREDITSFC) AS numeric(20,2))) AS CurrentDue,0 AS CustDepositCreditMemo     
        FROM ACCTSREC       
        WHERE DUE_DATE >= @today   AND INVTOTALFC-ARCREDITSFC > 0   
        AND lPrepay = 0 AND ISMANUALCM = 0      
        GROUP BY CUSTNO
	 UNION   -- Nitesh B 01/31/2020 If the customer only has a prepay or Credit Memo with balance need to display in the Invoice Summary Screen     
       SELECT CUSTNO, 0 AS FirstDue, 0 AS SecondDue, 0 AS ThirdDue,        
       0 AS CurrentDue, 
	   SUM(CAST((ARCREDITSFC) AS NUMERIC(20,2))) AS CustDepositCreditMemo        
       FROM ACCTSREC        
       WHERE (ARCREDITSFC  > 0 AND INVTOTALFC = 0 AND (lPrepay = 1 OR ISMANUALCM = 1))        
       GROUP BY CUSTNO       
       )       
       INSERT INTO @invoiceSummaryTable      
       (CustName,CustNo,CreditStatus,FirstDue,SecondDue,ThirdDue,CurrentDue,CustDepositCreditMemo,OpenSoBalance,CurrencyType,UseLatestExchangeRate,Currency,LastStmtSent,Initials,CreditAvailable)   -- 12/6/2018 Nilesh Added Currency columns                                 
                   
    SELECT CUSTOMER.CUSTNAME AS CustName,ArSummary.CUSTNO AS CustNo,CUSTOMER.CREDITOK AS CreditStatus,      
       SUM(FirstDue) AS FirstDue, SUM(SecondDue) AS SecondDue, SUM(ThirdDue) AS ThirdDue,SUM(CurrentDue) AS CurrentDue,SUM(CustDepositCreditMemo) AS CustDepositCreditMemo,      
       ISNULL(OpenSOInfo.Amt,0) AS OpenSoBalance  , @currencyType,@lLatestRate  ,FcUsed.Symbol,   
		     CUSTOMER.LastStmtSent AS LastStmtSent, ISNULL(aspnet_users.UserName,'') AS Initials  -- Nilesh Sa 5/27/2019 Update initial to username 
       ,CAST(CreditAvailableTable.CreditAvailable/FcUsed.AskPrice AS numeric(20,2)) AS AvailableCredit   
       FROM ArSummary       
       INNER JOIN CUSTOMER on ArSummary.CUSTNO = CUSTOMER.CUSTNO AND CUSTOMER.FcUsed_uniq = CUSTOMER.FcUsed_uniq   
         -- 06/20/19 @customerCreditAvailableTable already limited to the requested customers  
    -- INNER JOIN aspmnx_UserCustomers ON  aspmnx_UserCustomers.fkCustno=Customer.CUSTNO  AND fkUserId = @userId  -- Nilesh Sa 3/5/2019 : Fetch customer based on user id  
       INNER JOIN @customerCreditAvailableTable AS CreditAvailableTable ON ArSummary.CustNo = CreditAvailableTable.CustNo         
       LEFT OUTER JOIN @fcUsedViewTable FcUsed ON  CUSTOMER.FcUsed_Uniq = FcUsed.FcUsedUniq   
		     LEFT JOIN  aspnet_users ON CUSTOMER.LastStmtSentUserId = aspnet_users.UserId 
       OUTER APPLY (      
     SELECT SUM(ROUND(CASE WHEN SOPRICES.FLAT = 0 AND RecordType = 'P' THEN (PRICEFC * Balance)       
      WHEN SOPRICES.FLAT = 0 AND Quantity > ShippedQty THEN (PRICEFC *(Quantity - ShippedQty))       
      WHEN SOPRICES.FLAT = 1 AND Sodetail.SHIPPEDQTY=0 THEN PRICEFC      
      ELSE 0.00 END ,2)) AS Amt      
     FROM SOMAIN      
    INNER JOIN SODETAIL ON SOMAIN.SONO = SODETAIL.SONO AND SOMAIN.ORD_TYPE = 'Open' AND SOMAIN.CUSTNO = ArSummary.CUSTNO      
    INNER JOIN SOPRICES   ON SODETAIL.UNIQUELN = SOPRICES.UNIQUELN       
       ) AS OpenSOInfo      
		     GROUP BY ArSummary.CUSTNO,CUSTOMER.CUSTNAME,CUSTOMER.CREDITOK,OpenSOInfo.Amt,FcUsed.Symbol,CUSTOMER.LastStmtSent,aspnet_users.UserName,
       CreditAvailableTable.CreditAvailable,FcUsed.AskPrice        
  END      
ELSE       
  BEGIN    
      -- Total days late and Total Invoice Late w r to customer      
      INSERT INTO @invoiceLateTable      
	    SELECT CUSTNO,ISNULL(Sum(DATEDIFF(Day,DUE_DATE,@Today)),0), COUNT(CUSTNO)         
      FROM ACCTSREC       
      WHERE (INVTOTAL-ARCREDITS  > 0  AND DUE_DATE < @Today    
      AND lPrepay = 0 AND ISMANUALCM = 0) 
      GROUP BY CUSTNO      
      
      -- Total Invoice Late and Not Late w r to customer 
	  -- Shivshnakar P: 08/18/2020 Get IS_INPRINT AS IsInvPrint from PLMAIN to show invoice printed or not on UI
      INSERT INTO @totalInvoiceTable      
      SELECT CUSTNO,COUNT(CUSTNO) AS TotalInvoice, ISNULL(PackListInfo.IS_INPRINT, 1) AS IsInvPrint     
      FROM ACCTSREC
	  OUTER APPLY(SELECT TOP 1 IS_INPRINT FROM PLMAIN WHERE PLMAIN.CUSTNO = ACCTSREC.CUSTNO AND IS_INPRINT = 0 
					AND INV_DUPL = 1 AND PRINT_INVO = 1 AND IS_INVPOST = 1 AND IS_PKPRINT = 1) AS PackListInfo
      WHERE (INVTOTAL-ARCREDITS  > 0     
      AND lPrepay = 0 AND ISMANUALCM = 0)    
      GROUP BY CUSTNO, PackListInfo.IS_INPRINT; 
    
	-- Nitesh N 01/31/2020 Added CustDepositCreditMemo to get the prepay and customer memo total for the customer 
      IF @lLatestRate = 0     
        BEGIN    
     ;WITH ArSummary AS(    
      SELECT CUSTNO,      
      SUM(CAST((INVTOTAL-ARCREDITS) AS numeric(20,2))) AS FirstDue,      
      0 AS SecondDue, 0 AS ThirdDue,0 AS CurrentDue, 0 AS CustDepositCreditMemo        
      FROM ACCTSREC       
      WHERE DATEDIFF(Day,DUE_DATE,@Today) >= 1 AND DATEDIFF(Day,DUE_DATE,@today) <= @firstDueEnd     
      AND INVTOTAL-ARCREDITS  > 0 AND lPrepay = 0 AND ISMANUALCM = 0      
      GROUP BY CUSTNO      
      UNION      
      SELECT CUSTNO,0 AS FirstDue,       
      SUM(CAST((INVTOTAL-ARCREDITS) AS numeric(20,2))) AS SecondDue,      
      0 AS ThirdDue,0 AS CurrentDue, 0 AS CustDepositCreditMemo        
      FROM ACCTSREC       
      WHERE DATEDIFF(Day,DUE_DATE,@Today) >= (@firstDueEnd + 1) AND DATEDIFF(Day,DUE_DATE,@today) <= @secondDueEnd     
      AND INVTOTAL-ARCREDITS  > 0 AND lPrepay = 0 AND ISMANUALCM = 0       
      GROUP BY CUSTNO      
      UNION      
      SELECT CUSTNO, 0 AS FirstDue, 0 AS SecondDue,       
      SUM(CAST((INVTOTAL-ARCREDITS) AS numeric(20,2))) AS ThirdDue,      
      0 AS CurrentDue, 0 AS CustDepositCreditMemo        
      FROM ACCTSREC       
      WHERE  DATEDIFF(Day,DUE_DATE,@today) > (@secondDueEnd + 1)     
      AND INVTOTAL-ARCREDITS  > 0 AND lPrepay = 0 AND ISMANUALCM = 0    
      GROUP BY CUSTNO       
      UNION      
      SELECT CUSTNO, 0 AS FirstDue, 0 AS SecondDue, 0 AS ThirdDue,      
      SUM(CAST((INVTOTAL-ARCREDITS) AS numeric(20,2))) AS CurrentDue, 0 AS CustDepositCreditMemo        
      FROM ACCTSREC       
      WHERE DUE_DATE >= @today     
      AND INVTOTAL-ARCREDITS  > 0 AND lPrepay = 0 AND ISMANUALCM = 0     
      GROUP BY CUSTNO      
	  UNION   -- Nitesh B 01/31/2020 If the customer only has a prepay or Credit Memo with balance need to display in the Invoice Summary Screen     
      SELECT CUSTNO, 0 AS FirstDue, 0 AS SecondDue, 0 AS ThirdDue,        
      0 AS CurrentDue, SUM(CAST((ARCREDITS) AS numeric(20,2))) AS CustDepositCreditMemo        
      FROM ACCTSREC         
      WHERE (ARCREDITS  > 0 AND INVTOTAL = 0 AND (lPrepay = 1 OR ISMANUALCM = 1))        
      GROUP BY CUSTNO         
     )       
     INSERT INTO @invoiceSummaryTable      
     (CustName,CustNo,CreditStatus,FirstDue,SecondDue,ThirdDue,CurrentDue,CustDepositCreditMemo,OpenSoBalance,CurrencyType,UseLatestExchangeRate,Currency,LastStmtSent,Initials,CreditAvailable)       
     SELECT CUSTOMER.CUSTNAME AS CustName,ArSummary.CUSTNO AS CustNo,CUSTOMER.CREDITOK AS CreditStatus,      
     SUM(FirstDue) AS FirstDue, SUM(SecondDue) AS SecondDue, SUM(ThirdDue) AS ThirdDue,SUM(CurrentDue) AS CurrentDue,SUM(CustDepositCreditMemo) AS CustDepositCreditMemo,        
     ISNULL(OpenSOInfo.Amt,0) AS OpenSoBalance, @currencyType,@lLatestRate  ,FcUsed.Symbol,   
				 CUSTOMER.LastStmtSent AS LastStmtSent, ISNULL(aspnet_users.UserName,'') AS Initials -- Nilesh Sa 5/27/2019 Update initial to username
     ,CreditAvailableTable.CreditAvailable AS AvailableCredit   
     FROM ArSummary       
     INNER JOIN CUSTOMER on ArSummary.CUSTNO = CUSTOMER.CUSTNO      
       -- 06/20/19 @customerCreditAvailableTable already limited to the requested customers  
     --INNER JOIN aspmnx_UserCustomers ON  aspmnx_UserCustomers.fkCustno=Customer.CUSTNO  AND fkUserId = @userId  -- Nilesh Sa 3/5/2019 : Fetch customer based on user id  
     INNER JOIN @customerCreditAvailableTable AS CreditAvailableTable ON ArSummary.CustNo = CreditAvailableTable.CustNo     
     LEFT OUTER JOIN FcUsed ON CUSTOMER.FcUsed_uniq = FcUsed.FcUsed_Uniq  
				 LEFT JOIN  aspnet_users ON CUSTOMER.LastStmtSentUserId = aspnet_users.UserId  
     OUTER APPLY (      
     SELECT SUM(ROUND(CASE WHEN SOPRICES.FLAT = 0 and RecordType = 'P' THEN (Price * Balance)       
     WHEN SOPRICES.FLAT = 0 and Quantity > ShippedQty THEN (Price *(Quantity - ShippedQty))       
     WHEN SOPRICES.FLAT = 1 and Sodetail.SHIPPEDQTY=0 THEN Price      
     ELSE 0.00 END ,2)) AS Amt      
     FROM SOMAIN      
    INNER JOIN SODETAIL ON SOMAIN.SONO = SODETAIL.SONO AND SOMAIN.ORD_TYPE = 'Open' AND SOMAIN.CUSTNO = ArSummary.CUSTNO      
    INNER JOIN SOPRICES   ON SODETAIL.UNIQUELN = SOPRICES.UNIQUELN       
     ) AS OpenSOInfo      
     GROUP BY ArSummary.CUSTNO,CUSTOMER.CUSTNAME,CUSTOMER.CREDITOK,OpenSOInfo.Amt,FcUsed.Symbol,CUSTOMER.LastStmtSent,  
				 aspnet_users.UserName,CreditAvailableTable.CreditAvailable     
       END    
     ELSE     
    BEGIN
	-- Nitesh N 01/31/2020 Added CustDepositCreditMemo to get the prepay and customer memo total for the customer     
      ;WITH ArSummary AS(      
     SELECT ACCTSREC.CUSTNO,      
     SUM(CAST((INVTOTALFC-ARCREDITSFC)/fc.AskPrice AS numeric(20,2))) AS FirstDue,      
     0 AS SecondDue, 0 AS ThirdDue,0 AS CurrentDue,0 AS CustDepositCreditMemo      
     FROM ACCTSREC       
     JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO  
     LEFT OUTER JOIN @fcUsedViewTable fc ON CUSTOMER.FCUSED_UNIQ = fc.FcUsedUniq    
     WHERE DATEDIFF(Day,DUE_DATE,@Today) >= 1 AND DATEDIFF(Day,DUE_DATE,@today) <= @firstDueEnd   
     AND INVTOTALFC-ARCREDITSFC  > 0 AND lPrepay = 0 AND ISMANUALCM = 0      
     GROUP BY ACCTSREC.CUSTNO      
     UNION      
     SELECT ACCTSREC.CUSTNO,0 AS FirstDue,       
     SUM(CAST((INVTOTALFC-ARCREDITSFC)/fc.AskPrice AS numeric(20,2))) AS SecondDue,      
     0 AS ThirdDue,0 AS CurrentDue,0 AS CustDepositCreditMemo      
     FROM ACCTSREC       
     JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO  
     LEFT OUTER JOIN @fcUsedViewTable fc ON CUSTOMER.FCUSED_UNIQ = fc.FcUsedUniq   
     WHERE DATEDIFF(Day,DUE_DATE,@Today) >= (@firstDueEnd + 1) AND DATEDIFF(Day,DUE_DATE,@today) <= @secondDueEnd   
     AND INVTOTALFC-ARCREDITSFC  > 0 AND lPrepay = 0 AND ISMANUALCM = 0       
     GROUP BY ACCTSREC.CUSTNO      
     UNION      
     SELECT ACCTSREC.CUSTNO, 0 AS FirstDue, 0 AS SecondDue,       
     SUM(CAST((INVTOTALFC-ARCREDITSFC)/fc.AskPrice AS numeric(20,2))) AS ThirdDue,      
     0 AS CurrentDue,0 AS CustDepositCreditMemo      
     FROM ACCTSREC       
     JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO  
     LEFT OUTER JOIN @fcUsedViewTable fc ON CUSTOMER.FCUSED_UNIQ = fc.FcUsedUniq   
     WHERE  DATEDIFF(Day,DUE_DATE,@today) > (@secondDueEnd + 1)     
     AND INVTOTALFC-ARCREDITSFC  > 0 AND lPrepay = 0 AND ISMANUALCM = 0    
     GROUP BY ACCTSREC.CUSTNO       
     UNION      
     SELECT ACCTSREC.CUSTNO, 0 AS FirstDue, 0 AS SecondDue, 0 AS ThirdDue,      
     SUM(CAST((INVTOTALFC-ARCREDITSFC)/fc.AskPrice AS numeric(20,2))) AS CurrentDue,0 AS CustDepositCreditMemo      
     FROM ACCTSREC       
     JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO  
     LEFT OUTER JOIN @fcUsedViewTable fc ON CUSTOMER.FCUSED_UNIQ = fc.FcUsedUniq   
     WHERE DUE_DATE >= @today     
     AND INVTOTALFC-ARCREDITSFC  > 0 AND lPrepay = 0 AND ISMANUALCM = 0     
     GROUP BY ACCTSREC.CUSTNO
	 UNION   -- Nitesh B 01/31/2020 If the customer only has a prepay or Credit Memo with balance need to display in the Invoice Summary Screen     
     SELECT ACCTSREC.CUSTNO, 0 AS FirstDue, 0 AS SecondDue, 0 AS ThirdDue,        
     0 AS CurrentDue, SUM(CAST((ARCREDITS) AS numeric(20,2))) AS CustDepositCreditMemo        
     FROM ACCTSREC
	 JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO  
     LEFT OUTER JOIN @fcUsedViewTable fc ON CUSTOMER.FCUSED_UNIQ = fc.FcUsedUniq         
     WHERE (ARCREDITS  > 0 AND INVTOTAL = 0 AND (lPrepay = 1 OR ISMANUALCM = 1))        
     GROUP BY ACCTSREC.CUSTNO       
    )       
    INSERT INTO @invoiceSummaryTable      
    (CustName,CustNo,CreditStatus,FirstDue,SecondDue,ThirdDue,CurrentDue,CustDepositCreditMemo,OpenSoBalance,CurrencyType,UseLatestExchangeRate,Currency,LastStmtSent,Initials,CreditAvailable)  
    SELECT CUSTOMER.CUSTNAME AS CustName,ArSummary.CUSTNO AS CustNo,CUSTOMER.CREDITOK AS CreditStatus,      
    SUM(FirstDue) AS FirstDue, SUM(SecondDue) AS SecondDue, SUM(ThirdDue) AS ThirdDue,SUM(CurrentDue) AS CurrentDue,SUM(CustDepositCreditMemo) AS CustDepositCreditMemo,      
    ISNULL(OpenSOInfo.Amt,0) AS OpenSoBalance, @currencyType,@lLatestRate,FcUsed.Symbol,   
				CUSTOMER.LastStmtSent AS LastStmtSent, ISNULL(aspnet_users.UserName,'') AS Initials  -- Nilesh Sa 5/27/2019 Update initial to username
    ,CAST(CreditAvailableTable.CreditAvailable/FcUsed.AskPrice AS numeric(20,2)) AS AvailableCredit    
    FROM ArSummary       
    INNER JOIN CUSTOMER ON ArSummary.CUSTNO = CUSTOMER.CUSTNO      
      -- 06/20/19 @customerCreditAvailableTable already limited to the requested customers  
    --INNER JOIN aspmnx_UserCustomers ON  aspmnx_UserCustomers.fkCustno=Customer.CUSTNO  AND fkUserId = @userId  -- Nilesh Sa 3/5/2019 : Fetch customer based on user id  
    INNER JOIN @customerCreditAvailableTable AS CreditAvailableTable ON ArSummary.CustNo = CreditAvailableTable.CustNo    
    LEFT OUTER JOIN @fcUsedViewTable FcUsed ON CUSTOMER.FcUsed_uniq = FcUsed.FcUsedUniq   
				LEFT JOIN  aspnet_users ON CUSTOMER.LastStmtSentUserId = aspnet_users.UserId 
    OUTER APPLY (      
     SELECT SUM(CAST(ROUND(CASE WHEN SOPRICES.FLAT = 0 and RecordType = 'P' THEN (PriceFC * Balance)       
     WHEN SOPRICES.FLAT = 0 and Quantity > ShippedQty THEN (PriceFC *(Quantity - ShippedQty))       
     WHEN SOPRICES.FLAT = 1 and Sodetail.SHIPPEDQTY=0 THEN PriceFC      
     ELSE 0.00 END ,2) / fc.AskPrice AS NUMERIC(20,2))) AS Amt      
     FROM SOMAIN      
     INNER JOIN SODETAIL ON SOMAIN.SONO = SODETAIL.SONO AND SOMAIN.ORD_TYPE = 'Open' AND SOMAIN.CUSTNO = ArSummary.CUSTNO      
     INNER JOIN SOPRICES   ON SODETAIL.UNIQUELN = SOPRICES.UNIQUELN     
     JOIN CUSTOMER ON SOMAIN.CUSTNO = CUSTOMER.CUSTNO  
     LEFT OUTER JOIN @fcUsedViewTable fc ON CUSTOMER.FcUsed_uniq = FcUsed.FcUsedUniq     
    ) AS OpenSOInfo      
    GROUP BY ArSummary.CUSTNO,CUSTOMER.CUSTNAME,CUSTOMER.CREDITOK,OpenSOInfo.Amt,FcUsed.Symbol,CUSTOMER.LastStmtSent,   
				aspnet_users.UserName,CreditAvailableTable.CreditAvailable,FcUsed.AskPrice     
       END      
    END    
    
   ;WITH InvoiceSummary AS(    
     SELECT InvoiceSummaryTable.CustName,InvoiceSummaryTable.CustNo,CreditStatus,FirstDue,SecondDue,ThirdDue,CurrentDue,    
     OpenSoBalance, ISNULL((TotalDaysLate/TotalInvoiceLate),0) AS AvgDaysLate, (CurrentDue + FirstDue + SecondDue + ThirdDue) - CustDepositCreditMemo AS Balance,  -- Nilesh Sa 7/2/2019 Check null & put 0     
     CONCAT(ISNULL(TotalInvoiceLate,0),' / ',ISNULL(TotalInvoicePending,0)) AS InvoicePastDue,CurrencyType,UseLatestExchangeRate,Currency    -- Nilesh Sa 7/2/2019 Check null & put 0   
     ,LastStmtSent, Initials, InvoiceSummaryTable.CreditAvailable AS AvailableCredit, ISNULL(TotalInvoiceTable.IsInvPrint, 0) AS IsInvPrint   -- Shivshnakar P: 08/18/2020 Get IS_INPRINT AS IsInvPrint from PLMAIN to show invoice printed or not on UI
     FROM @invoiceSummaryTable AS InvoiceSummaryTable      
     LEFT JOIN @invoiceLateTable AS InvoiceLateTable ON InvoiceSummaryTable.CustNo = InvoiceLateTable.CustNo      -- Nilesh Sa 7/2/2019 Updated inner join to left join
     LEFT JOIN @totalInvoiceTable AS TotalInvoiceTable  ON InvoiceSummaryTable.CustNo = TotalInvoiceTable.CustNo      
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
     + ' ORDER BY CustName OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'       
     END      
     ELSE      
    BEGIN      
     SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t'      
      + ' ORDER BY CustName OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'      
 END      
 EXEC SP_EXECUTESQL @SQL      
END