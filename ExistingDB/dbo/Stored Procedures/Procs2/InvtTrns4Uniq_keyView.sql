
CREATE PROC [dbo].[InvtTrns4Uniq_keyView] (@gUniq_key char(10) ='')
AS
SELECT InvtTrns.*, 1.0 AS nSavePriority
	FROM InvtTrns
	WHERE Uniq_key = @gUniq_key
	ORDER BY Date


