CREATE PROC [dbo].[DudtHistView] @lcSono AS char(10) = ''
AS
SELECT *
	FROM DUDTHIST
	WHERE Sono = @lcSono


