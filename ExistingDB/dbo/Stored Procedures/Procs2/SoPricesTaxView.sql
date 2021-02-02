-- =============================================
-- Author:		Vicky Lu
-- Create date: <Create Date,,>
-- Description:	Get SO price tax record
-- Modified:	
-- 04/28/16 VL: Added TaxDesc from Taxtabl
-- =============================================
CREATE PROC [dbo].[SoPricesTaxView] @lcSono AS char(10) = ' '
AS
-- 02/26/15 VL decide to add all 5 logical fields, so even the setting are changed, the so/invoice/rma.... will keep original setting
--SELECT SopricesTax.*, Shiptax.PTPROD, Ptfrt, Stprod, Stfrt, Sttx
--	FROM Somain, SopricesTax, ShipTax
--	WHERE Somain.Sono = SopricesTax.Sono 
--	AND SopricesTax.Tax_id = ShipTax.Tax_id
--	AND ShipTax.CUSTNO = Somain.Custno
--	AND (ShipTax.TAXTYPE = 'S'
--	OR ShipTax.TAXTYPE = 'P'
--	OR ShipTax.TAXTYPE = 'E')
--	AND SopricesTax.Sono = @lcSono
SELECT SopricesTax.*, TaxDesc
	FROM SopricesTax, Taxtabl
	WHERE SopricesTax.Tax_id = Taxtabl.Tax_id 
	AND SopricesTax.Sono = @lcSono