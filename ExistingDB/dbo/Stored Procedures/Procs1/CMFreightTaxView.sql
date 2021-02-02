------------------------------------------------------------------
-- Modification
------------------------------------------------------------------

CREATE PROC [dbo].[CMFreightTaxView] 
	@gcCmUnique AS char(10) = ' '
AS
SELECT *
	FROM CMFreightTax
	WHERE Cmunique = @gcCmUnique
	