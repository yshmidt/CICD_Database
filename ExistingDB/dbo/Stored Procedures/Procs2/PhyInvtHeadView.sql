CREATE PROC [dbo].[PhyInvtHeadView] @lcUniqPiHead AS char(10) = ' '
AS
SELECT Invttype, Uniqpihead, Detailname, Detailno, Startno, Endno, Starttime, Pistatus, Cxlinit, Cxldate, Cxlreason, Pistatus AS OldPistatus
	FROM Phyinvth
	WHERE Uniqpihead = @lcUniqPiHead









