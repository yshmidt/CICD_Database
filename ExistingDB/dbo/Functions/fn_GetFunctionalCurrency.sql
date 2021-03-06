﻿-- =============================================
-- Author:		Vicky Lu
-- Create date: 09/26/2016
-- Description:	Function to get functional currency (fcused_uniq)
-- Modification:
-- 09/26/16 VL Remove fn_GetHomeCurrency and created fn_Get
-- 01/25/17 VL changed to return '' if FC not installed
-- =============================================
CREATE FUNCTION [dbo].[fn_GetFunctionalCurrency] ()
RETURNS char(10)
AS
BEGIN

-- Declare the return variable here
DECLARE @lcReturn char(10)


SELECT TOP 1 @lcReturn = Fcused_uniq 
	FROM Iso_4217 WHERE Entity = (SELECT ISNULL(wm.settingValue,mnx.settingValue)
	FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
	ON mnx.settingId = wm.settingId 
	WHERE mnx.settingName='functionalCurrency')
	ORDER BY Currency

-- Return the result of the function
-- 01/25/17 VL changed to return '' if FC not installed
SET @lcReturn = CASE WHEN dbo.fn_IsFCInstalled() = 1 THEN @lcReturn ELSE '' END
RETURN @lcReturn


END