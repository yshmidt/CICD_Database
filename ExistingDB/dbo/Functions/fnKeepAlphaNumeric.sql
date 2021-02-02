-- =============================================
-- Author:		David Sharp
-- Create date: 6/25/2013
-- Description:	strip all non alphanumeric characters
-- =============================================
CREATE FUNCTION dbo.fnKeepAlphaNumeric 
(
	-- Add the parameters for the function here
	@string varchar(MAX)
)
RETURNS varchar(MAX)
AS
BEGIN
	-- Declare the return variable here
	-- Add the T-SQL statements to compute the return value here
	Declare @KeepValues as varchar(50) = '%[^a-z0-9]%'
    While PatIndex(@KeepValues, @string) > 0
        Set @string = Stuff(@string, PatIndex(@KeepValues, @string), 1, '')
        
	-- Return the result of the function
	RETURN @string

END
