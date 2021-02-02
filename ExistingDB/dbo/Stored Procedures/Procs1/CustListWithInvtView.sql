CREATE proc [dbo].[CustListWithInvtView] 
As 
	SELECT DISTINCT CustName, Customer.CustNo  
	FROM Customer,Inventor WHERE Inventor.custno<>SPACE(10) AND Customer.CustNo = Inventor.CustNo ORDER BY CUSTNAME