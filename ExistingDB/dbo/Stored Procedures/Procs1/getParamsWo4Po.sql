-- =============================================
-- Author:		Debbie	
-- Create date:	09/25/2014
-- Description:	procedure to get list of work orders that are associated to PO item Schedules
-- Modified:	01/06/2015 DRP:  Added @customerStatus Filter
-- =============================================
CREATE PROCEDURE [dbo].[getParamsWo4Po] 

@paramFilter varchar(200) = ''		--- first 3+ characters entered by the user
,@top int = null							-- if not null return number of rows indicated
,@customerStatus varchar (20) = 'All'
,@userId uniqueidentifier = null

as
begin

/*CUSTOMER SELECTION LIST*/
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @tCustomer tCustomer
	DECLARE @tCustno tCustno ;
	-- get list of customers for @userid with access
	-- even if @lcCustomer is not empty we cannot assume that the user has rights to those customers. They might just know the codes of the customers that they have no rights to
	INSERT INTO @tCustomer EXEC [aspmnxSP_GetCustomers4User] @userid,null,@customerStatus ;
	INSERT INTO @tCustno SELECT Custno FROM @tCustomer	


if (@top is not null) 
	select  top(@top) WOENTRY.WONO as Value,SUBSTRING(woentry.wono,PATINDEX('%[^0]%',woentry.wono + ' '),LEN(woentry.wono)) AS Text 
	from	WOENTRY
	where	WONO in (select WOPRJNUMBER from POITSCHD where POITSCHD.WOPRJNUMBER = WOENTRY.WONO and REQUESTTP = 'WO Alloc')
			and 1= case when WOENTRY.CUSTNO IN (select CUSTNO from @tCustno) then 1 else 0 end
			and 1 = case when @paramFilter is null then 1 when WOENTRY.wono like '%'+@paramFilter+ '%' then 1 else 0 end 
	order by WONO
else
	select  WOENTRY.WONO as Value,SUBSTRING(woentry.wono,PATINDEX('%[^0]%',woentry.wono + ' '),LEN(woentry.wono)) AS Text 
	from	WOENTRY
	where	WONO in (select WOPRJNUMBER from POITSCHD where POITSCHD.WOPRJNUMBER = WOENTRY.WONO and REQUESTTP = 'WO Alloc')
			and 1= case when WOENTRY.CUSTNO IN (select CUSTNO from @tCustno) then 1 else 0 end
			and 1 = case when @paramFilter is null then 1 when WOENTRY.wono like '%'+@paramFilter+ '%' then 1 else 0 end 
	order by wono

end