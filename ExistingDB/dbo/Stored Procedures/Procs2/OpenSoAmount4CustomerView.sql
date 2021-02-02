CREATE PROCEDURE [dbo].[OpenSoAmount4CustomerView] @lcCustNo as CHAR(10) ='' 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
DECLARE @SoOpenAmt1 numeric (20,2),@SoOpenAmt2 numeric (20,2)
DECLARE @ZSoAmt1 TABLE (OpenAmt numeric(20,2));
DECLARE @ZSoAmt2 TABLE (OpenAmt numeric(20,2));


INSERT @ZSoAmt1
	SELECT ISNULL(SUM(ROUND(CASE WHEN RecordType = 'P' THEN (Price*Balance) ELSE
				CASE WHEN Quantity>ShippedQty THEN (Price*(Quantity-ShippedQty)) ELSE 0 END END,2)),0)
	FROM SOMAIN, SODETAIL, SOPRICES
	WHERE ORD_TYPE = 'Open'
	AND SOMAIN.SONO = SODETAIL.SONO
	AND SODETAIL.UNIQUELN = SOPRICES.UNIQUELN 
	AND SOPRICES.FLAT = 0
	AND CUSTNO = @lcCustno

SELECT * FROM @ZSoAmt1

INSERT @ZSoAmt2
	SELECT ISNULL(SUM(ROUND(Price,2)),0)
		FROM Somain, Sodetail, Soprices 
		WHERE Somain.Ord_type = 'Open'
		AND Somain.Sono = Sodetail.Sono 
		AND SoDetail.Uniqueln = Soprices.Uniqueln
		AND Soprices.Flat = 1
		AND Sodetail.ShippedQty = 0
		AND Custno = @lcCustno

SELECT * FROM @ZSoAmt2

END