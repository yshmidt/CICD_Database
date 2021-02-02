------------------------------------------------------------------
-- Modification
------------------------------------------------------------------

CREATE PROC [dbo].[PlFreightTaxView] @lcPacklistno AS char(10) = ''
AS
SELECT *
	FROM PlFreightTax
	WHERE Packlistno = @lcPacklistno
	