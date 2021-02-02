
-- =============================================
-- Modifications: 01/15/2014 DRP:  added the @userid parameter for WebManex 
-- 08/17/20 VL added customer filter
-- =============================================

CREATE PROC [dbo].[OpenWorkOrderCustomerView]

@userId uniqueidentifier=null

AS

-- 08/17/20 VL added customer filter
DECLARE  @tCustomer as tCustomer    
INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;  

 SELECT DISTINCT Woentry.Wono, Part_no, Revision, Due_date, Bldqty, CustName, SONO, OPENCLOS, COMPLETE, Balance
	FROM Woentry, Inventor, Customer
	WHERE Woentry.Uniq_key = Inventor.Uniq_key
	AND Customer.Custno = Woentry.Custno
	AND Woentry.OpenClos <> 'Closed'
	AND Woentry.OpenClos <> 'Cancel'
	AND Woentry.BALANCE <> 0
	-- 08/17/20 VL added customer filter
	AND EXISTS (SELECT 1 FROM @tCustomer T WHERE T.Custno = Customer.Custno)
	ORDER BY Woentry.Wono