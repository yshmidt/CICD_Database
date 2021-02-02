CREATE PROC [dbo].[AssyChkView] @gUniq_key AS char(10) = ''
AS
SELECT *
	FROM AssyChk
	WHERE Uniq_key = @gUniq_key