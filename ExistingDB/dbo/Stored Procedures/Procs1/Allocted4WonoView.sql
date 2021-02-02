CREATE PROC [dbo].[Allocted4WonoView] @gWono AS char(10) = ' '
AS

SELECT *
	FROM Invt_Res
	WHERE Wono = @gWono
	AND Invtres_no NOT IN
		(SELECT RefInvtres FROM Invt_res WHERE Wono = @gWono)
	AND QtyAlloc > 0
	ORDER BY Wono, W_KEY 




