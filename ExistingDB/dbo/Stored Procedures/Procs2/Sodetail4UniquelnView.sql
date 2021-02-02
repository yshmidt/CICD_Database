CREATE PROC [dbo].[Sodetail4UniquelnView] @lcUniqueln AS char(10) = ''
AS
SELECT Sodetail.*, ISNULL(Part_no,SPACE(25)) AS Part_no, ISNULL(Revision,SPACE(8)) AS Revision, 
	ISNULL(Part_Class,SPACE(8)) AS Part_Class, ISNULL(Part_Type,SPACE(8)) AS Part_Type, 
	ISNULL(Descript,Sodet_Desc) AS Descript, ISNULL(U_of_meas,SPACE(4)) AS U_of_meas, 
	ISNULL(Custno, SPACE(10)) AS Custno, ISNULL(Part_Sourc, SPACE(10)) AS Part_Sourc,
	ISNULL(SerialYes,0) AS SerialYes, ISNULL(SaleTypeid, SPACE(10)) AS SaleTypeid, 
	ISNULL(Make_Buy,0) AS Make_Buy, ISNULL(MinOrd,0) AS MinOrd, ISNULL(OrdMult,0) AS OrdMult 
	FROM Sodetail LEFT OUTER JOIN Inventor 
	ON Sodetail.Uniq_key = Inventor.Uniq_key
	WHERE Uniqueln = @lcUniqueln



