CREATE PROC [dbo].[InvtSer4WonoSerialnoView] @gWono AS char(10) = '', @lcSerialno as char(30)
AS
SELECT *
	FROM InvtSer
	WHERE Wono = @gWono
	AND Serialno = @lcSerialno
	ORDER BY Serialno