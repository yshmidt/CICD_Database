CREATE PROC [dbo].[Invt_res4SonoView] @lcSono AS char(10) = ''
AS
SELECT *
	FROM Invt_res
	WHERE Sono = @lcSono
	AND Sono <> ''
	ORDER BY DateTime