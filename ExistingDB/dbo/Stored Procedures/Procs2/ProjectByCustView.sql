CREATE PROC [dbo].[ProjectByCustView] @lcCustno  AS char(10) = ' '
AS
BEGIN
SELECT *
	FROM PJCTMAIN, Customer
	WHERE Pjctmain.CUSTNO = Customer.Custno
	AND Pjctmain.Custno = @lcCustno
	ORDER BY PrjNumber
END



