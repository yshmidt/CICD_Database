CREATE PROC [dbo].[EcSoView] @gUniqEcNo AS char(10) = ' '
AS
SELECT UniqecSono, Uniqecno, Ecso.Sono, Ecso.Uniqueln, Change, Balance, Line_no, Somain.Is_rma
	FROM EcSo, Somain
	WHERE Ecso.Sono = Somain.Sono
	AND Ecso.uniqecno = @gUniqecno
	ORDER BY Ecso.Sono




