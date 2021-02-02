-- =============================================
-- Author:		Debbie	
-- Create date:	01/16/2015
-- Description:	procedure to get list of Customer Inventory Part numbers (both Make and Buy) used for the report's parameters
-- Modified:	01/16/2015 DRP:  Copied this from the [getParamsInternalPnUniqkey]  This procedure is needed to pass the parts Uniq_key for Consigned. Since this one is used for Consigned I also had to add the Customer Select section.
--				01/23/2015 DRP:  changed <rtrim(CUSTPARTNO) AS Text> to <rtrim(CUSTPARTNO) +'     '+ rtrim(CUSTREV)  AS Text>
--				05/22/2015 DRP:  removed STATUS = 'Active' because all of the reports that this procedure was used on was for history information.  If that is the case you will need to look up all Active and/or Inactive parts on the parameter
-- =============================================
CREATE PROCEDURE [dbo].[getParamsConsignedPnUniqkey] 
--declare
	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@customerStatus varchar (20) = 'All',	--This is used to pass the customer status to the [aspmnxSP_GetCustomers4User] below.
	@lcCustNo char(10) = 'All',
	@userId uniqueidentifier = null
AS
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
		select distinct  top(@top) uniq_key as Value, rtrim(CUSTPARTNO) +'     '+ rtrim(CUSTREV)  AS Text 
		from	inventor
		WHERE	custno <> ''
				--and STATUS = 'Active'
				and 1 = case when @paramFilter is null then 1 else case when CUSTPARTNO like @paramFilter+ '%' then 1 else 0 end end
				and 1 = case when CUSTNO in (select CUSTNO from @customer) then 1 else 0 end

	else
		select distinct	uniq_key as Value, rtrim(CUSTPARTNO)+'     '+ rtrim(CUSTREV)  AS Text 
		from	inventor
		WHERE	custno <> ''
				--and STATUS = 'Active'
				and 1 = case when @paramFilter is null then 1 else case when CUSTPARTNO like @paramFilter+ '%' then 1 else 0 end end
				and 1 = case when CUSTNO in (select CUSTNO from @customer) then 1 else 0 end	
END