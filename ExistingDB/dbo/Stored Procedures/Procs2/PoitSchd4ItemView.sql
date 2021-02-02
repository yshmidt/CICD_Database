-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/25/10
-- Description:	Get PO schedule information for one item
-- =============================================
CREATE PROCEDURE dbo.PoitSchd4ItemView 
	-- Add the parameters for the stored procedure here
	@pcUniqLnno char(10)= ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	SELECT Poitschd.schd_date, Poitschd.req_date, Poitschd.schd_qty,
      Poitschd.balance, Poitschd.location,
       Poitschd.requesttp, Poitschd.gl_nbr, Poitschd.uniqlnno,
  Poitschd.uniqdetno, Poitschd.recdqty, Poitschd.uniqwh,
  Poitschd.woprjnumber, Poitschd.requestor, Poitschd.ponum,
  Poitschd.completedt, Poitschd.origcommitdt, Poitschd.schdnotes
  FROM poitschd 
  WHERE  Poitschd.uniqlnno =  @pcUniqLnno  
  ORDER BY Poitschd.schd_date


END