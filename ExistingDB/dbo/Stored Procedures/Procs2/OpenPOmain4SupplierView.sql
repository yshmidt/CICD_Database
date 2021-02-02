CREATE PROCEDURE [dbo].[OpenPOmain4SupplierView] @lcUniqSupno as CHAR(10) = ' ' 
AS
SELECT Ponum, POSTATUS, Terms
 FROM Pomain
 WHERE UNIQSUPNO = @lcUniqSupno
 AND (POSTATUS<>'CANCEL' AND POSTATUS<>'CLOSED')