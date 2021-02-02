CREATE PROC [dbo].[JobCostLaborBudgetCostView] @lcWono  AS char(10) = ' '
AS
BEGIN

DECLARE @lnXxPrcsTime numeric(1,0), @lnBldQty numeric(7,0), @lcUniq_key char(10)

SELECT @lnXxPrcsTime = XxPrcsTime FROM SHOPFSET
SELECT @lcUniq_key = Uniq_key, @lnBldQty = BldQty FROM WOENTRY WHERE WONO = @lcWono
	
-- Based on ShopfSet.xxprcstime to calculate by routing setup or by activity setup

BEGIN
IF @lnXxPrcsTime = 1	-- calculate by routing setup
	BEGIN
	
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
	ZJobLaborActCost -- activity cost
	AS
	(
	SELECT ZJobLaborHrs.Uniq_key, ZJobLaborHrs.Dept_id, ZJobLaborHrs.LaborHrs, 
		ZJobLaborHrs.UniqNumber, Quotdpdt.Activ_id, Actcost.Cost_hr AS CostRate, ZJobLaborHrs.Number
	FROM ZJobLaborHrs ,Quotdpdt, ActCost
	WHERE Quotdpdt.Uniq_key = ZJobLaborHrs.Uniq_key
	AND Quotdpdt.Uniqnumber = ZJobLaborHrs.Uniqnumber
	AND Actcost.Activ_id = Quotdpdt.Activ_id
	),
	ZJobLaborWcCost -- work center cost (no activity)
	AS
	(
	SELECT ZJobLaborHrs.Uniq_key, ZJobLaborHrs.Dept_id,ZJobLaborHrs.LaborHrs,
		ZJobLaborHrs.UniqNumber, SPACE(4) AS Activ_id, Depts.Shoprate AS CostRate, ZJobLaborHrs.Number
		FROM ZJobLaborHrs, Depts
		WHERE Depts.Dept_id = ZJobLaborHrs.Dept_id
		AND UniqNumber NOT IN (SELECT UniqNumber FROM ZJobLaborActCost)
	)
	
	SELECT *
		FROM ZJobLaborActCost
	UNION
	SELECT * 
		FROM ZJobLaborWcCost
		
	END
	-- Get the total labor budget cost is SUM(LaborHrs*CostRate)
ELSE
	-- @lnXxPrcsTime = 2	calculate by activity setup
	BEGIN
	;WITH ZJobCostSetupSum
	AS
	-- 09/01/15 VL added Rate field to use in JobCostLaborDetailView
	(SELECT Time_min/60 AS TotalTime, QuotDept.Dept_id, Depts.Shoprate, Actcost.Cost_hr, QuotDpdt.Activ_id, 'SETUPTIME' AS Type, ISNULL(Actcost.Cost_hr, Depts.Shoprate) AS Rate
		FROM QuotDept, Depts, ActSetTp, QuotDpdt LEFT OUTER JOIN Actcost
		ON Quotdpdt.Activ_id = ActCost.Activ_id
		WHERE QuotDpDt.Uniq_key = @lcUniq_key
		AND QuotDept.UniqNumber = Quotdpdt.UniqNumber
		AND Quotdept.Dept_id = Depts.Dept_id
		AND QuotDpDt.Actsettpid	= ActSetTp.Actsettpid
		AND QuotDpDt.Activ_id = ActSetTp.Activ_id
	),
	ZPhantomSubSelect -- get all part number for the uniq_key first
	AS
	(
	-- 02/17/15 VL added 10th parameter to filter out inactive part
	SELECT * FROM [dbo].[fn_PhantomSubSelect] (@lcUniq_key, 1, 'T', GETDATE(), 'F', 'T', 'F', 0, 0,0)
	),
	ZActPkg -- Get records for work center which has activity and activity package records
	AS
	(
	SELECT Bomparent, Uniq_key, ZPhantomSubSelect.Dept_id, ReqQty AS Qty, UniqPkg, Deptsdet.Activ_id, Vol_hr, ReqQty/Vol_hr AS RunTimeH 
		FROM ActPkg, Deptsdet, ZPhantomSubSelect
		WHERE ActPkg.Activ_id = Deptsdet.Activ_id 
		AND Deptsdet.Dept_id = ZPhantomSubSelect.Dept_id
	),
	ZActNoPkg -- Get records for work centers which only has activity but no activity package
	AS
	(
	SELECT Bomparent, Uniq_key, ZPhantomSubSelect.Dept_id, ZPhantomSubSelect.ReqQty AS Qty, SPACE(10) AS UniqPkg, Deptsdet.Activ_id, 0.00 AS Vol_hr, 0.0000 AS RunTimeH
		FROM Deptsdet, ZPhantomSubSelect
		WHERE Deptsdet.Dept_id = ZPhantomSubSelect.Dept_id
		AND Deptsdet.Dept_id+Deptsdet.Activ_id NOT IN (SELECT Dept_id+Activ_id FROM ZActPkg)
	),
	ZOnlyDept -- Get records for work centers which only has work centers, no activity, no activity package
	AS
	(
	SELECT Bomparent, Uniq_key, ZPhantomSubSelect.Dept_id, ZPhantomSubSelect.ReqQty AS Qty, SPACE(10) AS UniqPkg, SPACE(4) AS Activd, 0.00 AS Vol_hr, 0.0000 AS RunTimeH
		FROM ZPhantomSubSelect
		WHERE Dept_id NOT IN (SELECT Dept_id FROM Deptsdet)
	),
	BomPkg
	AS
	(
	SELECT * FROM ZActPkg
	UNION
	SELECT * FROM ZActNoPkg
	UNION
	SELECT * FROM ZOnlyDept
	),
	ZJobCostRuntimeSum
	AS
	(
	-- 09/01/15 VL added Rate field to use in JobCostLaborDetailView
	SELECT @lnBldQty*RunTimeH AS TotalTime, BomPkg.Dept_id, Depts.Shoprate, Actcost.Cost_hr, Bompkg.Activ_id, 'RUNTIME  ' AS Type, ISNULL(Actcost.Cost_hr, Depts.Shoprate) AS Rate
		FROM Depts,BomPkg LEFT OUTER JOIN Actcost
		ON BomPkg.Activ_id=ActCost.Activ_id
		WHERE BomPkg.Dept_id=Depts.Dept_id
	)

	-- Join ZJobCostSetupSum and ZJobCostRuntimeSum
	SELECT * 
		FROM ZJobCostSetupSum
	UNION
	SELECT * 
		FROM ZJobCostRuntimeSum

	-- Total Labor budget cost
	--SELECT SUM(TotalTime*CASE WHEN Cost_Hr IS NULL THEN ShopRate ELSE Cost_hr END)
	END		
END -- END OF @lnXxPrcsTime = 1

END