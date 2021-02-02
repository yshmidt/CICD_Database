-- =============================================
-- Author:Satish B
-- Create date: 04/21/2017
-- Description:	Get From W_Key when buyer Accept Fully 
-- GetFromWKey '42EAECK9D3'  
-- =============================================
CREATE PROCEDURE GetFromWKey
  @inspHeaderId char(10)=''
 AS
 BEGIN
	 SET NOCOUNT ON
	 SELECT invtmfgr.W_KEY
	 FROM InspectionHeader inspectionHeader
	 INNER JOIN ReceiverDetail receiverDetail ON inspectionHeader.ReceiverDetId=receiverDetail.ReceiverDetId
	 INNER JOIN INVTMFGR invtmfgr ON invtmfgr.UNIQ_KEY=receiverDetail.Uniq_key
	 INNER JOIN WAREHOUS warehouse ON invtmfgr.UNIQWH=warehouse.UNIQWH
	 WHERE warehouse.WAREHOUSE='MRB' AND
	       invtmfgr.Location =inspectionHeader.inspHeaderId AND
		   inspectionHeader.InspHeaderId = @inspHeaderId
 END
