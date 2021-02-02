CREATE PROC [dbo].[ConfgVar4WonoView] @gWono AS char(10) = ''
AS

BEGIN
SELECT *
	FROM 
	ConfgVar
	WHERE Wono = @gWono 
	ORDER BY Datetime

END