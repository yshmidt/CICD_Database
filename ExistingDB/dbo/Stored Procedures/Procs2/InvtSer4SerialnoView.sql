CREATE PROC [dbo].[InvtSer4SerialnoView] @lcSerialno AS char(30) = ''
AS
SELECT *
	FROM InvtSer
	WHERE Serialno = @lcSerialno

