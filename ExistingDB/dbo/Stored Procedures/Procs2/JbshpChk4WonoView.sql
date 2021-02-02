CREATE PROC [dbo].[JbshpChk4WonoView] @gWono AS char(10) = ''
AS
SELECT *
	FROM JbshpChk
	WHERE Wono = @gWono