
CREATE FUNCTION [dbo].[fn_IsRefDesDuplicated4oneBomItem] 
(
	-- Add the parameters for the function here
	@gUniq_key char(10), @lcUniqBomno char(10), @lcRef_desStr char(15)
)
RETURNS bit
AS
BEGIN

-- Declare the return variable here
DECLARE @lReturn bit, @lcRef_des char(15);
WITH Bom_det4OneBom AS
( 
SELECT UniqBomNo,Item_no
	FROM Bom_det
	WHERE Bomparent = @gUniq_key
	AND UniqBomNo <> @lcUniqBomno
	AND (Eff_dt<=GETDATE() OR Eff_dt IS NULL) 
	AND (Term_dt>GETDATE() OR Term_dt IS NULL)
)
SELECT @lcRef_des = Ref_des
	FROM Bom_ref,Bom_det4OneBom
	WHERE Bom_ref.UniqBomNo = Bom_det4OneBom.UniqBomNo
	AND UPPER(Ref_des)=UPPER(@lcRef_desStr)
	
BEGIN		
IF @@ROWCOUNT > 0
	SET @lReturn = 1;
ELSE
	SET @lReturn = 0;
END


-- Return the result of the function
RETURN @lReturn

END





