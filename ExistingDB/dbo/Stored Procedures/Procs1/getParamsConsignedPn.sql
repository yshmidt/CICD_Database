-- =============================================
-- Author:		Debbie	
-- Create date:	01/16/2015
-- Description:	procedure to get list of Consigned Inventory Part numbers used for the report's parameters . . . PASSED PN BECAUSE IT IS USED FOR PN RANGE PARAMETER SELECTIONS
--				I would normally pass the Uniq_key, but there were three existing reports that were just passing the Part Number itself for Range's, etc. . . this is why I created it to still pass the Part_no instead of the uniq_key
-- Modified:			
-- =============================================
CREATE PROCEDURE [dbo].[getParamsConsignedPn] 
--declare
	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@customerStatus varchar (20) = 'All',	--This is used to pass the customer status to the [aspmnxSP_GetCustomers4User] below.
	@lcCustNo char(10) = 'All',
	@userId uniqueidentifier = null
as
BEGIN

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	if (@top is not null)
		select distinct  top(@top) custPartno as Value, rtrim(custPartno) AS Text 
		from	inventor
		WHERE	custno <> ''
				and STATUS = 'Active'
				and 1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end
				and 1 = case when CUSTNO in (select CUSTNO from @customer) then 1 else 0 end
		
	else
		select distinct	custPartno as Value, rtrim(custPartno) AS Text 
		from	inventor
		WHERE	custno <> ''
				and STATUS = 'Active'
				and 1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end
				and 1 = case when CUSTNO in (select CUSTNO from @customer) then 1 else 0 end

		
END

