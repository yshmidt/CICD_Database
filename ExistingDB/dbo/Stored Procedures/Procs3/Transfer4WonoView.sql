CREATE PROC [dbo].[Transfer4WonoView] @gWono AS char(10) = ''
AS
SELECT *
	FROM 
	Transfer
	WHERE Wono = @gWono 
	ORDER BY Date