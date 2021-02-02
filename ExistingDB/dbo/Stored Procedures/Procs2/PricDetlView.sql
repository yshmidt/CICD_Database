-- =============================================
-- Author:		Vicky Lu
-- Create date: 09/24/10
-- Description:	Get PricDetl records, used in SO and Price modules
-- Modified: 
-- 05/02/16 VL	Added 3rd parameter, now even for same part, same customer, there might be different currency pricedetl record, also added Pricdetl.UniqPrHead = Prichead.UniqPrHead criteria
-- =============================================
CREATE PROC [dbo].[PricDetlView] @lcUniq_key AS char(10) = '',@lcCustno char(10) = '', @lcFcused_uniq char(10) = ' '
AS
SELECT PricDetl.*, Customer.CustName
	FROM PricDetl, PricHead, Customer
	WHERE Pricdetl.UniqPrHead = Prichead.UniqPrHead
	AND Prichead.Category = Customer.Custno
	ANd Prichead.Uniq_key = @lcUniq_key
	AND Prichead.Category = @lcCustno
	AND Prichead.FCUSED_UNIQ = @lcFcused_uniq
	ORDER BY FromQty