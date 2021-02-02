-- =============================================
-- Author:		Bill Blake
-- Create date: 
-- Description:	
-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
-- 05/28/15 YS remove ReceivingStatus
-- 10/19/15 YS added back item_desc column for the misc items added during the reconciliation
-- 03/28/16 YS this procedure will haver to be revritte or disgarded in the new manex_a_design. For now fix rnamed columns and added Fc columns
-- 11/29/16 VL Added presentation currency fields
-- 12/01/16 YS added partmfgr and mfgr_pt_no from porecdtl
-- =============================================
CREATE PROCEDURE [dbo].[PoReconFindDetailView]
	-- Add the parameters for the stored procedure here
	@lcSinv_uniq AS CHAR(10) = ' ', @pcRecieverNo AS CHAR(10)= ' ', @pcPoNum AS CHAR(15) = ' ',@lcUnreconGl AS CHAR(13) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
	-- Make sure only complete receivers are selected
		SELECT DISTINCT PoRecLoc.AccptQty+PoRecLoc.RejQty AS Recv_Qty, 0 as YesNo, PoRecPkNo AS SupPkNo, 
		PoRecLoc.AccptQty, PoRecLoc.AccptQty as Acpt_Qty, PoItSchd.Schd_Qty AS Ord_Qty, PoItSchd.Schd_Qty AS Ord_Qty1, 
		PoItems.CostEach, PoItems.Is_Tax,Poitems.tax_pct, PoItems.PoNum, PoItSchd.Balance AS Curr_Balln, Inventor.Part_No, 
		-- 10/19/15 YS added back item_desc column for the misc items added during the reconciliation
		Inventor.Part_Class, Inventor.Part_Type, Inventor.Descript AS item_Desc, PoRecLoc.UniqDetNo,Porecdtl.RecvDate AS Date,
		PoItems.ItemNo, PoItems.Overage, PoItems.Uniq_Key, PoItems.PoItType, PoItems.Tax_Pct AS Tax_Pct1, 
		-- 12/01/16 YS added partmfgr and mfgr_pt_no from porecdtl
		---PoItems.PartMfgr, 
		Porecdtl.partmfgr,porecdtl.mfgr_pt_no,
		@lcUnreconGl AS Gl_nbr, PorecDtl.ReceiverNo, 
		cast(NULL as smalldatetime)as Due_date, cast(NULL as smalldatetime) as InvDate, 0 AS Is_Rel_Gl, 
		Inventor.Revision, PoItems.Ord_Qty - PoItems.Acpt_Qty AS BalQty, PoItems.Recv_Qty AS totrecv_qt, 
		PoItems.Rej_qty AS TotRejQty, PoItems.Ord_Qty AS TotOrd_Qty, PoItems.UniqLnNo, 
		--03/28/16 YS this procedure will haver to be revritte or disgarded in the new manex_a_design. For now fix rnamed columns and added Fc columns
		--ROUND(PoRecDtl.AccptQty * PoItems.CostEach,2) AS Extension, @lcSinv_uniq AS SInv_Uniq, space(10) AS Sdet_Uniq, 
		--ROUND(PoRecDtl.AccptQty * PoItems.CostEach,2) AS item_total,PoRecLoc.loc_uniq, PoRecDtl.AccptQty AS OrgAcptQty, 
		ROUND(PoRecDtl.AcceptedQty * PoItems.CostEach,2) AS Extension, @lcSinv_uniq AS SInv_Uniq, space(10) AS Sdet_Uniq, 
		ROUND(PoRecDtl.AcceptedQty * PoItems.CostEach,2) AS item_total,PoRecLoc.loc_uniq, PoRecDtl.AcceptedQty AS OrgAcptQty, 
		PoRecDtl.UniqRecDtl, PoRecLoc.Fk_UniqRecDtl ,
		PoItems.CosteachFC, 
		ROUND(PoRecDtl.AcceptedQty * PoItems.CostEachFC,2) AS ExtensionFC, 
		ROUND(PoRecDtl.AcceptedQty * PoItems.CostEachFC,2) AS item_totalFC, PoRecdtl.FcUsed_uniq, PoRecdtl.Fchist_key,
		-- 11/29/16 VL added presentation currency fields
		PoItems.COSTEACHPR,
		ROUND(PoRecDtl.AcceptedQty * PoItems.CostEachPR,2) AS ExtensionPR, 
		ROUND(PoRecDtl.AcceptedQty * PoItems.CostEachPR,2) AS item_totalPR			  
	FROM PoRecDtl, PoItems, PoRecLoc, PoItSchd, Inventor 
	WHERE PoRecDtl.UniqLnNo = PoItems.UniqLnNo 
		AND PoRecLoc.FK_UniqRecDtl = PoRecDtl.UniqRecDtl 
		AND PoRecLoc.UniqDetNo = Poitschd.UniqDetNo 
		AND PoRecDtl.ReceiverNo = @pcRecieverNo 
		-- 05/28/15 YS remove ReceivingStatus
		--AND (Porecdtl.ReceivingStatus='Complete' or Porecdtl.ReceivingStatus=' ')
		AND Inventor.Uniq_Key = PoItems.Uniq_Key 
		AND PoItems.PoNum =  @pcPoNum 
		AND PoRecLoc.Sinv_Uniq =' '
		AND PoRecLoc.AccptQty > 0 
		AND NOT PoItems.Uniq_Key = ' '
	ORDER BY PoItems.ItemNo 

END