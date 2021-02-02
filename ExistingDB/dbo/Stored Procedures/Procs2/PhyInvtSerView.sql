CREATE PROC [dbo].[PhyInvtSerView] @lcUniqPiHead AS char(10) = ' '
AS
SELECT Phserunique, PhyInvtser.Uniqphyno, Serialno, Uniqmfgrhd, Uniqpihead
	FROM Phyinvtser
	WHERE Phyinvtser.Uniqpihead = @lcUniqPiHead










