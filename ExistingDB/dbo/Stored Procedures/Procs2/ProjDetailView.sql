CREATE PROC [dbo].[ProjDetailView] @lcPrjUnique  AS char(10) = ''
AS
BEGIN
SELECT Custname, P.PrjUnique, P.PrjNumber, P.Custno, P.PrjDescrp, P.PrjReferno, P.Prjgendt, P.PrjCompld, P.PrjParUniq,
	P.PrjStatus, P.PrjNote, PP.PrjNumber AS ParentPrjNumber
	FROM Customer, PJCTMAIN P LEFT OUTER JOIN PJCTMAIN PP
	ON P.PRJPARUNIQ = PP.PRJUNIQUE
	WHERE P.CUSTNO = Customer.Custno
	AND P.PRJUNIQUE = @lcPrjUnique
END




