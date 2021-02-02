-- =============================================
-- Author:		David Sharp
-- Create date: 10/20/2015
-- Description:	Detailed results for receiveing label by receiver
-- 
-- =============================================
CREATE PROCEDURE [dbo].[PoRecLocDetailView]
	-- Add the parameters for the stored procedure here
	@lcReceiverno char(10)=' '  
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
 SELECT INVENTOR.part_no,INVENTOR.revision,INVENTOR.descript,
	Poitschd.schd_date, Poitschd.balance, Poitschd.woprjnumber,Poitschd.requestor, Poitschd.schdnotes,Poitschd.requesttp, POITSCHD.PONUM, 
	Porecloc.accptqty,Porecloc.rejqty, Porecloc.uniqdetno, Porecloc.loc_uniq, Porecloc.receiverno, Porecloc.fk_uniqrecdtl, Porecloc.uniqwh,
		 Porecloc.sinv_uniq, Porecloc.sdet_uniq, Porecloc.accptqty-0 AS old_accptqty, Porecloc.rejqty-0 AS old_rejqty,Porecloc.sourceDev,
	Warehous.warehouse,Porecloc.location,WAREHOUS.WH_GL_NBR 
 FROM porecloc 
    INNER JOIN poitschd 
   ON  Porecloc.uniqdetno = Poitschd.uniqdetno 
    LEFT OUTER JOIN warehous 
   ON  Porecloc.uniqwh = Warehous.uniqwh
	INNER JOIN POITEMS ON POITEMS.UNIQLNNO=POITSCHD.UNIQLNNO
	INNER JOIN INVENTOR ON inventor.uniq_key=POITEMS.uniq_key
 WHERE  Porecloc.receiverno = @lcReceiverno 
 ORDER BY Poitschd.schd_date
END