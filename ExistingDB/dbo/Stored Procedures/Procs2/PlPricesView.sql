CREATE PROC [dbo].[PlPricesView] @lcPacklistno AS char(10) = ''
AS
SELECT *
	FROM Plprices
	WHERE Packlistno = @lcPacklistno