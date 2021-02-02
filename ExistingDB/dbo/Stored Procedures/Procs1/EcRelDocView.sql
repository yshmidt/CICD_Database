CREATE PROC [dbo].[EcRelDocView] @gUniqEcNo AS char(10) = ' '
AS
SELECT Doc_uniq, Uniqecno, Uniq_key, Docno, Docrevno, Docdescr, Docdate, Docnote, Docexec, Docpdf
	FROM Ecreldoc
	WHERE Ecreldoc.Uniqecno = @gUniqecno
	ORDER BY Docno





