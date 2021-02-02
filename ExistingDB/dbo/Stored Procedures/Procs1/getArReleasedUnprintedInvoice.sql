-- ==========================================================================================    
-- Author:  Satyawan H.     
-- Create date: 08/19/2020  
-- Description: procedure to get list of AR released Unprinted Invoices used for the report's parameters    
-- EXEC getArReleasedUnprintedInvoice @paramFilter=null, @top=10000, @userId = '49F80792-E15E-4B62-B720-21B360E3108A' 
-- ==========================================================================================    
  
CREATE PROCEDURE [dbo].[getArReleasedUnprintedInvoice]      
	 @paramFilter varchar(200) = null    
	,@top int = null 
	,@userId uniqueidentifier = null
AS    
BEGIN    
	SET NOCOUNT ON;    
	
	/*CUSTOMER LIST*/      
	DECLARE  @tCustomer as tCustomer   DECLARE @Customer TABLE (custno char(10))   -- get list of customers for @userid with access     
	INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;   
    
	if (@top is not null)    
		SELECT TOP(@top) INVOICENO AS VALUE, SUBSTRING(INVOICENO,PATINDEX('%[^0]%',INVOICENO + ' '),LEN(INVOICENO)) AS Text    
		FROM plmain  
		WHERE Is_invPost = 1 and is_inPrint =0 
		and 1 = case when CUSTNO in (select CUSTNO from @tCustomer) then 1 else 0 end    
		and 1 = case when ISNULL(@paramFilter,'')='' then 1 else case when INVOICENO like '%'+@paramFilter+ '%' then 1 else 0 end end  
		ORDER BY INVOICENO    
	else    
		select INVOICENO as Value, SUBSTRING(INVOICENO,PATINDEX('%[^0]%',INVOICENO + ' '),LEN(INVOICENO)) AS Text      
		from plmain    
		WHERE Is_invPost = 1 and is_inPrint =0   
		and 1 = case when  ISNULL(@paramFilter,'')='' then 1 else case when INVOICENO like '%'+@paramFilter+ '%' then 1 else 0 end end    
		and 1 = case when CUSTNO in (select CUSTNO from @tCustomer) then 1 else 0 end    
		ORDER BY INVOICENO    
END  