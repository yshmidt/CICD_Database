
CREATE PROC [dbo].[OutSvsSupView] @gUniq_key AS char(10) = ''
AS
SELECT OutSvs.*, SupInfo.SupName
	FROM OutSvs, SupInfo
	WHERE OutSvs.Supid = SupInfo.Supid
	AND OutSvs.Uniq_key = @gUniq_key
	ORDER BY PreferNo