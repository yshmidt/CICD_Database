
CREATE PROC [dbo].[Invt_isu4PacklistnoView] @lcPacklistno char(10) = NULL
AS
SELECT * 
	FROM Invt_isu
	WHERE SUBSTRING(ISSUEDTO,11,10) = @lcPacklistno
	ORDER BY Date