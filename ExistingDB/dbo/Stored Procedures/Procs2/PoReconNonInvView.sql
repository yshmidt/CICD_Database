-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
-- 05/28/15 YS remove ReceivingStatus
-- 10/19/15 YS added back item_desc column for the misc items added during the reconciliation
-- 03/28/16 YS this procedure will haver to be revritte or disgarded in the new manex_a_design. For now fix rnamed columns and added Fc columns
-- 07/11/16 VL Added PoItems.CostEachFC for MRO item
-- 11/29/16 VL Added presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[PoReconNonInvView] 
	-- Add the parameters for the stored procedure here
	@lcSinv_uniq as char(10) = ' ', @pcReceiverNo as char(10) = ' ', @pcPoNum as char(15) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
	-- make sure that only complete receiver is selected.
	--03/28/16 YS this procedure will haver to be revritte or disgarded in the new manex_a_design. For now fix rnamed columns and added Fc columns

	SELECT DISTINCT 0000000000 AS ApMast_No, PoRecLoc.AccptQty+PoRecLoc.RejQty AS Recv_Qty, 0 as YesNo, PoRecPkNo AS SupPkNo,
		PoRecLoc.AccptQty, PoRecLoc.AccptQty as Acpt_Qty, PoItSchd.Schd_Qty AS Ord_Qty, PoItSchd.Schd_Qty AS Ord_Qty1, 
		PoItems.CostEach, PoItems.Is_Tax,Poitems.tax_pct, PoItems.PoNum, PoItSchd.Balance AS Curr_Balln, Part_No, 
		-- 10/19/15 YS added back item_desc column for the misc items added during the reconciliation
		Part_Class, Part_Type, Descript AS item_Desc, PoRecLoc.UniqDetNo,Porecdtl.RecvDate AS Date, 
		PoItems.ItemNo, PoItems.Overage, PoItems.Uniq_Key, PoItems.PoItType, PoItems.Tax_Pct AS Tax_Pct1, 
		PoItems.PartMfgr, Poitschd.GL_nbr, PorecDtl.ReceiverNo, CAST(NULL as smalldatetime) as  Due_Date, 
		CAST(NULL as smalldatetime) AS InvDate, 0 AS Is_Rel_Gl, 
		PoItems.Ord_Qty - PoItems.Acpt_Qty AS BalQty, PoItems.Recv_Qty AS totrecv_qt, 
		PoItems.Rej_qty AS TotRejQty, PoItems.Ord_Qty AS TotOrd_Qty, PoItems.UniqLnNo, 
		--03/28/16 YS this procedure will haver to be revritte or disgarded in the new manex_a_design. For now fix rnamed columns and added Fc columns
		--ROUND(PoRecDtl.AccptQty * PoItems.CostEach,2) AS Extension, @lcSinv_uniq AS SInv_Uniq, space(10) AS Sdet_Uniq,
		--ROUND(PoRecDtl.AccptQty * PoItems.CostEach,2) AS item_total,PoRecLoc.loc_uniq, PoRecDtl.AccptQty AS OrgAcptQty 
		ROUND(PoRecDtl.AcceptedQty * PoItems.CostEach,2) AS Extension, @lcSinv_uniq AS SInv_Uniq, space(10) AS Sdet_Uniq,
		ROUND(PoRecDtl.AcceptedQty * PoItems.CostEach,2) AS item_total,PoRecLoc.loc_uniq, PoRecDtl.AcceptedQty AS OrgAcptQty ,
		-- 07/11/16 VL added PoItems.CostEachFC
		PoItems.CostEachFC,
		ROUND(PoRecDtl.AcceptedQty * PoItems.CostEachFC,2) AS ExtensionFC,
		ROUND(PoRecDtl.AcceptedQty * PoItems.CostEachfC,2) AS item_totalFC,
		PoRecdtl.FcUsed_uniq, PoRecdtl.Fchist_key,
		-- 11/29/16 VL Added presentation currency fields	 
		PoItems.CostEachPR,
		ROUND(PoRecDtl.AcceptedQty * PoItems.CostEachPR,2) AS ExtensionPR,
		ROUND(PoRecDtl.AcceptedQty * PoItems.CostEachPR,2) AS item_totalPR			 
	FROM PoRecDtl, PoItems, PoRecLoc, PoItSchd 
	WHERE PoRecDtl.UniqLnNo = PoItems.UniqLnNo 
		AND PoRecLoc.Fk_UniqRecDtl = PoRecDtl.UniqRecDtl 
		AND PoRecLoc.UniqDetNo = Poitschd.UniqDetNo 
		AND PoRecDtl.ReceiverNo = @pcReceiverNo
		-- 05/28/15 YS remove ReceivingStatus
		--and (PORECDTL.ReceivingStatus ='Complete' or PORECDTL.ReceivingStatus=' ')  
		AND PoItems.Uniq_Key = ' '
		AND PoItems.PoNum = @pcPoNum 
		AND PoRecLoc.Sinv_Uniq = ' ' 
		AND PoRecLoc.AccptQty > 0 
	ORDER BY PoItems.ItemNo 

END