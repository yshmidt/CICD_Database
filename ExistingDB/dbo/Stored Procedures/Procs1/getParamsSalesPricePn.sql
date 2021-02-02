-- =============================================
-- Author:		Debbie	
-- Create date:	12/05/2014
-- Description:	procedure to get list of Inventory Part numbers that have Sales Price List information created for them
-- Modified:	01/06/2015 DRP:  Added @customerStatus Filter
-- 12/05/19 VL changed to use new price tables for cube version
-- =============================================
CREATE PROCEDURE [dbo].[getParamsSalesPricePn] 

--declare
	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@customerStatus varchar (20) = 'All',	--01/06/2015 DRP: ADDED
	@userId uniqueidentifier = null
AS
BEGIN


/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	
	
	
/*SELECT STATEMENT*/
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    if (@top is not null)
		-- 12/05/19 VL changed to use new price tables for cube version
		--select distinct top(@top) prichead.uniq_key as Value,RTRIM(Part_no)+' / '+ RTRIM(revision)as text
		--from	INVENTOR
		--		inner join PRICHEAD on inventor.UNIQ_KEY = prichead.UNIQ_KEY
		--where	inventor.STATUS = 'Active'
		--		and 1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end
		--		and 1 = case when PRICHEAD.CATEGORY in (select CUSTNO from @tCustomer ) then 1 else 0 end
		select distinct top(@top) priceheader.uniq_key as Value,RTRIM(Part_no)+' / '+ RTRIM(revision)as text
		from	INVENTOR
				inner join priceheader on inventor.UNIQ_KEY = priceheader.UNIQ_KEY
				INNER JOIN priceCustomer ON priceheader.uniqprhead = priceCustomer.uniqprhead
		where	inventor.STATUS = 'Active'
				and 1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end
				and 1 = case when PriceCustomer.Custno in (select CUSTNO from @tCustomer ) then 1 else 0 end

				
	else
		-- 12/05/19 VL changed to use new price tables for cube version
		--select distinct prichead.uniq_key as Value,RTRIM(Part_no)+' / '+ RTRIM(revision)as text
		--from	INVENTOR
		--		inner join PRICHEAD on inventor.UNIQ_KEY = prichead.UNIQ_KEY	
		--where	inventor.STATUS = 'Active'
		--		and 1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end
		--		and 1 = case when PRICHEAD.CATEGORY in (select CUSTNO from @tCustomer ) then 1 else 0 end
		select distinct priceheader.uniq_key as Value,RTRIM(Part_no)+' / '+ RTRIM(revision)as text
		from	INVENTOR
				inner join priceheader on inventor.UNIQ_KEY = priceheader.UNIQ_KEY	
				INNER JOIN priceCustomer ON priceheader.uniqprhead = priceCustomer.uniqprhead
		where	inventor.STATUS = 'Active'
				and 1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end
				and 1 = case when PriceCustomer.Custno in (select CUSTNO from @tCustomer ) then 1 else 0 end
				
				

end	