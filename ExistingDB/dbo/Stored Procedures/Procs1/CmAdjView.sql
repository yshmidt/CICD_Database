CREATE PROC [dbo].[CmAdjView] @gcCmUnique AS char(10) = ''
AS
SELECT *
	FROM CmAdj
	WHERE CmUnique = @gcCmUnique



