-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <08/05/2013>
-- Description:	<Convert qty from stock to Purchase UOM>
-- =============================================
CREATE FUNCTION [dbo].[fn_ConverQtyPUOM]
(
	-- Add the parameters for the function here
	@pcPUOM char(4)=' ', -- purchase UOM
	@pcSUOM char(4)=' ', -- stock UOM
	@pnQty numeric(12,2) =0.00  -- Qty to convert
)
RETURNS numeric(12,2)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar numeric(12,2)
	SET @ResultVar=@pnQty

	-- Add the T-SQL statements to compute the return value here
	SELECT @ResultVar=CASE WHEN [FROM]=@pcSUOM THEN ROUND(@pnQty*Formula,2) 
					ELSE ROUND(@pnQty/Formula,2) END 
		FROM UNIT WHERE ([FROM]=@pcPUOM AND [TO]=@pcSUOM ) OR ([FROM]=@pcSUOM AND [TO]=@pcPUOM)
	
	
	-- Return the result of the function
	RETURN ISNULL(@ResultVar,@pnQty)

END
