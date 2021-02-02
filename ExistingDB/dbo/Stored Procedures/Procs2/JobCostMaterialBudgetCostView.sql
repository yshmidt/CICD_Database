-- =============================================
-- Author:		
-- Create date: 
-- Description:	<Job cost material budget cost view>
-- Modified: 
-- 08/28/15 VL increased qty numeric(9,2) to (12,2), Ext_cost numeric(12,5) to (25,5),Ext_cost_total numeric(13,5) to (25,5)
--				QtyReqWithoutCEILING numeric(9,2) to (16,2), Ext_cost_totalWithoutCEILING numeric(13,5) to (25,5)
-- 04/10/17 VL added functional currency code
-- =============================================
CREATE PROC [dbo].[JobCostMaterialBudgetCostView] @lcWono  AS char(10) = ' '
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

DECLARE @lcUniq_key char(10), @ldDue_date smalldatetime, @lnStdBldQty numeric(8,0), @lnBldQty numeric(7,0)

SELECT @lcUniq_key = Woentry.Uniq_key, @ldDue_date = Due_date, @lnStdBldQty = CASE WHEN Inventor.UseSetScrp = 1 THEN Inventor.StdBldQty ELSE 0 END, @lnBldQty = Woentry.BLDQTY 
	FROM WOENTRY, INVENTOR 
	WHERE Woentry.UNIQ_KEY = Inventor.UNIQ_KEY
	AND Woentry.WONO = @lcWono
	
INSERT @ZResult EXEC [sp_RollupCost] @lcUniq_key, @ldDue_date, @lnStdBldQty, @lnBldQty

SELECT * 
	FROM @ZResult
	

END