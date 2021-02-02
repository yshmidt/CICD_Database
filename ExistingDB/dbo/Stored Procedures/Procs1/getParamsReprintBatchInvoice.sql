-- =============================================
-- Author:		Debbie	
-- Create date:	04/21/2015
-- Description:	procedure to get list of Invoices from the last batch of Invoices used for the report's parameters
-- Modifaction: 
-- =============================================
CREATE PROCEDURE [dbo].[getParamsReprintBatchInvoice] 

--declare

	@paramFilter varchar(200) = null,		--- first 3+ characters entered by the user
	@top int = null							-- if not null return number of rows indicated
	,@userId uniqueidentifier = null

AS
BEGIN

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	



	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	if (@top is not null)
		select top(@top) fieldkey as Value, SUBSTRING(FIELDKEY,PATINDEX('%[^0]%',FIELDKEY + ' '),LEN(FIELDKEY))  AS Text 
		from	prevstat
				inner join plmain on PREVSTAT.FIELDKEY = plmain.INVOICENO
				inner join @tCustomer C on plmain.CUSTNO = C.custno
		WHERE	fieldtype = 'INVOICE' 
				and 1 = case when @paramFilter is null then 1 else case when FIELDKEY like '%'+@paramFilter+ '%' then 1 else 0 end end
		ORDER BY FIELDKEY

			
	else
		select	FIELDKEY as Value, SUBSTRING(FIELDKEY,PATINDEX('%[^0]%',FIELDKEY + ' '),LEN(FIELDKEY)) AS Text 
		from	prevstat
				inner join plmain on PREVSTAT.FIELDKEY = plmain.INVOICENO
				inner join @tCustomer C on plmain.CUSTNO = C.custno
		WHERE	fieldtype = 'INVOICE' 
				and 1 = case when @paramFilter is null then 1 else case when FIELDKEY like '%'+@paramFilter+ '%' then 1 else 0 end end
		ORDER BY FIELDKEY
		
END

