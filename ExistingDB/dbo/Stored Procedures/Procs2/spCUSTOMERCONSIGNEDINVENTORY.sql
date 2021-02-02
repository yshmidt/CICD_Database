﻿-- =============================================
-- Author:		<Avinash>
-- Create date: 06/24/2015
-- Description:	Created for the ICM for Customer Consigned Inventory filter
-- 6/8/2016 Nitesh B: Modify the with new parameter @intUnique
-- =============================================
CREATE PROCEDURE spCUSTOMERCONSIGNEDINVENTORY
(
@PARTMFGR CHAR(8),
@MFGR_PT_NO CHAR(30),
@CUSTNO CHAR(10),
@intUnique char(10)=''
)
AS 
BEGIN
	SELECT	IC.UNIQ_KEY,C.CUSTNAME,C.CUSTNO,IC.CUSTPARTNO,IC.CUSTREV,
			W.WAREHOUSE,CMF.LOCATION,ISNULL(P.NUMBEROFPKGS,0) AS NUMBEROFPKGS , CMF.QTY_OH,CMF.RESERVED,CMF.QTY_OH-CMF.RESERVED AS AVAILABLE,
			CMF.COUNT_DT AS LAST_COUNT,CMF.NETABLE,CMF.IS_VALIDATED,CMF.W_KEY,CMF.UNIQMFGRHD,CMF.UNIQWH,W.WHNO,C.CUSTNO
	FROM	CUSTOMER C 
			INNER JOIN INVENTOR IC ON C.CUSTNO=IC.CUSTNO
			INNER JOIN INVTMFGR CMF ON IC.UNIQ_KEY=CMF.UNIQ_KEY 
			INNER JOIN WAREHOUS W ON CMF.UNIQWH=W.UNIQWH
			CROSS APPLY  (SELECT M.MFGRMASTERID,PARTMFGR,MFGR_PT_NO,L.UNIQMFGRHD 
	FROM	MFGRMASTER M INNER JOIN INVTMPNLINK L ON L.MFGRMASTERID=M.MFGRMASTERID AND L.IS_DELETED=0
	WHERE	M.PARTMFGR = @PARTMFGR 
			AND M.MFGR_PT_NO = @MFGR_PT_NO
			AND IC.INT_UNIQ = @intUnique-- 6/8/2016 Nitesh B: Modify the with new parameter @intUnique
			AND M.IS_DELETED=0 AND L.UNIQ_KEY=IC.UNIQ_KEY AND CMF.UNIQMFGRHD=L.UNIQMFGRHD) CM
			OUTER APPLY (SELECT W_KEY,COUNT(*) AS NUMBEROFPKGS FROM IPKEY WHERE IPKEY.W_KEY=CMF.W_KEY AND PKGBALANCE<>0.00 GROUP BY IPKEY.W_KEY) P
			WHERE IC.PART_SOURC='CONSG' AND CMF.IS_DELETED=0 --OR C.CUSTNO=@CUSTNO
END