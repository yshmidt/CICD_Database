-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <11/30/2012>
-- Description:	Convert price from/to puom/suom
-- =============================================
CREATE FUNCTION dbo.fn_convertPrice
(
	-- Add the parameters for the function here
	@cFrom char(3),@Price numeric(13,5), @PUOM char(4),@SUOM char(4)
	--@cFrom ='Stk'  - if converting from Stock UOM, 'Pur' if converting from purchase uom
)
RETURNS numeric(13,5)
AS
BEGIN
	-- Declare the return variable here
	declare @ReturnPrice numeric(13,5)
	if @PUOM =@SUOM 
		SET @ReturnPrice=@Price
	else
	BEGIN
		select @ReturnPrice=
			CASE WHEN (Unit.[TO]=@SUOM and @cFrom='Stk') OR ( @cFrom='Pur' and Unit.[From] = @SUOM) THEN round(@Price*Unit.FORMULA,5)  
			ELSE round(@Price/Unit.FORMULA,5)  END 
				FROM unit 
				where  (Unit.[FROM] = @SUOM AND Unit.[TO] = @PUOM)
				OR (Unit.[TO] = @SUOM AND Unit.[From] = @PUOM) 
			
	END	
	-- Return the result of the function
	RETURN @ReturnPrice

END
