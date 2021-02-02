-- =============================================
-- Author:		
-- Create date: 
-- Description:	Job Cost Material Detail
-- Modified:	
-- 08/28/15 VL increased qty numeric(9,2) to (12,2), Ext_cost numeric(12,5) to (25,5),Ext_cost_total numeric(13,5) to (25,5)
-- QtyReqWithoutCEILING numeric(9,2) to (16,2), Ext_cost_totalWithoutCEILING numeric(13,5) to (25,5)
-- 04/10/17 VL: Added functional currency code
-- 04/25/17 VL use QtyReqTotal to replace SUM(qty)*@lnBldQty as BudgetQty. ZResult.Qty is already has ceiling or round(), so multiply lnBldQty will be much bigger, should multiply script then ceiling()
-- =============================================
CREATE PROC [dbo].[JobCostMaterialDetailView] @lcWono  AS char(10) = ' ', @lcCalculateBy AS varchar(20)
AS
BEGIN

-- 08/28/15 VL increased qty numeric(9,2) to (12,2), Ext_cost numeric(12,5) to (25,5),Ext_cost_total numeric(13,5) to (25,5)
--QtyReqWithoutCEILING numeric(9,2) to (16,2), Ext_cost_totalWithoutCEILING numeric(13,5) to (25,5)
DECLARE @ZResult TABLE (Uniq_key char(10), Part_Sourc char(8), StdCost numeric(13,5),
			Qty numeric(12,2), U_of_meas char(4), Scrap numeric(6,2), SetupScrap numeric(4,0), Phant_Make bit,
			UniqBomNo char(10), Ext_cost numeric(25,5), SetupScrap_Cost numeric(12,5), Ext_cost_total numeric(25,5),
			QtyReqTotal numeric(16,2), StdBldQty numeric(8,0), Ext_costWithoutCEILING numeric(12,5),
			QtyReqWithoutCEILING numeric(16,2), Ext_cost_totalWithoutCEILING numeric(25,5), QtyReqTotalWithoutCEILING numeric(16,2),
			-- 04/10/17 VL added functional currency code
			StdCostPR numeric(13,5), Ext_costPR numeric(25,5), SetupScrap_CostPR numeric(12,5), Ext_cost_totalPR numeric(25,5), Ext_costWithoutCEILINGPR numeric(12,5), Ext_cost_totalWithoutCEILINGPR numeric(25,5));

DECLARE @ZActWoMatCost TABLE (nRecno int, Uniq_key char(10), CostSource char(15), IssuedQty numeric(13,2), UnitCost numeric(13,5), 
								Ext_cost numeric(15,5), TotalRate numeric(3,2))
								
DECLARE @lcUniq_key char(10), @ldDue_date smalldatetime, @lnStdBldQty numeric(8,0), @lnBldQty numeric(7,0)

SELECT @lcUniq_key = Woentry.Uniq_key, @ldDue_date = Due_date, @lnStdBldQty = CASE WHEN Inventor.UseSetScrp = 1 THEN Inventor.StdBldQty ELSE 0 END, @lnBldQty = Woentry.BLDQTY 
	FROM WOENTRY, INVENTOR 
	WHERE Woentry.UNIQ_KEY = Inventor.UNIQ_KEY
	AND Woentry.WONO = @lcWono
	
INSERT @ZResult EXEC [sp_RollupCost] @lcUniq_key, @ldDue_date, @lnStdBldQty, @lnBldQty
INSERT @ZActWoMatCost EXEC [JobCostMaterialActualCostView] @lcWono, @lcCalculateBy

-- Material Budget
;WITH ZMatBudget
AS
(
	-- 04/25/17 VL use QtyReqTotal to replace SUM(qty)*@lnBldQty as BudgetQty. ZResult.Qty is already has ceiling or round(), so multiply lnBldQty will be much bigger, should multiply script then ceiling()
	SELECT Part_no, Revision, Part_class, Part_type, Inventor.Part_sourc, Descript, Zresult.Uniq_key, Zresult.StdCost AS BudgetUnitCost, 
		SUM(QtyReqTotal) AS BudgetQty, SUM(Ext_cost_total) + SUM(SetupScrap_cost)*@lnBldQty AS BudgetExt_cost
		FROM @ZResult Zresult, inventor 
		WHERE Zresult.Uniq_key = Inventor.Uniq_key
		GROUP BY Part_no, Revision, Part_class, Part_type, Inventor.Part_sourc, Descript, Zresult.Uniq_key, Zresult.StdCost
),
-- Material Atcual join Material Budget
ZMatActual
AS
(
	SELECT ZMatBudget.*, ZActWoMatCost.CostSource, ZActWoMatCost.IssuedQty, ZActWoMatCost.UnitCost AS ActUnitCost,
		ZActWoMatCost.Ext_cost AS ActExt_cost, ZActWoMatCost.TotalRate
		FROM @ZActWoMatCost ZActWoMatCost, ZMatBudget
		WHERE ZActWoMatCost.Uniq_key = ZMatBudget.Uniq_key
),
-- In Budget not in Actual
ZBudgetOnly
AS
(
	SELECT ZMatBudget.* 
		FROM ZMatBudget
		WHERE Uniq_key NOT IN (SELECT Uniq_key FROM ZMatActual)
),
-- In Actual not in Budget
ZActualOnly
AS
(
	SELECT Part_no, Revision, Part_class, Part_type, Part_sourc, Descript, ZActWoMatCost.Uniq_key, ZActWoMatCost.CostSource, ZActWoMatCost.IssuedQty, ZActWoMatCost.UnitCost AS ActUnitCost,
		ZActWoMatCost.Ext_cost AS ActExt_cost, ZActWoMatCost.TotalRate
		FROM @ZActWoMatCost ZActWoMatCost, Inventor
	WHERE ZActWoMatCost.Uniq_key = Inventor.Uniq_key
	AND ZActWoMatCost.Uniq_key NOT IN (SELECT Uniq_key FROM ZMatBudget)
)

-- Final result
SELECT Part_no, Revision,Part_class, Part_Type, Part_Sourc, Descript, BudgetQty, BudgetUnitCost, BudgetExt_cost, 
		IssuedQty, ActUnitCost, ActExt_cost, CostSource, TotalRate, Uniq_key, 'Both' AS Type -- Has both budget and actual cost
	FROM ZMatActual
UNION
SELECT Part_no, Revision,Part_class, Part_Type, Part_Sourc, Descript, BudgetQty, BudgetUnitCost, BudgetExt_cost, 
		0000000000.00 AS IssuedQty, 0000000.00000 AS ActUnitCost, 000000000.00000 AS ActExt_Cost, SPACE(15) AS CostSource, 
		0.00 AS TotalRate, Uniq_key, 'Budget' AS Type -- Has only budget
	FROM ZBudgetOnly
UNION
SELECT Part_no, Revision,Part_class, Part_Type, Part_Sourc, Descript, 0000000000.00 AS BUdgetQty, 0000000.00000 AS BudgetUnitCost,
		000000000.00000 AS BudgetExgt_cost, IssuedQty, ActUnitCost, ActExt_cost, CostSource, TotalRate, Uniq_key, 'Actual' AS Type -- Has only actual
	FROM ZActualOnly
ORDER BY PART_NO, Revision

END