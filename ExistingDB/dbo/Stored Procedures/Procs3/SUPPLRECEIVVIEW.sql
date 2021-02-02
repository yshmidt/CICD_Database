
-- 01/20/15 VL added Shipbill.UseDefaultTax
-- 01/26/15 VL added address3 and address4
CREATE PROC [dbo].[SUPPLRECEIVVIEW] @gi_link char(10) =''
AS
SELECT DISTINCT Shipbill.shipto, Shipbill.address1, Shipbill.city,
  Shipbill.linkadd, Shipbill.address2, Shipbill.address3,Shipbill.address4,Shipbill.state, Shipbill.zip,
  Shipbill.country, Shipbill.phone, Shipbill.fax, Shipbill.e_mail,
  Shipbill.attention, Shipbill.fob, Shipbill.shipcharge, Shipbill.shipvia,
  Shipbill.transday, Shipbill.billacount, Shipbill.shiptime,
  Shipbill.ship_days, Shipbill.recv_defa, Shipbill.confirm,
  Shipbill.taxexempt, Shipbill.UseDefaultTax
 FROM 
     shipbill
 WHERE Shipbill.custno ='' 
   AND  Shipbill.recordtype = 'I'
   AND  Shipbill.linkadd =  @gi_link