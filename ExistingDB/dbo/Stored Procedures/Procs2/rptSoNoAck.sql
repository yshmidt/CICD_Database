
-- =============================================  
-- Author:  <Debbie>  
-- Create date: <06-10-2011>  
-- Description: <This has been created for the Sales Orders without Acknowledgement/PO Report [sonoack.rpt]>  
-- Modified: 11/06/15 DRP:  @userId added  /*CUSTOMER LIST*/ ADDED  
--    11/14/15 DRP:  added min(DUE_DTS.SHIP_DTS) as SHIP_DTS,min(DUE_DTS.DUE_DTS) as DUE_DTS to help the WebReports work properly  
-- 12/26/2018 Shrikant B DECLARE  @lcDateStart and @lcDateEnd from SMALLDATETIME to VARCHAR to fix report conversion errors
-- 12/26/2018 Shrikant B CAST  @lcDateStart and @lcDateEnd from VARCHAR to SMALLDATETIME to fix report conversion errors
-- 01/02/2018 Shrikant B DECLARE @userId  from UNIQUEIDENTIFIER to VARCHAR to fix report conversion errors
-- 01/04/19 Shrikant B: Changed  Reverts @userId Changes from  VARCHAR(40) to UNIQUEIDENTIFIER 
-- rptSoNoAck '12/19/2018', '12/26/2018', 'Open Sales Orders', 'All', '49f80792-e15e-4b62-b720-21b360e3108a'
-- =============================================  
CREATE PROCEDURE [dbo].[rptSoNoAck]   
-- 12/26/2018 Shrikant B DECLARE  @lcDateStart and @lcDateEnd from SMALLDATETIME to VARCHAR to fix report conversion errors
  @lcDateStart AS VARCHAR(20)= NULL,  
  @lcDateEnd AS  VARCHAR(20)  = NULL,  
  @lcType CHAR(17) = 'Open Sales Orders',  
  @lcCustNo AS VARCHAR (35) = 'All' 
  -- 01/02/2018 Shrikant B DECLARE @userId  from UNIQUEIDENTIFIER to VARCHAR to fix report conversion errors 
  -- 01/04/19 Shrikant B: Changed  Reverts @userId Changes from  VARCHAR(40) to UNIQUEIDENTIFIER 
  ,@userId UNIQUEIDENTIFIER = NULL  
 
AS  
BEGIN  
  
/*CUSTOMER LIST*/ --01/07/2015 ADDED   
 DECLARE  @tCustomer AS tCustomer  
  DECLARE @Customer TABLE (custno CHAR(10))  
  --DECLARE  @tableName AS VARCHAR(MAX)
  -- get list of customers for @userid with access  
  INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,NULL,'Active' ;  
  --SELECT * FROM @tCustomer   
    
  IF @lcCustNo IS NOT NULL AND @lcCustNo <>'' AND @lcCustNo<>'All'  
   INSERT INTO @Customer SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')  
     WHERE CAST (id AS CHAR(10)) IN (SELECT CustNo FROM @tCustomer)  
  ELSE  
  
  IF  @lcCustNo='All'   
  BEGIN  
   INSERT INTO @Customer SELECT CustNo FROM @tCustomer  
  END  
  
  SELECT CUSTOMER.CUSTNO, CUSTOMER.CUSTNAME, SOMAIN.sono, SOMAIN.ORDERDATE, SOMAIN.PONO, SOMAIN.ORD_TYPE, MIN(DUE_DTS.SHIP_DTS) AS SHIP_DTS,MIN(DUE_DTS.DUE_DTS) 
	AS DUE_DTS,SOMAIN.ACKPO_DOC, SOMAIN.IS_RMA  
  
FROM CUSTOMER INNER JOIN  
  SOMAIN ON SOMAIN.CUSTNO = CUSTOMER.CUSTNO LEFT OUTER JOIN  
  DUE_DTS ON SOMAIN.SONO = DUE_DTS.sono  
  
WHERE SOMAIN.ACKPO_DOC = ''   
  AND somain.ORD_TYPE = CASE WHEN @lcType = 'All Sales Orders' THEN SOMAIN.ORD_TYPE ELSE 'Open' END  
   -- 12/26/2018 Shrikant B CAST  @lcDateStart and @lcDateEnd from VARCHAR to SMALLDATETIME to fix report conversion errors
  AND SOMAIN.ORDERDATE>=CAST(@lcDateStart  AS SMALLDATETIME) AND somain.orderdate < CAST(@lcDateEnd AS SMALLDATETIME)+1  
  --and Customer.CUSTNAME like case when @lcCust ='*' then '%' else @lcCust+'%' end --11/06/15 DRP:  replaced by the below  
  AND EXISTS (select 1 from @Customer t INNER JOIN customer c ON t.custno=c.custno WHERE c.custno=somain.custno)  
   
GROUP BY  CUSTOMER.CUSTNAME,CUSTOMER.CUSTNO, SOMAIN.sono, SOMAIN.ORDERDATE, SOMAIN.PONO, SOMAIN.ORD_TYPE, SOMAIN.ACKPO_DOC, SOMAIN.IS_RMA  
ORDER BY custname,sono  
   
END  