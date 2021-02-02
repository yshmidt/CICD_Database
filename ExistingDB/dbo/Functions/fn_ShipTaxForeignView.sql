-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/08/2012
-- Description:	return information form ShipTax and use the result in another procedure
-- =============================================
CREATE FUNCTION dbo.fn_ShipTaxForeignView
(	
	-- Add the parameters for the function here
	 @lcCustno char(10)=' ',@lcTaxType char(1) = ' ', @lcLinkAdd char(10)=' '
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT PtProd,StProd,StTx,PtFrt,StFrt,Tax_Rate,TaxType,Tax_id

           FROM ShipTax

     WHERE TaxType=@lcTaxType and Custno=@lcCustno and RECORDTYPE='S' and LINKADD = @lcLinkAdd 
)