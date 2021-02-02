CREATE PROC [dbo].[QainspView] @lcQaseqmain AS char(10) = ''
AS
SELECT *
	FROM QAINSP
	WHERE QASEQMAIN = @lcQaseqmain





