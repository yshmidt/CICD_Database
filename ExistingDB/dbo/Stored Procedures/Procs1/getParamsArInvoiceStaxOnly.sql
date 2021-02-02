-- =============================================
-- Author:		Debbie	
-- Create date:	10/30/2015
-- Description:	procedure to get list of AR Invoice No that have Sales Tax Only the user is approved to see for the report's parameters
-- Modifaction: 
-- =============================================
CREATE PROCEDURE [dbo].[getParamsArInvoiceStaxOnly] 

--declare

	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null							-- if not null return number of rows indicated
	,@userId uniqueidentifier = NULL

AS
BEGIN

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it. 
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	



	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	if (@top is not null)
		select top(@top) invoiceno as Value, SUBSTRING(INVOICENO,PATINDEX('%[^0]%',INVOICENO + ' '),LEN(INVOICENO))  AS Text 
		from	plmain inner join @tCustomer C on plmain.CUSTNO = c.custno	
		WHERE	1 = case when @paramFilter is null then 1 else case when INVOICENO like '%'+@paramFilter+ '%' then 1 else 0 end end
				and tottaxe <> 0 
				
		ORDER BY INVOICENO
			
	else
		select	INVOICENO as Value, SUBSTRING(INVOICENO,PATINDEX('%[^0]%',INVOICENO + ' '),LEN(INVOICENO)) AS Text 
		from	plmain
		WHERE	1 = case when @paramFilter is null then 1 else case when INVOICENO like '%'+@paramFilter+ '%' then 1 else 0 end end
				and 1 = case when CUSTNO in (select CUSTNO from @tCustomer) then 1 else 0 end
				and tottaxe <> 0
		ORDER BY INVOICENO
		
END