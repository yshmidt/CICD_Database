

CREATE proc [dbo].[POITSCHD4POVIEW] (@gcPoNum char(15) =null)
AS
SELECT Poitschd.schd_date, Poitschd.req_date, Poitschd.schd_qty,
  Poitschd.balance, Warehous.warehouse, Poitschd.location,
  Poitschd.requesttp, Poitschd.gl_nbr, Poitschd.uniqlnno,
  Poitschd.uniqdetno, Poitschd.recdqty, Poitschd.uniqwh,
  Poitschd.woprjnumber, Poitschd.requestor, Poitschd.ponum,
  Poitschd.completedt, Poitschd.origcommitdt, Poitschd.schdnotes
 FROM 
     poitschd 
    LEFT OUTER JOIN warehous 
   ON  Poitschd.uniqwh = Warehous.uniqwh
 WHERE  Poitschd.ponum =  @gcPoNum 
 ORDER BY Poitschd.schd_date

--exec poitschd4poview
