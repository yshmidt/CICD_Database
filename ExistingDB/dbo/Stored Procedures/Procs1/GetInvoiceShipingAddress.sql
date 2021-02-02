
-- =============================================    
-- Author:  <Shripati>    
-- Create date: <09/21/2018>    
-- Description: Get Billing address view    
-- GetInvoiceShipingAddress '0000000001', '_4650OHCIU', 0,150, '','', 'S'
-- =============================================    
CREATE PROCEDURE [dbo].[GetInvoiceShipingAddress]    
 --DECLARE    
 @custNo CHAR(10) = '',    
 @billingAdd CHAR(10) = '', 
 @startRecord INT = 0,    
 @endRecord INT = 150,     
 @sortExpression NVARCHAR(1000) = null,    
 @filter NVARCHAR(1000) = null,    
 @recordType CHAR = ''    
AS    
BEGIN    
 SET NOCOUNT ON;    
    
 DECLARE @SQL nvarchar(max);    
 DECLARE @shipBillTable TABLE(Address VARCHAR(50),City VARCHAR(50),STATE VARCHAR(50),Zip VARCHAR(50),
 Bank VARCHAR(50),PaymentType VARCHAR(50),    
 Currency VARCHAR(40),Symbol VARCHAR(3),LinkAdd CHAR(10),IsDefault BIT, BillRemitAddess CHAR(10), ShipConfirmToAddress  CHAR(10));
      
 IF(@sortExpression = NULL OR @sortExpression = '')    
 BEGIN    
  SET @sortExpression = 'IsDefault DESC'    
 END    
    
 BEGIN    
  INSERT INTO @shipBillTable    
  SELECT sb.SHIPTO AS Address,sb.CITY AS City,sb.STATE AS State,sb.ZIP AS Zip, ISNULL(Bank,SPACE(50)) AS Bank,     
  ISNULL(PaymentType, 'Check') AS PaymentType, ISNULL(FcUsed.Currency, SPACE(40)) AS Currency, ISNULL(FcUsed.Symbol,SPACE(3)) AS Symbol,    
  sb.LINKADD AS LinkAdd, adlink.IsDefaultAddress,  adlink.BillRemitAddess, adlink.ShipConfirmToAddress  
  FROM SHIPBILL sb  
  INNER JOIN CUSTOMER ON sb.CUSTNO = CUSTOMER.CUSTNO  
  INNER JOIN AddressLinkTable adlink on adlink.ShipConfirmToAddress =sb.LINKADD AND adlink.BillRemitAddess =@billingAdd  AND sb.RECORDTYPE ='S'
  LEFT OUTER JOIN BANKS ON Banks.Bk_Uniq = sb.Bk_Uniq    
  LEFT OUTER JOIN FcUsed ON FcUsed.FcUsed_Uniq = sb.FcUsed_Uniq    
  WHERE sb.CUSTNO = @custNo  
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