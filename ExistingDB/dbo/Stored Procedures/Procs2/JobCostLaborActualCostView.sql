-- =============================================
-- Author:		Vicky Lu
-- Create date: ?
-- Description:	Get Labor Actual cost for the job
-- Modification: 
--	09/02/15	VL	Changed to not getting Depts.Shoprate to calculate Labor cost, will get Actcost data (if any), then depts.shoprate to calculate labor cost
-- =============================================
CREATE PROC [dbo].[JobCostLaborActualCostView] @lcWono  AS char(10) = ' '
AS
BEGIN
	-- 09/02/15 VL comment out old code
	--SELECT Wono, Dept_lgt.Dept_id, Dept_lgt.Number, Time_used, Date_in, Date_out, Log_init, Logout_ini, Overtime, Is_holiday, 
	--	Time_used + Overtime AS Totaltime, Shoprate, (Time_used+Overtime)/60*Shoprate as LaborCost, Dept_name
	--FROM Dept_lgt, Depts
	--WHERE Wono = @lcWono
	--AND Dept_lgt.Dept_id = Depts.Dept_id 
	--ORDER BY Date_in, Dept_id, Log_init 

	-- 09/02/15 VL added the temp table variable to get labor cost from ActCost
	DECLARE @ZLabBudgetbyRouting TABLE (Uniq_key char(10), Dept_id char(4), Uniqnumber char(10), Activ_id char(4),
							CostRate numeric(7,3), Number numeric(4,0))
	DECLARE @lnBldQty numeric(7,0), @lcUniq_key char(10)
	SELECT @lcUniq_key = Uniq_key, @lnBldQty = BldQty FROM WOENTRY WHERE WONO = @lcWono

	-- Get the code from JobCostLaborBudgetCostView @lnXxPrcsTime = 1	-- calculate by routing setup part, 
	-- found no matter @lnXxPrcsTime = 1 or 2, use the same method to get rate from Actcost (if has) or Depts (if no records in Actcost) to calculate actual cost
	;WITH ZJobLaborHrs -- Routing setup time/run time for this uniq_key
	AS
	(
	SELECT Quotdept.Uniq_key, Quotdept.Dept_id, Quotdept.UniqNumber, Quotdept.Number
	FROM Quotdept
	WHERE Quotdept.Uniq_key = @lcUniq_key
	),
	ZJobLaborActCost -- activity cost
	AS
	(
	SELECT ZJobLaborHrs.Uniq_key, ZJobLaborHrs.Dept_id, 
		ZJobLaborHrs.UniqNumber, Quotdpdt.Activ_id, Actcost.Cost_hr AS CostRate, ZJobLaborHrs.Number
	FROM ZJobLaborHrs ,Quotdpdt, ActCost
	WHERE Quotdpdt.Uniq_key = ZJobLaborHrs.Uniq_key
	AND Quotdpdt.Uniqnumber = ZJobLaborHrs.Uniqnumber
	AND Actcost.Activ_id = Quotdpdt.Activ_id
	),
	ZJobLaborWcCost -- work center cost (no activity)
	AS
	(
	SELECT ZJobLaborHrs.Uniq_key, ZJobLaborHrs.Dept_id,
		ZJobLaborHrs.UniqNumber, SPACE(4) AS Activ_id, Depts.Shoprate AS CostRate, ZJobLaborHrs.Number
		FROM ZJobLaborHrs, Depts
		WHERE Depts.Dept_id = ZJobLaborHrs.Dept_id
		AND UniqNumber NOT IN (SELECT UniqNumber FROM ZJobLaborActCost)
	)
	INSERT @ZLabBudgetbyRouting
	SELECT *
		FROM ZJobLaborActCost
	UNION
	SELECT * 
		FROM ZJobLaborWcCost
	-- End of insert @ZLabBudgetbyRouting



	;WITH ZLaborBudgetGroupbyUniqnumber -- get from [JobCostLaborBudgetCostView] but group by uniqnumber to get costrate by wc
	AS
	(
		SELECT Dept_id, Number, Uniqnumber, ISNULL(SUM(CostRate),0.00) AS CostRate
			FROM @ZLabBudgetbyRouting
			GROUP BY Dept_id, Number, Uniqnumber
	)

	SELECT Wono, Dept_lgt.Dept_id, Dept_lgt.Number, Time_used, Date_in, Date_out, Log_init, Logout_ini, Overtime, Is_holiday, 
			Time_used + Overtime AS Totaltime, ZLaborBudgetGroupbyUniqnumber.CostRate AS Shoprate, (Time_used+Overtime)/60*ZLaborBudgetGroupbyUniqnumber.CostRate as LaborCost, Dept_name
		FROM Dept_lgt, Depts, ZLaborBudgetGroupbyUniqnumber
		WHERE Wono = @lcWono
		AND Dept_lgt.Dept_id = Depts.Dept_id 
		AND Dept_lgt.Dept_ID = ZLaborBudgetGroupbyUniqnumber.Dept_id 
		AND Dept_lgt.Number = ZLaborBudgetGroupbyUniqnumber.Number
		ORDER BY Date_in, Dept_id, Log_init

		-- Calculate actual labor cost
	--SELECT SUM(LaborCost)

END