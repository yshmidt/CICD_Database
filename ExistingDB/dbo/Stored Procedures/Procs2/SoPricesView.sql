CREATE PROC [dbo].[SoPricesView] @lcSono AS char(10) = ''
AS
SELECT *
	FROM Soprices
	WHERE Sono = dbo.padl(@lcSoNo,10,'0')