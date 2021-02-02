CREATE PROC [dbo].[Woentry4SonoView] @lcSono AS char(10) = ''
AS
SELECT *
	FROM 
	Woentry
	WHERE Sono = @lcSono 
	AND Uniqueln <> ''
	AND OpenClos<>'Cancel    '
	ORDER BY Wono