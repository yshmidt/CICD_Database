CREATE PROC [dbo].[Invt_res4EcoDeleteItemView] @lcUniqEcno AS char(10) = ' '
AS
DECLARE @lcEcoUniq_key char(10)
SELECT @lcEcoUniq_key = Uniq_key FROM ECMAIN WHERE UNIQECNO = @lcUniqEcno

SELECT DISTINCT Part_no, Revision, Wono
	FROM Inventor, Invt_res
	WHERE Inventor.Uniq_key = Invt_res.Uniq_key 
	AND Wono IN
		(SELECT Wono
			FROM woentry 
			WHERE Uniq_key = @lcEcoUniq_key
			AND OpenClos <> 'Closed'
			AND OpenClos <> 'Cancel')
	AND Invt_res.Uniq_key IN
		(SELECT Uniq_key FROM Bom_det
			WHERE UniqBomno IN
				(SELECT UniqBomno 
					FROM EcDetl 
					WHERE DetStatus = 'Delete'
					AND UniqEcno = @lcUniqEcno) 
			AND BomParent = @lcEcoUniq_key)
	AND Invtres_no NOT IN
		(SELECT Refinvtres FROM Invt_res WHERE REFINVTRES <> '')
			












