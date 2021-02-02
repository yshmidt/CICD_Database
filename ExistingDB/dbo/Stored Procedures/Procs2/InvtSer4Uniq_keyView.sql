CREATE PROC [dbo].[InvtSer4Uniq_keyView] @gUniq_key AS char(10) = ''
AS
SELECT *
	FROM InvtSer
	WHERE UNIQ_KEY = @gUniq_key
	ORDER BY Serialno