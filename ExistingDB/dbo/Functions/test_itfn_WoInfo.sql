-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION dbo.test_itfn_WoInfo 
(	
	@cWono char(10)=' '
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT Wono, BldQty from Woentry WHERE Wono = @cWono
);