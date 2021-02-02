-- Modification ----------------------------------------------
-- 02/24/15 VL Create the view to get all customer with bill currency info
--------------------------------------------------------------
CREATE PROC [dbo].[CustBillCurrencyView] 
AS
BEGIN
	SELECT DISTINCT Custname, Customer.Custno, Fcused.symbol, shipbill.fcused_uniq
	FROM Customer, shipbill, fcused
	WHERE Customer.custno = shipbill.custno 
	AND shipbill.recordtype = 'B'
	AND shipbill.fcused_uniq = fcused.fcused_uniq
	ORDER BY CustName
END