-- =============================================
-- Author:		Vicky
-- Create date: 06/28/2010
-- Description:	Function to return if the wono has shortage, used in shop floor transfer to FGI
-- =============================================
CREATE FUNCTION [dbo].[fn_IsWoShort] 
(
	-- Add the parameters for the function here
	@gWono char(10)
)
RETURNS char(13)
AS
BEGIN

-- Declare the return variable here
DECLARE @lReturn bit, @cWono char(10);

SELECT @cWono = Wono
	FROM Kamain
	WHERE Wono = @gWono
	AND ShortQty > 0
	AND IgnoreKit = 0

BEGIN
IF @@ROWCOUNT > 0
	SET @lReturn = 1;
ELSE
	SET @lReturn = 0;
END


-- Return the result of the function
RETURN @lReturn

END