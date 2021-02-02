-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <01/10/2011>
-- Description:	HeadRejView
-- 07/23/14 YS added new column to porecdtl table to indicate if receiving process complete or waiting for inspection 
-- 02/03/17 YS comment out the code , changes in the DMR module
-- =============================================
CREATE PROCEDURE [dbo].[HeadRejView] 
	-- Add the parameters for the stored procedure here
	@lcuniqrecdtl char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/23/14 YS make sure only 'complete' receiver is selected
	--SELECT Poitems.ponum, Poitems.itemno, Poitems.uniq_key, Poitems.uniqlnno,
	--Poitems.acpt_qty, Poitems.ord_qty-Poitems.acpt_qty AS balance,
	--Porecdtl.recvqty, Porecdtl.rejqty, Porecdtl.receiverno, Porecdtl.transno,
	--Porecdtl.rejreason, Porecdtl.uniqrecdtl,
	--CASE WHEN Poitems.uniq_key=' ' THEN Poitems.part_no ELSE Inventor.part_no END AS part_view,
	--CASE WHEN Poitems.uniq_key=' ' THEN Poitems.revision ELSE Inventor.revision END AS rev_view,
	--CASE WHEN Poitems.uniq_key=' ' THEN Poitems.part_class ELSE Inventor.part_class END AS class_view,
	--CASE WHEN Poitems.uniq_key=' ' THEN Poitems.part_type ELSE Inventor.part_type END AS type_view,
	--CASE WHEN Poitems.uniq_key=' ' THEN Poitems.descript ELSE Inventor.descript END AS descript_view,
	--Poitems.u_of_meas AS uom_view,Porecdtl.accptqty, Porecdtl.porecpkno, Poitems.poittype,
	--Porecdtl.recvdate, Porecdtl.uniqmfgrhd, Porecdtl.partmfgr,
	--Porecdtl.mfgr_pt_no, ISNULL(Inventor.serialyes,CAST(0 as bit)) AS serialyes,
	--Inventor.matl_cost,Inventor.STDCOST, Poitems.pur_uofm AS puom_view,Poitems.inspectionote
	--FROM inventor 
 --   RIGHT OUTER JOIN  poitems 
 --   INNER JOIN porecdtl 
	--ON  Poitems.uniqlnno = Porecdtl.uniqlnno 
	--ON  Inventor.uniq_key = Poitems.uniq_key
	--WHERE  Porecdtl.uniqrecdtl = @lcuniqrecdtl
	

END