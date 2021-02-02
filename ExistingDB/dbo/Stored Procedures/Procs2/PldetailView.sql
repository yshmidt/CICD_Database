
-- 04/11/13 VL added PrjUnique field

CREATE PROC [dbo].[PldetailView] @lcPacklistno AS char(10) = ''
AS
SELECT Pldetail.*, ISNULL(Sodetail.Uniq_key,SPACE(10)) AS Uniq_key, ISNULL(Part_no,SPACE(25)) AS Part_no, 
	ISNULL(Revision,SPACE(8)) AS Revision, ISNULL(Part_Class,SPACE(8)) AS Part_Class, 
	ISNULL(Part_Type,SPACE(8)) AS Part_Type, ISNULL(Descript,ISNULL(Sodet_Desc,cDescr)) AS Descript,	
	ISNULL(U_of_meas,SPACE(4)) AS U_of_meas, ISNULL(Ord_Qty,0.00) AS Ord_Qty, ISNULL(Balance, 0.00) AS Balance, 
	ISNULL(Sodetail.Sono,SPACE(10)) AS Sono, ISNULL(Part_Sourc, SPACE(10)) AS Part_Sourc, 
	ISNULL(Inventor.SerialYes, 0) AS SerialYes, ISNULL(Sodetail.Prodtpuniq, SPACE(10)) AS Prodtpuniq, 
	ISNULL(Sodetail.ProdtpUkln, SPACE(10)) AS ProdtpUkln, ISNULL(Sodetail.CnfgQtyPer, 0) AS CnfgQtyPer,
	ISNULL(Inventor.Cert_Req, 0) AS Cert_Req, ISNULL(Inventor.Cert_Type, SPACE(10)) AS Cert_Type,
	ISNULL(Sodetail.Line_no,Pldetail.Uniqueln) AS Line_no, 
	IsFromso = CAST(CASE WHEN Sodetail.Uniqueln IS NULL THEN 0 ELSE 1 END AS Bit), 
	PLDETAIL.SHIPPEDQTY AS OldShippedQty,
	ISNULL(Sodetail.PrjUnique, SPACE(10)) AS PrjUnique
	FROM Pldetail
    LEFT OUTER JOIN Sodetail
	ON Pldetail.Uniqueln = Sodetail.Uniqueln
    LEFT OUTER JOIN Inventor
	ON Sodetail.uniq_key = Inventor.uniq_key
	WHERE Packlistno = @lcPacklistno
	ORDER BY ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(pldetail.uniqueln,2,6)),6,'0'))
--	ORDER BY Line_no