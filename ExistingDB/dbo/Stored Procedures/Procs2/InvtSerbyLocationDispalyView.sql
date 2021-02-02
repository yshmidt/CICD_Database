
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <05/05/2010>
-- Description:	<Show Serial Numbers by Uniq Key with Mfgr Warehouse and Location information>
-- Modified: 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[InvtSerbyLocationDispalyView]
	@lcw_key char(10)=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--10/09/14 YS removed invtmfhd table and replaced with 2 new tables
	SELECT Invtser.serialno, M.Partmfgr,M.Mfgr_pt_no,
	Warehous.Warehouse,Invtmfgr.Location,InvtSer.LotCode,InvtSer.ExpDate,
	InvtSer.Reference,InvtSer.Ponum,Invtser.isreserved, Invtser.id_key, Invtser.id_value
	FROM invtser , InvtMPNLink L,MfgrMaster M,Invtmfgr ,warehous
	 WHERE Invtser.uniqMfgrHd =  L.UniqMfgrhd
	and Invtser.id_key='W_KEY'
	and Invtser.id_value=@lcW_key	
	and InvtSer.id_value=Invtmfgr.w_key 
	and L.is_deleted=0 and m.IS_DELETED=0
	and invtmfgr.is_deleted=0
	and warehous.uniqwh=invtmfgr.uniqwh
	ORDER BY PartMfgr,Mfgr_pt_no,Warehouse,Location,SerialNo

	 


END