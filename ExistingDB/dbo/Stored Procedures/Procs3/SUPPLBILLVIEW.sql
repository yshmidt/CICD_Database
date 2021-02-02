
CREATE proc [dbo].[SUPPLBILLVIEW] (@gb_link char(10) ='')
AS
SELECT DISTINCT Shipbill.shipto, Shipbill.address1, Shipbill.city,
  Shipbill.linkadd, Shipbill.address2, Shipbill.state, Shipbill.zip,
  Shipbill.country, Shipbill.phone, Shipbill.fax, Shipbill.e_mail,
  Shipbill.attention, Shipbill.fob, Shipbill.shipcharge, Shipbill.shipvia,
  Shipbill.transday, Shipbill.billacount, Shipbill.shiptime,
  Shipbill.ship_days, Shipbill.recv_defa, Shipbill.confirm,
  Shipbill.taxexempt
 FROM 
     shipbill
 WHERE   Shipbill.custno =''
   AND  Shipbill.recordtype = 'P'  
   AND  Shipbill.linkadd =  @gb_link 

--select * from supplreceivview('_0TG0WZ7T2')