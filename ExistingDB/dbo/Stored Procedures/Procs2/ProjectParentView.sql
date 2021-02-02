CREATE PROC [dbo].[ProjectParentView] @lcPrjUnique  AS char(10) = ' '
AS
BEGIN
SELECT Prjunique, Prjnumber, PrjDescrp, PrjReferNo, PrjParUniq, PrjStatus
	FROM Pjctmain
	WHERE PrjUnique = @lcPrjUnique
END





