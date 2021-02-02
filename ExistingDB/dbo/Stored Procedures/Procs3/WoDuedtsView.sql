CREATE PROC [dbo].[WoDuedtsView] @gWono AS char(10) = ''
AS
SELECT *
	FROM WoDuedts
	WHERE Wono = @gWono
	ORDER BY Due_dts

