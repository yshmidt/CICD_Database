CREATE PROC [dbo].[PkallocView] @lcPacklistno AS char(10) = ''
AS
SELECT *
	FROM Pkalloc
	WHERE Packlistno = @lcPacklistno
