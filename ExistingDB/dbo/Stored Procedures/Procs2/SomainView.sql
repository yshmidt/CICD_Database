CREATE PROC [dbo].[SomainView] @lcSono AS char(10) = ''
AS
SELECT *
	FROM Somain
	WHERE Sono = @lcSono
