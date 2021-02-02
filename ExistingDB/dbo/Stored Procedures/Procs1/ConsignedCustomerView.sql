CREATE PROCEDURE [dbo].[ConsignedCustomerView]
AS 
BEGIN
	SELECT DISTINCT CustName, Customer.CustNo
		FROM Customer, Inventor 
		WHERE Customer.CustNo = Inventor.CustNo 
		ORDER BY CustName 
END






