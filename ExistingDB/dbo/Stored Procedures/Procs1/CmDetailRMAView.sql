CREATE PROC [dbo].[CmDetailRMAView] @gcCmUnique AS char(10) = ''
AS
SELECT CMDetail.*, ISNULL(Sodetail.Uniq_key,SPACE(10)) AS Uniq_key, ISNULL(Part_no,SPACE(25)) AS Part_no, 
	ISNULL(Revision,SPACE(8)) AS Revision, ISNULL(Part_Class,SPACE(8)) AS Part_Class, 
	ISNULL(Part_Type,SPACE(8)) AS Part_Type, ISNULL(Descript,ISNULL(Sodet_Desc,CmDescr)) AS CmDescr,	
	ISNULL(U_of_meas,SPACE(4)) AS U_of_meas, ISNULL(Ord_Qty,0.00) AS Ord_Qty, 
	ISNULL(-Sodetail.Balance, 0.00) AS Balance, 
	ISNULL(Sodetail.Sono,SPACE(10)) AS Sono, ISNULL(Part_Sourc, SPACE(10)) AS Part_Sourc, 
	ISNULL(Inventor.SerialYes, 0) AS SerialYes, ISNULL(Sodetail.Line_no,Cmdetail.Uniqueln) AS Line_no, 
	ISNULL(Sodetail.STATUS, SPACE(10)) AS Status, ISNULL(Sodetail.OriginUqln, SPACE(10)) AS OriginUqln
	FROM Cmdetail
    LEFT OUTER JOIN Sodetail
	ON Cmdetail.Uniqueln = Sodetail.Uniqueln
    LEFT OUTER JOIN Inventor
	ON Sodetail.uniq_key = Inventor.uniq_key
	WHERE CmUnique = @gcCmUnique
	ORDER BY Line_no