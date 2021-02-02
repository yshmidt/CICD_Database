-- =============================================
-- Author:		Bill Blake
-- Create date: <Create Date,,>
-- Description:	Check if invoice is part of the existsing batch
-- Modified:	03/31/15 YS revision was getting value from poitems, need to get it from inventor when possible 
--				07/24/15 VL re-added the changes did 02/09/15 that was lost:02/09/15 VL added CostEachFC, ExtensionFC and Item_totalFC
-- 10/19/15 YS added back item_desc column for the misc items added during the reconciliation
-- 03/28/16 YS replace recvqty and rejqty with ReceivedQty and FailedQty
-- 11/16/16 VL added presentation fields
-- 12/01/16 YS added partmfgr and mfgr_pt_no from porecdtl
-- 02/06/17 VL found we had comment but the item_desc was still using SPACE(45), changed to sinvdetl.item_desc
-- =============================================
CREATE PROCEDURE [dbo].[SInvoice_det_view]
	-- Add the parameters for the stored procedure here
	@gcsInv_uniq as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 03/28/16 YS replace recvqty and rejqty with ReceivedQty and FailedQty
	--				07/24/15 VL re-added the changes did 02/09/15 that was lost:02/09/15 VL added CostEachFC, ExtensionFC and Item_totalFC
	SELECT Sinvdetl.sdet_uniq, Sinvdetl.sinv_uniq, Sinvdetl.uniqlnno,
  Sinvdetl.transno, Sinvdetl.uniqdetno, POITEMS.ponum,
  Sinvdetl.trans_date, PORECDTL.RECEIVERNO, Sinvoice.suppkno, PoMain.conum,
  POITEMS.itemno, ISNULL(Inventor.part_no,Poitems.PART_NO) as Part_no,
  -- 10/19/15 YS added back item_desc column for the misc items added during the reconciliation
  ISNULL(Inventor.DESCRIPT,Poitems.DESCRIPT) as item_desc,
  ISNULL(Inventor.part_class,Poitems.PART_CLASS) as Part_class, 
  -- 12/01/16 YS added partmfgr and mfgr_pt_no from porecdtl
  --PoItems.partmfgr, 
  Porecdtl.Partmfgr,porecdtl.mfgr_pt_no,
  PoItems.ord_qty, 
  porecdtl.ReceivedQty,porecdtl.FailedQty,
  Sinvdetl.acpt_qty, PoItems.Ord_Qty - PoItems.Acpt_Qty as curr_balln, Sinvdetl.costeach,
  Sinvdetl.is_tax, PoItems.overage, Sinvdetl.gl_nbr, 
  ISNULL(Inventor.part_type,poitems.PART_TYPE) as Part_type,
  PoItems.uniq_key,Porecdtl.U_OF_MEAS,Porecdtl.PUR_UOFM,
  ISNULL(Inventor.Matl_cost,CAST(0.00 as numeric(13,5))) as Matl_cost, 
  ISNULL(Inventor.LABORCOST,CAST(0.00 as numeric(13,5))) as LABORCost,
  ISNULL(Inventor.OVERHEAD,CAST(0.00 as numeric(13,5))) as OverHead,
  ISNULL(Inventor.OTHERCOST2,CAST(0.00 as numeric(13,5))) as OtherCost2,
  ISNULL(Inventor.Other_cost,CAST(0.00 as numeric(13,5))) as Other_cost,  
  ROUND(Sinvdetl.acpt_qty*Sinvdetl.costeach,2) AS extension,
  CAST(1 as bit) AS yesno, 
   --03/31/15 YS revision was getting value from poitems, need to get it from inventor when possible 
  ISNULL(Inventor.Revision,PoItems.revision) as Revision,
  PoItems.Ord_Qty - PoItems.rej_Qty AS balqty, PoItems.Rej_Qty AS totrejqty, PoItems.Recv_Qty AS totrecv_qt,
  POITEMS.ORD_QTY as totord_qty, Sinvdetl.dmr_no, Sinvdetl.rma_date,
  Sinvdetl.ret_qty, Sinvdetl.trans_no, Sinvdetl.item_total,
  Sinvdetl.loc_uniq, Sinvdetl.orgacptqty,
  Sinvdetl.COSTEACHFC, ROUND(Sinvdetl.acpt_qty*Sinvdetl.COSTEACHFC,2) AS extensionFC, Sinvdetl.item_totalFC,
   -- 11/16/16 VL added presentation fields
  ISNULL(Inventor.Matl_costPR,CAST(0.00 as numeric(13,5))) as Matl_costPR, 
  ISNULL(Inventor.LABORCOSTPR,CAST(0.00 as numeric(13,5))) as LABORCostPR,
  ISNULL(Inventor.OVERHEADPR,CAST(0.00 as numeric(13,5))) as OverHeadPR,
  ISNULL(Inventor.OTHERCOST2PR,CAST(0.00 as numeric(13,5))) as OtherCost2PR,
  ISNULL(Inventor.Other_costPR,CAST(0.00 as numeric(13,5))) as Other_costPR,  
  Sinvdetl.COSTEACHPR, ROUND(Sinvdetl.acpt_qty*Sinvdetl.COSTEACHPR,2) AS extensionPR, Sinvdetl.item_totalPR
 FROM 
    SINVOICE INNER JOIN  SINVDETL ON SInvoice.sInv_Uniq = SInvDetl.Sinv_Uniq 
    INNER JOIN PoREcDtl ON Sinvoice.receiverno = PORECDTL.RECEIVERNO  AND Sinvdetl.Uniqlnno=Porecdtl.UNIQLNNO 
    inner join POITEMS ON PORECDTL.UNIQLNNO = POITEMS.Uniqlnno
    inner join Pomain  on POITEMS.PONUM = POMAIN.Ponum
    LEFT OUTER JOIN Inventor on POITEMS.UNIQ_KEY = INVENTOR.Uniq_Key
    WHERE Sinvdetl.sinv_uniq = @gcsInv_uniq
 UNION
 SELECT Sinvdetl.sdet_uniq, Sinvdetl.sinv_uniq, Sinvdetl.uniqlnno,
  Sinvdetl.transno, Sinvdetl.uniqdetno, SPACE(15) as ponum,
  Sinvdetl.trans_date, SPACE(10) as RECEIVERNO,SPACE(15) as suppkno, 
  CAST(0 as numeric(3)) as conum, SPACE(3) as itemno, SPACE(25) as Part_no,
 -- 10/19/15 YS added back item_desc column for the misc items added during the reconciliation
 -- 02/06/17 VL found we had comment but the item_desc was still using SPACE(45), changed to sinvdetl.item_desc
  sinvdetl.item_desc as item_desc, SPACE(8) Part_class, 
  -- 12/01/16 YS added partmfgr and mfgr_pt_no from porecdtl
  SPACE(8) as partmfgr, space(30) as mfgr_pt_no, CAST(0.00 as numeric(10,2)) as ord_qty, 
  CAST(0.00 as numeric(10,2)) as RecvQty, CAST(0.00 as numeric(10,2)) as RejQty,
  Sinvdetl.acpt_qty, CAST(0.00 as numeric(10,2)) as curr_balln, Sinvdetl.costeach,
  Sinvdetl.is_tax, CAST(0.00 as numeric(5,2)) as overage, Sinvdetl.gl_nbr, 
  SPACE(8) as Part_type,SPACE(10) as uniq_key,SPACE(4) as U_OF_MEAS,SPACE(4) as PUR_UOFM,
  CAST(0.00 as numeric(13,5)) as Matl_cost, 
  CAST(0.00 as numeric(13,5)) as LABORCost,
  CAST(0.00 as numeric(13,5)) as OverHead,
  CAST(0.00 as numeric(13,5)) as OtherCost2,
  CAST(0.00 as numeric(13,5)) as Other_cost,  
  CAST(0.00 as NUMERIC(13,2)) AS extension,
  CAST(1 as bit) AS yesno, 
  SPACE(8) as revision,
  CAST(0.00 as numeric(10,2)) as balqty, 
  CAST(0.00 as numeric(10,2)) AS totrejqty, 
  CAST(0.00 as numeric(10,2)) AS totrecv_qt,
  CAST(0.00 as numeric(10,2)) as totord_qty, 
  Sinvdetl.dmr_no, Sinvdetl.rma_date,
  Sinvdetl.ret_qty, Sinvdetl.trans_no, Sinvdetl.item_total,
  Sinvdetl.loc_uniq, Sinvdetl.orgacptqty   ,
  Sinvdetl.COSTEACHFC, CAST(0.00 as NUMERIC(13,2)) AS extensionFC, Sinvdetl.item_totalFC,
  -- 11/16/16 VL added presentation fields
  CAST(0.00 as numeric(13,5)) as Matl_costPR, 
  CAST(0.00 as numeric(13,5)) as LABORCostPR,
  CAST(0.00 as numeric(13,5)) as OverHeadPR,
  CAST(0.00 as numeric(13,5)) as OtherCost2PR,
  CAST(0.00 as numeric(13,5)) as Other_costPR,  
  Sinvdetl.COSTEACHPR, CAST(0.00 as NUMERIC(13,2)) AS extensionPR, Sinvdetl.item_totalPR              
  FROM  Sinvdetl
   WHERE Sinvdetl.sinv_uniq = @gcsInv_uniq
   AND UNIQLNNO=' '
   

END