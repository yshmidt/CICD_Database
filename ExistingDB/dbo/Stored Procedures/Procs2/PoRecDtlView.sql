-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <10/28/2010>
-- Description:	<PoRecdtlView - PO Receiving Module>
-- Modified: 05/15/14 YS added sourcedev column to porecdtl = 'D' when updated from desktop
---			07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
-- -- 10/09/14 YS removed Invtmfhd table and replaced with 2 new tables
-- 05/28/15 YS remove ReceivingStatus
--			01/29/15 VL Added Fcused_uniq and Fchist_key
--03/28/16 YS removed transno,rejreason, accptqty,doc_uniq columns. Renamed recvqty, rejqty. Moved recinit,editinit to the receiverheader
--			11/15/16 VL Added PRFcused_uniq and FuncFcused_uniq fields
-- 07/12/18 YS supname field name encreased 30 to 50
-- =============================================
CREATE PROCEDURE [dbo].[PoRecDtlView]
	-- Add the parameters for the stored procedure here
	@lcReceiverno char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 10/09/14 YS removed Invtmfhd table and replaced with 2 new tables
	--03/28/16 YS removed transno,rejreason, doc_uniq columns. Renamed recvqty, rejqty
	SELECT Poitems.uniq_key, ISNULL(Inventor.Part_no,Poitems.part_no) as Part_no, 
	ISNULL(Inventor.Revision,Poitems.revision) as Revision,
	ISNULL(Inventor.Part_class,Poitems.part_class) as Part_class, 
	ISNULL(Inventor.Part_type,Poitems.part_type) as Part_type, 
	ISNULL(Inventor.Descript,Poitems.descript) as Descript,
	Porecdtl.uniqlnno, 
	--03/28/16 YS removed transno,rejreason, doc_uniq columns. Renamed recvqty, rejqty
	--Porecdtl.transno, 
	Porecdtl.recvdate,
	Porecdtl.porecpkno, 
	--03/28/16 YS removed transno,rejreason, doc_uniq columns. Renamed recvqty, rejqty
	--Porecdtl.rejqty, Porecdtl.rejreason,
	porecdtl.FailedQty,
	--Porecdtl.recvqty, Porecdtl.accptqty, 
	Porecdtl.ReceivedQty,porecdtl.AcceptedQty,
	Porecdtl.u_of_meas,
	Porecdtl.pur_uofm, Porecdtl.receiverno, 
	--Porecdtl.dock_uniq,
	Poitems.itemno, Poitems.ord_qty-Poitems.acpt_qty AS balance,
	-- 07/12/18 YS supname field name encreased 30 to 50
	SPACE(50) AS supname, Poitems.ponum, Poitems.poittype,
	--Porecdtl.recvqty-0 AS old_recvqty,
	Porecdtl.ReceivedQty-0 AS old_recvqty,
	--Porecdtl.accptqty-0 AS old_accptqty, 
	Porecdtl.AcceptedQty-0 AS old_accptqty, 
	--Porecdtl.rejqty-0 AS old_rejqty,
	Porecdtl.FailedQty-0 AS old_rejqty,
	CAST(1 as bit) AS norecon, Porecdtl.uniqrecdtl, Poitems.firstarticle,
	Poitems.inspexcept, Poitems.inspexception, Poitems.note1,
	Poitems.overage,
	Poitems.ord_qty, Poitems.acpt_qty AS qtyacptsofar, 
	--Porecdtl.recinit,
	---Porecdtl.editinit, 
	Porecdtl.editdate, Porecdtl.uniqmfgrhd,
	Porecdtl.partmfgr, Porecdtl.mfgr_pt_no, Poitems.inspexcnote,
	Poitems.inspexcdoc, 
	ISNULL(M.AUTOLOCATION,CAST(0 as bit)) AS autolocation, 
	ISNULL(M.Matltype,SPACE(10)) AS matltype, CAST(0 as bit) AS triggerreject, Poitems.package,
	ISNULL(M.LDISALLOWBUY,CAST(0 as bit)) AS ldisallowbuy, ' ' AS overwritedisallowbuy,
	--Porecdtl.recvqty-Porecdtl.recvqty AS nqpp,
	--Porecdtl.recvqty-Porecdtl.recvqty AS npkgsrecv,
	--Porecdtl.recvqty-Porecdtl.recvqty AS ordmult, 
	Poitems.uniqmfsp,porecdtl.sourceDev,
	Porecdtl.FcUsed_uniq, Porecdtl.Fchist_key, Porecdtl.PRFcused_Uniq, Porecdtl.FUNCFCUSED_UNIQ 
 FROM Porecdtl, Poitems LEFT OUTER JOIN INVENTOR ON POITEMS.UNIQ_KEY =INVENTOR.UNIQ_KEY 
	-- 10/09/14 YS removed Invtmfhd table and replaced with 2 new tables
	LEFT JOIN InvtMPNLink L ON Poitems.UniqMfgrhd=L.UniqMfgrhd
	LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
 WHERE  Porecdtl.uniqlnno = Poitems.uniqlnno
   AND  Porecdtl.receiverno =  @lcReceiverno
 ORDER BY Poitems.itemno
END