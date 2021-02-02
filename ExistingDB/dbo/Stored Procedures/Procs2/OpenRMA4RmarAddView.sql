CREATE PROC [dbo].[OpenRMA4RmarAddView]
AS
SELECT DISTINCT Somain.Sono, CustName, Pono
	FROM Somain, Sodetail, Customer
	WHERE Somain.Custno = Customer.Custno
	AND SOMAIN.SONO = SODETAIL.SONO
	AND Somain.Ord_type = 'Open'
	AND Somain.Poack = 1
	AND Somain.Is_rma = 1
	AND Sodetail.Ord_Qty < 0
	AND Sodetail.Balance <> 0
	AND (Sodetail.Status = 'Standard' 
	OR Sodetail.Status = 'Priority-1'
	OR Sodetail.Status = 'Priority-2')
	ORDER BY 1

