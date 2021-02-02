CREATE PROC [dbo].[WoAllocatedView] @gWono AS char(10) = ''
AS
SELECT W_key, Uniq_key, Lotcode, Expdate, ISNULL(SUM(Qtyalloc),0) AS qtyalloc,Reference, Ponum
	FROM
	Invt_res
	WHERE wono = @gWono
	GROUP BY Uniq_key, W_key, Lotcode, Expdate, Reference, Ponum
	ORDER BY Uniq_key, W_key, Lotcode, Expdate, Reference, Ponum