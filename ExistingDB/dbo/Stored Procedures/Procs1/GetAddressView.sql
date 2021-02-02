-- =============================================    
-- Author:  <Shripati>    
-- Create date: <09/12/2018>    
-- Description: Get Billing address view    
-- exec [dbo].[GetAddressView] '0000000091', 0,150,'','','B'    
-- 03/31/2020 YS changed link from customer to shipbill. The default value is not saved in the customer.blinkadd and slinkadd anymore  
-- 04/08/2020 Sachin B Add the @custNo in the where clause
-- =============================================    
CREATE PROCEDURE [dbo].[GetAddressView]      
 --DECLARE    
 @custNo CHAR(10) = '',    
 @startRecord INT = 0,    
 @endRecord INT = 150,     
 @sortExpression NVARCHAR(1000) = null,    
 @filter NVARCHAR(1000) = null,    
 @recordType CHAR = ''    
AS    
BEGIN    
 SET NOCOUNT ON;    
    
 DECLARE @SQL NVARCHAR(max);    
 DECLARE @shipBillTable TABLE(Address VARCHAR(50),City VARCHAR(50),STATE VARCHAR(50),Zip VARCHAR(50),Bank VARCHAR(50),PaymentType VARCHAR(50),    
 Currency VARCHAR(40),Symbol VARCHAR(3),LinkAdd CHAR(10),IsDefault BIT, CUSTNO VARCHAR(10));      
      
 IF(@sortExpression = NULL OR @sortExpression = '')    
 BEGIN    
  SET @sortExpression = 'IsDefault DESC'    
 END    
    
 BEGIN    
  INSERT INTO @shipBillTable    
  SELECT sb.SHIPTO AS Address,sb.CITY AS City,sb.STATE AS State,sb.ZIP AS Zip, ISNULL(Bank,SPACE(50)) AS Bank,       
   ISNULL(PaymentType, 'Check') AS PaymentType, ISNULL(FcUsed.Currency, SPACE(40)) AS Currency, ISNULL(FcUsed.Symbol,SPACE(3)) AS Symbol,    
   LINKADD AS LinkAdd,IsDefaultAddress, sb.CUSTNO AS custNo  
  FROM SHIPBILL  sb     
  LEFT OUTER JOIN BANKS ON Banks.Bk_Uniq = sb.Bk_Uniq      
  LEFT OUTER JOIN FcUsed ON FcUsed.FcUsed_Uniq = sb.FcUsed_Uniq      
   -- 03/31/2020 YS changed link from customer to shipbill. The default value is not saved in the customer.blinkadd and slinkadd anymore  
  --LEFT JOIN CUSTOMER ON sb.CUSTNO = CUSTOMER.CUSTNO and sb.LINKADD =  CUSTOMER.BLINKADD      
  LEFT OUTER join customer on  Sb.custno = CUSTOMER.custno  
  -- 04/08/2020 Sachin B Add the @custNo in the where clause
  WHERE Recordtype=@recordType and sb.CUSTNO = @custNo  
 END    
    
 SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @shipBillTable    
    
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
 ELSE     
     IF @filter <> '' AND @sortExpression = ''    
    BEGIN    
     SET @SQL=N'SELECT  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+''     
     + ' ORDER BY Address DESC OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'     
    END    
  ELSE    
    BEGIN    
     SET @SQL=N'SELECT  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t'    
      + ' ORDER BY Address DESC OFFSET (' +CONVERT(VARCHAR(10), @startRecord)+ ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'    
    END    
 EXEC SP_EXECUTESQL @SQL    
END