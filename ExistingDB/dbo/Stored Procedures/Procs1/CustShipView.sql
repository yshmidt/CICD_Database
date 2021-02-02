-- 01/14/15 VL added ORDER BY Shipto  
-- 06/19/20 VL now the shipto is tight to the bill to, so need to get info from AddressLinkTable table, also added 2nd parameter @Blinkadd  
-- 06/25/20 Shivshankar P : Added condition IF ELSE when @Blinkadd is empty  
CREATE proc [dbo].[CustShipView]   
 @lcCustno as char(10)='', @Blinkadd as char(10)=' '  
AS   
IF (TRIM(@Blinkadd) <> '')  
	SELECT * FROM Shipbill   
	WHERE Custno = @lcCustno   
	AND Recordtype='S'   
	AND EXISTS(SELECT 1 FROM AddressLinkTable A WHERE BillRemitAddess = @Blinkadd AND Shipbill.Linkadd = A.ShipConfirmToAddress)  
	ORDER BY Shipto  
ELSE 
	SELECT * FROM Shipbill   
	WHERE Custno = @lcCustno   
	AND Recordtype='S'   
	ORDER BY Shipto 
  