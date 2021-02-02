CREATE PROC [dbo].[SoPHisView] @lcSono AS char(10) = ''
AS
SELECT *
	FROM SoPHis
	WHERE Sono = @lcSono
