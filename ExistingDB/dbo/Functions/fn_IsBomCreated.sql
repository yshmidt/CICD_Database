
CREATE FUNCTION [dbo].[fn_IsBomCreated] 
(
	-- Add the parameters for the function here
	@gUniq_key char(10)
)
RETURNS bit
AS
BEGIN

-- Declare the return variable here
DECLARE @lReturn bit, @lcUniq_key char(10)

SELECT @lcUniq_key = Uniq_key
	FROM Bom_det
	WHERE Bomparent = @gUniq_key

BEGIN
IF @@ROWCOUNT > 0
	SET @lReturn = 1;
ELSE
	SET @lReturn = 0;
END


-- Return the result of the function
RETURN @lReturn

END





