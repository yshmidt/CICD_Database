CREATE PROC [dbo].[ProjMainView] @lcCustNo  AS char(10) = '', @lcPrjStatus AS char(10) = ''
AS
BEGIN
SELECT Custname, P.PrjUnique, P.PrjNumber, P.Custno, P.PrjDescrp, P.PrjReferno, P.Prjgendt, P.PrjCompld, P.PrjParUniq,
	P.PrjStatus, P.PrjNote, PP.PrjNumber AS ParentPrjNumber
	FROM Customer, PJCTMAIN P LEFT OUTER JOIN PJCTMAIN PP
	ON P.PRJPARUNIQ = PP.PRJUNIQUE
	WHERE P.CUSTNO = Customer.Custno
	AND 1 = CASE WHEN @lcCustNo <> '' THEN CASE WHEN (P.Custno = @lcCustno) THEN 1 ELSE 0 END ELSE 1 END
	AND 1 = CASE WHEN @lcPrjStatus <> '' THEN CASE WHEN (P.PrjStatus = @lcPrjStatus) THEN 1 ELSe 0 END ELSE 1 END
END




