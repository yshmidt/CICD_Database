CREATE PROC [dbo].[Pldetail4UniquelnView] @lcUniqueln AS char(10) = '', @lcPacklistno AS char(10) = ''
AS
BEGIN
IF LEFT(@lcUniqueln,1) <> '*'
	SELECT Pldetail.PACKLISTNO, ShippedQty
		FROM Pldetail
 		WHERE Uniqueln = @lcUniqueln
 		ORDER BY Packlistno
ELSE
	SELECT Pldetail.PACKLISTNO, ShippedQty
		FROM Pldetail
 		WHERE Uniqueln = @lcUniqueln
 		AND PACKLISTNO = @lcpacklistno
 		ORDER BY Packlistno
END 		
 		