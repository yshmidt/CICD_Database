CREATE PROC [dbo].[PriceAssignSalesRepView] @gUniq_key AS char(10) = ''
AS
---08/26/13 YS   changed name to varchar(200), increased length of the ccontact fields.
	SELECT CAST(RTRIM(LTRIM(Ccontact.Lastname))+', '+RTRIM(LTRIM(Ccontact.Firstname)) as varCHAR(200)) AS Name,
	  Pricsrep.commission, Pricsrep.cid, Pricsrep.uniq_key, Pricsrep.custno, PricSrepUk
 FROM 
     Prichead, Pricsrep, Ccontact
 WHERE Prichead.Uniq_key = Pricsrep.Uniq_key
   AND Prichead.Category = Pricsrep.Custno
   AND Pricsrep.Cid = Ccontact.Cid
   AND Ccontact.Type = 'R'
   AND Pricsrep.Uniq_key = @gUniq_key


