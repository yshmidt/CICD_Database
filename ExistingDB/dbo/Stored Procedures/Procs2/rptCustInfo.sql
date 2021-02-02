
-- =============================================
-- Author:		Debbie
-- Create date: 11/19/15
-- Description:	This Stored Procedure was created for the Customer Information
-- Reports:		custlist
-- Modified:	
-- 03/31/2020 YS changed link from customer to shipbill. The default value is not saved in the customer.blinkadd and slinkadd anymore
-- =============================================
CREATE PROCEDURE [dbo].[rptCustInfo]

--declare
	@customerStatus char(10) = 'All'
	,@userId uniqueidentifier = null



as 
begin

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it. 
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	

/*RECORD SELECTION SECTION*/
select	CUSTNAME,CUSTPFX,CUSTOMER.CUSTNO
		,rtrim(SHIPBILL.Address1)+case when SHIPBILL.address2<> '' then char(13)+char(10)+rtrim(SHIPBILL.address2) else '' end+
				CASE WHEN SHIPBILL.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(SHIPBILL.City)+',  '+rtrim(SHIPBILL.State)+'      '+RTRIM(SHIPBILL.zip)  ELSE '' END +
				CASE WHEN SHIPBILL.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(SHIPBILL.Country) ELSE '' end  as BillToAddress
		,CUSTOMER.PHONE,CUSTOMER.STATUS
from	CUSTOMER 
		--INNER JOIN SHIPBILL ON CUSTOMER.BLINKADD = SHIPBILL.LINKADD
		LEFT OUTER join SHIPBILL on  CUSTOMER.custno=Shipbill.custno and SHIPBILL.RECORDTYPE='B' and SHIPBILL.IsDefaultAddress=1
where	exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)
		and 1 = case when @customerStatus = 'All' then 1 when @customerStatus = 'Active' and customer.status = 'Active' then 1 when @customerStatus = 'Inactive' and customer.STATUS = 'Inactive' then 1 else 0 end

end