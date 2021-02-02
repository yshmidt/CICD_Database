
CREATE PROC [dbo].[SupMfgrView] (@lcUniqSupno char(10) ='')
AS
SELECT Unqsupmfgr, UniqSupno, Partmfgr, LEFT(Text,30) AS MfgrDescript
FROM Supmfgr, Support
WHERE Partmfgr = LEFT(Support.Text2,8)
AND Fieldname ='PARTMFGR'
AND UniqSupno = @lcUniqSupno
ORDER BY Partmfgr

