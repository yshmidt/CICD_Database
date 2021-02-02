-- =============================================  
-- Author: Shivshankar Patil   
-- Create date: 07/17/19
-- Description: Fetch the setting 
-- =============================================  
CREATE FUNCTION fn_GetMnxModuleSetting 
(
@settingModuleName VARCHAR(100),
@moduleId INT =NULL
)
RETURNS VARCHAR(100)
AS
BEGIN
      DECLARE @settingValue VARCHAR(100)
      SELECT @settingValue = ISNULL(WS.SETTINGVALUE ,S.SETTINGVALUE)  FROM MNXSETTINGSMANAGEMENT S
							LEFT JOIN WMSETTINGSMANAGEMENT WS ON WS.SETTINGID =S.SETTINGID
							WHERE SETTINGNAME = @settingModuleName AND ((@moduleId IS NULL AND 1=1) 
							       OR (@moduleId IS NOT NULL AND  MODULEID = @moduleId))
    
	  RETURN @settingValue
END

