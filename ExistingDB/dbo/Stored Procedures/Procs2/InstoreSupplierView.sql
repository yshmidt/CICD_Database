CREATE PROCEDURE [dbo].[InstoreSupplierView]
AS 
BEGIN
	SELECT DISTINCT SupName, SupInfo.SUPID, SupInfo.UniqSupno
		FROM SupInfo, InvtMfgr 
		WHERE SupInfo.UniqSupno = InvtMfgr.UniqSupno
		AND InStore = 1
		AND Invtmfgr.Is_Deleted = 0
		ORDER BY SupName 
END








