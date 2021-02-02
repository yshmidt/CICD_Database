
CREATE PROC [dbo].[sp_GetJobCostMaterialBudgetCost] @lcWono AS char(10) = ' '

AS

BEGIN

-- =============================================

-- Author: Vicky

-- Create date: 10/15/2013

-- Description: Procedure to return sum of cost from JobCostMaterialBudgetCostView
-- Modification:
-- 08/28/15 VL increased qty numeric(9,2) to (12,2), Ext_cost numeric(12,5) to (25,5),Ext_cost_total numeric(13,5) to (25,5)
--				QtyReqWithoutCEILING numeric(9,2) to (16,2), Ext_cost_totalWithoutCEILING numeric(13,5) to (25,5)
--				(didn't find where this SP is used)

-- =============================================

-- 08/28/15 VL increased qty numeric(9,2) to (12,2), Ext_cost numeric(12,5) to (25,5),Ext_cost_total numeric(13,5) to (25,5)
--QtyReqWithoutCEILING numeric(9,2) to (16,2), Ext_cost_totalWithoutCEILING numeric(13,5) to (25,5)
DECLARE @ZResult TABLE (Uniq_key char(10), Part_Sourc char(8), StdCost numeric(13,5),
			Qty numeric(12,2), U_of_meas char(4), Scrap numeric(6,2), SetupScrap numeric(4,0), Phant_Make bit,
			UniqBomNo char(10), Ext_cost numeric(25,5), SetupScrap_Cost numeric(12,5), Ext_cost_total numeric(25,5),
			QtyReqTotal numeric(16,2), StdBldQty numeric(8,0), Ext_costWithoutCEILING numeric(12,5),
			QtyReqWithoutCEILING numeric(16,2), Ext_cost_totalWithoutCEILING numeric(25,5), QtyReqTotalWithoutCEILING numeric(16,2));

DECLARE @lcUniq_key char(10), @ldDue_date smalldatetime, @lnStdBldQty numeric(8,0), @lnBldQty numeric(7,0)

SELECT @lcUniq_key = Woentry.Uniq_key, @ldDue_date = Due_date, @lnStdBldQty = CASE WHEN Inventor.UseSetScrp = 1 THEN Inventor.StdBldQty ELSE 0 END, @lnBldQty = Woentry.BLDQTY

FROM WOENTRY, INVENTOR

WHERE Woentry.UNIQ_KEY = Inventor.UNIQ_KEY

AND Woentry.WONO = @lcWono

INSERT @ZResult EXEC [sp_RollupCost] @lcUniq_key, @ldDue_date, @lnStdBldQty, @lnBldQty

SELECT ISNULL(SUM(Ext_cost_total),0)+ISNULL(SUM(SetupScrap_cost),0)*@lnBldQty

FROM @ZResult

END