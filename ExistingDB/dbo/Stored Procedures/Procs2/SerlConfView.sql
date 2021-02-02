CREATE PROC [dbo].[SerlConfView] @lcSerialUniq AS char(10) ='' 
AS
SELECT Wono, serialno, Serlconf.uniq_key, Trackno, Comment,
	CASE WHEN SERLCONF.UNIQ_KEY<>'' THEN INVENTOR.PART_NO ELSE SERLCONF.PART_NO END AS DispPart_no,
	CASE WHEN SERLCONF.UNIQ_KEY<>'' THEN INVENTOR.Revision ELSE SERLCONF.Revision END AS DispRevision,
	Serlconf.Part_no, Serlconf.Revision, Serlconf.Uniqconfig, SerialUniq
	FROM Serlconf LEFT OUTER JOIN Inventor 
	ON Serlconf.Uniq_key = Inventor.Uniq_key
	WHERE Serlconf.SerialUniq = @lcSerialUniq