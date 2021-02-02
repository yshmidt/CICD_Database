CREATE PROC [dbo].[View_Wo] @gWono AS char(10) = ''
AS
SELECT BldQty-0 AS BldQty2, SPACE(8) AS Part_class, SPACE(8) AS Part_type, SPACE(25) AS Part_no,
		SPACE(8) AS Revision, SPACE(10) AS Prod_id, SPACE(45) AS Descript, SPACE(35) AS CustName,
		Woentry.*
	FROM Woentry
	WHERE Wono = @gWono
