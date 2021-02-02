CREATE PROC [dbo].[SupplierConfirmView] 
	@lcSupId AS char(10)=' '
AS SELECT ShipBill.*, 
 RTRIM(Ccontact.firstname)+' '+RTRIM(Ccontact.lastname) AS AttnName
FROM Shipbill LEFT OUTER JOIN ccontact 
   ON  (Shipbill.custno+'S'+RTRIM(Shipbill.attention)) = ( Ccontact.custno+Ccontact.type+Ccontact.cid )
WHERE ShipBill.Custno = @lcSupId AND Recordtype='C' 