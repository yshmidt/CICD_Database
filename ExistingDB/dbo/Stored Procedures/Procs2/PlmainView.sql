-- =============================================
-- Modification:
-- 01/25/21 VL added SaveInitDisp to use in desktop, found the saveinit is nvarchar(256) which display weird in desktop text field
-- =============================================

CREATE PROC [dbo].[PlmainView] @lcPacklistno AS char(10) = ''
AS
SELECT *, LEFT(SaveInit,15) AS SaveInitDisp
	FROM Plmain
	WHERE Packlistno = @lcPacklistno