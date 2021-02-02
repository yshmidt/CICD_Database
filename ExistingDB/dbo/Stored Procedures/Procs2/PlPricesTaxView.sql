-- Author:		Vicky Lu
-- Create date: <Create Date,,>
-- Description:	Get PL price tax record
-- Modified:	
-- 05/03/16 VL: Added TaxDesc from Taxtabl
-- =============================================
CREATE PROC [dbo].[PlPricesTaxView] @lcPacklistno AS char(10) = ''
AS
SELECT PLPRICESTAX.*, TaxDesc
	FROM PlpricesTax INNER JOIN TAXTABL
	ON PlpricesTax.TAX_ID = Taxtabl.Tax_id
	WHERE Packlistno = @lcPacklistno