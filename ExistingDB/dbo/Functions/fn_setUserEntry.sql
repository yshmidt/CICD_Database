-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/06/11
-- Description:	
-- =============================================
CREATE FUNCTION dbo.fn_setUserEntry
(
	-- Add the parameters for the function here
	@pcUserEntry varchar(10)
)
RETURNS varbinary(64)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result varbinary(64)

	-- Add the T-SQL statements to compute the return value here
	SELECT @Result = HashBytes('MD5',LTRIM(RTRIM(@pcUserEntry)))

	-- Return the result of the function
	RETURN @Result

END
