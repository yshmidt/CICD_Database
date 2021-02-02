-- =============================================
-- Author:Satish B
-- Create date: 04/21/2017
-- Description:	Get To W_Key when buyer Accept Fully 
-- GetToWKey '76Y8CMFR5Y'  
-- =============================================
CREATE PROCEDURE GetToWKey
  @inspHeaderId char(10)=''
 AS
 BEGIN
	 SET NOCOUNT ON
	 SELECT invtmfgr.W_KEY
	 FROM InspectionHeader inspectionHeader
	 INNER JOIN ReceiverDetail receiverDetail ON inspectionHeader.ReceiverDetId=receiverDetail.ReceiverDetId
	 INNER JOIN INVTMFGR invtmfgr ON invtmfgr.UNIQ_KEY=receiverDetail.Uniq_key
	 INNER JOIN porecdtl porecdtl ON receiverDetail.ReceiverDetId=porecdtl.receiverdetId
	 INNER JOIN porecloc porecloc ON porecdtl.UniqRecDTL=porecloc.FK_UNIQRECDTL
	 INNER JOIN WAREHOUS warehouse ON invtmfgr.UNIQWH=warehouse.UNIQWH
	 WHERE inspectionHeader.inspHeaderId = @inspHeaderId AND
	       porecdtl.uniqmfgrhd =invtmfgr.UNIQMFGRHD AND
           porecloc.UNIQWH = invtmfgr.UNIQWH AND
		   porecloc.LOCATION = invtmfgr.LOCATION
 END

