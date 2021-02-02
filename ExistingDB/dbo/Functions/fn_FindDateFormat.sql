-- =============================================
-- Author:		Debbie
-- Create date: 05/02/2016
-- Description:	Function to which Date Format the user has set
-- =============================================
create FUNCTION [dbo].[fn_FindDateFormat] ()
RETURNS varchar(max)
AS
BEGIN

-- Declare the return variable here
DECLARE @lcReturn varchar(max)

SELECT @lcReturn = ISNULL(wm.settingValue,mnx.settingValue)
	FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
	ON mnx.settingId = wm.settingId 
	WHERE mnx.settingName='dateFormat'

-- Return the result of the function
RETURN @lcReturn

END