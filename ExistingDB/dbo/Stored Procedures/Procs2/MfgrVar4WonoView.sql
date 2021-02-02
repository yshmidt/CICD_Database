CREATE PROC [dbo].[MfgrVar4WonoView] @gWono AS char(10) = ' '
AS
SELECT *
	FROM MfgrVar
	WHERE WONO = @gWono




