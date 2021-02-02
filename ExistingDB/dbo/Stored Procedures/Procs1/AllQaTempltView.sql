CREATE PROC [dbo].[AllQaTempltView]
AS
	SELECT * 
		FROM QaTemplt
		ORDER BY Templdescr
