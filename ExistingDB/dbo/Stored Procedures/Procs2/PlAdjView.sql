CREATE PROC [dbo].[PlAdjView] @lcPacklistno AS char(10) = ''
AS
SELECT *
	FROM PlAdj
	WHERE Packlistno = @lcPacklistno