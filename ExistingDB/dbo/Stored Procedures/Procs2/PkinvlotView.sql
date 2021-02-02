CREATE PROC [dbo].[PkinvlotView] @lcPacklistno AS char(10) = ''
AS
SELECT *
	FROM Pkinvlot
	WHERE Packlistno = @lcPacklistno