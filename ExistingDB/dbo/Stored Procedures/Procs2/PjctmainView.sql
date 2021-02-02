CREATE PROC [dbo].[PjctmainView] @lcPrjUnique AS char(10) = ''
AS
SELECT *
	FROM Pjctmain
	WHERE PrjUnique = @lcPrjUnique




