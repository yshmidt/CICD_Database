CREATE PROC [dbo].[InvtSer4SerialUniqView] @lcSerialUniq AS char(10) = ''
AS
SELECT *
	FROM InvtSer
	WHERE SerialUniq = @lcSerialUniq
	ORDER BY Serialno