CREATE PROC [dbo].[Kalocser4WonoView] @gWono AS char(10) ='' 
AS
SELECT *
	FROM Kalocser
	WHERE Wono = @gWono
	ORDER BY Serialno
