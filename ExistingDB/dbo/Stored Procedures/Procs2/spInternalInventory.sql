-- =============================================
-- Author:		<Avinash>
-- Create date: 06/24/2015
-- Description:	Created for the ICM for Internal Inventory filter
-- 5/26/2016 Nitesh B: Rename the inventory to 'In-Plant Supplier (IPS)','In-Plant Customer (IPC)' ,'Manufacturer Part No' & 'Inactive'
-- 6/9/2016  Nitesh B: Commenting the unused parameters @PARTMFGR,@MFGRPTNO,@INTUNIQ,@InventorType
--                     No need to check by inventory type	
-- =============================================
CREATE PROCEDURE spInternalInventory
(
@UNIQMFGRHD nvarchar(20)--,
--@PARTMFGR char(8)='',
--@MFGRPTNO char(30)='',
--@INTUNIQ char(10)='',
--@InventorType CHAR(30)
)
AS
BEGIN
--5/26/2016 Nitesh B: Rename the inventory to 'In-Plant Supplier (IPS)','In-Plant Customer (IPC)' ,'Manufacturer Part No' & 'Inactive'
-- 6/9/2016 Nitesh B: Commenting the unused parameters @PARTMFGR,@MFGRPTNO,@INTUNIQ,@InventorType
--                    No need to check by inventory type	
--IF(@InventorType = 'Internal Inventory' OR @InventorType = 'In-Plant Supplier (IPS)' or @InventorType= 'Manufacturer Part No' or @InventorType='Inactive')
	SELECT	W.WAREHOUSE,MF.LOCATION,ISNULL(P.NUMBEROFPKGS,0) AS NUMBEROFPKGS , MF.QTY_OH,MF.RESERVED,MF.QTY_OH-MF.RESERVED AS AVAILABLE,
			MF.COUNT_DT AS LAST_COUNT,MF.NETABLE,MF.IS_VALIDATED,MF.W_KEY,MF.UNIQMFGRHD,MF.UNIQWH,W.WHNO
	FROM	INVTMFGR MF 
			INNER JOIN WAREHOUS W ON MF.UNIQWH=W.UNIQWH
			OUTER APPLY (SELECT W_KEY,COUNT(*) AS NUMBEROFPKGS FROM IPKEY WHERE IPKEY.W_KEY=MF.W_KEY AND PKGBALANCE<>0.00 GROUP BY IPKEY.W_KEY) P
	WHERE	MF.IS_DELETED=0 AND MF.INSTORE=0 AND UNIQMFGRHD = @UNIQMFGRHD
	--5/26/2016 Nitesh B: Rename the inventory to 'In-Plant Supplier (IPS)','In-Plant Customer (IPC)' ,'Manufacturer Part No' & 'Inactive'
	-- 6/9/2016 Nitesh B: Commenting the unused parameters @PARTMFGR,@MFGRPTNO,@INTUNIQ,@InventorType 
	--                    No need to check by inventory type
/*
ELSE IF(@InventorType = 'In-Plant Customer (IPC)') 
	SELECT W.WAREHOUSE,MF.LOCATION,ISNULL(P.NUMBEROFPKGS,0) AS NUMBEROFPKGS , MF.QTY_OH,MF.RESERVED,MF.QTY_OH-MF.RESERVED AS AVAILABLE,
	MF.COUNT_DT AS LAST_COUNT,MF.NETABLE,MF.IS_VALIDATED,MF.W_KEY,MF.UNIQMFGRHD,MF.UNIQWH,W.WHNO
	FROM INVTMFGR MF INNER JOIN WAREHOUS W ON MF.UNIQWH=W.UNIQWH
	INNER JOIN INVTMPNLINK L ON L.UNIQMFGRHD=MF.UNIQMFGRHD
	INNER JOIN MFGRMASTER M ON M.MFGRMASTERID=L.MFGRMASTERID
	OUTER APPLY (SELECT W_KEY,COUNT(*) AS NUMBEROFPKGS FROM IPKEY WHERE IPKEY.W_KEY=MF.W_KEY AND PKGBALANCE<>0.00 GROUP BY IPKEY.W_KEY) P
	WHERE L.UNIQ_KEY= @INTUNIQ	 
	AND L.IS_DELETED=0 AND M.IS_DELETED=0
	AND M.MFGR_PT_NO=@MFGRPTNO
	AND M.PARTMFGR=@PARTMFGR
	AND MF.IS_DELETED=0 AND MF.INSTORE=0 
	*/
END