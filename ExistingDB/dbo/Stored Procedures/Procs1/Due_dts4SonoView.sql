CREATE PROC [dbo].[Due_dts4SonoView] @lcSono AS char(10) = ''
AS
SELECT *
	FROM Due_dts
	WHERE Sono = @lcSono
	ORDER BY Due_dts

