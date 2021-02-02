
------------------------------------------------------------------------------------------------------------------------
-- Modification
-- 04/16/13 VL added PrjUnique
-- 12/17/14 VL added Slinkadd and all the fields from shipbill because now a SO might have multiple shipto
-- 03/02/15 VL added shipcharge
------------------------------------------------------------------------------------------------------------------------
CREATE PROC [dbo].[PkAddSoItemView] @lcSono AS char(10) = ''
AS
SELECT ISNULL(Inventor.Part_no,SPACE(25)) AS Part_no, ISNULL(Inventor.Revision, SPACE(8)) AS Revision, 
	ISNULL(Inventor.Part_class, SPACE(8)) AS Part_class, ISNULL(Inventor.Part_type, SPACE(8)) AS Part_type, 
	ISNULL(Inventor.Descript, Sodet_Desc) AS Descript, ISNULL(Inventor.Part_Sourc, SPACE(10)) AS Part_Sourc, 
	ISNULL(Inventor.U_of_meas, SPACE(4)) AS U_of_meas, ISNULL(Inventor.SerialYes, 0) AS SerialYes,
	ISNULL(Inventor.Revision, SPACE(4)) AS ShippedRev, ISNULL(Inventor.Cert_req, 0) AS Cert_req,
	ISNULL(Inventor.Cert_type, SPACE(10)) AS Cert_type,	Sodetail.Uniq_key, Uniqueln, Line_no, UofMeas, 
	Ord_qty, Shippedqty, Balance, Sono, Sodetail.Prodtpuniq, ProdtpUkln, CnfgQtyPer, 
	CAST('' AS DateTime) AS Due_dts, CAST(0 AS Bit) AS Is_Selected, Note, PrjUnique, SLinkAdd, FOB, Shipvia, BillAcount,Deliv_Time, Attention, ShipCharge 
FROM Sodetail LEFT OUTER JOIN Inventor 
ON Sodetail.Uniq_key = Inventor.Uniq_key
WHERE Sodetail.Sono = @lcSono 
AND Balance > 0
AND (Sodetail.Status = 'Standard' 
OR Sodetail.Status = 'Priority-1'
OR Sodetail.Status = 'Priority-2')
ORDER BY Line_no
