CREATE PROC [dbo].[Invt_res4PJNoSumView] @lcPrjUnique AS char(10) = ' '
AS
SELECT *
	FROM Invt_res
	WHERE FK_PrjUnique  = @lcPrjUnique