
CREATE PROC [dbo].[Pjctmain4CustomerView] @lcCustno AS char(10) = ''
AS
 SELECT PrjNumber, PrjUnique
	FROM Pjctmain
	WHERE Custno = @lcCustno
	AND UPPER(PrjStatus) = 'OPEN'
	ORDER BY PrjNumber
