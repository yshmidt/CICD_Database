-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <2013/11/06>
-- Description:	<Function to return a part price from SO module>
-- =============================================
CREATE FUNCTION [dbo].[fn_GetPartSoPrice] 
(	
	@lcSono char(10)=' ', @lcUniqueln char(10) = ' ', @lnBldQty numeric(7,0)
)
RETURNS numeric(15,5)
AS
BEGIN
DECLARE @lnPrice numeric(15,5) = 0.00

IF @lcSono <> ''
	BEGIN
	;WITH ZSoPrice 
	AS
	(
		SELECT CASE WHEN Sodetail.Ord_qty=0.00 THEN 0.00 ELSE
			SUM(Soprices.Extended)/Sodetail.Ord_qty END AS EachPrice 
			FROM Soprices,Sodetail
		WHERE Soprices.SoNo = @lcSono
		AND Soprices.Uniqueln = @lcUniqueLn
		AND Soprices.Uniqueln = Sodetail.Uniqueln
		GROUP BY Sodetail.Uniqueln,Sodetail.Ord_qty 
	)
	SELECT @lnPrice = ISNULL(EachPrice,0)*@lnBldQty
		FROM ZSoPrice
	
END

RETURN @lnPrice

END