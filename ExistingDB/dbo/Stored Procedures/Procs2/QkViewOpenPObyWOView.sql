CREATE PROCEDURE [dbo].[QkViewOpenPObyWOView] @lcWono char(10) = ' '
AS
BEGIN

SET NOCOUNT ON;

SELECT ISNULL(Inventor.PART_NO, Poitems.PART_NO) AS Part_no, ISNULL(Inventor.Revision, Poitems.Revision) AS Revision,
	ISNULL(Inventor.Part_class, SPACE(8)) AS Part_Class, ISNULL(Inventor.Part_type, SPACE(8)) AS Part_type,
	ISNULL(Inventor.Descript, SPACE(45)) AS Descript, Poitems.Ponum, SUM(Schd_qty) AS Schd_qty, SUM(Balance) AS Balance, Poitems.Uniqlnno 
FROM Pomain, Poitschd, Poitems LEFT OUTER JOIN Inventor 
ON Inventor.Uniq_key = Poitems.Uniq_key 
WHERE Poitschd.Uniqlnno = Poitems.Uniqlnno 
AND Pomain.Ponum = Poitems.Ponum 
AND Poitschd.woprjnumber = @lcWono
AND Poitschd.RequestTp='WO Alloc  '
AND Poitems.lCancel = 0
GROUP BY Poitems.Uniqlnno,ISNULL(Inventor.PART_NO, Poitems.PART_NO),ISNULL(Inventor.Revision, Poitems.Revision),
	ISNULL(Inventor.Part_class, SPACE(8)),ISNULL(Inventor.Part_type, SPACE(8)), ISNULL(Inventor.Descript, SPACE(45)), Poitems.Ponum
ORDER BY 1 
   
END