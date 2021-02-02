-- =============================================    
-- Author:  Debbie     
-- Create date: 04/12/2016     
-- Description: Procedure that will gather the Ship To Addresses associated with a selected Sales Order    
-- Modified: 03/23/17 DRP: needed to change the the where clause when it came to the Sono filter.  If I left the option null it would list all ShipTo for any customer and it would also populate to the final report results.     
-- 09/06/2049 Mahesh B : Change the select statment names as Key & Value from  Value & Text
-- =============================================    
 CREATE PROCEDURE [dbo].[getParamsSoNoShipTo]   
--declare    
 @paramFilter VARCHAR(200) = '',  --- first 3+ characters entered by the user    
 @top INT = NULL,       -- if not null return number of rows indicated    
 @customerStatus VARCHAR (20) = 'All', --This is used to pass the customer status to the [aspmnxSP_GetCustomers4User] below.    
 @lcCustNo CHAR(10) = 'All',    
 @userId UNIQUEIDENTIFIER = NULL,    
 @lcSoNo CHAR(10) = NULL    
    
AS    
BEGIN    
    
    
     
/*CUSTOMER LIST*/      
 DECLARE  @tCustomer AS tCustomer    
  DECLARE @Customer TABLE (custno CHAR(10))    
  -- get list of customers for @userid with access    
  INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,NULL,@customerStatus ;    
  --SELECT * FROM @tCustomer     
      
  IF @lcCustNo IS NOT NULL AND @lcCustNo <>'' AND @lcCustNo<>'All'    
   INSERT INTO @Customer SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')    
     WHERE CAST (id AS CHAR(10)) IN (SELECT CustNo FROM @tCustomer)    
  ELSE    
    
  IF  @lcCustNo='All'     
  BEGIN    
   INSERT INTO @Customer SELECT CustNo FROM @tCustomer    
  END    
    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
    
    -- Insert statements for procedure here    
 IF (@top IS NOT NULL)    
    -- 09/06/2049 Mahesh B : Change the select statment names as Key & Value from  Value & Text
    SELECT DISTINCT  TOP(@TOP) SLINKADD AS [Key], RTRIM(Shipto) AS Value      
    FROM SODETAIL INNER JOIN shipbill ON sodetail.SLINKADD = SHIPBILL.LINKADD    
    WHERE custno <> ''    
    --and 1 = CASE WHEN @paramFilter is null then 1 else CASE WHEN sono like dbo.padl(@paramFilter+ '%',10,'0') then 1 else 0 end end    
    --and 1 = CASE WHEN @lcSoNo is null then 1 when sodetail.sono like '%'+@lcSoNo+ '%' then 1 else 0 end --03/23/17 DRP:  Replaced with the below    
    AND sodetail.sono LIKE '%'+@lcSoNo+ '%'     
    AND 1 = CASE WHEN CUSTNO IN (select CUSTNO FROM @customer) THEN 1 ELSE 0 END    
    
 ELSE    
  
	-- 09/06/2049 Mahesh B : Change the select statment names as Key & Value from  Value & Text
    SELECT DISTINCT  TOP(@top) SLINKADD AS [Key], RTRIM(Shipto) AS Value      
	FROM SODETAIL INNER JOIN shipbill ON sodetail.SLINKADD = SHIPBILL.LINKADD    
	WHERE custno <> ''    
    --and 1 = CASE WHEN @lcSoNo is null then 1 when sodetail.sono like '%'+@lcSoNo+ '%' then 1 else 0 end --03/23/17 DRP:  replaced with the below    
    AND sodetail.sono LIKE '%'+@lcSoNo+ '%'     
    AND 1 = CASE WHEN CUSTNO IN (SELECT CUSTNO from @customer) THEN 1 ELSE 0 END     
END