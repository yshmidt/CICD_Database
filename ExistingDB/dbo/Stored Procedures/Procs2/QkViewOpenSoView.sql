﻿
-- =============================================
-- Author:		Unknown
-- Description:	Sales Order Quick View
-- Modified:	07/19/17 DRP:  needed to add the /*CUSTOMER LIST*/ in order to make sure only records the users are approved to see are displayed.  
-- =============================================
CREATE PROCEDURE [dbo].[QkViewOpenSoView]
@userid uniqueidentifier = null
AS
BEGIN

/*CUSTOMER LIST*/		--07/19/17 DRP:  added	
	DECLARE  @tCustomer as tCustomer
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	

SET NOCOUNT ON;

WITH ZSoItem
AS
(SELECT Sono, ISNULL(COUNT(*),0) AS NoItems
	FROM SODETAIL
	WHERE SONO IN 
		(SELECT SONO 
			FROM SOMAIN
			WHERE Ord_type = 'Open'
			AND Is_Rma = 0)
	GROUP BY Sono
)
	
SELECT DATEDIFF(day, OrderDate, GETDATE()) AS Age, Somain.Sono, Custname, Pono, OrderDate, ZSoItem.NoITems, Poackdt
	FROM Somain, Customer, ZSoItem 
	WHERE Somain.Custno = Customer.Custno 
	AND Somain.SONO = ZSoitem.Sono
	AND Ord_type = 'Open'
	AND Is_Rma = 0
	and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)	--07/19/17 DRP:  added
	ORDER BY Age
	
END