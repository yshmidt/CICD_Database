CREATE PROC [dbo].[Allocted4PJ4WonoView] @gWono AS char(10) = ' '
AS

WITH ZWo AS
(
SELECT Wono, PrjUnique 
	FROM WOENTRY
	WHERE WONO = @gWono
)

SELECT Invt_res.*, UniqMfgrhd, Instore, UniqSupno 
	FROM Invt_res, Invtmfgr, ZWo
	WHERE Invt_res.W_key = Invtmfgr.W_key 
	AND Invt_res.Fk_Prjunique = ZWo.PrjUnique 
	AND ZWo.PrjUnique <> ''
	AND Invtres_no NOT IN 
		(SELECT RefInvtRes
			FROM Invt_res 
			WHERE Fk_Prjunique = ZWo.PrjUnique) 
	AND Invtmfgr.Location = 'WO'+@gWono
	AND QtyAlloc > 0
	ORDER BY Fk_PrjUnique,Invt_res.w_key




