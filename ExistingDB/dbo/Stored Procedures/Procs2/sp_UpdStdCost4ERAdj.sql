-- =============================================
-- Author:		Vicky Lu
-- Create date: 2017/05/10
-- Description:	When user changes the functional currency stdcost exchange rate, need to convert all stdcost with new rate, and insert UPDTSTD with the new GL number set up for exchange rate adjustment
-- Modification:
-- 05/11/17 VL removed ReceivingStatus 
-- 09/19/17 VL added another parameter to indicate if use FUNC as base to convert PR or use PR as base to convert FUNC, @cCurrBase = 'FUNC' or 'PR', also added code to update TargetPrice which should be updated too, but no need to insert UPDTSTD
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdStdCost4ERAdj] @cUserId AS char(8) = '', @cCurrBase as char(4) = 'FUNC' 
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

BEGIN TRANSACTION

DECLARE @STDCOSTERADJGLNO char(13)
-- 07/21/16 VL create @ZShortWipGroup to replace the CTE ZShortWipGroup, found in Penang's data, it took more than 7 min (I cancelled the code) if I used CTE ZShortWipGroup, after replacing to use table variable @ZShortWipGroup, it only took 10 seconds
DECLARE @ZShortWipGroup TABLE (Uniq_key char(10), WIPQty numeric(12,2))
-- 09/19/17 VL create @ZFinalUnRecords to be used in updating PO un-reconcilied, so it can be used separately in IF @cCurrBase = 'FUNC' or 'PR'
DECLARE @ZFinalUnRecords TABLE (Ponum char(15), Uniq_Key char(10), ReceiverNo char(10), RecvDate smalldatetime, Unrecon_gl_nbr char(13), Sum_transqty numeric(10,2))

SELECT @STDCOSTERADJGLNO = STDCOSTERADJGLNO FROM INVSETUP
IF @STDCOSTERADJGLNO=''
BEGIN
	RAISERROR('Standard Cost Exchange Rate Adjustment Account is not set up.  This operation will be cancelled.',11,1)
	ROLLBACK TRANSACTION
	RETURN 
END

-- 1. PO un-reconciled
--------------------------
;WITH ZUnRecords AS
(
	-- 01/05/17 VL added functional currency fields
	SELECT Poitems.Ponum, Poitems.Uniq_Key, PorecDtl.ReceiverNo, PorecDtl.RecvDate,
			CASE WHEN PorecRelGl.DebitRawAcct = 1 THEN Porecrelgl.TransQty ELSE -Porecrelgl.TransQty END AS TransQty,
			Porecrelgl.UniqRecRel, PorecrelGl.Unrecon_gl_nbr, Porecrelgl.StdCost, 
			Porecrelgl.StdCostPR AS StdCostPR
		FROM Porecrelgl, Porecdtl, Poitems, Porecloc
		WHERE Porecloc.Loc_uniq = Porecrelgl.Loc_uniq 
		AND Porecdtl.UniqRecDtl = Porecloc.FK_UNIQRECDTL
		AND Poitems.Uniqlnno = Porecdtl.UniqLnno
		-- 05/11/17 VL removed ReceivingStatus 
		-- make sure only complete receiver selected
		-- and (PORECDTL.ReceivingStatus='Complete' or porecdtl.ReceivingStatus = ' ')
		AND (Porecloc.Sinv_uniq = ''
		OR Porecloc.Sinv_uniq IN 
			(SELECT Sinv_uniq FROM Sinvoice WHERE Sinvoice.Is_rel_ap = 0))
)
-- 09/19/17 VL create @ZFinalUnRecords to be used in updating PO un-reconcilied, so it can be used separately in IF @cCurrBase = 'FUNC' or 'PR'
--ZFinalUnRecords  AS
--(
--	SELECT Ponum, Uniq_Key, ReceiverNo, RecvDate, Unrecon_gl_nbr, ISNULL(SUM(TransQty),0000000.00) AS Sum_transqty
--		FROM ZUnRecords
--		GROUP BY Ponum,Uniq_Key,ReceiverNo,RecvDate,Unrecon_gl_nbr
--		HAVING ISNULL(SUM(TransQty),0000000.00)<>0
--)
INSERT @ZFinalUnRecords  
	SELECT Ponum, Uniq_Key, ReceiverNo, RecvDate, Unrecon_gl_nbr, ISNULL(SUM(TransQty),0000000.00) AS Sum_transqty
		FROM ZUnRecords
		GROUP BY Ponum,Uniq_Key,ReceiverNo,RecvDate,Unrecon_gl_nbr
		HAVING ISNULL(SUM(TransQty),0000000.00)<>0


--07/12/04 YS make a transaction that will Credit Un-reconcile and Debit Adjustment for the difference
--to do that change places for old and new cost, so the sign will be changed and it will force the system to debit Adjustment account 
--instead of un-reconcile account.

--REPLACE ALL ChangeAmt WITH ROUND(Qty_Oh * NewMatlCst,2) - ROUND(Qty_Oh * OldMatlcst,2)

-- 01/05/17 VL added functional currency fields
-- 05/10/17 VL added Is_ERAdj
-- 09/19/17 VL added to separate convert base on FUNC or PR
BEGIN
IF @cCurrBase = 'FUNC'
	BEGIN
	INSERT UPDTSTD 
		SELECT Inventor.Uniq_Key, dbo.fn_GenerateUniqueNumber() AS Uniq_Updt, ZFinalUnRecords.Unrecon_gl_nbr AS WH_Gl_NBR,
			ZFinalUnRecords.Sum_transqty AS Qty_oh, 
			0000000.00000 AS OldStdCost, 0000000.00000 AS NewStdCost, 
			0000000.00000 AS ChangeAmt,
			GETDATE() AS RunDate, GETDATE() AS UpDtDate, @cUserId AS Init, '' AS RollType, 0 AS Is_Rel_Gl, 
			0000000.00000 AS Matl_Cost, 
			Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost AS NewMatlcst, 
			Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost AS OldMatlcst, 
			SPACE(10) AS UniqWh,
			-- 01/05/17 VL added functional currency fields
			0000000.00000 AS OldStdCostPR, 0000000.00000 AS NewStdCostPR, 
			ROUND(ZFinalUnRecords.Sum_transqty * (Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR),2) -
			ROUND(ZFinalUnRecords.Sum_transqty * 
				(ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)+
				ROUND(Inventor.LaborCost*FcSys.StdCostExRate,5)+
				ROUND(Inventor.Overhead*FcSys.StdCostExRate,5)+
				ROUND(Inventor.OtherCost2*FcSys.StdCostExRate,5)+
				ROUND(Inventor.Other_Cost*FcSys.StdCostExRate,5)),2) AS ChangeAmtPR,
			0000000.00000 AS Matl_CostPR, 
			Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR AS NewMatlcstPR, 
			ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)+
				ROUND(Inventor.LaborCost*FcSys.StdCostExRate,5)+
				ROUND(Inventor.Overhead*FcSys.StdCostExRate,5)+
				ROUND(Inventor.OtherCost2*FcSys.StdCostExRate,5)+
				ROUND(Inventor.Other_Cost*FcSys.StdCostExRate,5) AS OldMatlcstPR,
			dbo.fn_GetPresentationCurrency() AS PRFcused_uniq, 
			dbo.fn_GetFunctionalCurrency() AS FuncFcused_uniq,
			1 AS Is_ERAdj
		FROM @ZFinalUnRecords ZFinalUnRecords INNER JOIN Inventor 
		ON ZFinalUnRecords.Uniq_Key = Inventor.Uniq_key
		CROSS JOIN FcSys
		WHERE (Inventor.Matl_CostPR <> ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)
		OR Inventor.LaborCostPR <> ROUND(Inventor.LaborCost*FcSys.StdCostExRate,5)
		OR Inventor.OverHeadPR <> ROUND(Inventor.OverHead*FcSys.StdCostExRate,5)
		OR Inventor.OtherCost2PR <> ROUND(Inventor.OtherCost2*FcSys.StdCostExRate,5)
		OR Inventor.Other_CostPR <> ROUND(Inventor.Other_Cost*FcSys.StdCostExRate,5))
	END
ELSE
-- @cCurrBase = 'PR'
	BEGIN
	INSERT UPDTSTD 
		SELECT Inventor.Uniq_Key, dbo.fn_GenerateUniqueNumber() AS Uniq_Updt, ZFinalUnRecords.Unrecon_gl_nbr AS WH_Gl_NBR,
			ZFinalUnRecords.Sum_transqty AS Qty_oh, 0000000.00000 AS OldStdCost, 0000000.00000 AS NewStdCost, 
			ROUND(ZFinalUnRecords.Sum_transqty * (Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost),2) -
			ROUND(ZFinalUnRecords.Sum_transqty * 
				(ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.LaborCostPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.OverheadPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.OtherCost2PR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.Other_CostPR/FcSys.StdCostExRate,5)),2) AS ChangeAmt,
			GETDATE() AS RunDate, GETDATE() AS UpDtDate, @cUserId AS Init, '' AS RollType, 0 AS Is_Rel_Gl, 0000000.00000 AS Matl_Cost, 
			(Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost) AS NewMatlcst, 
			ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.LaborCostPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.OverheadPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.OtherCost2PR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.Other_CostPR/FcSys.StdCostExRate,5) AS OldMatlcst, SPACE(10) AS UniqWh,
			-- 01/05/17 VL added functional currency fields
			0000000.00000 AS OldStdCostPR, 0000000.00000 AS NewStdCostPR, 0000000.00000 AS ChangeAmtPR,	0000000.00000 AS Matl_CostPR, 
			Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR AS NewMatlcstPR, 
			Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR AS OldMatlcstPR,
			dbo.fn_GetPresentationCurrency() AS PRFcused_uniq, 
			dbo.fn_GetFunctionalCurrency() AS FuncFcused_uniq,
			1 AS Is_ERAdj
		FROM @ZFinalUnRecords  ZFinalUnRecords INNER JOIN Inventor 
		ON ZFinalUnRecords.Uniq_Key = Inventor.Uniq_key
		CROSS JOIN FcSys
		WHERE (Inventor.Matl_Cost <> ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)
		OR Inventor.LaborCost <> ROUND(Inventor.LaborCostPR/FcSys.StdCostExRate,5)
		OR Inventor.OverHead <> ROUND(Inventor.OverHeadPR/FcSys.StdCostExRate,5)
		OR Inventor.OtherCost2 <> ROUND(Inventor.OtherCost2PR/FcSys.StdCostExRate,5)
		OR Inventor.Other_Cost <> ROUND(Inventor.Other_CostPR/FcSys.StdCostExRate,5))
	END
END


-- 2. Inventory Qty OH
-------------------
-- 09/19/17 VL added to separate convert base on FUNC or PR
BEGIN
IF @cCurrBase = 'FUNC'
	BEGIN
	INSERT UPDTSTD 
		SELECT Inventor.Uniq_Key, dbo.fn_GenerateUniqueNumber() AS Uniq_UpDt, Warehous.Wh_Gl_Nbr, InvtMfgr.Qty_Oh,
			0000000.00000 AS OldStdCost, 0000000.00000 AS NewStdCost, 
			0000000.00000 AS ChangeAmt,
			GETDATE() AS RunDate, GETDATE() AS UpDtDate, @cUserId AS Init, '' AS RollType, 0 AS Is_Rel_Gl, 
			0000000.00000 AS Matl_Cost, 
			Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost AS NewMatlcst,
			Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost AS OldMatlcst, Invtmfgr.UniqWh,
			-- 01/05/17 VL added functional currency fields
			0000000.00000 AS OldStdCostPR, 0000000.00000 AS NewStdCostPR, 
			ROUND(InvtMfgr.Qty_Oh * 
				(ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)+
				ROUND(Inventor.LaborCost*FcSys.StdCostExRate,5)+
				ROUND(Inventor.Overhead*FcSys.StdCostExRate,5)+
				ROUND(Inventor.OtherCost2*FcSys.StdCostExRate,5)+
				ROUND(Inventor.Other_Cost*FcSys.StdCostExRate,5)),2) -
			ROUND(InvtMfgr.Qty_Oh * (Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR),2) AS ChangeAmtPR,			
			0000000.00000 AS Matl_CostPR, 
			ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)+
				ROUND(Inventor.LaborCost*FcSys.StdCostExRate,5)+
				ROUND(Inventor.Overhead*FcSys.StdCostExRate,5)+
				ROUND(Inventor.OtherCost2*FcSys.StdCostExRate,5)+
				ROUND(Inventor.Other_Cost*FcSys.StdCostExRate,5) AS NewMatlcst,
			Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR AS OldMatlcstPR,
			dbo.fn_GetPresentationCurrency() AS PRFcused_uniq, 
			dbo.fn_GetFunctionalCurrency() AS FuncFcused_uniq,
			1 AS Is_ErAdj
		FROM InvtMfgr INNER JOIN Warehous ON Invtmfgr.UniqWh = Warehous.UniqWh 
		INNER JOIN Inventor ON InvtMfgr.Uniq_Key = Inventor.Uniq_key 
		CROSS JOIN FcSys
		WHERE (Inventor.Matl_CostPR <> ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)
		OR Inventor.LaborCostPR <> ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)
		OR Inventor.OverHeadPR <> ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)
		OR Inventor.OtherCost2PR <> ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)
		OR Inventor.Other_CostPR <> ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)) 
		AND InvtMfgr.Qty_oh <> 0 
		AND Invtmfgr.Is_Deleted = 0
		AND Invtmfgr.Instore = 0
	END
ELSE
-- @cCurrBase = 'PR'
	BEGIN
	INSERT UPDTSTD 
		SELECT Inventor.Uniq_Key, dbo.fn_GenerateUniqueNumber() AS Uniq_UpDt, Warehous.Wh_Gl_Nbr, InvtMfgr.Qty_Oh,
			0000000.00000 AS OldStdCost, 0000000.00000 AS NewStdCost, 
			ROUND(InvtMfgr.Qty_Oh * 
				(ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.LaborCostPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.OverheadPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.OtherCost2PR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.Other_CostPR/FcSys.StdCostExRate,5)),2) -
			ROUND(InvtMfgr.Qty_Oh * (Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost),2) AS ChangeAmt,
			GETDATE() AS RunDate, GETDATE() AS UpDtDate, @cUserId AS Init, '' AS RollType, 0 AS Is_Rel_Gl, 0000000.00000 AS Matl_Cost, 
			ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.LaborCostPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.OverheadPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.OtherCost2PR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.Other_CostPR/FcSys.StdCostExRate,5) AS NewMatlcst,
			(Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost) AS OldMatlcst, Invtmfgr.UniqWh,
			-- 01/05/17 VL added functional currency fields
			0000000.00000 AS OldStdCostPR, 0000000.00000 AS NewStdCostPR, 0000000.00000 AS ChangeAmtPR,	0000000.00000 AS Matl_CostPR, 
			Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR AS NewMatlcstPR,
			Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR AS OldMatlcstPR,
			dbo.fn_GetPresentationCurrency() AS PRFcused_uniq, 
			dbo.fn_GetFunctionalCurrency() AS FuncFcused_uniq,
			1 AS Is_ErAdj
		FROM InvtMfgr INNER JOIN Warehous ON Invtmfgr.UniqWh = Warehous.UniqWh 
		INNER JOIN Inventor ON InvtMfgr.Uniq_Key = Inventor.Uniq_key 
		CROSS JOIN FcSys
		WHERE (Inventor.Matl_Cost <> ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)
		OR Inventor.LaborCost <> ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)
		OR Inventor.OverHead <> ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)
		OR Inventor.OtherCost2 <> ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)
		OR Inventor.Other_Cost <> ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)) 
		AND InvtMfgr.Qty_oh <> 0 
		AND Invtmfgr.Is_Deleted = 0
		AND Invtmfgr.Instore = 0
	END
END


-- 3. WIP
-------------------------
-- Now will get WIP Qty from Kamain, then to update @ZShortWipGroup.WipQty
;WITH zShort AS
(
	SELECT Kamain.Uniq_key, SUM(Act_qty) AS Act_qty, LineShort, SUM(ShortQty) AS ShortQty, Woentry.Wono, Woentry.Balance,
			Woentry.Uniq_key AS ParentUniq, Woentry.Bldqty
		FROM Kamain, Woentry
		WHERE Kamain.Wono = Woentry.Wono
		AND Balance > 0 
		AND (OPENCLOS <> 'Closed' 
		AND OPENCLOS <> 'Cancel')
		GROUP BY Woentry.Wono, Kamain.Uniq_key, LineShort, Woentry.Balance, Woentry.Uniq_key, Woentry.Bldqty
),
ZShortWip AS
(
	SELECT Uniq_key, 
		CASE WHEN LineShort = 0 THEN (((Act_Qty+ShortQty)/BldQty)*Balance) - CASE WHEN (ShortQty>0.00 AND ShortQty <=(((Act_Qty+ShortQty)/BldQty)*Balance)) THEN ShortQty ELSE CASE WHEN ShortQty <=0 THEN 0 ELSE (((Act_Qty+ShortQty)/BldQty)*Balance) END END
			ELSE 
				CASE WHEN Uniq_key = ParentUniq THEN CASE WHEN (Act_Qty + CASE WHEN ShortQty < 0.00 THEN ShortQty ELSE 0.00 END) > Balance THEN BALANCE ELSE (Act_Qty + CASE WHEN ShortQty < 0.00 THEN ShortQty ELSE 0.00 END) END
					ELSE Act_Qty + CASE WHEN ShortQty < 0.00 THEN ShortQty ELSE 0.00 END
					END
			END AS WipQty
		FROM zShort
)
-- 07/21/16 VL create @ZShortWipGroup to replace the CTE ZShortWipGroup, found in Penang's data, it took more than 7 min (I cancelled the code) if I used CTE ZShortWipGroup, after replacing to use table variable @ZShortWipGroup, it only took 10 seconds
--ZShortWipGroup AS
--(
--	SELECT Uniq_key, SUM(WipQty) AS WipQty
--		FROM ZShortWip
--		GROUP BY Uniq_key
--)
INSERT INTO @ZShortWipGroup 
	SELECT Uniq_key, SUM(WipQty) AS WipQty
		FROM ZShortWip
		GROUP BY Uniq_key
-- 02/21/16 VL End}

-- 09/19/17 VL added to separate convert base on FUNC or PR
BEGIN
IF @cCurrBase = 'FUNC'
	BEGIN
	INSERT UPDTSTD 
		SELECT Inventor.Uniq_Key, dbo.fn_GenerateUniqueNumber() AS Uniq_UpDt, Warehous.Wh_Gl_Nbr, ZShortWipGroup.WIPQty AS Qty_Oh,
			0000000.00000 AS OldStdCost, 0000000.00000 AS NewStdCost, 
			0000000.00000 AS ChangeAmt,
			GETDATE() AS RunDate, GETDATE() AS UpDtDate, @cUserId AS Init, '' AS RollType, 0 AS Is_Rel_Gl, 0000000.00000 AS Matl_Cost, 
			Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost AS NewMatlcst,
			Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost AS OldMatlCst, Warehous.UniqWh,
			-- 01/05/17 VL added functional currency fields	
			0000000.00000 AS OldStdCostPR, 0000000.00000 AS NewStdCostPR, 
			ROUND(ZShortWipGroup.WIPQty * 
				(ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)+
				ROUND(Inventor.LaborCost*FcSys.StdCostExRate,5)+
				ROUND(Inventor.Overhead*FcSys.StdCostExRate,5)+
				ROUND(Inventor.OtherCost2*FcSys.StdCostExRate,5)+
				ROUND(Inventor.Other_Cost*FcSys.StdCostExRate,5)),2) - 
			ROUND(ZShortWipGroup.WIPQty * (Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR),2) AS ChangeAmtPR,
			0000000.00000 AS Matl_CostPR, 
			ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)+
				ROUND(Inventor.LaborCost*FcSys.StdCostExRate,5)+
				ROUND(Inventor.Overhead*FcSys.StdCostExRate,5)+
				ROUND(Inventor.OtherCost2*FcSys.StdCostExRate,5)+
				ROUND(Inventor.Other_Cost*FcSys.StdCostExRate,5) AS NewMatlcst,
			Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR AS OldMatlCstPR,
			dbo.fn_GetPresentationCurrency() AS PRFcused_uniq, 
			dbo.fn_GetFunctionalCurrency() AS FuncFcused_uniq,
			1 AS Is_ErAdj
		FROM @ZShortWipGroup ZShortWipGroup INNER JOIN Inventor
		ON ZShortWipGroup.UNIQ_KEY = Inventor.Uniq_key
		CROSS JOIN Warehous 
		CROSS JOIN FcSys
		WHERE (Inventor.Matl_CostPR <> ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)
		OR Inventor.LaborCostPR <> ROUND(Inventor.LaborCost*FcSys.StdCostExRate,5)
		OR Inventor.OverHeadPR <> ROUND(Inventor.OverHead*FcSys.StdCostExRate,5)
		OR Inventor.OtherCost2PR <> ROUND(Inventor.OtherCost2*FcSys.StdCostExRate,5)
		OR Inventor.Other_CostPR <> ROUND(Inventor.Other_Cost*FcSys.StdCostExRate,5))
		AND Warehous.Warehouse = 'WIP   '
		AND ZShortWipGroup.WIPQty <> 0 
	END
ELSE
-- @cCurrBase = 'PR'
	BEGIN
	INSERT UPDTSTD 
		SELECT Inventor.Uniq_Key, dbo.fn_GenerateUniqueNumber() AS Uniq_UpDt, Warehous.Wh_Gl_Nbr, ZShortWipGroup.WIPQty AS Qty_Oh,
			0000000.00000 AS OldStdCost, 0000000.00000 AS NewStdCost, 
			ROUND(ZShortWipGroup.WIPQty * 
				(ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.LaborCostPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.OverheadPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.OtherCost2PR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.Other_CostPR/FcSys.StdCostExRate,5)),2) - 
			ROUND(ZShortWipGroup.WIPQty * (Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost),2) AS ChangeAmt,
			GETDATE() AS RunDate, GETDATE() AS UpDtDate, @cUserId AS Init, '' AS RollType, 0 AS Is_Rel_Gl, 0000000.00000 AS Matl_Cost, 
			ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.LaborCostPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.OverheadPR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.OtherCost2PR/FcSys.StdCostExRate,5)+
				ROUND(Inventor.Other_CostPR/FcSys.StdCostExRate,5) AS NewMatlcst,
			(Inventor.Matl_Cost+Inventor.LaborCost+Inventor.Overhead+Inventor.OtherCost2+Inventor.Other_Cost) AS OldMatlCst, Warehous.UniqWh,
			-- 01/05/17 VL added functional currency fields	
			0000000.00000 AS OldStdCostPR, 0000000.00000 AS NewStdCostPR, 0000000.00000 AS ChangeAmtPR,	0000000.00000 AS Matl_CostPR, 
			Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR AS NewMatlcstPR,
			Inventor.Matl_CostPR+Inventor.LaborCostPR+Inventor.OverheadPR+Inventor.OtherCost2PR+Inventor.Other_CostPR AS OldMatlCstPR,
			dbo.fn_GetPresentationCurrency() AS PRFcused_uniq, 
			dbo.fn_GetFunctionalCurrency() AS FuncFcused_uniq,
			1 AS Is_ErAdj
		FROM @ZShortWipGroup ZShortWipGroup INNER JOIN Inventor
		ON ZShortWipGroup.UNIQ_KEY = Inventor.Uniq_key
		CROSS JOIN Warehous 
		CROSS JOIN FcSys
		WHERE (Inventor.Matl_Cost <> ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)
		OR Inventor.LaborCost <> ROUND(Inventor.LaborCostPR/FcSys.StdCostExRate,5)
		OR Inventor.OverHead <> ROUND(Inventor.OverHeadPR/FcSys.StdCostExRate,5)
		OR Inventor.OtherCost2 <> ROUND(Inventor.OtherCost2PR/FcSys.StdCostExRate,5)
		OR Inventor.Other_Cost <> ROUND(Inventor.Other_CostPR/FcSys.StdCostExRate,5))
		AND Warehous.Warehouse = 'WIP   '
		AND ZShortWipGroup.WIPQty <> 0 
	END
END

-- Update Inventor cost 
-- 09/19/17 VL added to separate convert base on FUNC or PR
BEGIN
IF @cCurrBase = 'FUNC'
	BEGIN
	UPDATE INVENTOR	
		SET Matl_CostPR	= ROUND(Matl_Cost*FcSys.StdCostExRate,5),
			LaborCostPR	= ROUND(LaborCost*FcSys.StdCostExRate,5),
			OverheadPR	= ROUND(Overhead*FcSys.StdCostExRate,5),
			OtherCost2PR	= ROUND(OtherCost2*FcSys.StdCostExRate,5),
			Other_CostPR	= ROUND(Other_Cost*FcSys.StdCostExRate,5),
			StdCostPR		= ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)+ROUND(Inventor.LaborCost*FcSys.StdCostExRate,5)+ROUND(Inventor.Overhead*FcSys.StdCostExRate,5)+ROUND(Inventor.OtherCost2*FcSys.StdCostExRate,5)+ROUND(Inventor.Other_Cost*FcSys.StdCostExRate,5),
			-- 09/19/17 VL added to update TargetPrice field as well, zendesk#1300
			TARGETPRICEPR	= ROUND(TargetPrice*FcSys.StdCostExRate,5)
		FROM Inventor CROSS JOIN FcSys
		WHERE (Part_sourc = 'BUY' 
		OR PART_SOURC = 'MAKE' )
		AND (Matl_CostPR	<> ROUND(Inventor.Matl_Cost*FcSys.StdCostExRate,5)
		OR	LaborCostPR	<> ROUND(Inventor.LaborCost*FcSys.StdCostExRate,5)
		OR	OverheadPR	<> ROUND(Inventor.Overhead*FcSys.StdCostExRate,5)
		OR	OtherCost2PR	<> ROUND(Inventor.OtherCost2*FcSys.StdCostExRate,5)
		OR	Other_CostPR	<> ROUND(Inventor.Other_Cost*FcSys.StdCostExRate,5)
		OR	StdCostPR		<> ROUND(Inventor.StdCost*FcSys.StdCostExRate,5)+ROUND(Inventor.LaborCost*FcSys.StdCostExRate,5)+ROUND(Inventor.Overhead*FcSys.StdCostExRate,5)+ROUND(Inventor.OtherCost2*FcSys.StdCostExRate,5)+ROUND(Inventor.Other_Cost*FcSys.StdCostExRate,5)
		OR	TargetPricePR	<> ROUND(Inventor.TargetPrice*FcSys.StdCostExRate,5))
	END
ELSE
-- @cCurrBase = 'PR'
	BEGIN
	UPDATE INVENTOR	
		SET Matl_Cost	= ROUND(Matl_CostPR/FcSys.StdCostExRate,5),
			LaborCost	= ROUND(LaborCostPR/FcSys.StdCostExRate,5),
			Overhead	= ROUND(OverheadPR/FcSys.StdCostExRate,5),
			OtherCost2	= ROUND(OtherCost2PR/FcSys.StdCostExRate,5),
			Other_Cost	= ROUND(Other_CostPR/FcSys.StdCostExRate,5),
			StdCost		= ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)+ROUND(Inventor.LaborCostPR/FcSys.StdCostExRate,5)+ROUND(Inventor.OverheadPR/FcSys.StdCostExRate,5)+ROUND(Inventor.OtherCost2PR/FcSys.StdCostExRate,5)+ROUND(Inventor.Other_CostPR/FcSys.StdCostExRate,5),
			-- 09/19/17 VL added to update TargetPrice field as well, zendesk#1300
			TargetPrice = ROUND(TargetPricePR/FcSys.StdCostExRate,5)
		FROM Inventor CROSS JOIN FcSys
		WHERE (Part_sourc = 'BUY' 
		OR PART_SOURC = 'MAKE' )
		AND (Matl_Cost	<> ROUND(Inventor.Matl_CostPR/FcSys.StdCostExRate,5)
		OR	LaborCost	<> ROUND(Inventor.LaborCostPR/FcSys.StdCostExRate,5)
		OR	Overhead	<> ROUND(Inventor.OverheadPR/FcSys.StdCostExRate,5)
		OR	OtherCost2	<> ROUND(Inventor.OtherCost2PR/FcSys.StdCostExRate,5)
		OR	Other_Cost	<> ROUND(Inventor.Other_CostPR/FcSys.StdCostExRate,5)
		OR	StdCost		<> ROUND(Inventor.StdCostPR/FcSys.StdCostExRate,5)+ROUND(Inventor.LaborCostPR/FcSys.StdCostExRate,5)+ROUND(Inventor.OverheadPR/FcSys.StdCostExRate,5)+ROUND(Inventor.OtherCost2PR/FcSys.StdCostExRate,5)+ROUND(Inventor.Other_CostPR/FcSys.StdCostExRate,5)
		OR	TargetPrice <> ROUND(TargetPricePR/FcSys.StdCostExRate,5))
	END
END


COMMIT

END