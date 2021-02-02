-- =============================================
-- Author:		Debbie
-- Create date: 08/01/2016
-- Description:	Function to get the Packing List Signature path if loaded. 
-- Modified:
-- =============================================
create FUNCTION [dbo].[fn_packListSignaturePath] ()
RETURNS varchar(max)
AS
BEGIN

-- Declare the return variable here
DECLARE @lcReturn varchar(max)

SELECT @lcReturn = ISNULL(wm.settingValue,mnx.settingValue)
	FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
	ON mnx.settingId = wm.settingId 
	WHERE mnx.settingName='packListSignaturePath'

-- Return the result of the function
RETURN @lcReturn

END