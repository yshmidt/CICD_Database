CREATE PROC [dbo].[JshpChkl4WonoView] @gWono AS char(10) = ''
AS
SELECT *
	FROM JshpChkl
	WHERE Wono = @gWono