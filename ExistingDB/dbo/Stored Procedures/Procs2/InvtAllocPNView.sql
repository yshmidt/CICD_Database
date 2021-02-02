-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <04/13/2011>
-- Description:	<Allocations by Part number>
-- Modified:	10/09/14 YS removed invtmfhd table and replace with 2 new tables
--- 02/02/17 YS removed serialno column from the table
-- =============================================
CREATE PROCEDURE [dbo].[InvtAllocPNView]
	-- Add the parameters for the stored procedure here
	@lcUniq_key char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--10/09/14 YS removed invtmfhd table and replace with 2 new tables
    -- Insert statements for procedure here
	SELECT Inventor.part_no, Inventor.revision, Inventor.descript,
	Inventor.part_sourc, Inventor.part_class, Inventor.part_type,
	CAST(0.00 as numeric (12,2)) AS reqqty, PJCTMAIN.PrjNumber ,
	Warehous.warehouse, Invtmfgr.location, M.partmfgr,
	M.mfgr_pt_no, Invtmfgr.qty_oh-Invtmfgr.reserved AS availqty,
	Invt_res.qtyalloc, Invt_res.lotcode, Invt_res.expdate, Invt_res.wono,
	Invt_res.reference, Invt_res.w_key, Invtmfgr.qty_oh, Invtmfgr.reserved,
	Invt_res.datetime, Invt_res.saveinit, Invt_res.invtres_no,
	Invt_res.ponum, Invt_res.refinvtres, Invt_res.fk_prjunique,
	--- 02/02/17 YS removed serialno column from the table
	--Invt_res.serialno, Invt_res.serialuniq, 
	Invt_res.sono, Invt_res.uniqueln
	FROM invt_res inner join inventor on INVT_RES.UNIQ_KEY =INVENTOR.UNIQ_KEY 
		inner join invtmfgr on invt_res.w_key=invtmfgr.w_key
		inner join InvtMPNLink L on INVTMFGR.UNIQMFGRHD = l.UNIQMFGRHD 
		inner join MfgrMaster M ON l.mfgrmasterid=m.mfgrmasterid
		inner join warehous on INVTMFGR.UNIQWH=WAREHOUS.UNIQWH 
		left outer join PjctMain on INVT_RES.FK_PRJUNIQUE =PJCTMAIN.PRJUNIQUE  
	WHERE  Invt_res.uniq_key = @lcUniq_key
   
END