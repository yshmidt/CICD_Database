CREATE PROC [dbo].[ECOPendingView] @gUniq_key AS char(10) = ''
AS
SELECT UniqEcno, ECOno
	FROM Ecmain
	WHERE Uniq_key = @gUniq_key
	AND ChangeType = 'ECO'
	AND (UpdatedDt=''
	OR UpdatedDt IS NULL )
	AND EcStatus <> 'Approved'
	AND EcStatus <> 'Completed'
	AND EcStatus <> 'Cancelled'