CREATE PROC [dbo].[CmWoentryView] @gcCmUnique AS char(10) = ''
AS
SELECT *
	FROM Woentry 
	WHERE Woentry.Cmpricelnk IN 
		(SELECT Cmpricelnk
			FROM CMDETAIL 
			WHERE CmUnique = @gcCmUnique)



