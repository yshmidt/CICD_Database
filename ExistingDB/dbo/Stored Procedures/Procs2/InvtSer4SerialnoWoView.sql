CREATE PROC [dbo].[InvtSer4SerialnoWoView] @lcSerialno AS char(30) = ''
AS
SELECT SERIALNO, SERIALUNIQ, ID_VALUE, Wono
	FROM InvtSer
	WHERE Serialno = @lcSerialno
	AND WONO <> ''
	AND ID_KEY = 'DEPTKEY'









