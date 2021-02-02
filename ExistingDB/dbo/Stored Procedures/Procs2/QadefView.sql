CREATE PROC [dbo].[QadefView] @lcQaseqmain AS char(10) = ''
AS
SELECT * 
	FROM Qadef
	WHERE QASEQMAIN = @lcQaseqmain 
	ORDER BY Serialno





