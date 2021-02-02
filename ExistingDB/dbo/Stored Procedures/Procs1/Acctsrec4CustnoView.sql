CREATE PROC [dbo].[Acctsrec4CustnoView] @lcCustno AS char(10) = ''
AS
SELECT ACCTSREC.*, InvTotal - ArCredits AS Balance
	FROM 
	Acctsrec
	WHERE Custno = @lcCustno