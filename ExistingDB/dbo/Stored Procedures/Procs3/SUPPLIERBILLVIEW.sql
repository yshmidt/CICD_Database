
-- 01/14/15 VL added Address3 and address4

CREATE proc [dbo].[SUPPLIERBILLVIEW] 
AS
SELECT DISTINCT Shipbill.shipto, Shipbill.address1, Shipbill.city,
  Shipbill.linkadd, Shipbill.address2, Shipbill.ADDRESS3, Shipbill.address4, Shipbill.state, Shipbill.zip,
  Shipbill.country, Shipbill.phone, Shipbill.fax, Shipbill.e_mail,
  Shipbill.attention, Shipbill.fob, Shipbill.shipcharge, Shipbill.shipvia,
  Shipbill.transday, Shipbill.billacount, Shipbill.shiptime,
  Shipbill.ship_days, Shipbill.recv_defa, Shipbill.confirm,
  Shipbill.taxexempt,Recordtype
 FROM 
     shipbill
 WHERE   Shipbill.custno =''
   AND  Shipbill.recordtype = 'P'  
   

--