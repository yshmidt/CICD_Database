CREATE PROC [dbo].[JobCostLaborDetailView] @lcWono  AS char(10) = ' '
AS
BEGIN

-- 01/20/14 VL change to use LEFT OUTER JOIN in last SQL
-- 10/31/16 VL changed LaborHrs from numeric(7,2) to (11,2) to prevent getting numeric overflow error, change all time field from (7,2) to (11,2)
DECLARE @ZLabActTotal TABLE (Wono char(10), Dept_id char(4), Number numeric(4,0), Time_Used numeric(6,0), Date_in smalldatetime,
						Date_out smalldatetime, Log_init char(8), Logout_ini char(8), Overtime numeric(6,0), Is_Holiday bit,
						TotalTime numeric(6,0), Shoprate numeric(7,3), Laborcost numeric(8,2), Dept_name char(25))

-- 10/31/16 VL changed LaborHrs from numeric(7,2) to (11,2) to prevent getting numeric overflow error
DECLARE @ZLabBudgetbyRouting TABLE (Uniq_key char(10), Dept_id char(4), LaborHrs numeric(11,2), Uniqnumber char(10), Activ_id char(4),
							CostRate numeric(7,3), Number numeric(4,0))

-- 10/31/16 VL changed LaborHrs from numeric(7,2) to (11,2) to prevent getting numeric overflow error, change all time field from (7,2) to (11,2)
DECLARE @ZLabBudgetbyActivity TABLE (TotalTime numeric(13,3), Dept_id char(4), Shoprate numeric(7,3), Cost_hr numeric(11,2), Activ_id char(4), Type char(9), Rate numeric(7,3))
						
					
DECLARE @lnXxPrcsTime numeric(1,0), @lnBldQty numeric(7,0), @lcUniq_key char(10)
SELECT @lnXxPrcsTime = XxPrcsTime FROM SHOPFSET
SELECT @lcUniq_key = Uniq_key, @lnBldQty = BldQty FROM WOENTRY WHERE WONO = @lcWono

INSERT @ZLabActTotal EXEC [JobCostLaborActualCostView] @lcWono
	
BEGIN
IF @lnXxPrcsTime = 1	-- calculate by routing setup
	BEGIN

	INSERT @ZLabBudgetbyRouting EXEC [JobCostLaborBudgetCostView] @lcWono

	;WITH ZJobLaborHrs -- Routing setup time/run time for this uniq_key
	AS
	(
		SELECT Quotdept.Uniq_key, Quotdept.Dept_id, Quotdept.UniqNumber, 
			((@lnBldQty*Quotdept.Runtimesec+Quotdept.Setupsec)/3600) AS LaborHrs,
			(@lnBldQty*Quotdept.Runtimesec)/3600 AS RunTimeH, Quotdept.Setupsec/3600 AS SetupTimeH,
			Quotdept.Number, Quotdept.Setupsec, Quotdept.Runtimesec
		FROM Quotdept
		WHERE Quotdept.Uniq_key = @lcUniq_key
	),
	ZLaborBudgetGroupbyUniqnumber -- get from [JobCostLaborBudgetCostView] but group by uniqnumber to get costrate by wc
	AS
	(
		SELECT Uniqnumber, ISNULL(SUM(CostRate),0.00) AS CostRate
			FROM @ZLabBudgetbyRouting
			GROUP BY UniqNumber
	),
	ZLaborActualGroupByNumber -- get from [JobCostLaborActualCostView] but group by number to get time by wc
	AS
	(
		SELECT Dept_id, Number, ISNULL(SUM(Totaltime/60),0.00) AS TotalTimeH, Shoprate, ISNULL(SUM(LaborCost),0.00) AS ActualCost
			FROM @ZLabActTotal
			GROUP BY dept_id, Number, shoprate
	),
	-- 09/01/15 VL group the result by dept_id, so duplicate WC with different activity cost will be summed up
	-- Also join with dept_qty at last to get order by dept_qty.number
	--SELECT ZJobLaborHrs.Dept_id, Dept_name, CAST(ISNULL(LaborHrs,0.00) AS DECIMAL (7,2)) AS BudgetTimeH, CAST(ISNULL(TotalTimeH,0.00) AS DECIMAL(7,2)) AS ActualTimeH, 
	--		CAST(ISNULL(ZJobLaborHrs.LaborHrs,0)-ISNULL(ZLaborActualGroupByNumber.TotalTimeH,0) AS DECIMAL (7,2)) AS VarTimeH,
	--		CAST(ISNULL(ZLaborBudgetGroupbyUniqnumber.CostRate*ZJobLaborHrs.LaborHrs,0.00) AS DECIMAL (13,5)) AS BudgetCost, 
	--		CAST(ISNULL(ZLaborActualGroupByNumber.ActualCost,0.00) AS DECIMAL (13,5)) AS ActualCost,
	--		CAST(ISNULL(ZLaborBudgetGroupbyUniqnumber.CostRate,0)*ISNULL(ZJobLaborHrs.LaborHrs,0) - ISNULL(ZLaborActualGroupByNumber.ActualCost,0) AS DECIMAL (13,5)) AS VarCost, 
	--		ZJobLaborHrs.Number, CAST(RunTimeH AS DECIMAL (7,2)) AS BudgetRunTimeH, CAST(SetupTimeH AS DECIMAL (7,2)) AS BudgetSetupTimeH
	--	FROM ZLaborBudgetGroupbyUniqnumber, Depts, ZJobLaborHrs LEFT OUTER JOIN ZLaborActualGroupByNumber
	--	ON  ZJobLaborHrs.NUMBER = ZLaborActualGroupByNumber.Number
	--	WHERE ZJobLaborHrs.UNIQNUMBER = ZLaborBudgetGroupbyUniqnumber.UniqNumber
	--	AND ZJobLaborHrs.DEPT_ID = Depts.Dept_id
	--	ORDER BY ZJobLaborHrs.Number
	ZLbCost
	AS
	(
	-- 10/31/16 VL changed LaborHrs from numeric(7,2) to (11,2) to prevent getting numeric overflow error, change all time field from (7,2) to (11,2)
	SELECT ZJobLaborHrs.Dept_id, Depts.Dept_name, CAST(ISNULL(SUM(LaborHrs),0.00) AS DECIMAL (11,2)) AS BudgetTimeH, CAST(ISNULL(SUM(TotalTimeH),0.00) AS DECIMAL(11,2)) AS ActualTimeH, 
			CAST(ISNULL(SUM(ZJobLaborHrs.LaborHrs),0)-ISNULL(SUM(ZLaborActualGroupByNumber.TotalTimeH),0) AS DECIMAL (11,2)) AS VarTimeH,
			CAST(ISNULL(SUM(ZLaborBudgetGroupbyUniqnumber.CostRate*ZJobLaborHrs.LaborHrs),0.00) AS DECIMAL (13,5)) AS BudgetCost, 
			CAST(ISNULL(SUM(ZLaborActualGroupByNumber.ActualCost),0.00) AS DECIMAL (13,5)) AS ActualCost,
			CAST(ISNULL(SUM(ZLaborBudgetGroupbyUniqnumber.CostRate),0)*ISNULL(SUM(ZJobLaborHrs.LaborHrs),0) - ISNULL(SUM(ZLaborActualGroupByNumber.ActualCost),0) AS DECIMAL (13,5)) AS VarCost, 
			CAST(SUM(RunTimeH) AS DECIMAL (11,2)) AS BudgetRunTimeH, CAST(SUM(SetupTimeH) AS DECIMAL (11,2)) AS BudgetSetupTimeH
		FROM ZLaborBudgetGroupbyUniqnumber, Depts, ZJobLaborHrs LEFT OUTER JOIN ZLaborActualGroupByNumber
		ON  ZJobLaborHrs.Dept_id = ZLaborActualGroupByNumber.Dept_id
		AND ZJobLaborHrs.NUMBER = ZLaborActualGroupByNumber.Number
		WHERE ZJobLaborHrs.UNIQNUMBER = ZLaborBudgetGroupbyUniqnumber.UniqNumber
		AND ZJobLaborHrs.DEPT_ID = Depts.Dept_id
		GROUP BY ZJobLaborHrs.Dept_id, Depts.Dept_name
	),
	ZDeptOrder 
	AS
	(SELECT Dept_id, number, ROW_NUMBER() OVER (PARTITION BY Dept_id ORDER BY Number) AS N FROM Dept_qty where wono = @lcWono)

	SELECT ZLbCost.*
		FROM ZLbCost LEFT OUTER JOIN ZDeptOrder
		ON ZLbCost.Dept_id = ZDeptOrder.Dept_id
		AND ZDeptOrder.N = 1
		ORDER BY Number
		
	END	
ELSE
	BEGIN
	
	INSERT @ZLabBudgetbyActivity EXEC [JobCostLaborBudgetCostView] @lcWono
	
	;WITH ZDept 
	AS
	(
		SELECT DISTINCT ZLabBudgetbyActivity.Dept_id, Dept_name, Number 
			FROM @ZLabBudgetbyActivity ZLabBudgetbyActivity, DEPTS
			WHERE ZLabBudgetbyActivity.Dept_id = Depts.DEPT_ID
	),
	ZLabSetupTimeSum
	AS
	(
		SELECT Dept_id, ISNULL(SUM(TotalTime),0.00) AS TotalSetupTime, ISNULL(SUM(TotalTime*ISNULL(Cost_hr, ShopRate)),0.00) AS TotalSetupLabor
			FROM @ZLabBudgetbyActivity ZLabBudgetbyActivity
			WHERE TYPE = 'SETUPTIME'
			GROUP BY Dept_id
	),
	ZLabRunTimeSum
	AS
	(
		SELECT Dept_id, ISNULL(SUM(TotalTime),0.00) AS TotalRunTime, ISNULL(SUM(TotalTime*ISNULL(Cost_hr, ShopRate)),0.00) AS TotalRunLabor
			FROM @ZLabBudgetbyActivity ZLabBudgetbyActivity
			WHERE TYPE = 'RUNTIME  '
			GROUP BY Dept_id
	),
	ZLaborActualGroupByNumber -- get from [JobCostLaborActualCostView] but group by number to get time by wc
	AS
	(
		-- 09/02/15 VL changed not group by number, shoprate, just group by dept_id
		--SELECT Dept_id, Number, ISNULL(SUM(Totaltime/60),0.00) AS TotalTimeH, Shoprate, ISNULL(SUM(LaborCost),0.00) AS ActualCost
		--	FROM @ZLabActTotal
		--	GROUP BY dept_id, Number, shoprate
		SELECT Dept_id, ISNULL(SUM(Totaltime/60),0.00) AS TotalTimeH, ISNULL(SUM(LaborCost),0.00) AS ActualCost
			FROM @ZLabActTotal
			GROUP BY dept_id
	),
	-- 09/01/15 VL group the result by dept_id, so duplicate WC with different activity cost will be summed up				
	-- Also join with dept_qty at last to get order by number
	--SELECT ZDept.Dept_id, Dept_name, CAST(ISNULL(ZLabSetupTimeSum.TotalSetupTime,0.00) AS DECIMAL (7,2)) AS TotalSetupTime, 
	--		CAST(ISNULL(ZLabRunTimeSum.TotalRunTime,0.00) AS DECIMAL (7,2)) AS TotalRunTime, 
	--		CAST(ISNULL(ZLabSetupTimeSum.TotalSetupTime,0)+ISNULL(ZLabRunTimeSum.TotalRunTime,0) AS DECIMAL (7,2)) AS BudgetTimeH, 
	--		CAST(ISNULL(ZLaborActualGroupByNumber.TotalTimeH,0.00) AS DECIMAL (7,2)) AS ActualTimeH, 
	--		CAST(ISNULL(ZLabSetupTimeSum.TotalSetupTime,0)+ISNULL(ZLabRunTimeSum.TotalRunTime,0)-ISNULL(ZLaborActualGroupByNumber.TotalTimeH,0) AS DECIMAL (7,2)) AS VarTimeH,
	--		CAST(ISNULL(ZLabRunTimeSum.TotalRunLabor,0)+ISNULL(ZLabSetupTimeSum.TotalSetupLabor,0) AS DECIMAL (13,5)) AS BudgetCost,
	--		CAST(ISNULL(ZLaborActualGroupByNumber.ActualCost,0.00) AS DECIMAL (13,5)) AS ActualCost, 
	--		CAST(ISNULL(ZLabRunTimeSum.TotalRunLabor,0)+ISNULL(ZLabSetupTimeSum.TotalSetupLabor,0)-ISNULL(ZLaborActualGroupByNumber.ActualCost,0) AS DECIMAL (13,5)) AS VarCost, ZDept.Number
	--	FROM ZDept LEFT OUTER JOIN ZLabRunTimeSum ON ZDept.Dept_id = ZLabRunTimeSum.Dept_id 
	--	LEFT OUTER JOIN ZLabSetupTimeSum ON ZDept.Dept_id = ZLabSetupTimeSum.Dept_id 
	--	LEFT OUTER JOIN ZLaborActualGroupByNumber ON ZDept.Dept_id = ZLaborActualGroupByNumber.Dept_id
	--	ORDER BY Number
	ZLbCost
	AS
	(
	-- 10/31/16 VL changed LaborHrs from numeric(7,2) to (11,2) to prevent getting numeric overflow error, change all time field from (7,2) to (11,2)
	SELECT ZDept.Dept_id, Dept_name, CAST(ISNULL(SUM(ZLabSetupTimeSum.TotalSetupTime),0.00) AS DECIMAL (11,2)) AS TotalSetupTime, 
			CAST(ISNULL(SUM(ZLabRunTimeSum.TotalRunTime),0.00) AS DECIMAL (11,2)) AS TotalRunTime, 
			CAST(ISNULL(SUM(ZLabSetupTimeSum.TotalSetupTime),0)+ISNULL(SUM(ZLabRunTimeSum.TotalRunTime),0) AS DECIMAL (11,2)) AS BudgetTimeH, 
			CAST(ISNULL(SUM(ZLaborActualGroupByNumber.TotalTimeH),0.00) AS DECIMAL (11,2)) AS ActualTimeH, 
			CAST(ISNULL(SUM(ZLabSetupTimeSum.TotalSetupTime),0)+ISNULL(SUM(ZLabRunTimeSum.TotalRunTime),0)-ISNULL(SUM(ZLaborActualGroupByNumber.TotalTimeH),0) AS DECIMAL (11,2)) AS VarTimeH,
			CAST(ISNULL(SUM(ZLabRunTimeSum.TotalRunLabor),0)+ISNULL(SUM(ZLabSetupTimeSum.TotalSetupLabor),0) AS DECIMAL (13,5)) AS BudgetCost,
			CAST(ISNULL(SUM(ZLaborActualGroupByNumber.ActualCost),0.00) AS DECIMAL (13,5)) AS ActualCost, 
			CAST(ISNULL(SUM(ZLabRunTimeSum.TotalRunLabor),0)+ISNULL(SUM(ZLabSetupTimeSum.TotalSetupLabor),0)-ISNULL(SUM(ZLaborActualGroupByNumber.ActualCost),0) AS DECIMAL (13,5)) AS VarCost
		FROM ZDept LEFT OUTER JOIN ZLabRunTimeSum ON ZDept.Dept_id = ZLabRunTimeSum.Dept_id 
		LEFT OUTER JOIN ZLabSetupTimeSum ON ZDept.Dept_id = ZLabSetupTimeSum.Dept_id 
		LEFT OUTER JOIN ZLaborActualGroupByNumber ON ZDept.Dept_id = ZLaborActualGroupByNumber.Dept_id
		GROUP BY ZDept.Dept_id, ZDept.Dept_name
	),
	ZDeptOrder 
	AS
	(SELECT Dept_id, number, ROW_NUMBER() OVER (PARTITION BY Dept_id ORDER BY Number) AS N FROM Dept_qty where wono = @lcWono)

	SELECT ZLbCost.*
		FROM ZLbCost LEFT OUTER JOIN ZDeptOrder
		ON ZLbCost.Dept_id = ZDeptOrder.Dept_id
		AND ZDeptOrder.N = 1
		ORDER BY Number
	END

END

END