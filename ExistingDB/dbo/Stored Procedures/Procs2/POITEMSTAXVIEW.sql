-- =============================================
-- Author:		Vicky Lu
-- Create date: <01/19/2015>
-- Description:	Get PO items tax
-- Modified:	
-- 05/03/16 VL: Added TaxDesc from Taxtabl
-- 09/06/16 VL: Change inner join to left outer join and show 'N/A' as tax_id and tax_desc for the old records that have no tax_id associated
-- =============================================
CREATE PROCEDURE [dbo].[POITEMSTAXVIEW] (@gcPoNum char(15) ='')
AS

-- 01/19/15 VL created a new PO tax view for GST project
-- 05/03/16 VL: Added TaxDesc from Taxtabl
SELECT UniqPoitemsTax, Ponum, Uniqlnno, CASE WHEN PoitemsTax.Tax_id<>'' THEN PoitemsTax.Tax_id ELSE 'N/A     ' END AS Tax_id, PoitemsTax.TAX_RATE, ISNULL(Taxdesc, 'N/A     ') AS TaxDesc
	FROM PoitemsTax LEFT OUTER JOIN Taxtabl
	ON PoitemsTax.Tax_id = Taxtabl.Tax_id
	WHERE PoitemsTax.ponum = @gcponum