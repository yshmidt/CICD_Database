-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/04/13
-- Description:	Update UpDtStd table and inventory cost fields
-- Modification:
-- 01/29/14 VL found insert un-reconciled PO into updtstd table has to filter by rolltype: @lcRollType
-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
-- 12/12/14 VL Move the deleting cost of phantom part to upper place, so it only delete cost when the curLevel = MaxLevel, otherwise, it deleted the cost before reaching max level
-- 05/28/15 YS remove ReceivingStatus
-- 09/03/15 VL only update inventor records if the cost are different from rollup table, otherwise, if user only changes few records, all the inventor records linked to rollup table would still be updated, Paramit complained about it
-- 01/05/17 VL added functional currency fields
-- 05/16/17 VL added Is_ERAdj to indicate the record is not from standard cost ER adjustment
-- 04/23/20 VL Found an issue for instore part, after the parts were issued to kit, then did cost adjustment, then created instore PO, the GL balance of instore GL account would not be zero, has to insert a record in UPDTSTD for instore part after issue before instore PO created
-- =============================================
CREATE PROCEDURE [dbo].[sp_CostRollUpdCost] @lcRollType char(4), @cUserId AS char(8) = ''

AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @lnCurLevel numeric(2,0), @lnMaxLevel numeric(2,0)
-- 01/05/17 VL added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
-- 04/23/20 VL Found an issue for instore part, after the parts were issued to kit, then did cost adjustment, then created instore PO, the GL balance of instore GL account would not be zero, has to insert a record in UPDTSTD for instore part after issue before instore PO created
DECLARE @Inst_gl_no char(13)
SELECT @Inst_gl_no = Inst_gl_no FROM INVSETUP

BEGIN TRANSACTION
BEGIN TRY;
WITH ZUnRecords AS
(
	-- 01/05/17 VL added functional currency fields
	SELECT Poitems.Ponum, Poitems.Uniq_Key, PorecDtl.ReceiverNo, PorecDtl.RecvDate,
			CASE WHEN PorecRelGl.DebitRawAcct = 1 THEN Porecrelgl.TransQty ELSE -Porecrelgl.TransQty END AS TransQty,
			Porecrelgl.UniqRecRel, PorecrelGl.Unrecon_gl_nbr, Porecrelgl.StdCost,
			CASE WHEN @lFCInstalled = 0 THEN 0.00000 ELSE Porecrelgl.StdCostPR END AS StdCostPR
		FROM Porecrelgl, Porecdtl, Poitems, Porecloc
		WHERE Porecloc.Loc_uniq = Porecrelgl.Loc_uniq 
		AND Porecdtl.UniqRecDtl = Porecloc.FK_UNIQRECDTL
		AND Poitems.Uniqlnno = Porecdtl.UniqLnno
		-- make sure only complete receiver selected
		-- 05/28/15 YS remove ReceivingStatus
		--and (PORECDTL.ReceivingStatus='Complete' or porecdtl.ReceivingStatus = ' ')
		AND (Porecloc.Sinv_uniq = ''
		OR Porecloc.Sinv_uniq IN 
			(SELECT Sinv_uniq FROM Sinvoice WHERE Sinvoice.Is_rel_ap = 0))
),
ZFinalUnRecords  AS
(
	SELECT Ponum, Uniq_Key, ReceiverNo, RecvDate, Unrecon_gl_nbr, ISNULL(SUM(TransQty),0000000.00) AS Sum_transqty
		FROM ZUnRecords
		GROUP BY Ponum,Uniq_Key,ReceiverNo,RecvDate,Unrecon_gl_nbr
		HAVING ISNULL(SUM(TransQty),0000000.00)<>0
)
--07/12/04 YS make a transaction that will Credit Un-reconcile and Debit Adjustment for the difference
--to do that change places for old and new cost, so the sign will be changed and it will force the system to debit Adjustment account 
--instead of un-reconcile account.

--REPLACE ALL ChangeAmt WITH ROUND(Qty_Oh * NewMatlCst,2) - ROUND(Qty_Oh * OldMatlcst,2)

-- 01/29/14 VL added roll type filter
-- 01/05/17 VL added functional currency fields
INSERT UPDTSTD 
	SELECT RollUp.Uniq_Key, dbo.fn_GenerateUniqueNumber() AS Uniq_Updt, ZFinalUnRecords.Unrecon_gl_nbr AS WH_Gl_NBR,
		ZFinalUnRecords.Sum_transqty AS Qty_oh, 0000000.00000 AS OldStdCost, 0000000.00000 AS NewStdCost, 
		ROUND(ZFinalUnRecords.Sum_transqty * (Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost),2) -
		ROUND(ZFinalUnRecords.Sum_transqty * (RollUp.NewMatlcst+RollUp.NewLabrCst+RollUp.NewOvhdCst+RollUp.NewOthrCst+RollUp.NewUdCst),2) AS ChangeAmt,
		RollUp.RunDate, GETDATE() AS UpDtDate, @cUserId AS Init, RollType, 0 AS Is_Rel_Gl, 0000000.00000 AS Matl_Cost, 
		(Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost) AS NewMatlcst, 
		(RollUp.NewMatlcst+RollUp.NewLabrCst+RollUp.NewOvhdCst+RollUp.NewOthrCst+RollUp.NewUdCst) AS OldMatlcst, SPACE(10) AS UniqWh,
		-- 01/05/17 VL added functional currency fields
		0000000.00000 AS OldStdCostPR, 0000000.00000 AS NewStdCostPR, 
		CASE WHEN @lFCInstalled = 0 THEN 0.00 ELSE
		ROUND(ZFinalUnRecords.Sum_transqty * (Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR),2) -
		ROUND(ZFinalUnRecords.Sum_transqty * (RollUp.NewMatlcstPR+RollUp.NewLabrCstPR+RollUp.NewOvhdCstPR+RollUp.NewOthrCstPR+RollUp.NewUdCstPR),2) END AS ChangeAmtPR,
		0000000.00000 AS Matl_CostPR, 
		CASE WHEN @lFCInstalled = 0 THEN 0.00000 ELSE
		(Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR) END AS NewMatlcstPR, 
		CASE WHEN @lFCInstalled = 0 THEN 0.00000 ELSE
		(RollUp.NewMatlcstPR+RollUp.NewLabrCstPR+RollUp.NewOvhdCstPR+RollUp.NewOthrCstPR+RollUp.NewUdCstPR) END AS OldMatlcstPR,
		CASE WHEN @lFCInstalled = 0 THEN SPACE(10) ELSE dbo.fn_GetPresentationCurrency() END AS PRFcused_uniq, 
		CASE WHEN @lFCInstalled = 0 THEN SPACE(10) ELSE dbo.fn_GetFunctionalCurrency() END AS FuncFcused_uniq,
		-- 05/16/17 VL added to indicate the record is not from standard cost ER adjustment
		0 AS Is_ERAdj
	FROM RollUp, ZFinalUnRecords, Inventor
	WHERE ((Inventor.Matl_Cost <> RollUp.NewMatlcst 
	AND (RollUp.Manual = 1 
	OR RollUp.UseCalc = 1)) 
	OR Inventor.LaborCost <> RollUp.NewLabrCst 
	OR Inventor.OverHead <> RollUp.NewOvhdCst 
	OR Inventor.OtherCost2 <> RollUp.NewOthrCst 
	OR Inventor.Other_Cost <> RollUp.NewUdCst) 
	AND ZFinalUnRecords.Uniq_Key = RollUp.Uniq_Key 
	AND RollUp.Uniq_key = Inventor.Uniq_key
	AND ROLLUP.ROLLTYPE = @lcRollType
	
-- {04/23/20 VL Found an issue for instore part, after the parts were issued to kit, then did cost adjustment, then created instore PO, the GL balance of instore GL account would not be zero, has to insert a record in UPDTSTD for instore part after issue before instore PO created
INSERT UPDTSTD 
	SELECT RollUp.Uniq_Key, dbo.fn_GenerateUniqueNumber() AS Uniq_Updt, @Inst_gl_no AS WH_Gl_NBR,
		Qty_isu AS Qty_oh, 0000000.00000 AS OldStdCost, 0000000.00000 AS NewStdCost, 
		ROUND(QTY_ISU * (Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost),2) -
		ROUND(QTY_ISU * (RollUp.NewMatlcst+RollUp.NewLabrCst+RollUp.NewOvhdCst+RollUp.NewOthrCst+RollUp.NewUdCst),2) AS ChangeAmt,
		RollUp.RunDate, GETDATE() AS UpDtDate, @cUserId AS Init, RollType, 0 AS Is_Rel_Gl, 0000000.00000 AS Matl_Cost, 
		(Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost) AS NewMatlcst, 
		(RollUp.NewMatlcst+RollUp.NewLabrCst+RollUp.NewOvhdCst+RollUp.NewOthrCst+RollUp.NewUdCst) AS OldMatlcst, UniqWh,
		-- 01/05/17 VL added functional currency fields
		0000000.00000 AS OldStdCostPR, 0000000.00000 AS NewStdCostPR, 
		CASE WHEN @lFCInstalled = 0 THEN 0.00 ELSE
		ROUND(QTY_ISU * (Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR),2) -
		ROUND(QTY_ISU * (RollUp.NewMatlcstPR+RollUp.NewLabrCstPR+RollUp.NewOvhdCstPR+RollUp.NewOthrCstPR+RollUp.NewUdCstPR),2) END AS ChangeAmtPR,
		0000000.00000 AS Matl_CostPR, 
		CASE WHEN @lFCInstalled = 0 THEN 0.00000 ELSE
		(Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR) END AS NewMatlcstPR, 
		CASE WHEN @lFCInstalled = 0 THEN 0.00000 ELSE
		(RollUp.NewMatlcstPR+RollUp.NewLabrCstPR+RollUp.NewOvhdCstPR+RollUp.NewOthrCstPR+RollUp.NewUdCstPR) END AS OldMatlcstPR,
		CASE WHEN @lFCInstalled = 0 THEN SPACE(10) ELSE dbo.fn_GetPresentationCurrency() END AS PRFcused_uniq, 
		CASE WHEN @lFCInstalled = 0 THEN SPACE(10) ELSE dbo.fn_GetFunctionalCurrency() END AS FuncFcused_uniq,
		-- 05/16/17 VL added to indicate the record is not from standard cost ER adjustment
		0 AS Is_ERAdj
	FROM RollUp, Postore, Inventor
	WHERE ((Inventor.Matl_Cost <> RollUp.NewMatlcst 
	AND (RollUp.Manual = 1 
	OR RollUp.UseCalc = 1)) 
	OR Inventor.LaborCost <> RollUp.NewLabrCst 
	OR Inventor.OverHead <> RollUp.NewOvhdCst 
	OR Inventor.OtherCost2 <> RollUp.NewOthrCst 
	OR Inventor.Other_Cost <> RollUp.NewUdCst) 
	AND Postore.Uniq_Key = RollUp.Uniq_Key 
	AND RollUp.Uniq_key = Inventor.Uniq_key
	AND ROLLUP.ROLLTYPE = @lcRollType
	AND Postore.Ponum = ''
-- 04/23/20 VL End}

-- Invt Qty OH records
-- 01/29/14 VL added roll type filter
-- 01/05/17 VL added functional currency fields
INSERT UPDTSTD 
	SELECT RollUp.Uniq_Key, dbo.fn_GenerateUniqueNumber() AS Uniq_UpDt, Warehous.Wh_Gl_Nbr, InvtMfgr.Qty_Oh,
		0000000.00000 AS OldStdCost, 0000000.00000 AS NewStdCost, 
		ROUND(InvtMfgr.Qty_Oh * (RollUp.NewMatlcst+RollUp.NewLabrCst+RollUp.NewOvhdCst+RollUp.NewOthrCst+RollUp.NewUdCst),2) -
		ROUND(InvtMfgr.Qty_Oh * (Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost),2) AS ChangeAmt,
		RollUp.RunDate, GETDATE() AS UpDtDate, @cUserId AS Init, RollType, 0 AS Is_Rel_Gl, 0000000.00000 AS Matl_Cost, 
		(RollUp.NewMatlcst+RollUp.NewLabrCst+RollUp.NewOvhdCst+RollUp.NewOthrCst+RollUp.NewUdCst) AS NewMatlcst,
		(Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost) AS OldMatlcst, Invtmfgr.UniqWh,
		-- 01/05/17 VL added functional currency fields
		0000000.00000 AS OldStdCostPR, 0000000.00000 AS NewStdCostPR, 
		CASE WHEN @lFCInstalled = 0 THEN 0.00 ELSE
		ROUND(InvtMfgr.Qty_Oh * (RollUp.NewMatlcstPR+RollUp.NewLabrCstPR+RollUp.NewOvhdCstPR+RollUp.NewOthrCstPR+RollUp.NewUdCstPR),2) -
		ROUND(InvtMfgr.Qty_Oh * (Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR),2) END AS ChangeAmtPR,
		000000.00000 AS Matl_CostPR, 
		CASE WHEN @lFCInstalled = 0 THEN 0.00000 ELSE
		(RollUp.NewMatlcstPR+RollUp.NewLabrCstPR+RollUp.NewOvhdCstPR+RollUp.NewOthrCstPR+RollUp.NewUdCstPR) END AS NewMatlcstPR,
		CASE WHEN @lFCInstalled = 0 THEN 0.00000 ELSE
		(Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR) END AS OldMatlcstPR,
		CASE WHEN @lFCInstalled = 0 THEN SPACE(10) ELSE dbo.fn_GetPresentationCurrency() END AS PRFcused_uniq, 
		CASE WHEN @lFCInstalled = 0 THEN SPACE(10) ELSE dbo.fn_GetFunctionalCurrency() END AS FuncFcused_uniq,
		-- 05/16/17 VL added to indicate the record is not from standard cost ER adjustment
		0 AS Is_ERAdj
	FROM RollUp, InvtMfgr, Warehous, Inventor 
	WHERE ((Inventor.Matl_Cost <> RollUp.NewMatlcst 
	AND (RollUp.Manual = 1
	OR RollUp.UseCalc = 1)) 
	OR Inventor.LaborCost <> RollUp.NewLabrCst 
	OR Inventor.OverHead <> RollUp.NewOvhdCst 
	OR Inventor.OtherCost2 <> RollUp.NewOthrCst
	OR Inventor.Other_Cost <> RollUp.NewUdCst) 
	AND InvtMfgr.Uniq_Key = RollUp.Uniq_Key 
	AND InvtMfgr.Uniq_key = Inventor.Uniq_key
	AND Warehous.UniqWh = InvtMfgr.UNIQWH 
	AND InvtMfgr.Qty_oh <> 0 
	AND Invtmfgr.Is_Deleted = 0
	AND Invtmfgr.Instore = 0
	AND ROLLUP.ROLLTYPE = @lcRollType

-- 10/25/06 VL create data for updating Updtstd for WIP Qty
-- 01/29/14 VL added roll type filter
-- 01/05/17 VL added functional currency fields
INSERT UPDTSTD 
	SELECT RollUp.Uniq_Key, dbo.fn_GenerateUniqueNumber() AS Uniq_UpDt, Warehous.Wh_Gl_Nbr, RollUp.WIPQty AS Qty_Oh,
		0000000.00000 AS OldStdCost, 0000000.00000 AS NewStdCost, 
		ROUND(RollUp.WIPQty * (RollUp.NewMatlcst+RollUp.NewLabrCst+RollUp.NewOvhdCst+RollUp.NewOthrCst+RollUp.NewUdCst),2) - 
		ROUND(RollUp.WIPQty * (Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost),2) AS ChangeAmt,
		RollUp.RunDate, GETDATE() AS UpDtDate, @cUserId AS Init, RollType, 0 AS Is_Rel_Gl, 0000000.00000 AS Matl_Cost, 
		(RollUp.NewMatlcst+RollUp.NewLabrCst+RollUp.NewOvhdCst+RollUp.NewOthrCst+RollUp.NewUdCst) AS NewMatlcst,
		(Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost) AS OldMatlCst, Warehous.UniqWh,
		-- 01/05/17 VL added functional currency fields	
		0000000.00000 AS OldStdCostPR, 0000000.00000 AS NewStdCostPR, 
		CASE WHEN @lFCInstalled = 0 THEN 0.00 ELSE
		ROUND(RollUp.WIPQty * (RollUp.NewMatlcstPR+RollUp.NewLabrCstPR+RollUp.NewOvhdCstPR+RollUp.NewOthrCstPR+RollUp.NewUdCstPR),2) - 
		ROUND(RollUp.WIPQty * (Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR),2) END AS ChangeAmtPR,
		0000000.00000 AS Matl_CostPR, 
		CASE WHEN @lFCInstalled = 0 THEN 0.00000 ELSE
		(RollUp.NewMatlcstPR+RollUp.NewLabrCstPR+RollUp.NewOvhdCstPR+RollUp.NewOthrCstPR+RollUp.NewUdCstPR) END AS NewMatlcstPR,
		CASE WHEN @lFCInstalled = 0 THEN 0.00000 ELSE
		(Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR) END AS OldMatlCstPR,
		CASE WHEN @lFCInstalled = 0 THEN SPACE(10) ELSE dbo.fn_GetPresentationCurrency() END AS PRFcused_uniq, 
		CASE WHEN @lFCInstalled = 0 THEN SPACE(10) ELSE dbo.fn_GetFunctionalCurrency() END AS FuncFcused_uniq,
		-- 05/16/17 VL added to indicate the record is not from standard cost ER adjustment
		0 AS Is_ERAdj
	FROM RollUp, Warehous, Inventor 
	WHERE ((Inventor.Matl_Cost <> RollUp.NewMatlCst 
	AND (RollUp.Manual = 1 
	OR RollUp.UseCalc =1))
	OR Inventor.LaborCost <> RollUp.NewLabrCst 
	OR Inventor.OverHead <> RollUp.NewOvhdCst 
	OR Inventor.OtherCost2 <> RollUp.NewOthrCst
	OR Inventor.Other_Cost <> RollUp.NewUdCst) 
	AND RollUp.UNIQ_KEY = Inventor.Uniq_key
	AND Warehous.Warehouse = 'WIP   '
	AND RollUp.WIPQty <> 0 
	AND ROLLUP.ROLLTYPE = @lcRollType

BEGIN 
IF @lcRollType = 'BUY'
	BEGIN
		-- 01/29/14 VL added roll type filter
		-- 09/03/15 VL only update if the new cost is different from old cost, also, no need to update date fields, they are updated in inventor trigger
		-- 01/05/17 VL separate FC and non FC
		BEGIN
		IF @lFCInstalled = 0
			BEGIN
			UPDATE INVENTOR	
				SET --StdDt = CASE WHEN Inventor.STDCOST	<>	RollUp.NewMatlCst + RollUp.NewLabrCst + RollUp.NewOvhdCst + RollUp.NewOthrCst + RollUp.NewUdCst THEN GETDATE() ELSE Inventor.STDDT END,
					--MATDT = CASE WHEN Inventor.Matl_Cost<>	RollUp.NewMatlcst THEN GETDATE() ELSE Inventor.MatDt END, 
					--LABDT = CASE WHEN Inventor.LaborCost<>	RollUp.NewLabrCst THEN GETDATE() ELSE Inventor.Labdt END, 
					--OHDT  = CASE WHEN Inventor.Overhead	<>	RollUp.NewOvhdCst THEN GETDATE() ELSE Inventor.Ohdt END,
					--OTH2DT= CASE WHEN Inventor.OtherCost2<>	RollUp.NewOthrCst THEN GETDATE() ELSE Inventor.Oth2dt END, 
					--OTHDT = CASE WHEN Inventor.Other_Cost<>	RollUp.NewUdCst THEN GETDATE() ELSE Inventor.Othdt END,
					Matl_Cost	= RollUp.NewMatlcst,
					LaborCost	= RollUp.NewLabrCst,
					Overhead	= RollUp.NewOvhdCst, 
					OtherCost2	= RollUp.NewOthrCst,
					Other_Cost	= RollUp.NewUdCst,
					StdCost		= RollUp.NewMatlcst + RollUp.NewLabrCst + RollUp.NewOvhdCst + RollUp.NewOthrCst + RollUp.NewUdCst
				FROM Inventor, ROLLUP
				WHERE Inventor.UNIQ_KEY = RollUp.UNIQ_KEY
				AND (Part_sourc = 'BUY' 
				OR (PART_SOURC = 'MAKE' AND Make_Buy = 1))
				AND ROLLUP.ROLLTYPE = @lcRollType
				AND (Matl_Cost	<> RollUp.NewMatlcst
				OR	LaborCost	<> RollUp.NewLabrCst
				OR	Overhead	<> RollUp.NewOvhdCst
				OR	OtherCost2	<> RollUp.NewOthrCst
				OR	Other_Cost	<> RollUp.NewUdCst
				OR	StdCost		<> RollUp.NewMatlcst + RollUp.NewLabrCst + RollUp.NewOvhdCst + RollUp.NewOthrCst + RollUp.NewUdCst)
			END
		ELSE
			BEGIN
			-- 01/05/17 VL added functional currency fields
			UPDATE INVENTOR	
				SET --StdDt = CASE WHEN Inventor.STDCOST	<>	RollUp.NewMatlCst + RollUp.NewLabrCst + RollUp.NewOvhdCst + RollUp.NewOthrCst + RollUp.NewUdCst THEN GETDATE() ELSE Inventor.STDDT END,
					--MATDT = CASE WHEN Inventor.Matl_Cost<>	RollUp.NewMatlcst THEN GETDATE() ELSE Inventor.MatDt END, 
					--LABDT = CASE WHEN Inventor.LaborCost<>	RollUp.NewLabrCst THEN GETDATE() ELSE Inventor.Labdt END, 
					--OHDT  = CASE WHEN Inventor.Overhead	<>	RollUp.NewOvhdCst THEN GETDATE() ELSE Inventor.Ohdt END,
					--OTH2DT= CASE WHEN Inventor.OtherCost2<>	RollUp.NewOthrCst THEN GETDATE() ELSE Inventor.Oth2dt END, 
					--OTHDT = CASE WHEN Inventor.Other_Cost<>	RollUp.NewUdCst THEN GETDATE() ELSE Inventor.Othdt END,
					Matl_Cost	= RollUp.NewMatlcst,
					LaborCost	= RollUp.NewLabrCst,
					Overhead	= RollUp.NewOvhdCst, 
					OtherCost2	= RollUp.NewOthrCst,
					Other_Cost	= RollUp.NewUdCst,
					StdCost		= RollUp.NewMatlcst + RollUp.NewLabrCst + RollUp.NewOvhdCst + RollUp.NewOthrCst + RollUp.NewUdCst,
					-- 01/05/17 VL added functional currency fields
					Matl_CostPR	= RollUp.NewMatlcstPR,
					LaborCostPR	= RollUp.NewLabrCstPR,
					OverheadPR	= RollUp.NewOvhdCstPR, 
					OtherCost2PR= RollUp.NewOthrCstPR,
					Other_CostPR= RollUp.NewUdCstPR,
					StdCostPR	= RollUp.NewMatlcstPR + RollUp.NewLabrCstPR + RollUp.NewOvhdCstPR + RollUp.NewOthrCstPR + RollUp.NewUdCstPR
				FROM Inventor, ROLLUP
				WHERE Inventor.UNIQ_KEY = RollUp.UNIQ_KEY
				AND (Part_sourc = 'BUY' 
				OR (PART_SOURC = 'MAKE' AND Make_Buy = 1))
				AND ROLLUP.ROLLTYPE = @lcRollType
				AND (Matl_Cost	<> RollUp.NewMatlcst
				OR	LaborCost	<> RollUp.NewLabrCst
				OR	Overhead	<> RollUp.NewOvhdCst
				OR	OtherCost2	<> RollUp.NewOthrCst
				OR	Other_Cost	<> RollUp.NewUdCst
				OR	StdCost		<> RollUp.NewMatlcst + RollUp.NewLabrCst + RollUp.NewOvhdCst + RollUp.NewOthrCst + RollUp.NewUdCst)
			END
		END
		-- Delete RollUp
		DELETE FROM RollUp WHERE ROLLTYPE = 'BUY'
	END
ELSE
	BEGIN
		-- 01/29/14 VL added roll type filter
		-- 09/03/15 VL only update if the new cost is different from old cost, also, no need to update date fields, they are updated in inventor trigger
		-- 01/05/17 VL separate FC and non FC
		BEGIN
		IF @lFCInstalled = 0
			BEGIN
			UPDATE INVENTOR	
				SET --StdDt = CASE WHEN Inventor.STDCOST	<>	RollUp.NewMatlCst + RollUp.NewLabrCst + RollUp.NewOvhdCst + RollUp.NewOthrCst + RollUp.NewUdCst THEN GETDATE() ELSE Inventor.STDDT END,
				--	MATDT = CASE WHEN Inventor.Matl_Cost<>	RollUp.NewMatlcst THEN GETDATE() ELSE Inventor.MatDt END, 
				--	LABDT = CASE WHEN Inventor.LaborCost<>	RollUp.NewLabrCst THEN GETDATE() ELSE Inventor.Labdt END, 
				--	OHDT  = CASE WHEN Inventor.Overhead	<>	RollUp.NewOvhdCst THEN GETDATE() ELSE Inventor.Ohdt END,
				--	OTH2DT= CASE WHEN Inventor.OtherCost2<>	RollUp.NewOthrCst THEN GETDATE() ELSE Inventor.Oth2dt END, 
				--	OTHDT = CASE WHEN Inventor.Other_Cost<>	RollUp.NewUdCst THEN GETDATE() ELSE Inventor.Othdt END,
					Matl_Cost	= RollUp.NewMatlcst,
					LaborCost	= RollUp.NewLabrCst,
					Overhead	= RollUp.NewOvhdCst, 
					OtherCost2	= RollUp.NewOthrCst,
					Other_Cost	= RollUp.NewUdCst,
					StdCost		= RollUp.NewMatlcst + RollUp.NewLabrCst + RollUp.NewOvhdCst + RollUp.NewOthrCst + RollUp.NewUdCst
				FROM Inventor, ROLLUP
				WHERE Inventor.UNIQ_KEY = RollUp.UNIQ_KEY
				AND (Part_sourc = 'MAKE' 
				OR PART_SOURC = 'PHANTOM')
				AND ROLLUP.ROLLTYPE = @lcRollType
				AND (Matl_Cost	<> RollUp.NewMatlcst
				OR	LaborCost	<> RollUp.NewLabrCst
				OR	Overhead	<> RollUp.NewOvhdCst
				OR	OtherCost2	<> RollUp.NewOthrCst
				OR	Other_Cost	<> RollUp.NewUdCst
				OR	StdCost		<> RollUp.NewMatlcst + RollUp.NewLabrCst + RollUp.NewOvhdCst + RollUp.NewOthrCst + RollUp.NewUdCst)
			END
		ELSE
			BEGIN
			-- 01/05/17 VL added functional currency fields
			UPDATE INVENTOR	
				SET --StdDt = CASE WHEN Inventor.STDCOST	<>	RollUp.NewMatlCst + RollUp.NewLabrCst + RollUp.NewOvhdCst + RollUp.NewOthrCst + RollUp.NewUdCst THEN GETDATE() ELSE Inventor.STDDT END,
				--	MATDT = CASE WHEN Inventor.Matl_Cost<>	RollUp.NewMatlcst THEN GETDATE() ELSE Inventor.MatDt END, 
				--	LABDT = CASE WHEN Inventor.LaborCost<>	RollUp.NewLabrCst THEN GETDATE() ELSE Inventor.Labdt END, 
				--	OHDT  = CASE WHEN Inventor.Overhead	<>	RollUp.NewOvhdCst THEN GETDATE() ELSE Inventor.Ohdt END,
				--	OTH2DT= CASE WHEN Inventor.OtherCost2<>	RollUp.NewOthrCst THEN GETDATE() ELSE Inventor.Oth2dt END, 
				--	OTHDT = CASE WHEN Inventor.Other_Cost<>	RollUp.NewUdCst THEN GETDATE() ELSE Inventor.Othdt END,
					Matl_Cost	= RollUp.NewMatlcst,
					LaborCost	= RollUp.NewLabrCst,
					Overhead	= RollUp.NewOvhdCst, 
					OtherCost2	= RollUp.NewOthrCst,
					Other_Cost	= RollUp.NewUdCst,
					StdCost		= RollUp.NewMatlcst + RollUp.NewLabrCst + RollUp.NewOvhdCst + RollUp.NewOthrCst + RollUp.NewUdCst,
					-- 01/05/17 VL added functional currency fields
					Matl_CostPR	= RollUp.NewMatlcstPR,
					LaborCostPR	= RollUp.NewLabrCstPR,
					OverheadPR	= RollUp.NewOvhdCstPR, 
					OtherCost2PR= RollUp.NewOthrCstPR,
					Other_CostPR= RollUp.NewUdCstPR,
					StdCostPR	= RollUp.NewMatlcstPR + RollUp.NewLabrCstPR + RollUp.NewOvhdCstPR + RollUp.NewOthrCstPR + RollUp.NewUdCstPR

				FROM Inventor, ROLLUP
				WHERE Inventor.UNIQ_KEY = RollUp.UNIQ_KEY
				AND (Part_sourc = 'MAKE' 
				OR PART_SOURC = 'PHANTOM')
				AND ROLLUP.ROLLTYPE = @lcRollType
				AND (Matl_Cost	<> RollUp.NewMatlcst
				OR	LaborCost	<> RollUp.NewLabrCst
				OR	Overhead	<> RollUp.NewOvhdCst
				OR	OtherCost2	<> RollUp.NewOthrCst
				OR	Other_Cost	<> RollUp.NewUdCst
				OR	StdCost		<> RollUp.NewMatlcst + RollUp.NewLabrCst + RollUp.NewOvhdCst + RollUp.NewOthrCst + RollUp.NewUdCst)
			END
		END
		SELECT @lnCurLevel = CurLevel, @lnMaxLevel = MaxLevel
			FROM RollMake

		-- {12/12/14 VL move the code from bottom before CurLevel is increased
		IF @@ROWCOUNT > 0 AND @lnCurLevel = @lnMaxLevel
		BEGIN
			-- 01/05/17 VL added functional currency fields
			UPDATE INVENTOR 
				SET Matl_Cost = 0.00,
					LaborCost = 0.00, 
					Overhead = 0.00, 
					OtherCost2 = 0.00, 
					Other_Cost = 0.00, 
					StdCost = 0.00,
					-- 01/05/17 VL added functional currency fields
					Matl_CostPR = 0.00,
					LaborCostPR = 0.00, 
					OverheadPR = 0.00, 
					OtherCost2PR = 0.00, 
					Other_CostPR = 0.00, 
					StdCostPR = 0.00  					 
				WHERE PART_SOURC = 'PHANTOM'
		END
		--12/12/14 VL End}
		
		BEGIN
		IF @lnCurLevel <> @lnMaxLevel
			BEGIN
			UPDATE ROLLMAKE
				SET CurLevel = CurLevel + 1 
			END
		ELSE
			BEGIN
			UPDATE ROLLMAKE
				SET CurLevel = 0,
					MAXLEVEL = 0
			END
		END
				

		-- Delete RollUp
		DELETE FROM RollUp WHERE ROLLTYPE = 'MAKE'		
	END
			
END

-- {12/12/14 VL found should check if current level = Max level and set cost to 0 for phantom parts before the code that increase curlevel above
-- it caused the phantom part cost become 0 even it reaches to the top level, will move the code to upper place
--SELECT @lnCurLevel = CurLevel, @lnMaxLevel = MaxLevel
--	FROM RollMake


--IF @@ROWCOUNT > 0 AND @lnCurLevel = @lnMaxLevel
--BEGIN
--	UPDATE INVENTOR 
--		SET Matl_Cost = 0.00,
--			LaborCost = 0.00, 
--			Overhead = 0.00, 
--			OtherCost2 = 0.00, 
--			Other_Cost = 0.00, 
--			StdCost = 0.00 
--		WHERE PART_SOURC = 'PHANTOM'
--END
--12/12/14 VL End}

	
END TRY

BEGIN CATCH
	RAISERROR('Error occurred in cost roll cost updating. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END