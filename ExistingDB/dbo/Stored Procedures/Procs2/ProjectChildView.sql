CREATE PROC [dbo].[ProjectChildView] @lcPrjUnique  AS char(10) = ' '
AS
BEGIN
SELECT Prjunique, Prjnumber, PrjDescrp, PrjReferNo, PrjParUniq, PrjStatus
	FROM Pjctmain
	WHERE 1 = CASE WHEN @lcPrjUnique = '' THEN 2 ELSE CASE WHEN PRJPARUNIQ = @lcPrjUnique THEN 1 ELSE 2 END END 
END




