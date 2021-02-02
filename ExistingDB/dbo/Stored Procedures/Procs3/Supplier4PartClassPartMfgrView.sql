CREATE PROC [dbo].[Supplier4PartClassPartMfgrView] @lcPart_class AS char(8) = '', @lcPartMfgr AS char(8) = ''
AS
SELECT Supname, Supinfo.SUPID, Supinfo.UniqSupNo
	FROM Supinfo, SupClass, SupMfgr
	WHERE Supinfo.UniqSupno = SupClass.UniqSupno
	AND SupClass.UniqSupno = SupMfgr.UniqSupno 
	AND SupClass.Part_Class =@lcPart_class
	AND SupMfgr.Partmfgr = @lcPartMfgr
	ORDER BY 1

