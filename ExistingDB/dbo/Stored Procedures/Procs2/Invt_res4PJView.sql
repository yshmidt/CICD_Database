CREATE PROC [dbo].[Invt_res4PJView] @lcPrjUnique AS char(10) = ''
AS
SELECT W_key, Uniq_key, ISNULL(SUM(Qtyalloc),0) AS Qtyalloc, Lotcode, Expdate, Reference, Ponum, Fk_prjunique
	FROM Invt_res
	WHERE Fk_prjunique = @lcPrjUnique
	AND Invt_res.wono = SPACE(10)
	GROUP BY Uniq_key, W_key, Lotcode, Expdate, Reference, Ponum, Fk_prjunique
	ORDER BY Uniq_key, W_key, Lotcode, Expdate, Reference, Ponum




