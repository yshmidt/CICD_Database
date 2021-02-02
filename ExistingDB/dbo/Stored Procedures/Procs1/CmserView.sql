CREATE PROC [dbo].[CmserView] @gcCmUnique AS char(10) = ''
AS
SELECT *
	FROM Cmser
	WHERE CmUnique = @gcCmUnique
	ORDER BY Serialno





