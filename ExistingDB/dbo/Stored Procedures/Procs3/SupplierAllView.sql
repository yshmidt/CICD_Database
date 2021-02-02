
CREATE PROC [dbo].[SupplierAllView] AS 
SELECT Supname, Supid, UniqSupNo, STATUS, PURCH_TYPE, C_LINK, SUPNOTE
FROM Supinfo
ORDER BY Supname
