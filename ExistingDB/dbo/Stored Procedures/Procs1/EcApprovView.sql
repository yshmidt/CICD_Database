CREATE PROC [dbo].[EcApprovView] @gUniqEcNo AS char(10) = ' '
AS
SELECT Uniqappno, Uniqecno, Dept, Init, Date
	FROM Ecapprov
	WHERE Uniqecno = @gUniqecno






