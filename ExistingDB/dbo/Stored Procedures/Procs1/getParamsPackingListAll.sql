-- =============================================
-- Author:		Debbie	
-- Create date:	04/27/2015
-- Description:	procedure to get list of Packing Lists the user is approved to see for the report's parameters
-- Modifaction: 10/28/15 DRP:  Changed the "plmain inner join @Customer C on plmain.CUSTNO = c.custno" to be "plmain inner join @tCustomer C on plmain.CUSTNO = c.custno"
-- =============================================
create PROCEDURE [dbo].[getParamsPackingListAll] 

--declare

	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null							-- if not null return number of rows indicated
	,@userId uniqueidentifier = null

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
		select top(@top) PACKLISTNO as Value, SUBSTRING(PACKLISTNO,PATINDEX('%[^0]%',PACKLISTNO + ' '),LEN(PACKLISTNO))  AS Text 
		from	plmain inner join @tCustomer C on plmain.CUSTNO = c.custno	--10/28/15 DRP:  change @Customer to be @tCustomer
		WHERE	1 = case when @paramFilter is null then 1 else case when PACKLISTNO like '%'+@paramFilter+ '%' then 1 else 0 end end
				
		ORDER BY PACKLISTNO
			
	else
		select	PACKLISTNO as Value, SUBSTRING(PACKLISTNO,PATINDEX('%[^0]%',PACKLISTNO + ' '),LEN(PACKLISTNO)) AS Text 
		from	plmain
		WHERE	1 = case when @paramFilter is null then 1 else case when PACKLISTNO like '%'+@paramFilter+ '%' then 1 else 0 end end
				and 1 = case when CUSTNO in (select CUSTNO from @tCustomer) then 1 else 0 end
		ORDER BY PACKLISTNO
		
END