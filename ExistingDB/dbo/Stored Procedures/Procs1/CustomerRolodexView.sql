
-- =============================================
-- Author:		Unknown
-- Description:	Customer Rolodex Quick View
-- Modified:	07/19/17 DRP:  needed to add the /*CUSTOMER LIST*/ in order to make sure only records the users are approved to see are displayed.  
-- =============================================
CREATE PROCEDURE [dbo].[CustomerRolodexView]

--declare
@userId uniqueidentifier=null
AS
BEGIN


/*CUSTOMER LIST*/		--07/19/17 DRP:  added	
	DECLARE  @tCustomer as tCustomer
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer

SET NOCOUNT ON;
-- 08/26/13 YS   changed first name/last name to varchar(100), increased length of the ccontact fields.
SELECT CustName, CAST(ISNULL(LTRIM(RTRIM(Lastname))+', '+LTRIM(RTRIM(Firstname)),'') as varchar(200)) AS Contact,
	cast(ISNULL(Title,'') as varchar(100)) AS Title, cast(ISNULL(WorkPhone,'') as varchar(50)) AS Phone, cast(ISNULL(Email,'') as varchar(100)) AS Email, 
	cast(ISNULL(ContactFax,'') as varchar(50)) AS ContactFax, Customer.Custno, 'C' AS FromWhere 
	FROM Customer LEFT OUTER JOIN Ccontact 
	ON Customer.Custno = Ccontact.Custno 
	AND Ccontact.Type = 'C'
	AND Ccontact.Status = 'Active'
    WHERE Customer.Custno <> '000000000~'
    AND Customer.Status = 'Active'
	and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)	--07/19/17 DRP:  added
	ORDER BY 1,2 ;
		
END