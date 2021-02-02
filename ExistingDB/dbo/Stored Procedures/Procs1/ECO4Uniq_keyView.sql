CREATE PROC [dbo].[ECO4Uniq_keyView] @gUniq_key AS char(10) = ''
AS
SELECT UniqEcno,Econo, EcoRef, EffectiveDt
	FROM Ecmain
	WHERE EcStatus = 'Approved'
	AND (UpdatedDt = '' OR UpdatedDt IS NULL)
	AND ChangeType = 'ECO'
	AND Uniq_key = @gUniq_key
	ORDER BY Econo

