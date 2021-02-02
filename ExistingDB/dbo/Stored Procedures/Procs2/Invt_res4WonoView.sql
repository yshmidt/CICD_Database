CREATE PROC [dbo].[Invt_res4WonoView] @lcWono AS char(10) = ' '
AS
-- 05/01/12 VL added nSavePrioirity for Kit use, it has to have saving orders

SELECT Invt_res.*, 1.0 AS nSavePriority
	FROM Invt_res
	WHERE WONO = @lcWono




