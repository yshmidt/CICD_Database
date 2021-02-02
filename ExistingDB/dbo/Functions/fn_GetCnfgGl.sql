-- =============================================
-- Author:		Vicky
-- Create date: 06/16/2010
-- Description:	Function to return configuration GL numbers
-- =============================================
CREATE FUNCTION [dbo].[fn_GetCnfgGl] 
(
	-- Add the parameters for the function here
	@lcType char(5)
)
RETURNS char(13)
AS
BEGIN

-- Declare the return variable here
DECLARE @lcReturn char(13);

IF @lcType = ''
BEGIN
	SET @lcType = 'CONFG';
END

IF @lcType = 'CONFG'

	SELECT @lcReturn = Conf_Gl_No FROM InvSetup;
ELSE
	IF @lcType = 'LABOR'
		SELECT @lcReturn = Lab_v_gl FROM InvSetup;
	ELSE
		IF @lcType = 'OVRHD'
			SELECT @lcReturn = Over_v_gl FROM InvSetup;
		ELSE
			IF @lcType = 'OTHER'
				SELECT @lcReturn = Oth_v_gl FROM InvSetup;
			ELSE
				IF @lcType = 'USRDF'
					SELECT @lcReturn = UserDef_gl FROM InvSetup;
				ELSe
					IF @lcType = 'RVAR'
						SELECT @lcReturn = RundVar_gl FROM InvSetup;


-- Return the result of the function
RETURN @lcReturn

END