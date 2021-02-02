-- =============================================
-- Author:Satish B
-- Create date: 08/24/2017
-- Description : get Po Management tax detail
-- exec GetPoManagementTaxDetails '_43701U6AK',1,500,0
-- =============================================
CREATE PROCEDURE GetPoManagementTaxDetails
	@uniqLnNo char(10) ='',
	@startRecord int ='',
    @endRecord int =10, 
	@outTotalNumberOfRecord int OUTPUT
 AS
 BEGIN
	 SET NOCOUNT ON	 
	 SELECT COUNT(poitemTax.TAX_ID) AS RowCnt -- Get total counts 
	 INTO #tempPoTaxGidData
	 FROM POITEMSTAX poitemTax
		 INNER JOIN POITEMS poitem ON poitem.UNIQLNNO=poitemTax.UNIQLNNO
		 INNER JOIN TAXTABL taxtable ON taxtable.TAX_ID=poitemTax.TAX_ID
	 WHERE poitem.UNIQLNNO=@uniqLnNo
     SELECT poitemTax.TAX_ID AS TaxId
		  ,taxtable.TAXDESC AS TaxDescription
		  ,poitemTax.TAX_RATE AS TaxRate

	FROM POITEMSTAX poitemTax
	INNER JOIN POITEMS poitem ON poitem.UNIQLNNO=poitemTax.UNIQLNNO
	INNER JOIN TAXTABL taxtable ON taxtable.TAX_ID=poitemTax.TAX_ID
	WHERE poitem.UNIQLNNO=@uniqLnNo
	ORDER BY poitemTax.TAX_ID
	OFFSET(@startRecord-1) ROWS
	FETCH NEXT @EndRecord ROWS ONLY;

	SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPoTaxGidData) -- Set total count to Out paramete
END