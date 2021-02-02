CREATE PROCEDURE [dbo].[QkViewOpenPOItemsView] @lcPonum char(15) = ' '
AS
BEGIN

SET NOCOUNT ON;

SELECT Itemno, CASE WHEN Poitems.UNIQ_KEY = '' THEN Poitems.PART_NO ELSE ISNULL(Inventor.PART_NO, 'DELETED INVENTORY        ') END AS Part_no,
	CASE WHEN Poitems.UNIQ_KEY = '' THEN Poitems.Revision ELSE ISNULL(Inventor.Revision, SPACE(8)) END AS Revision,
	CASE WHEN Poitems.UNIQ_KEY = '' THEN Poitems.Part_class ELSE ISNULL(Inventor.Part_class, SPACE(8)) END AS Part_class, 
	CASE WHEN Poitems.UNIQ_KEY = '' THEN Poitems.Part_type ELSE ISNULL(Inventor.Part_type, SPACE(8)) END AS Part_type, 
	CASE WHEN Poitems.UNIQ_KEY = '' THEN Poitems.Descript ELSE ISNULL(Inventor.Descript, SPACE(45)) END AS Descript, 
	Ord_qty, Ord_qty-Acpt_qty AS Balance 
FROM Poitems LEFT OUTER JOIN Inventor 
ON Poitems.Uniq_key = Inventor.Uniq_key 
WHERE Poitems.Ponum = @lcPonum
AND Ord_qty-Acpt_qty > 0 
AND Poitems.lCancel = 0
ORDER BY Itemno 

END