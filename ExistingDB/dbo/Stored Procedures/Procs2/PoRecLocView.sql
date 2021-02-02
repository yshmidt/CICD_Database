-- =============================================
-- Author:		Yelena Shmidt	
-- Create date: <10/28/2010>
-- Description:	<PoRecLocView for PO receiving module>
-- Modified: 05/15/14 YS added sourcedev column to porecdtl = 'D' when updated from desktop
-- =============================================
CREATE PROCEDURE [dbo].[PoRecLocView]
	-- Add the parameters for the stored procedure here
	@lcReceiverno char(10)=' '  
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Poitschd.schd_date, Poitschd.balance, Porecloc.accptqty,
  Porecloc.rejqty, Poitschd.requestor, Poitschd.woprjnumber,
  Poitschd.schdnotes, Porecloc.uniqdetno, Porecloc.loc_uniq,
  Porecloc.receiverno, Porecloc.fk_uniqrecdtl, Porecloc.uniqwh,
  Porecloc.location, Porecloc.sinv_uniq, Porecloc.sdet_uniq,
  Poitschd.requesttp, Warehous.warehouse,WAREHOUS.WH_GL_NBR , 
  Porecloc.accptqty-0 AS old_accptqty, Porecloc.rejqty-0 AS old_rejqty,Porecloc.sourceDev
 FROM porecloc 
    INNER JOIN poitschd 
   ON  Porecloc.uniqdetno = Poitschd.uniqdetno 
    LEFT OUTER JOIN warehous 
   ON  Porecloc.uniqwh = Warehous.uniqwh
 WHERE  Porecloc.receiverno = @lcReceiverno 
 ORDER BY Poitschd.schd_date
END