CREATE PROC [dbo].[Deviation4Uniq_keyView] @gUniq_key AS char(10) = ''
AS
SELECT UniqEcno,Econo, EcoRef, ExpDate
	FROM Ecmain
	WHERE EcStatus = 'Approved'
	AND ChangeType = 'DEVIATION'
	AND (EffectiveDt =  GETDATE()
	OR EffectiveDt < GETDATE())
	AND (ExpDate<>'' 
	AND ExpDate IS NOT NULL
	AND (ExpDate > GETDATE()
	OR ExpDate = GETDATE()))
	AND Uniq_key = @gUniq_key