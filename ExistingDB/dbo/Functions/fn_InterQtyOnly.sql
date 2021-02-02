-- =============================================
-- Author:		Vicky Lu	
-- Create date: <04/11/2012>
-- Description:	Calculates Quantity on hand for internal records, excludes In-Store, convert from VFP stored procedure InterQtyOnly
-- =============================================
CREATE FUNCTION [dbo].[fn_InterQtyOnly]
(
	-- Add the parameters for the function here
	@lcUniq_key char(10) = ' '
)
RETURNS numeric(12,2)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @lnReturn numeric(12,2)
	SET @lnReturn = 000000000.00
		
	SELECT @lnReturn = ISNULL(SUM(Qty_Oh),000000000.00)
		FROM InvtMfgr 
		WHERE Uniq_Key = @lcUniq_key
		AND Instore = 0
	
	-- Return the result of the function
	RETURN @lnReturn

END




