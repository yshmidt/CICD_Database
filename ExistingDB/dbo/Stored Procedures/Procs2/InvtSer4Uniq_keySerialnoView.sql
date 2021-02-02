CREATE PROC [dbo].[InvtSer4Uniq_keySerialnoView] @gUniq_key AS char(10) = '', @lcSerialno AS char(10) = ''
AS
SELECT *
	FROM InvtSer
	WHERE Uniq_key = @gUniq_key 
	AND Serialno = @lcSerialno
