CREATE PROC [dbo].[PacklserView] @lcPacklistno AS char(10) = ''
AS
SELECT *
	FROM Packlser
	WHERE Packlistno = @lcPacklistno