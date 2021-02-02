-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/18/2010
-- Description:	<Get GL Post Rules for given Type. This procedure is duplicated in accountingutilities (vfp class.> 
--- when checking rules in VFP use utility, when checking rules inside stored procedure use this function.
-- =============================================
CREATE FUNCTION dbo.GetGlPostRules4PostType
(
	-- Add the parameters for the function here
	@pcGlType char(10)=null
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE  @pnPostType int
	SET @pnPostType=0

	-- Add the T-SQL statements to compute the return value here
	SELECT @pnPostType=DirectPost 
		FROM GlPostDef
	WHERE PostType=@pcGlType

	-- Return the result of the function
	RETURN @pnPostType

END
