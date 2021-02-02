CREATE PROC [dbo].[FcStdCostERHistView] 
AS
SELECT *
	FROM FcStdCostERHist
	ORDER BY StdCostERUpdateDate DESC