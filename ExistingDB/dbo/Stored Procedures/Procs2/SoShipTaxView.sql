-- =============================================
-- Author:		Vicky Lu
-- Create date: ??
-- Description:	Get shiptax for linkadd
-- Modification
-- 03/16/15 VL re-write the criteria to not use 1 = .... so the code will run faster
-- 05/02/16 VL added Taxdesc from Taxtabl
-- 11/23/16 VL didn't consider that user might not check secondary product tax but check sttx tax, so add code to cosinder the situation
-- 11/26/19 VL changed for cube version to use new fields
-- 11/20/20 VL talked with YS, we will save Tax_id in SopricesTax.TaxApplicableTo while Taxtabl.TaxApplicableTo saves the TaxUnique, we will use the 
--				SopricesTax.TaxApplicableTo (tax_id) to find associated primary tax in SopricesTax table that keeps the old tax rate
-- =============================================
CREATE PROC [dbo].[SoShipTaxView] @lcLinkAdd char(10) = ''
AS
-- 03/16/15 VL re-write the criteria to not use 1 = .... so the code will run faster
--SELECT *
--	FROM ShipTax
--	WHERE LinkAdd = @lcLinkAdd 
--	AND RecordType = 'S'
--	AND (1 = CASE WHEN (TAXTYPE = 'P' AND PTPROD = 1) THEN 1 ELSE 0 END 
--	OR 1 = CASE WHEN (TAXTYPE = 'E' AND STPROD = 1) THEN 1 ELSE 0 END 
--	OR 1 = CASE WHEN TAXTYPE = 'S' THEN 1 ELSE 0 END)

-- 11/26/19 VL changed for cube version
--SELECT *
--	FROM ShipTax INNER JOIN TAXTABL
--	ON ShipTax.TAX_ID = TAXTABL.Tax_id 
--	WHERE LinkAdd = @lcLinkAdd 
--	AND RecordType = 'S'
--	AND ((ShipTax.TAXTYPE = 'P' AND ShipTax.PTPROD = 1) 
--	-- 11/23/16 VL didn't consider that user might not check secondary product tax but check sttx tax, so add code to cosinder the situation
--	--OR (ShipTax.TAXTYPE = 'E' AND ShipTax.STPROD = 1)
--	OR (ShipTax.TAXTYPE = 'E' AND (ShipTax.STPROD = 1 OR ShipTax.Sttx = 1))
--	OR (ShipTax.TAXTYPE = 'S'))

-- 11/26/19 VL added new code	
-- 11/20/20 VL talked with YS, we will save Tax_id in SopricesTax.TaxApplicableTo while Taxtabl.TaxApplicableTo saves the TaxUnique, we will use the 
-- SopricesTax.TaxApplicableTo (tax_id) to find associated primary tax in SopricesTax table that keeps the old tax rate, will use TaxApplicableToTax_id to save in sopricesTax
SELECT Shiptax.unqshiptax, Shiptax.linkadd, Shiptax.custno,
  Shiptax.address1, Shiptax.taxdesc, Shiptax.taxtype, Shiptax.tax_rate,
  Shiptax.tax_id, Shiptax.recordtype, Shiptax.ptprod, Shiptax.ptfrt,
  Shiptax.stprod, Shiptax.stfrt, Shiptax.sttx,
  modifiedDate, DefaultTax, Shiptax.IsSynchronizedFlag, Taxtabl.TaxType AS SetupTaxType, Taxtabl.TAXUNIQUE, Taxtabl.IsProductTotal, Taxtabl.IsFreightTotals, 
  Taxtabl.TaxApplicableTo, ISNULL(T2.Tax_id,SPACE(10)) AS TaxApplicableToTax_id
 FROM 
     shiptax INNER JOIN TAXTABL ON Shiptax.Tax_id = TAXTABL.Tax_id
	 LEFT OUTER JOIN TAXTABL T2 ON TAXTABL.TaxApplicableTo = T2.TAXUNIQUE
 WHERE LinkAdd = @lcLinkAdd 
 AND Shiptax.recordtype = 'S' --Sales
 AND ShipTax.TaxType = 'S' -- Shipping