
CREATE PROCEDURE [dbo].[UDFTableView] @lcTablename AS varchar(20) = ' '
AS
BEGIN
SELECT name 
	FROM sys.objects
	WHERE type='U' 
	AND name = 'udf'+LTRIM(RTRIM(@lcTablename))

END
