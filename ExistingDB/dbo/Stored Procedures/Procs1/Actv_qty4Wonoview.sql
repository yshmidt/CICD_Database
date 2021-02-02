CREATE PROC [dbo].[Actv_qty4Wonoview] @gWono AS char(10) = ''
AS
SELECT *
	FROM Actv_qty
	WHERE Wono = @gWono
	ORDER BY Numbera
