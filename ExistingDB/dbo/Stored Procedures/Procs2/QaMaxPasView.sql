CREATE PROC [dbo].[QaMaxPasView] @lcWono char(10) = ' '
AS
BEGIN
-- 04/17/14 VL added parameter @lcWono

SELECT * 
	FROM QaMaxPas
	WHERE Wono = @lcWono

END








