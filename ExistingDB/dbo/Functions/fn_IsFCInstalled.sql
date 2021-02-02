-- =============================================
-- Author:		Vicky Lu
-- Create date: 04/08/2016
-- Description:	Function to check if user has FC module or not
-- =============================================
CREATE FUNCTION [dbo].[fn_IsFCInstalled] ()
RETURNS bit
AS
BEGIN

-- Declare the return variable here
DECLARE @lcReturn bit

SELECT @lcReturn = ISNULL(wm.settingValue,mnx.settingValue)
	FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
	ON mnx.settingId = wm.settingId 
	WHERE mnx.settingName='ForeignCurrency'

-- Return the result of the function
RETURN @lcReturn

END