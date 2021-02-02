CREATE PROC [dbo].[Kalocate4WonoView] @gWono AS char(10) =' ' 
AS
SELECT *
	FROM Kalocate
	WHERE Wono = @gWono




