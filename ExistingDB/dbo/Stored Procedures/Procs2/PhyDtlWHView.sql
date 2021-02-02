CREATE PROC [dbo].[PhyDtlWHView] @lcUniqPiHead AS char(10) = ' '
AS
SELECT Uniqpihead, Uniqpihdtl, Warehous.Whno, Phyhdtl.UniqWh, Warehouse
	FROM Phyhdtl, Warehous
	WHERE Phyhdtl.UniqWh = Warehous.UniqWh
	AND Phyhdtl.UniqWh <> ''
	AND Uniqpihead = @lcUniqPiHead
	ORDER BY Warehous.Whno









