CREATE PROCEDURE [dbo].[Supplier4PartmfgrView] @lcPartMfgr char(8) = ' '
AS
BEGIN

SET NOCOUNT ON;

SELECT Supname, Status 
	FROM Supinfo, SupMfgr 
	WHERE Supinfo.UniqSupno = SupMfgr.UniqSupno 
	AND SupMfgr.Partmfgr = @lcPartMfgr 
	ORDER BY SupName
  
END