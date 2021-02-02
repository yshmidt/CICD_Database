-- =============================================
-- Author:		Vicky Lu
-- Create date: 04/21/2011
-- Description:	Function to return Manufacturer Variance GL number from setup
-- =============================================
CREATE FUNCTION [dbo].[fn_GetMfgrGl] ()

RETURNS char(13)
AS
BEGIN

-- Declare the return variable here
DECLARE @lcReturn char(13);

SELECT @lcReturn = Manu_Gl_No FROM InvSetup;


-- Return the result of the function
RETURN @lcReturn

END





