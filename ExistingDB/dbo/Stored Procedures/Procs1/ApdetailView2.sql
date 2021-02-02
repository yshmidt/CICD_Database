-- =============================================
-- Author:		Bill Blake
-- Create date:
-- Description:	get apdetails for the invoice. Used in DM
-- 12/05/13 YS check if another DM for the same detail line was created and remove if balance is 0 or decrease the amount
-- 06/26/15 VL added FC fields 
-- 06/29/15 VL added is_tax field
-- 01/06/16 VL remove Tax_pct field
-- 11/30/16 VL added presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[ApdetailView2] 
      @gcUniqApHead as Char(10)=''

AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT Apdetail.uniqapdetl, Apdetail.uniqaphead, 
  Apdetail.shipno, Apdetail.item_no, Apdetail.item_desc, 
  -- 12/05/132 YS calculate balance if another DM was created for the same line
	CASE WHEN APDMDETL.QTY_EACH IS null THEN  Apdetail.qty_each ELSE Apdetail.qty_each- APDMDETL.QTY_EACH END as Qty_each,
  Apdetail.price_each, Apdetail.is_tax, 
  CASE WHEN APDMDETL.ITEM_TOTAL IS null THEN Apdetail.item_total ELSE Apdetail.item_total-APDMDETL.ITEM_TOTAL END as Item_total, 
  Apdetail.gl_nbr, Apdetail.item_note,
  Apdetail.trans_no, Gl_nbrs.Gl_Descr, Apdetail.price_eachFC, 
  CASE WHEN APDMDETL.ITEM_TOTALFC IS null THEN Apdetail.item_totalFC ELSE Apdetail.item_totalFC-APDMDETL.ITEM_TOTALFC END as Item_totalFC, Apdetail.Is_tax,
  -- 11/30/16 VL added presentation currency fields
  Apdetail.price_eachPR, CASE WHEN APDMDETL.ITEM_TOTALPR IS null THEN Apdetail.item_totalPR ELSE Apdetail.item_totalPR-APDMDETL.ITEM_TOTALPR END as Item_totalPR
 FROM apdetail INNER JOIN  Gl_Nbrs ON Gl_Nbrs.Gl_Nbr = ApDetail.Gl_Nbr
	LEFT OUTER JOIN APDMDETL ON APDETAIL.UNIQAPDETL =APDMDETL.UNIQAPDETL   
 WHERE ApDetail.uniqApHead = @gcUniqApHead
	and (APDMDETL.ITEM_TOTAL is null or Apdetail.item_total-APDMDETL.ITEM_TOTAL>0)
      
END