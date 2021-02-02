
-- =============================================
-- Author:		Debbie
-- Create date:	11/19/15
-- Description:	This Stored Procedure was created for the Customer Contact
-- Reports:		cstcont
-- Modified:	
-- =============================================
create PROCEDURE [dbo].[rptCustContact]

--declare

	@userId uniqueidentifier = null



as 
begin

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it. 
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	

/*RECORD SELECTION SECTION*/
select	CUSTNAME,CUSTOMER.CUSTNO,isnull(ccontact.lastname,'')as lastname,isnull(ccontact.firstname,'') as firstname,isnull(ccontact.title,'') as Title
		,isnull(ccontact.workphone,'') as workphone,isnull(ccontact.contactfax,'') as contactfax,isnull(ccontact.email,'') as email
from	CUSTOMER 
		left outer join ccontact on customer.custno = ccontact.custno
where	exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)
		and customer.status = 'Active'
order by custname,lastname,firstname

end