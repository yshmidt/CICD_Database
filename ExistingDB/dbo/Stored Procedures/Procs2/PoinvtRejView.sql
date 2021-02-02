-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <01/11/2011>
-- Description:	Bring information for items located in MRB warehouse. 
-- Used in the DMRAdd screen when From Inventory is selected
-- Modified: 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
-- 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- 02/03/17 YS structure changes, not sure if we will use this in the future at all. Fix for now.
-- 10/11/19 VL changed part_no from char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[PoinvtRejView] 
	-- Add the parameters for the stored procedure here
	-- 10/11/19 VL changed part_no from char(25) to char(35)
	@lcPart_No varchar(35)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--07/23/14 YS make sure only complete receiver is selected
	--10/09/14 YS removed invtmfhd table and replaced with 2 new tables
	--02/03/17 YS structure changes
	SELECT Poitems.ponum,  Poitems.itemno, Supinfo.supname,
		Porecdtl.receiverno, Porecdtl.AcceptedQty, Invtmfgr.qty_oh,Pomain.conum,
		Inventor.part_no, Inventor.revision, Inventor.uniq_key, Invtmfgr.w_key,
		M.partmfgr, M.mfgr_pt_no, Invtmfgr.location, Invtmfgr.UniqWh,
		Warehous.whno,Porecdtl.FailedQty, Porecdtl.uniqrecdtl, 
		Porecdtl.uniqlnno, Pomain.uniqsupno
	FROM inventor, invtmfgr, warehous,
         poitems,porecdtl,InvtMPNLink L,MfgrMaster M,supinfo,pomain 
	WHERE Inventor.part_no LIKE '%'+@lcPart_No+'%'
    AND  Warehous.warehouse = 'MRB' 
    AND  Invtmfgr.location=' '
    AND  Invtmfgr.Uniqwh = Warehous.Uniqwh
    AND  Inventor.uniq_key = Invtmfgr.uniq_key 
    AND  Poitems.uniq_key = Inventor.uniq_key 
    AND  Pomain.ponum = Poitems.ponum
    AND  Supinfo.uniqsupno = Pomain.uniqsupno 
    AND  Porecdtl.uniqmfgrhd = L.uniqmfgrhd
    AND  L.uniqmfgrhd = Invtmfgr.uniqmfgrhd
	AND  L.mfgrMasterId=L.mfgrMasterId
    AND  Porecdtl.uniqlnno = Poitems.uniqlnno 
    AND  Porecdtl.AcceptedQty <>  0 
	AND  Invtmfgr.qty_oh <>  0 

END