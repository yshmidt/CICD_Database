﻿-- ======================================================================================
-- Author: Shivshankar P
-- Create date: 11/15/2017
-- Description:	Created for the ICM for Supplier Consigned Filter
-- ======================================================================================
CREATE PROCEDURE GetSupplierConsignedInventor --'_01F15SZ7F'
(
@uniq_key NVARCHAR(10)
)
AS
BEGIN
SELECT	S.SUPNAME,S.SUPID,W.WAREHOUSE + '/' + MF.LOCATION AS WAREHOUSE,ISNULL(P.NUMBEROFPKGS,0) AS NUMBEROFPKGS , MF.QTY_OH,MF.RESERVED,MF.QTY_OH-MF.RESERVED AS AVAILABLE,
		MF.COUNT_DT AS LAST_COUNT,MF.NETABLE,MF.IS_VALIDATED,MF.W_KEY,MF.UNIQMFGRHD,MF.UNIQWH,W.WHNO,MF.UNIQ_KEY
FROM	INVTMFGR MF 
		INNER JOIN WAREHOUS W ON MF.UNIQWH=W.UNIQWH
		INNER JOIN SUPINFO S ON MF.UNIQSUPNO=S.UNIQSUPNO 
		OUTER APPLY (SELECT W_KEY,COUNT(*) AS NUMBEROFPKGS FROM IPKEY WHERE IPKEY.W_KEY=MF.W_KEY AND PKGBALANCE<>0.00 GROUP BY IPKEY.W_KEY) P
WHERE	MF.IS_DELETED=0 AND MF.INSTORE=1 AND uniq_key=@uniq_key 
END
