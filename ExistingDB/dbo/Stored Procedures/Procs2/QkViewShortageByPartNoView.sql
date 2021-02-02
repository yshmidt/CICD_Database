CREATE PROCEDURE [dbo].[QkViewShortageByPartNoView] @lcUniq_key char(10) = ' '
AS
BEGIN

SET NOCOUNT ON;

SELECT Wono, ISNULL(Dept_name, dbo.PADR('No WC',25,' ')) AS Dept_Name, Qty, ShortQty, 
		CEILING(ShortQty/CASE WHEN Qty > 0 THEN Qty ELSE 1 END) AS UnitAffect, Uniq_key
	FROM Kamain LEFT OUTER JOIN Depts 
	ON Kamain.Dept_id = Depts.Dept_id 
	WHERE Kamain.uniq_key = @lcUniq_key
	AND ShortQty > 0 
	AND IgnoreKit = 0
	AND Wono NOT IN 
		(SELECT Wono 
			FROM Woentry 
			WHERE Openclos = 'Cancel' 
			OR OpenClos = 'Closed' 
			OR Balance = 0 
			OR Kit = 0) 
	ORDER BY 1 

END