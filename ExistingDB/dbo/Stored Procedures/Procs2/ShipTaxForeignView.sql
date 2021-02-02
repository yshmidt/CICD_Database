-- =============================================
-- Author:		<Bill Blake>
-- Create date: <05/28/10>
-- Description:	<Get foreign tax info>
-- Modification:
-- 11/20/20 VL We don't use PlFreightTAx anymore, so need to use this SP again, need to add 4 new tax fields and linked to Taxtabl
-- =============================================
CREATE PROCEDURE [dbo].[ShipTaxForeignView]

     -- Add the parameters for the stored procedure here

     @lcCustno char(10)=' ',@lcTaxType char(1) = ' ', @lcLinkAdd char(10)='
'

AS

BEGIN

     -- SET NOCOUNT ON added to prevent extra result sets from

     -- interfering with SELECT statements.

     SET NOCOUNT ON;



   -- Insert statements for procedure here

     SELECT ShipTax.PtProd,ShipTax.StProd,ShipTax.StTx,ShipTax.PtFrt,ShipTax.StFrt,ShipTax.Tax_Rate,ShipTax.TaxType,ShipTax.Tax_id, 
		Taxtabl.TaxType AS SetupTaxType, TaxApplicableTo, IsFreightTotals, IsProductTotal

           FROM ShipTax INNER JOIN TAXTABL ON ShipTax.TAX_ID = TAXTABL.TAX_ID

     WHERE ShipTax.TaxType=@lcTaxType and Custno=@lcCustno and RECORDTYPE='S' and LINKADD = @lcLinkAdd 

END