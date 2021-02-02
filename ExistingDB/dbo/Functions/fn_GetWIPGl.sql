-- =============================================
-- Author:		Vicky Lu
-- Create date: 04/21/2011
-- Description:	Function to return WIP GL number
-- =============================================
CREATE FUNCTION [dbo].[fn_GetWIPGl] ()
RETURNS char(13)
AS
BEGIN

-- Declare the return variable here
DECLARE @lcReturn char(13), @lIsGLInstalled bit;

SELECT @lIsGLInstalled = Installed FROM Items WHERE ScreenName = 'GLREL   '

-- GL is instal
IF @lIsGLInstalled = 1
	SELECT @lcReturn = Wh_gl_nbr FROM Warehous WHERE Warehouse = 'WIP   '
ELSE
	SET @lcReturn = SPACE(13)

-- Return the result of the function
RETURN @lcReturn

END




