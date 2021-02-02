-- ==========================================================================================      
-- Author:  <Nilesh Sa>    
-- Create date: 4/9/2019
-- Description: Get Bill address if ship address is linked to Bill to address
-- EXEC [dbo].[GetBillAddress] '0000000001','_47D0I4QRJ'   
-- ==========================================================================================      
CREATE PROCEDURE [dbo].[GetBillAddress]   
  @custno AS CHAR(10)='',
  @shipLinkAdd AS CHAR(10)=''  
AS  
  SELECT Shipbill.*
  FROM SHIPBILL   
  OUTER APPLY(
 	SELECT BillRemitAddess FROM AddressLinkTable WHERE ShipConfirmToAddress = @shipLinkAdd
  ) AS BillAddressTable
  WHERE CUSTNO = @custno  AND SHIPBILL.LINKADD IN (BillAddressTable.BillRemitAddess)
  AND Recordtype='B'  
  ORDER BY Shipto