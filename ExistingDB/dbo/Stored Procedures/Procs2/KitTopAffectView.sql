CREATE PROC [dbo].[KitTopAffectView] @gWono AS char(10) = ''
AS
SELECT TOP 1 ShortQty,Qty, Affected = 
	CASE Qty
		WHEN 0 THEN  CEILING(ShortQty)
		ELSE CEILING(ShortQty/Qty)
	END
FROM Kamain	
WHERE Wono = @gWono
AND ShortQty > 0
AND IgnoreKit = 0
ORDER BY Affected DESC