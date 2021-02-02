-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/29/2013
-- Description:	Remove patern from the string
-- =============================================
CREATE FUNCTION dbo.fnRemovePatern 
(
	-- Add the parameters for the function here
	@string varchar(max),@patern varchar(max)
)
RETURNS varchar(max)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Result varchar(max)

	-- Add the T-SQL statements to compute the return value here
	SELECT @Result = @string
	-- exmple @patern to remove any none numeric values
	--@patern = '%[^0-9]%'
    While PatIndex(@patern, @Result) > 0
      SET @Result = Stuff(@Result, PatIndex(@patern, @Result ), 1, '')

	-- Return the result of the function
	RETURN @Result

END
