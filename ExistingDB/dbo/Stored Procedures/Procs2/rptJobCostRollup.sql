-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/31/2018
-- Description:	Job Cost working progress
-- =============================================
CREATE PROCEDURE [dbo].[rptJobCostRollup] 
	-- Add the parameters for the stored procedure here
	@lcwono char(10) = null, 
	@userid uniqueidentifier = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	if OBJECT_ID('tempdb..#tJobCost') IS NOT NULL
		DROP TABLE #tJobCost

	
	;with budget
	as
	(
	select w.wono,w.uniq_key,w.uniquerout,
	w.BLDQTY,q.dept_id,q.number,q.SETUPSEC,q.RUNTIMESEC,
	q.SETUPSEC/3600.00 as budgetSetupTimeH,
	(q.RUNTIMESEC/3600.00)*w.bldqty as budgetRunTimeH ,
	(q.SETUPSEC/3600.00)*d.shoprate as budgetSetupCost,
	(q.RUNTIMESEC/3600.00)*w.bldqty * d.shoprate as budgetRunTimeCost
	from woentry w inner join QUOTDEPT q on w.UNIQ_KEY=q.UNIQ_KEY and w.uniquerout=q.uniqueRout
	inner join depts d on q.DEPT_ID=d.dept_id
	where w.WONO=@lcwono 
	--order by number
	)
	,
	Actual
	as
	(
	-- get actual
	select TMLOGTP.TMLOG_DESC,dept_lgt.WONO, dept_lgt.dept_id,dept_lgt.number,
	sum(TIME_USED)/60 as TotalTimeH,
	(sum(TIME_USED)/60) * a.PayRate as TotalCost
	from dept_lgt inner join TMLOGTP on dept_lgt.TMLOGTPUK=tmlogtp.TMLOGTPUK  
	inner join aspnet_Profile a on dept_lgt.inUserId=a.UserId
	where wono=@lcwono
	GROUP BY  TMLOGTP.TMLOG_DESC,dept_lgt.WONO, dept_lgt.dept_id,dept_lgt.number,a.PayRate
	--order by wono,number
	)
	Select a.TMLOG_DESC,a.wono,a.dept_id,a.number,a.TotalTimeH as ActualTimeH,bsetup.budgetSetupTimeH as budgetTimeH, 
	a.TotalTimeH-bsetup.budgetSetupTimeH as timeDeltaH,
	a.totalCost as actualCostH,bsetup.budgetSetupCost as budgetCost,
	a.totalCost-bsetup.budgetSetupCost as costDelta
	into #tJobcost
	from actual A inner JOIN
	BUDGET BSetup on a.wono=bSetup.wono and a.DEPT_ID=BSetup.DEPT_ID and a.NUMBER=BSetup.number and a.TMLOG_DESC='Setup Time'
	UNION
	Select a.TMLOG_DESC,a.wono,a.dept_id,a.number,a.TotalTimeH,brun.budgetRunTimeH as budgetTimeH, 
	a.TotalTimeH-brun.budgetRunTimeH as timeDeltaH,
	a.totalCost,brun.budgetRunTimeCost as budgetCost ,
	a.totalCost-brun.budgetRunTimeCost  as costDelta
	from actual A inner JOIN
	BUDGET BRUN on a.wono=brun.wono and a.DEPT_ID=Brun.DEPT_ID and a.NUMBER=Brun.number and a.TMLOG_DESC='Run Time'
	UNION
	Select a.TMLOG_DESC,a.wono,a.dept_id,a.number,a.TotalTimeH,0.00 as budgetTimeH, 
	a.TotalTimeH as timeDeltaH,
	a.totalCost,0.00 as budgetCost ,
	a.totalCost as costDelta
	from actual A
	where a.TMLOG_DESC NOT IN ('Run Time','Setup Time')
	order by wono,number
	--select * from #tJobcost

	--- rollup output
	SELECT
	  coalesce (wono, 'All Work Orders') AS Wono,
	  coalesce(TMLOG_DESC,'All Log Types') as TMLOG_DESC,
	  coalesce (Dept_id,'All Depts') AS Dept_id,
	  sum(ActualTimeH) as ActualTimeH,
	  sum(budgetTimeH) as BudgetTimeH,
	  sum(timeDeltaH) as TimeDeltaH,
	   sum(ActualCostH) as ActualCost,
	  sum(budgetCost) as BudgetCost,
	  sum(CostDelta) as CostDelta
	  FROM #tJobcost
	  GROUP BY ROLLUP (wono,tmlog_desc,dept_id)
	  order by wono,tmlog_desc,dept_id

	/*
	SELECT
	  coalesce (wono, 'All Work Orders') AS Wono,
	  coalesce(TMLOG_DESC,'All Log Types') as TMLOG_DESC,
	  coalesce (Dept_id,'All Depts') AS Dept_id,
	  sum(ActualTimeH) as ActualTimeH,
	  sum(budgetTimeH) as BudgetTimeH,
	  sum(timeDeltaH) as TimeDeltaH,
	   sum(ActualCostH) as ActualCost,
	  sum(budgetCost) as BudgetCost,
	  sum(CostDelta) as CostDelta
	  FROM #tJobcost
	  GROUP BY CUBE (wono,tmlog_desc,dept_id)
	  order by wono,tmlog_desc,dept_id
	*/
	if OBJECT_ID('tempdb..#tJobCost') IS NOT NULL
	DROP TABLE #tJobCost
END