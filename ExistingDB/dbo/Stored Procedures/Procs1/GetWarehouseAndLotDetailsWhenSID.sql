-- =============================================
-- Author:Satish B
-- Create date: 01/23/2017
-- Description:	Get Warehouse and Lot details against SID 
-- Modified : 06/09/2017 Satish B : Combine Lotcode,Expiration date and Reference
-- Modified : 06/21/2017 Satish B : Select ip.qtyAllocatedTotal column
-- GetWarehouseAndLotDetailsWhenSID 'P79KFNEIKL'
-- =============================================
CREATE PROCEDURE GetWarehouseAndLotDetailsWhenSID
	@ipKeyUniq AS char(10)
	AS
	BEGIN
		SET NOCOUNT ON;
		SELECT  mfgrmaster.PartMfgr AS MFGR
		   ,mfgrmaster.mfgr_pt_no AS MFGRPtNo
		   ,warehouse.WAREHOUSE +(CASE WHEN invtmfgr.LOCATION IS NULL OR invtmfgr.LOCATION = '' THEN '' ELSE '/' END)+ invtmfgr.LOCATION AS WhLocation
		   ,warehouse.UNIQWH
		   ,ip.LOTCODE
		   ,ip.EXPDATE
		   ,ip.REFERENCE
		   ,ip.UNIQMFGRHD
		   ,invtmfgr.W_KEY
		   ,ip.PONUM
		   ,invtLot.UNIQ_LOT	
		   ,invtlot.LOTQTY
		   ,inventor.SerialYes
		   ,inventor.useipkey AS Useipkey
		   ,recdtl.RECEIVERDETID
		   ,invtmfgr.QTY_OH
	       ,invtmfgr.RESERVED
		   ,ip.PKGBALANCE
		    --06/09/2017 Satish B : Combine Lotcode,Expiration date and Reference 
		   ,(RTRIM(invtlot.LOTCODE)+'/'+(CONVERT(VARCHAR, invtlot.EXPDATE , 10))+'/'+LTRIM(invtlot.REFERENCE)) AS LotExpDtRef
		   --06/21/2017 Satish B : Select ip.qtyAllocatedTotal column
		   ,ip.qtyAllocatedTotal AS QtyReserved
	    FROM ipkey ip
		INNER JOIN INVENTOR inventor ON inventor.UNIQ_KEY=ip.UNIQ_KEY
		INNER JOIN INVTMFGR invtmfgr ON invtmfgr.UNIQ_KEY=ip.UNIQ_KEY AND invtmfgr.W_KEY=ip.W_KEY
		INNER JOIN porecdtl p ON p.uniqrecdtl=ip.RecordId
		INNER JOIN receiverDetail recdtl ON recdtl.receiverDetId=p.receiverdetId
		INNER JOIN WAREHOUS warehouse ON warehouse.UNIQWH=invtmfgr.UNIQWH
		INNER JOIN InvtMPNLink invtlink ON invtlink.uniqmfgrhd=ip.UNIQMFGRHD
		INNER JOIN MfgrMaster mfgrmaster ON mfgrmaster.MfgrMasterId=invtlink.MfgrMasterId
		LEFT  JOIN INVTLOT invtlot ON invtlot.LOTCODE=ip.LOTCODE AND invtlot.EXPDATE=ip.EXPDATE AND invtlot.REFERENCE=ip.REFERENCE AND invtlot.PONUM=ip.PONUM
		WHERE 
		 ip.IPKEYUNIQUE=@ipKeyUniq
		 AND warehouse.WAREHOUSE<>'MRB'
	END 

	
