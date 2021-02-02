-- ==========================================================================================        
-- Author:  <Nitesh B>      
-- Create date: 12/19/2019 
-- Description: Get all Bill addresses linked with customer 
-- EXEC [dbo].[GetCustomerBillAddress] '0000000001'     
-- ==========================================================================================        
CREATE PROCEDURE [dbo].[GetCustomerBillAddress]     
  @custno AS CHAR(10)=''   
AS    
  SELECT Shipbill.*  
  FROM SHIPBILL       
  WHERE CUSTNO = @custno AND Recordtype='B'    
  ORDER BY Shipto