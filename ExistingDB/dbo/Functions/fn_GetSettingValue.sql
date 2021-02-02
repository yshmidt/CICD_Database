-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/25/2019
-- Description:	get settings value for a given setting name
-- =============================================
CREATE FUNCTION [dbo].[fn_GetSettingValue] (@settingName varchar(100))
RETURNS varchar(200)
AS
BEGIN

-- Declare the return variable here
DECLARE @lcReturn varchar(200)=null


SELECT @lcReturn = ISNULL(wm.settingValue,mnx.settingValue)
	FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
	ON mnx.settingId = wm.settingId 
	WHERE mnx.settingName=@settingName



-- Return the result of the function

RETURN @lcReturn


END