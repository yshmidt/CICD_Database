CREATE PROC [dbo].[SoHistView] @lcSono AS char(10) = ''
AS
SELECT *
	FROM SoHist
	WHERE Sono = @lcSono
