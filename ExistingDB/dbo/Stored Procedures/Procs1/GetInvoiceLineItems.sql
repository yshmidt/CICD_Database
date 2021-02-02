-- =============================================    
-- Author:  <Nilesh Sa>    
-- Create date: 4/2/2014
-- Description: Get AR Invoice item against packing list number  
-- EXEC [dbo].[GetInvoiceLineItems] '0000000733',0,150,'','' 
-- Modify : Nitesh B : 11/2/2019 : Added COGAcctNo to get Cost of goods Account number form plprice  
--          Nitesh B : 12/6/2019 : Get SUOM from Pldetail for manual PL line items
--          Nitesh B : 1/14/2020 : Get PackListNo from Pldetail for manual PL line items
--          Shivshankar P : 06/23/2020 : Get Quantity from Plprices table for line items
--          Shivshankar P : 07/20/2020 : Get Quantity from Pldetail table if null in Plprices and also check null for other fields 
--          Shivshankar P : 09/11/2020 : Added sorting by RECORDTYPE desc
-- =============================================    
CREATE PROCEDURE [dbo].[GetInvoiceLineItems]
  --DECLARE    
  @packingListNo CHAR(10) = '',
  @startRecord INT = 0,    
  @endRecord INT = 150,     
  @sortExpression NVARCHAR(1000) = NULL,    
  @filter NVARCHAR(1000) = NULL
AS    
BEGIN    
    SET NOCOUNT ON;    
       
    IF(@sortExpression = NULL OR @sortExpression = '')    
    BEGIN    
      -- DefaultSort based on Line Item Number
      SET @sortExpression = 'DefaultSort asc, RECORDTYPE desc'    --Shivshankar P : 09/11/2020 : Added sorting by RECORDTYPE desc
    END    
   
    -- To store invoice line item
    DECLARE @invoiceLineItemTable TABLE(DefaultSort int,LineItemNo CHAR(10),PartNoRev NVARCHAR(MAX),Description NVARCHAR(MAX),
    SUOM CHAR(4),Quantity NUMERIC(9,2),UniqKey CHAR(10),Flat BIT,Taxable BIT,AcctNo CHAR(13),COGAcctNo CHAR(13) --Nitesh B : 11/2/2019 : Added COGAcctNo to get Cost of goods Account number form plprice
    ,Price NUMERIC(14,5),Extended NUMERIC(20,2),PriceDesc CHAR(45),PlUniqLink CHAR(10),InvLink CHAR(10)
    ,TransPrice NUMERIC(14,5),TransExtended NUMERIC(20,2),PricePr NUMERIC(14,5),ExtendedPr NUMERIC(20,2), PackListNo CHAR(10), RECORDTYPE CHAR(2));  --Nitesh B : 1/14/2020 : Get PackListNo from Pldetail for manual PL line items
       
    DECLARE @SQL nvarchar(MAX);     

    INSERT INTO @invoiceLineItemTable
    SELECT 
    CASE 
    WHEN ISNUMERIC(ISNULL(CASE WHEN Sodetail.Line_no <> '' AND Sodetail.Line_no IS NOT NULL THEN dbo.fRemoveLeadingZeros(Sodetail.Line_no) ELSE NULL END,Pldetail.Uniqueln)) = 1 
    THEN CONVERT(INT, Sodetail.Line_no) ELSE 9999999 END AS  DefaultSort,
    ISNULL(CASE WHEN Sodetail.Line_no <> '' AND Sodetail.Line_no IS NOT NULL THEN dbo.fRemoveLeadingZeros(Sodetail.Line_no) ELSE NULL END,Pldetail.Uniqueln) AS LineItemNo,
    CASE 
	WHEN Part_no <> '' AND Part_no IS NOT NULL AND  Revision <> '' AND Revision IS NOT NULL THEN CONCAT(RTRIM(Part_no),' / ',RTRIM(Revision)) 
	WHEN (Revision = '' OR Revision IS NULL ) AND (Part_no <> '' AND Part_no IS NOT NULL) THEN  RTRIM(Part_no) 
	ELSE '' END AS PartNoRev,
    CASE 
	WHEN  
		(Part_Class <> '' AND Part_Class IS NOT NULL) AND (Part_Type <> '' AND Part_Type IS NOT NULL) AND (i.Descript <> '' AND i.Descript IS NOT NULL) 
		THEN CONCAT(RTRIM(Part_Class),' / ',RTRIM(Part_Type),' / ',RTRIM(i.Descript)) 
	WHEN 
		(Part_Class <> '' AND Part_Class IS NOT NULL) AND (Part_Type = '' OR Part_Type IS NULL) AND (i.Descript <> '' AND i.Descript IS NOT NULL) 
		THEN CONCAT(RTRIM(Part_Class),' / ','',' / ',RTRIM(i.Descript)) 
	WHEN  
		(Part_Class <> '' AND Part_Class IS NOT NULL) AND (Part_Type <> '' AND Part_Type IS NOT NULL) AND (i.Descript = '' OR i.Descript IS NULL) 
		THEN CONCAT(RTRIM(Part_Class),' / ',RTRIM(Part_Type)) 
      ELSE 
    ISNULL(Part_Class,'') END AS Description,
    CASE WHEN i.U_OF_MEAS <> '' AND i.U_OF_MEAS IS NOT NULL 
	THEN i.U_OF_MEAS ELSE ISNULL(Pldetail.UOFMEAS,'') END AS SUOM,  --Nitesh B : 12/6/2019 : Get SUOM from Pldetail for manual PL line items
	--Shivshankar P : 07/20/2020 : Get Quantity from Pldetail table if null in Plprices and also check null for other fields
    ISNULL(Plprices.QUANTITY, Pldetail.SHIPPEDQTY) AS Quantity,  --Shivshankar P : 06/23/2020 : Get Quantity from Plprices table for line items
    ISNULL(Sodetail.Uniq_key,'') AS UniqKey,
    ISNULL(Plprices.FLAT, 0) As Flat,
    ISNULL(Plprices.TAXABLE, 0) AS Taxable,
    Plprices.PL_GL_NBR AS AcctNo,
	Plprices.COG_GL_NBR AS COGAcctNo, --Nitesh B : 11/2/2019 : Added COGAcctNo to get Cost of goods Account number form plprice  
    ISNULL(Plprices.PRICE, 0) AS Price,
    ISNULL(Plprices.EXTENDED, 0) AS Extended,
    Plprices.DESCRIPT AS PriceDesc,
    Plprices.PLUNIQLNK AS PlUniqLink,
    PLDETAIL.INV_LINK AS InvLink,
    ISNULL(Plprices.PRICEFC, 0) AS TransPrice,
    ISNULL(Plprices.EXTENDEDFC, 0) AS TransExtended,
    ISNULL(Plprices.PRICEPR, 0) AS PricePr,
    ISNULL(Plprices.EXTENDEDPR, 0) AS ExtendedPr,
	Pldetail.PACKLISTNO AS PackListNo, --Nitesh B : 1/14/2020 : Get PackListNo from Pldetail for manual PL line items
	Plprices.RECORDTYPE AS RECORDTYPE  --Shivshankar P : 09/11/2020 : Added sorting by RECORDTYPE desc
    FROM Pldetail  
    LEFT OUTER JOIN Sodetail ON Pldetail.Uniqueln = Sodetail.Uniqueln  
    LEFT OUTER JOIN Inventor i ON Sodetail.uniq_key = i.uniq_key  
    LEFT OUTER JOIN Plprices ON Pldetail.PACKLISTNO = Plprices.PACKLISTNO AND Pldetail.Uniqueln = Plprices.Uniqueln 
    WHERE Pldetail.Packlistno = @packingListNo;
     
    SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @invoiceLineItemTable;
    
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