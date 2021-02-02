CREATE PROCEDURE [dbo].[QkViewShortageByWOView] @lcWono AS char(10) = ' '
AS
BEGIN

SET NOCOUNT ON;

SELECT ' ' AS Is_Misc, Dept_id, CASE WHEN Part_sourc = 'CONSG' THEN CustPartno ELSE Part_no END AS Part_no,
	CASE WHEN Part_Sourc = 'CONSG' THEN CustRev ELSE Revision END AS Revision, Qty AS UnitQty, ShortQty, 
	CEILING(ShortQty/CASE WHEN Qty>0 THEN Qty ELSE 1 END) AS UnitAffect, Part_Sourc 
	FROM Inventor, Kamain 
	WHERE Inventor.Uniq_key = Kamain.Uniq_key 
	AND Kamain.Wono = @lcWono
	AND ShortQty > 0 
	AND IgnoreKit = 0
UNION ALL 
	(SELECT 'M' AS Is_Misc, Dept_id, Part_no, Revision, Qty As UnitQty, ShortQty, 
	CEILING(ShortQty/CASE WHEN Qty>0 THEN Qty ELSE 1 END) AS UnitAffect, Part_Sourc 
	FROM MiscMain 
	WHERE Miscmain.Wono = @lcWono
	AND ShortQty > 0) 
	ORDER BY 3,4
END