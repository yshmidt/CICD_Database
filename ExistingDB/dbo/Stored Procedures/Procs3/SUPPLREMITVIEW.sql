﻿ --[SUPPLREMITVIEW] '0000000006'  
-- 01/26/15 VL added address3 and address4    
--07/18/2019 Vijay G :Add extra filter condition to get confirmTo  
CREATE proc [dbo].[SUPPLREMITVIEW] @gcsupid char(10) ='',@gr_link char(10) =''    
AS    
 SELECT DISTINCT Shipbill.shipto, Shipbill.address1, Shipbill.city,    
  Shipbill.linkadd, Shipbill.address2, Shipbill.address3, Shipbill.address4, Shipbill.state, Shipbill.zip,    
  Shipbill.country, Shipbill.phone, Shipbill.fax, Shipbill.e_mail,    
  Shipbill.attention, Shipbill.fob, Shipbill.shipcharge, Shipbill.shipvia,    
  Shipbill.transday, Shipbill.billacount, Shipbill.shiptime,    
  Shipbill.ship_days, Shipbill.recv_defa, Shipbill.confirm,    
  Shipbill.taxexempt,    
  RTRIM(Ccontact.lastname)+' '+RTRIM(Ccontact.firstname) AS name    
 FROM     
     shipbill     
    LEFT OUTER JOIN ccontact     
   ON  ( Shipbill.custno+'S'+RTRIM(Shipbill.attention) ) = ( Ccontact.custno+Ccontact.type+Ccontact.cid )    
 WHERE   Shipbill.custno = @gcsupid     
   AND  Shipbill.recordtype = 'R'    
   --07/08/2019 Vijay G :Add extra filter condition to get confirmTo  
   AND  ((@gr_Link='' OR @gr_Link=NULL) OR (Shipbill.linkadd = @gr_Link))  
  
    
    