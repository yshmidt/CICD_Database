

CREATE PROC [dbo].[OpenWorkOrders4Uniq_keyView] @gUniq_key AS char(10) =''    
AS
SELECT Wono, BldQty, Complete, Balance, Sono, Due_date, ReleDate, OpenClos, CustName
	FROM Woentry, Customer 
	WHERE Woentry.Custno = Customer.Custno
	AND (OpenClos<>'Closed' 
	AND OpenClos<>'Cancel'
	ANd OpenClos<>'ARCHIVED')
	AND Uniq_key = @gUniq_key 
ORDER BY Wono