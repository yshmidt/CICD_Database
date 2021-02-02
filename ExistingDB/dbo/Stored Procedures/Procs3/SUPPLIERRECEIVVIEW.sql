
-- 01/14/15 VL added UseDefaultTax field for GST, Address3, address4

CREATE PROC [dbo].[SUPPLIERRECEIVVIEW] 
AS
SELECT DISTINCT Shipbill.shipto, Shipbill.address1, Shipbill.city,
  Shipbill.linkadd, Shipbill.address2, Shipbill.ADDRESS3, Shipbill.ADDRESS4, Shipbill.state, Shipbill.zip,
  Shipbill.country, Shipbill.phone, Shipbill.fax, Shipbill.e_mail,
  Shipbill.attention, Shipbill.fob, Shipbill.shipcharge, Shipbill.shipvia,
  Shipbill.transday, Shipbill.billacount, Shipbill.shiptime,
  Shipbill.ship_days, Shipbill.recv_defa, Shipbill.confirm,
  Shipbill.taxexempt,RecordType, Shipbill.UseDefaultTax
 FROM 
     shipbill
 WHERE Shipbill.custno ='' 
   AND  Shipbill.recordtype = 'I'
   