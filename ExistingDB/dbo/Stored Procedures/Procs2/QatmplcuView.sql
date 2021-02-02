CREATE PROC [dbo].[QatmplcuView] @lcTemplUniq AS char(10) = ' '
AS
	SELECT Qatmplcu.*, Custname
		FROM Qatmplcu, Customer
		WHERE Qatmplcu.Custno = Customer.Custno 
		ANd TEMPLUNIQ = @lcTemplUniq
		ORDER BY CUSTNAME