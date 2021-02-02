-- Modification ----------------------------------------------
-- 12/01/14 VL added Bank info
-- 01/14/15 VL added ORDER BY Shipto
--------------------------------------------------------------
CREATE proc [dbo].[CustBillView] 
	@lcCustno AS char(10)=' '
AS
SELECT Shipbill.*, ISNULL(Bank,SPACE(50)) AS Bank, 
	ISNULL(PaymentType, 'Check') AS PaymentType, ISNULL(FcUsed.Currency, SPACE(40)) AS Currency, ISNULL(FcUsed.Symbol,SPACE(3)) AS Symbol
	FROM SHIPBILL 
	LEFT OUTER JOIN BANKS ON Banks.Bk_Uniq = Shipbill.Bk_Uniq
	LEFT OUTER JOIN FcUsed ON FcUsed.FcUsed_Uniq = Shipbill.FcUsed_Uniq
	WHERE CUSTNO = @lcCustno 
	AND Recordtype='B'
	ORDER BY Shipto