-- =============================================    
-- Author:  <Nilesh Sa>    
-- Create date: 
-- Description: Get AR Invoicing Summary View    
-- EXEC [dbo].[GetInvoicingSummaryView] 0,1,'0000000001',0,500,'ShipDate asc',''
-- EXEC [dbo].[GetInvoicingSummaryView] 1,0,'',0,500,'ShipDate asc',''  
-- EXEC [dbo].[GetInvoicingSummaryView] 0,0,'',0,500,'ShipDate asc',''  
-- Nilesh Sa 4/25/2019 Check for Bill to & ship to address are linked
-- Nilesh Sa 5/08/2019  Changes made for FC implementation
-- Nitesh B 5/8/2019 update Currency logic based on Packing list/invoice created
-- Nitesh B 12/26/2019 Get column plType from Plmain table
-- Nitesh B 01/21/2020 Remove dbo.fRemoveLeadingZeros function to get complete InvoiceNo 
-- Shivshankar P 04/02/2020 Add parameters and condition and case to get Release Manual Invoices
-- Shivshankar P 04/13/2020 Get PLMAIN.TERMS AS PayTerms for invoices
-- Shivshankar P 07/27/2020 Added Outer Apply to get the sum of SHIPPEDQTY AS PLQTY for packinglist
-- =============================================    
CREATE PROCEDURE [dbo].[GetInvoicingSummaryView]
  --DECLARE    
  @unPrinted BIT = 0,
  @isManual BIT = 0,  -- Shivshankar P 04/02/2020 Add parameters and condition and case to get Release Manual Invoices
  @custNo char(10) = '',
  @startRecord INT = 0,    
  @endRecord INT = 150,     
  @sortExpression NVARCHAR(1000) = NULL,    
  @filter NVARCHAR(1000) = NULL
AS    
BEGIN    
     SET NOCOUNT ON;    
        
     IF(@sortExpression = NULL OR @sortExpression = '')    
     BEGIN    
       SET @sortExpression = 'ShipDate asc'    
     END    
     
     DECLARE @SQL nvarchar(MAX),@lFCInstalled BIT;     
       
     -- To store invoice summary details w r to customer    
     DECLARE @invoicingSummaryTable TABLE(InvoiceType NVARCHAR(MAX),PlType NVARCHAR(MAX),CustName CHAR(50), 
     CustNo CHAR(10),Amount NUMERIC(20,2), 
     InvoiceNo CHAR(10),InvoiceDate smalldatetime,InvoiceDueDate smalldatetime,PackListNo CHAR(10),SalesOrder CHAR(10),
     ShipDate smalldatetime,IsAddressLinked BIT,Currency VARCHAR(3),AmountFC NUMERIC(20,2), PayTerms CHAR(15), PLQTY NUMERIC(20,2)); 
     
     -- Nilesh Sa 5/08/2019  Changes made for FC implementation
     SELECT @lFCInstalled = dbo.fn_IsFCInstalled();   

     IF @lFCInstalled =  1 
	     BEGIN
		-- Nilesh Sa 5/08/2019  Changes made for FC implementation
		    INSERT INTO @invoicingSummaryTable
		    SELECT 
		     PLMAIN.InvoiceType AS InvoiceType
			,PLMAIN.plType AS PlType -- Nitesh B 12/26/2019 Get column plType from Plmain table
		    ,CUSTNAME AS CustName
		    ,CUSTOMER.CUSTNO AS CustNo
		    ,PLMAIN.INVTOTAL AS Amount
		    --,dbo.fRemoveLeadingZeros(INVOICENO) AS InvoiceNo
			,INVOICENO AS InvoiceNo -- Nitesh B 01/21/2020 Remove dbo.fRemoveLeadingZeros function to get complete InvoiceNo 
		    ,PLMAIN.INVDATE AS InvoiceDate
		    ,CASE WHEN PmtTerms.PMT_DAYS IS NOT NULL THEN DATEADD(Day,PmtTerms.PMT_DAYS, PLMAIN.INVDATE) ELSE GETDATE() END  AS InvoiceDueDate
		    ,CASE WHEN PACKLISTNO ='' OR PACKLISTNO IS NULL THEN '' ELSE dbo.fRemoveLeadingZeros(PACKLISTNO) END AS PackListNo
		    ,CASE WHEN SONO ='' OR SONO IS NULL THEN '' ELSE dbo.fRemoveLeadingZeros(SONO) END AS SalesOrder
		    ,SHIPDATE AS ShipDate 
		    -- Nilesh Sa 4/25/2019 Check for Bill to & ship to address are linked
		    ,CASE WHEN AddressLink.LinkAddressId IS NULL THEN 0 ELSE 1 END AS IsAddressLinked
		    ,FcUsed.SYMBOL AS Currency
		    ,PLMAIN.INVTOTALFC AS AmountFC
			,PLMAIN.TERMS AS PayTerms -- Shivshankar P 04/13/2020 Get PLMAIN.TERMS AS PayTerms for invoices
			,PLQTY.QTY AS PLQTY  -- Shivshankar P 07/27/2020 Added Outer Apply to get the sum of SHIPPEDQTY AS PLQTY for packinglist
		    FROM PLMAIN
		    INNER JOIN CUSTOMER ON PLMAIN.CUSTNO = CUSTOMER.CUSTNO
		    -- Nitesh B 5/8/2019 update Currency logic based on Packing list/invoice created
		    LEFT OUTER JOIN FcUsed ON PLMAIN.FcUsed_uniq = FcUsed.FcUsed_Uniq 
		    OUTER APPLY(
			   SELECT Pmt_days  
			   FROM PMTTERMS  
			   WHERE DESCRIPT = CASE WHEN PLMAIN.TERMS IS NOT NULL AND PLMAIN.TERMS <> '' THEN PLMAIN.TERMS ELSE CUSTOMER.TERMS END
		    ) AS PmtTerms
		    -- Nilesh Sa 4/25/2019 Check for Bill to & ship to address are linked
		    OUTER APPLY(
			   SELECT TOP 1 LinkAddressId From AddressLinkTable where ShipConfirmToAddress=PLMAIN.LINKADD And BillRemitAddess =PLMAIN.BLINKADD
		    ) AS AddressLink
			-- Shivshankar P 07/27/2020 Added Outer Apply to get the sum of SHIPPEDQTY AS PLQTY for packinglist
			OUTER APPLY (SELECT ISNULL(SUM(PLDETAIL.SHIPPEDQTY),0) AS QTY FROM PLDETAIL WHERE PLDETAIL.PACKLISTNO = PLMAIN.PACKLISTNO) AS PLQTY
			-- Shivshankar P 04/02/2020 Add parameters and condition and case to get Release Manual Invoices
		    WHERE (PLMAIN.PACKLISTNO ='' OR PLMAIN.PRINTED = CASE WHEN @isManual = 1 THEN 1 ELSE @unPrinted END) 
			AND Plmain.IS_INVPOST = CASE WHEN @isManual = 1 THEN 1 ELSE 0 END
			AND PLMAIN.plType = CASE WHEN @isManual = 1 THEN '' ELSE PLMAIN.plType END 
			AND PLMAIN.InvoiceType = CASE WHEN @isManual = 1 THEN 'Manual' ELSE PLMAIN.InvoiceType END
			AND PLMAIN.CUSTNO = CASE WHEN @isManual = 1 THEN @custNo ELSE PLMAIN.CUSTNO END;
	     END
     ELSE
	     BEGIN
	        INSERT INTO @invoicingSummaryTable
	        SELECT 
	         PLMAIN.InvoiceType AS InvoiceType
			,PLMAIN.plType AS PlType -- Nitesh B 12/26/2019 Get column plType from Plmain table
	        ,CUSTNAME AS CustName
	        ,CUSTOMER.CUSTNO AS CustNo
	        ,PLMAIN.INVTOTAL AS Amount
	        --,dbo.fRemoveLeadingZeros(INVOICENO) AS InvoiceNo
			,INVOICENO AS InvoiceNo -- Nitesh B 01/21/2020 Remove dbo.fRemoveLeadingZeros function to get complete InvoiceNo 
	        ,PLMAIN.INVDATE AS InvoiceDate
	        ,CASE WHEN PmtTerms.PMT_DAYS IS NOT NULL THEN DATEADD(Day,PmtTerms.PMT_DAYS, PLMAIN.INVDATE) ELSE GETDATE() END  AS InvoiceDueDate
	        ,CASE WHEN PACKLISTNO ='' OR PACKLISTNO IS NULL THEN '' ELSE dbo.fRemoveLeadingZeros(PACKLISTNO) END AS PackListNo
	        ,CASE WHEN SONO ='' OR SONO IS NULL THEN '' ELSE dbo.fRemoveLeadingZeros(SONO) END AS SalesOrder
	        ,SHIPDATE AS ShipDate 
	        -- Nilesh Sa 4/25/2019 Check for Bill to & ship to address are linked
	        ,CASE WHEN AddressLink.LinkAddressId IS NULL THEN 0 ELSE 1 END AS IsAddressLinked
		    ,'' AS Currency
		    ,0.00 AS AmountFC
			,PLMAIN.TERMS AS PayTerms -- Shivshankar P 04/13/2020 Get PLMAIN.TERMS AS PayTerms for invoices
			,PLQTY.QTY AS PLQTY -- Shivshankar P 07/27/2020 Added Outer Apply to get the sum of SHIPPEDQTY AS PLQTY for packinglist
	        FROM PLMAIN
	        INNER JOIN CUSTOMER ON PLMAIN.CUSTNO = CUSTOMER.CUSTNO
	        OUTER APPLY(
	     		   SELECT Pmt_days  
	     		   FROM PMTTERMS  
	     		   WHERE DESCRIPT =   CASE WHEN PLMAIN.TERMS IS NOT NULL AND PLMAIN.TERMS <> '' THEN PLMAIN.TERMS ELSE CUSTOMER.TERMS END
	        ) AS PmtTerms
	        -- Nilesh Sa 4/25/2019 Check for Bill to & ship to address are linked
	        OUTER APPLY(
	     		 SELECT TOP 1 LinkAddressId From AddressLinkTable where ShipConfirmToAddress=PLMAIN.LINKADD And BillRemitAddess =PLMAIN.BLINKADD
	        ) AS AddressLink
			-- Shivshankar P 07/27/2020 Added Outer Apply to get the sum of SHIPPEDQTY AS PLQTY for packinglist
			OUTER APPLY (SELECT ISNULL(SUM(PLDETAIL.SHIPPEDQTY),0) AS QTY FROM PLDETAIL WHERE PLDETAIL.PACKLISTNO = PLMAIN.PACKLISTNO) AS PLQTY
			-- Shivshankar P 04/02/2020 Add parameters and condition and case to get Release Manual Invoices
	        WHERE (PLMAIN.PACKLISTNO ='' OR PLMAIN.PRINTED = CASE WHEN @isManual = 1 THEN 1 ELSE @unPrinted END) 
			AND Plmain.IS_INVPOST = CASE WHEN @isManual = 1 THEN 1 ELSE 0 END
			AND PLMAIN.plType = CASE WHEN @isManual = 1 THEN '' ELSE PLMAIN.plType END 
			AND PLMAIN.InvoiceType = CASE WHEN @isManual = 1 THEN 'Manual' ELSE PLMAIN.InvoiceType END
			AND PLMAIN.CUSTNO = CASE WHEN @isManual = 1 THEN @custNo ELSE PLMAIN.CUSTNO END;
	     END
  
    SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @invoicingSummaryTable
    
    IF @filter <> ''
    	    BEGIN    
    		  SET @SQL=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE '+@filter    
    		  +' ORDER BY '+ @SortExpression+''+ ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'    
    	     END    
     ELSE IF @filter = ''    
    	    BEGIN    
    		  SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t '      
    		   +' ORDER BY '+ @sortExpression+'' + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'     
           END    

    EXEC SP_EXECUTESQL @SQL    
END