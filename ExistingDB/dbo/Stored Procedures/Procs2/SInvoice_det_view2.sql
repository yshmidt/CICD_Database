CREATE PROCEDURE [dbo].[SInvoice_det_view2]
-- 06/13/18 structure of the receiving tables are changed. Make it work here and make sure that po reconciliation is still working
	-- Add the parameters for the stored procedure here.  Used for non-Inventory items
	@gcsInv_uniq as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Sinvdetl.sdet_uniq, Sinvdetl.sinv_uniq, Sinvdetl.uniqlnno,
  Sinvdetl.transno, Sinvdetl.uniqdetno, POITEMS.ponum,
  Sinvdetl.trans_date, PORECDTL.RECEIVERNO, Sinvoice.suppkno, PoMain.conum,
  POITEMS.itemno, PoItems.Descript as PO_Desc,
  -- 06/13/18 structure of the receiving tables are changed. Make it work here and make sure that po reconciliation is still working
  PoItems.partmfgr, PoItems.ord_qty, PORECDTL.receivedQty, PORECDTL.FailedQty,
  Sinvdetl.acpt_qty, PoItems.Ord_Qty - PoItems.Acpt_Qty as curr_balln, Sinvdetl.costeach,
  Sinvdetl.is_tax, PoItems.overage, Sinvdetl.gl_nbr, 
  PoItems.uniq_key,
  ROUND(Sinvdetl.acpt_qty*Sinvdetl.costeach,2) AS extension,
  1 AS yesno, PoItems.revision,
  PoItems.Ord_Qty - PoItems.rej_Qty AS balqty, PoItems.Rej_Qty AS totrejqty, PoItems.Recv_Qty AS totrecv_qt,
  POITEMS.ORD_QTY as totord_qty, Sinvdetl.dmr_no, Sinvdetl.rma_date,
  Sinvdetl.ret_qty, Sinvdetl.trans_no, Sinvdetl.item_total,
  Sinvdetl.loc_uniq, Sinvdetl.orgacptqty
 FROM 
    sinvdetl, sInvoice, PoRecDtl
    inner join POITEMS ON PORECDTL.UNIQLNNO = POITEMS.Uniqlnno
    inner join Pomain  on POITEMS.PONUM = POMAIN.Ponum
  WHERE  SInvoice.sInv_Uniq = SInvDetl.Sinv_Uniq 
	and Sinvdetl.sinv_uniq = @gcsInv_uniq
	and POITEMS.UNIQ_KEY = ' '
	and SinvDetl.uniqlnno = PoRecDtl.uniqlnno
END