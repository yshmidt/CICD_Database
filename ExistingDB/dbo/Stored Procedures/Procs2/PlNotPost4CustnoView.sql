CREATE PROC [dbo].[PlNotPost4CustnoView] @lcCustno AS char(10) = '', @lcPacklistno AS char(10) = ''
AS
BEGIN
IF @lcPacklistno = ''
	SELECT InvTotal
		FROM Plmain
		WHERE Print_Invo = 0
		AND Custno = @lcCustno
ELSE
	SELECT InvTotal
		FROM Plmain
		WHERE Custno = @lcCustno
		AND Print_Invo = 0	
		AND PACKLISTNO <> @lcPacklistno
END