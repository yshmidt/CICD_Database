-- ==========================================================================================  
-- Author:  Debbie   
-- Create date: 04/21/2015  
-- Description: procedure to get list of Unprinted Invoices used for the report's parameters  
-- Modifaction:   
-- 07/27/2020 Satyawan H : Added @isZerobalInv parameter to get 0 balance invoices or not
-- 07/27/2020 Satyawan H : Added condition to filter 0 balance invoices 
-- EXEC getParamsUnprintedInvoice @userId = '49F80792-E15E-4B62-B720-21B360E3108A',@isZerobalInv=0
-- ==========================================================================================  
--select * from aspnet_Profile where FirstName = 'company'
-- getParamsUnprintedInvoice @paramFilter=null, @top=10000, @userId = '49F80792-E15E-4B62-B720-21B360E3108A',@isZerobalInv=1

CREATE PROCEDURE [dbo].[getParamsUnprintedInvoice]   
	--declare  
	@paramFilter varchar(200) = null  --- first 3+ characters entered by the user  
	,@top int = null       -- if not null return number of rows indicated  
	,@userId uniqueidentifier = null  
	,@isZerobalInv bit =1 -- 07/27/2020 Satyawan H : Added @isZerobalInv parameter to get 0 balance invoices or not
AS  
BEGIN  
  
	/*CUSTOMER LIST*/    
	DECLARE  @tCustomer as tCustomer   DECLARE @Customer TABLE (custno char(10))   -- get list of customers for @userid with access   
	INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ; 
	--SELECT * FROM @tCustomer    
  
  
	-- SET NOCOUNT ON added to prevent extra result sets from  
	-- interfering with SELECT statements.  
	SET NOCOUNT ON;  
  --select @top
	-- Insert statements for procedure here  
	if (@top is not null)  
		SELECT TOP(@top) INVOICENO AS VALUE, SUBSTRING(INVOICENO,PATINDEX('%[^0]%',INVOICENO + ' '),LEN(INVOICENO)) AS Text  
		FROM plmain --inner join @Customer C ON plmain.CUSTNO = c.custno  
		WHERE IS_INPRINT = 0 and IS_PKPRINT = 1   
		and 1 = case when CUSTNO in (select CUSTNO from @tCustomer) then 1 else 0 end  
		and 1 = case when ISNULL(@paramFilter,'')='' then 1 else case when INVOICENO like '%'+@paramFilter+ '%' then 1 else 0 end end
		AND ((@isZerobalInv=1 AND 1=1) OR (@isZerobalInv=0 AND INVTOTAL <> 0)) -- 07/27/2020 Satyawan H : Added condition to filter 0 balance invoices 
		ORDER BY INVOICENO  
	else  
		select INVOICENO as Value, SUBSTRING(INVOICENO,PATINDEX('%[^0]%',INVOICENO + ' '),LEN(INVOICENO)) AS Text    
		from plmain  
		WHERE IS_INPRINT = 0 and IS_PKPRINT = 1   
		and 1 = case when  ISNULL(@paramFilter,'')='' then 1 else case when INVOICENO like '%'+@paramFilter+ '%' then 1 else 0 end end  
		and 1 = case when CUSTNO in (select CUSTNO from @tCustomer) then 1 else 0 end  
		AND ((@isZerobalInv=1 AND 1=1) OR (@isZerobalInv=0 AND INVTOTAL <> 0)) -- 07/27/2020 Satyawan H : Added condition to filter 0 balance invoices 
		ORDER BY INVOICENO  
END
  