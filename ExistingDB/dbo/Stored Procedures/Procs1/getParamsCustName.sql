-- =============================================
-- Author:		Debbie	
-- Create date:	06/15/16
-- Description:	procedure to get list of Customer Names approved for the users to be used with Parameters  we were using <<aspmnxSP_GetCustomers4User>> itself for the custname listing, but it did not work when the user had a large number of customers. 
-- Modified:			
-- =============================================
create PROCEDURE [dbo].[getParamsCustName] 

--declare
	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@userId uniqueidentifier = null,
	@customerStatus char(8)='Active'

AS
BEGIN


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	  
	DECLARE  @tCustomer as tCustomer
		--DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;

		--select * from @tcustomer order by custname



	if (@top is not null)
		select distinct  top(@top) custno as Value, rtrim(custname) AS Text 
		from	@tcustomer
		WHERE	1 = case when @paramFilter is null then 1 else case when custname like @paramFilter+ '%' then 1 else 0 end end

	
		
	else
		select distinct	custno as Value, rtrim(custname) AS Text 
		from	@tcustomer
		WHERE	1 = case when @paramFilter is null then 1 else case when custname like @paramFilter+ '%' then 1 else 0 end end

end