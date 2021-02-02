CREATE PROC [dbo].[RMARAddRMAItemView] @lcSono AS char(10) = ''
AS
SELECT ISNULL(Inventor.Part_no,SPACE(25)) AS Part_no, ISNULL(Inventor.Revision, SPACE(8)) AS Revision, 
	ISNULL(Inventor.Part_class, SPACE(8)) AS Part_class, ISNULL(Inventor.Part_type, SPACE(8)) AS Part_type, 
	ISNULL(Inventor.Descript, Sodet_Desc) AS Descript, ISNULL(Inventor.Part_Sourc, SPACE(10)) AS Part_Sourc, 
	ISNULL(Inventor.U_of_meas, SPACE(4)) AS U_of_meas, ISNULL(Inventor.SerialYes, 0) AS SerialYes,
	Sodetail.Uniq_key, Uniqueln, Line_no, UofMeas, Balance AS Ord_qty, Shippedqty, -Balance AS Balance, 
	Sono, OriginUqln, Sodetail.Status, CAST(0 AS Bit) AS Is_Selected
FROM Sodetail LEFT OUTER JOIN Inventor 
ON Sodetail.Uniq_key = Inventor.Uniq_key
WHERE Sodetail.Sono = @lcSono 
AND Balance < 0
AND (Sodetail.Status = 'Standard' 
OR Sodetail.Status = 'Priority-1'
OR Sodetail.Status = 'Priority-2')
ORDER BY Line_no




