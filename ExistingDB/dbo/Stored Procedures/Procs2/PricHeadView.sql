CREATE PROC [dbo].[PricHeadView] @lcUniq_key AS char(10) = '',@lcCustno char(10) = ''
AS
DECLARE @lcUniqPrHead char(10);

SELECT @lcUniqPrHead = UniqPrHead
	FROM PRICHEAD
	WHERE Uniq_key = @lcUniq_key
	AND Category = @lcCustno

IF @@ROWCOUNT > 0
	SELECT PricHead.*, Customer.Custname
		FROM PricHead, Customer
		WHERE Prichead.Category = Customer.Custno 
		AND Uniq_key = @lcUniq_key
		AND Category = @lcCustno
ELSE
	SELECT PricHead.*,dbo.PADR('Standard Price',35,' ') AS CustName
		FROM PricHead 
		WHERE Prichead.Category = '000000000~'
		AND Uniq_key = @lcUniq_key




