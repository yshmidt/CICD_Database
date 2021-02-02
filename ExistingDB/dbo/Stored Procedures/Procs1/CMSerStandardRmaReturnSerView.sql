
--- This view will get all available serial numbers that were shipped from '@lcOldPacklistno','@lcOldUniqueln' and excluded those already be
--- returned in Cmser table (@lcRmaRPacklistno and @lcRmaUniqueln from CM)

CREATE PROCEDURE [dbo].[CMSerStandardRmaReturnSerView]
	-- Add the parameters for the stored procedure here
@lcOldPacklistno as char(10) = ' ', @lcOldUniqueln as char(10) = ' ', @lcRmaRPacklistno as char(10) = ' ', @lcRmaUniqueln as char(10) = ' '

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT Serialno, Wono, SerialUniq
		FROM Packlser, Plmain
		WHERE Plmain.Packlistno = Packlser.Packlistno 
		AND Packlser.Packlistno = @lcOldPacklistno
		AND Packlser.Uniqueln = @lcOldUniqueln
		AND Serialno+SerialUniq NOT IN 
			(SELECT Serialno+SerialUniq 
				FROM CmSer
				WHERE Packlistno = @lcRmaRPacklistno
				AND Uniqueln = @lcRmaUniqueln)
		AND Serialno+SerialUniq IN 
			(SELECT Serialno+SerialUniq 
				FROM InvtSer 
				WHERE Id_Key = 'PACKLISTNO' 
				AND Id_Value = @lcOldPacklistno)
		ORDER BY 1
END