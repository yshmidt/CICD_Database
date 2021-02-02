-- =============================================
-- Author:Satish B
-- Create date: 01/30/2017
-- Description:	Get Warehouse and Lot details for non SID part
-- Modified :06/09/2017 Satish B : Combine Lotcode,Expiration date and Reference
-- Modified :06/21/2017 Satish B : Select porecdtl.AcceptedQty and invtlot.LOTRESQTY columns
-- Modified :06/21/2017 Satish B : Declare @partType
-- Modified :06/21/2017 Satish B : Apply the filter between invtmfgr and invtlot table conditionally 
-- Modified :08/31/2017 Satish B : Calculate Accepted qty and Insert into temp table 
-- Modified :08/31/2017 Satish B : Comment selection of accepted qty from porecdtl.AcceptedQty and select Calculated AcceptedQty
-- Modified :08/31/2017 Satish B : Apply the join of #TempTable
-- Modified :09/19/2017 Satish B : Check null for AcceptedQty
-- Modified :09/21/2017 Satish B : Comment the code of filter inspHdr.RejectedAt='Production'
-- Modified :09/21/2017 Satish B : Comment the existing logic of calculat the AcceptedQty and implement new logic to calculate the AcceptedQty
-- Modified :09/21/2017 Satish B : Commemt the selection of t.AcceptedQty and calculate the AcceptedQty
-- Modified :09/21/2017 Satish B : Commemt join of #TempTable
-- Modified :09/21/2017 Satish B : Added filter to check acceptable quantity is > 0
-- Modified :02/22/2018 Satish B : Check condition not equal to 0 instade of greater then 0
-- GetWarehouseAndLotDetails '_26V0MTTWO','0000001353',1
-- =============================================
CREATE PROCEDURE GetWarehouseAndLotDetails
	@uniqKey varchar(10)='',
	@rcvNumber varchar(10)='',
	@isLotted bit= 0   -- 06/21/2017 Satish B : Declare @isLotted
AS
BEGIN
	 SET NOCOUNT ON;
	 --08/31/2017 Satish B :Calculate Accepted qty and Insert into temp table 
	 --SELECT (po.AcceptedQty -((SUM(inspHdr.FailedQty) + SUM(inspHdr.ReturnQty)) - SUM(inspHdr.Buyer_Accept))) AS AcceptedQty,inspHdr.receiverDetId
		--  INTO #TempTable
		--  FROM inspectionHeader inspHdr INNER JOIN porecdtl po ON po.receiverdetId =inspHdr.receiverDetId
		--  --09/21/2017 Satish B :Comment the code of filter inspHdr.RejectedAt='Production'
		--  WHERE po.receiverno=@rcvNumber AND inspHdr.RejectedAt='Production'
		--  GROUP BY inspHdr.receiverDetId,po.AcceptedQty
	 
	 --09/21/2017 Satish B :Comment the existing logic of calculat the AcceptedQty and implement new logic to calculate the AcceptedQty
	 DECLARE @ProductionReject numeric(10,2);
	 SELECT @ProductionReject=(((SUM(inspHdr.FailedQty) + SUM(inspHdr.ReturnQty)) - SUM(inspHdr.Buyer_Accept)))
		  FROM inspectionHeader inspHdr INNER JOIN porecdtl po ON po.receiverdetId =inspHdr.receiverDetId
		  WHERE po.receiverno=@rcvNumber AND inspHdr.RejectedAt='Production'
		  GROUP BY inspHdr.receiverDetId,po.AcceptedQty

	 SELECT porecdtl.PARTMFGR AS MFGR
		 ,porecdtl.MFGR_PT_NO AS MFGRPtNo
		 ,porecdtl.UNIQMFGRHD
		 ,invtlot.LOTCODE
		 ,invtlot.EXPDATE
		 ,invtlot.REFERENCE
		 ,invtlot.LOTQTY
		 ,invtlot.UNIQ_LOT
		 ,invtmfgr.W_KEY
		 ,warehous.WAREHOUSE +(CASE WHEN invtmfgr.LOCATION IS NULL OR invtmfgr.LOCATION = '' THEN '' ELSE '/' END) + invtmfgr.LOCATION AS WhLocation  
		 ,warehous.UNIQWH
		 ,inventor.SerialYes
		 ,inventor.useipkey AS Useipkey
		 ,recdetail.RECEIVERDETID
		 ,invtmfgr.QTY_OH
		 ,invtmfgr.RESERVED
		 ,invtmfgr.W_KEY
		 --06/09/2017 Satish B : Combine Lotcode,Expiration date and Reference
		 ,(RTRIM(invtlot.LOTCODE)+'/'+(CONVERT(VARCHAR, invtlot.EXPDATE , 10))+'/'+LTRIM(invtlot.REFERENCE)) AS LotExpDtRef
		 --06/21/2017 Satish B : Select porecdtl.AcceptedQty and invtlot.LOTRESQTY columns
		 --08/31/2017 Satish B : Comment selection of accepted qty from porecdtl.AcceptedQty and select Calculated AcceptedQty
		 --,porecdtl.AcceptedQty 
		 --09/19/2017 Satish B : Check null for AcceptedQty
		 --09/21/2017 Satish B : Commemt the selection of t.AcceptedQty and calculate the AcceptedQty
		 --,ISNULL(t.AcceptedQty,0) AS AcceptedQty
		  ,porecdtl.AcceptedQty-ISNULL(@ProductionReject,0) AS AcceptedQty
		 ,ISNULL(invtlot.LOTRESQTY,0) AS LOTRESQTY
	 FROM PORECDTL porecdtl
	 INNER JOIN receiverDetail recdetail ON porecdtl.receiverdetId=recdetail.receiverdetId
	 INNER JOIN INVENTOR inventor ON inventor.UNIQ_KEY=recdetail.Uniq_key
	 INNER JOIN PORECLOC porecloc ON porecloc.FK_UNIQRECDTL=porecdtl.uniqrecdtl
	 LEFT JOIN PORECLOT poreclot ON poreclot.LOC_UNIQ=porecloc.LOC_UNIQ 
	 LEFT JOIN INVTLOT invtlot ON invtlot.LOTCODE=poreclot.LOTCODE AND invtlot.REFERENCE = poreclot.REFERENCE AND invtlot.EXPDATE = poreclot.EXPDATE
	 INNER JOIN INVTMFGR invtmfgr ON invtmfgr.UNIQMFGRHD=porecdtl.uniqmfgrhd AND invtmfgr.LOCATION=porecloc.LOCATION AND invtmfgr.UNIQWH=porecloc.UNIQWH 
	 INNER JOIN WAREHOUS warehous ON warehous.UNIQWH=invtmfgr.UNIQWH 
	 --08/31/2017 Satish B : Apply the join of #TempTable
	 --09/21/2017 Satish B : Commemt join of #TempTable
	 --LEFT JOIN #TempTable t ON porecdtl.receiverdetId =t.receiverDetId
	 WHERE inventor.UNIQ_KEY= @uniqKey 
	 AND porecdtl.receiverno=@rcvNumber 
	 AND warehous.WAREHOUSE<>'MRB' 
	  --06/21/2017 Satish B : Apply the filter between invtmfgr and invtlot table conditionally 
	 AND (@isLotted=0 OR invtmfgr.W_KEY=invtlot.W_KEY )
	 --09/21/2017 Satish B : Added filter to check acceptable quantity is > 0
	 --02/22/2018 Satish B : Check condition not equal to 0 instade of greater then 0
	 AND (porecdtl.AcceptedQty-ISNULL(@ProductionReject,0)) <>0
END

