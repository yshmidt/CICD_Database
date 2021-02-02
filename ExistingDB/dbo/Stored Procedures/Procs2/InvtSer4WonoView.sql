CREATE PROC [dbo].[InvtSer4WonoView] @gWono AS char(10) = ''
-- 10/30/15 VL added Wono<>'' criteria, so it won't bring all the BUY part serial number even @gWono=''
AS
SELECT *
	FROM InvtSer
	WHERE Wono = @gWono
	AND Wono<>' '
	ORDER BY Serialno