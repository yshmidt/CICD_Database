CREATE PROC [dbo].[SerlNpfView] @lcWono char(10) = ' '
AS
BEGIN
-- 04/17/14 VL added parameter @lcWono

SELECT * 
	FROM SerlNpf
	WHERE Wono = @lcWono

END






