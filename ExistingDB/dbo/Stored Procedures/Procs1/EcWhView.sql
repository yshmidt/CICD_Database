CREATE PROC [dbo].[EcWhView] @gUniqEcNo AS char(10) = ' '
AS
SELECT Uniqecno, Uniqecwh, Qty_oh, Warehouse, Location
	FROM Ecwh
	WHERE Uniqecno = @gUniqecno




