-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/04/18
-- Description:	Delete old RollUp records and insert new BUY RollUp from entered parameters
-- Modified:	Filter out MAKE_BUY part, it's included in BUY part roll up
-- 12/12/14: Also update NewMatlCst to CalcCost if it's phantom part, otherwise just check the UseCalc didn't get right cost
-- 05/03/17 VL added functional currency code
-- 12/14/17 VL added index and changed from IN (select...) to EXISTS (....) to speed up
-- 12/25/17 YS none unique index cannot be created for the table variable prio to SQL 2014. I will create an unique index, but need to check if the speed is still improved.
-- 01/02/18 VL Changed from using table variable to temp table, because wanted to add index to speed up, but only SQL2014 can add regular index on table variable
-- =============================================
CREATE PROCEDURE [dbo].[sp_CostRollUpdateMAKEParts] @llChkUseCalc bit, @llChkUseCalcnotzero bit

AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
-- 05/03/17 VL added functional currency code
DECLARE @llCostRollIgnoreScrap bit, @lnCurLevel numeric(2,0), @lnnCostDiffPct numeric(3,0), @lnnCostDiffAmt numeric(13,5), @lnMaxLevel numeric(2,0), @lnnCostDiffAmtPR numeric(13,5)
-- Used for preparing final data
-- 12/14/17 VL added index to speed up
-- 01/02/18 VL use temp table instead of table variable, Paramit is still using SQL2012 and can not use regular index on table variable
IF OBJECT_ID('tempdb..#tCostMakePartPrep') IS NOT NULL
    DROP TABLE #tCostMakePartPrep
--DECLARE @tCostMakePartPrep TABLE 
CREATE TABLE #tCostMakePartPrep (Uniq_key char(10), CalcCost numeric(13,5), Matl_Cost numeric(13,5), Roll_Qty numeric(12,2),
							Eff_dt smalldatetime, Term_dt smalldatetime, BomChildUniq_key char(10), Item_no numeric(4,0),
							LaborCost numeric(13,5), Overhead numeric(13,5), OtherCost2 numeric(13,5), Other_Cost numeric(13,5),
							Dept_id char(4), U_of_meas char(4),
							-- 05/03/17 VL added functional currency code
							CalcCostPR numeric(13,5), Matl_CostPR numeric(13,5), LaborCostPR numeric(13,5), OverheadPR numeric(13,5), OtherCost2PR numeric(13,5), Other_CostPR numeric(13,5))
							--,
							--INDEX Uniq_key NONCLUSTERED (Uniq_key))
							-- 12/25/17 YS none unique index cannot be created for the table variable prio to SQL 2014. I will create an unique index, but need to check if the speed is still improved.
						--- looking at the code inserted in this table I have to create a combination unique key
						--UNIQUE NONCLUSTERED (Uniq_key,BomChildUniq_key,Item_no,Dept_id))
CREATE NONCLUSTERED INDEX IDX ON #tCostMakePartPrep (Uniq_key)

-- Create another temp table for now, can not use GROUP in CTE
-- 05/03/17 VL added functional currency code
-- 12/14/17 VL added index to speed up
-- 01/02/18 VL use temp table instead of table variable, Paramit is still using SQL2012 and can not use regular index on table variable
IF OBJECT_ID('tempdb..#tChkEffDt') IS NOT NULL
    DROP TABLE #tChkEffDt

--DECLARE @tChkEffDt TABLE 
CREATE TABLE #tChkEffDt (Uniq_key char(10), CalcCost numeric(13,5), CalcCostPR numeric(13,5))
--,
						-- 12/25/17 YS none unique index cannot be created for the table variable prio to SQL 2014. I will create an unique index, but need to check if the speed is still improved.
		--- looking at the code inserted in this table assuming that uniq__key is unique and not null
				--INDEX Uniq_key NONCLUSTERED (Uniq_key))
				--UNIQUE NONCLUSTERED (Uniq_key))
CREATE NONCLUSTERED INDEX IDX ON #tChkEffDt (Uniq_key)

-- Will insert into this temp table to update RollUp table						
-- 12/14/17 VL added index to speed up	
-- 01/02/18 VL use temp table instead of table variable, Paramit is still using SQL2012 and can not use regular index on table variable
IF OBJECT_ID('tempdb..#tCostMakePartFinal') IS NOT NULL
    DROP TABLE #tCostMakePartFinal

--DECLARE @tCostMakePartFinal TABLE 
CREATE TABLE #tCostMakePartFinal (Uniq_key char(10), Uniq_Roll char(10), Roll_Qty numeric(12,2), NewStdCost numeric(13,5), UseCalc bit, Manual bit,
						Delta numeric(12,2), RunDate smalldatetime, Pct numeric(3,0), RollType char(4), CalcCost numeric(13,5), 
						ManualCost numeric(13,5), NewMatlCst numeric(13,5), NewLabrCst numeric(13,5), NewOvhdCst numeric(13,5), 
						NewOthrCst numeric(13,5), NewUdCst numeric(13,5), WIPQty numeric(12,2), nAmountDiff numeric(12,2),
						Matl_Cost numeric(13,5), LaborCost numeric(13,5), Overhead numeric(13,5), OtherCost2 numeric(13,5), Other_Cost numeric(13,5),
						-- 05/03/17 VL added functional currency code
						NewStdCostPR numeric(13,5), DeltaPR numeric(12,2), CalcCostPR numeric(13,5), 
						ManualCostPR numeric(13,5), NewMatlCstPR numeric(13,5), NewLabrCstPR numeric(13,5), NewOvhdCstPR numeric(13,5), 
						NewOthrCstPR numeric(13,5), NewUdCstPR numeric(13,5), nAmountDiffPR numeric(12,2), Matl_CostPR numeric(13,5), LaborCostPR numeric(13,5), 
						OverheadPR numeric(13,5), OtherCost2PR numeric(13,5), Other_CostPR numeric(13,5))
						--,
						-- 12/25/17 YS none unique index cannot be created for the table variable prio to SQL 2014. I will create an unique index, but need to check if the speed is still improved.
		--- looking at the code inserted in this table I have to add Uniq_roll for now to make sure 
						--INDEX Uniq_key NONCLUSTERED (Uniq_key))
							--UNIQUE NONCLUSTERED (Uniq_key,Uniq_roll))
CREATE NONCLUSTERED INDEX IDX ON #tCostMakePartFinal (Uniq_key)


-- 07/21/16 VL create @ZShortWipGroup to replace the CTE ZShortWipGroup, found in Penang's data, it took more than 7 min (I cancelled the code) if I used CTE ZShortWipGroup, after replacing to use table variable @ZShortWipGroup, it only took 10 seconds
-- 01/02/18 VL use temp table instead of table variable, Paramit is still using SQL2012 and can not use regular index on table variable
IF OBJECT_ID('tempdb..#ZShortWipGroup') IS NOT NULL
    DROP TABLE #ZShortWipGroup

--DECLARE @ZShortWipGroup TABLE 
CREATE TABLE #ZShortWipGroup (Uniq_key char(10), WIPQty numeric(12,2))
--,
			-- 12/25/17 YS none unique index cannot be created for the table variable prio to SQL 2014. I will create an unique index, but need to check if the speed is still improved.
		--- looking at the code inserted in this table assuming that uniq__key is unique and not null
				--INDEX Uniq_key NONCLUSTERED (Uniq_key))
				--UNIQUE NONCLUSTERED (Uniq_key))
CREATE NONCLUSTERED INDEX IDX ON #ZShortWipGroup (Uniq_key)

-- 12/14/17 VL added to replace CTE to speed up
-- 01/02/18 VL use temp table instead of table variable, Paramit is still using SQL2012 and can not use regular index on table variable
IF OBJECT_ID('tempdb..#ZShort') IS NOT NULL
    DROP TABLE #ZShort 

--DECLARE @ZShort TABLE 
CREATE TABLE #ZShort (Uniq_key char(10), Act_qty numeric(12,2), Lineshort bit, ShortQty numeric(12,2), wono char(10), Balance numeric(7,0), parentuniq char(10), bldqty numeric(7,0))
--,
						-- 12/25/17 YS none unique index cannot be created for the table variable prio to SQL 2014. I will create an unique index, but need to check if the speed is still improved.
		--- looking at the code inserted in this table assuming that uniq__key is unique and not null
				--INDEX Uniq_key NONCLUSTERED (Uniq_key))
				--UNIQUE NONCLUSTERED (Uniq_key))
CREATE NONCLUSTERED INDEX IDX ON #ZShort (Uniq_key)

SELECT @llCostRollIgnoreScrap = lCostRollIgnoreScrap FROM KITDEF
SELECT @lnCurLevel = CurLevel, @lnMaxLevel = MaxLevel FROM RollMake;
SELECT @lnnCostDiffPct = nCostDiffPct, @lnnCostDiffAmt = nCostDiffAmt FROM INVTSETUP

-- 05/03/17 VL added to calcualte @lnnCostDiffAmtPR from ROUND(@lnnCostDiffAmt * Fcsys.StdCostExRate,5)
SELECT @lnnCostDiffAmtPR = CASE WHEN dbo.fn_IsFCInstalled() = 1 THEN ROUND(@lnnCostDiffAmt * StdCostExRate,5) ELSE 0 END FROM Fcsys

BEGIN TRANSACTION
BEGIN TRY

-- First, get records with either has setup scrap and StdBldQty set up
-- 06/05/14 VL filter out MAKE_BUY part, it's included in BUY part roll up
INSERT #tCostMakePartPrep
SELECT DISTINCT I2.Uniq_key, 
	CASE WHEN Bom_det.Qty<>0 THEN 
		CASE WHEN @llCostRollIgnoreScrap = 0 THEN 
			ROUND((Bom_Det.Qty * I1.StdCost * (1 + I1.Scrap/100) * I2.StdBldQty + I1.SetUpScrap*I1.StdCost)/I2.StdBldQty,5) 
			ELSE ROUND(Bom_Det.Qty * I2.StdBldQty * I1.StdCost/I2.StdBldQty,5) END 
		ELSE 0000000.00000 END AS CalcCost,
	I2.Matl_Cost, dbo.fn_InterQtyOnly(I2.Uniq_Key) AS Roll_Qty, Eff_Dt, Term_Dt, Bom_det.Uniq_key AS BomChildUniq_key, Item_no, 
	I2.LaborCost, I2.Overhead, I2.Othercost2, I2.Other_Cost, Bom_det.Dept_id, I1.U_of_meas,
	-- 05/03/17 VL added functional currency code
	CASE WHEN Bom_det.Qty<>0 THEN 
		CASE WHEN @llCostRollIgnoreScrap = 0 THEN 
			ROUND((Bom_Det.Qty * I1.StdCostPR * (1 + I1.Scrap/100) * I2.StdBldQty + I1.SetUpScrap*I1.StdCostPR)/I2.StdBldQty,5) 
			ELSE ROUND(Bom_Det.Qty * I2.StdBldQty * I1.StdCostPR/I2.StdBldQty,5) END 
		ELSE 0000000.00000 END AS CalcCostPR,
	I2.Matl_CostPR, I2.LaborCostPR, I2.OverheadPR, I2.Othercost2PR, I2.Other_CostPR
	FROM Bom_det, Inventor AS I1, Inventor AS I2 
	WHERE I1.Uniq_Key = Bom_Det.Uniq_Key 
		AND I2.Uniq_Key = Bom_Det.BomParent 
		AND I2.Mrp_Code = @lnCurLevel
		AND I2.UseSetScrp = 1
		AND I2.StdBldQty > 0 
		AND I1.Status = 'Active'
		AND I2.Status = 'Active'
		AND ((I2.PART_SOURC = 'MAKE' AND I2.MAKE_BUY = 0)
		OR I2.PART_SOURC = 'PHANTOM')		
UNION ALL
--09/18/08 VL found some parts in lnCurLevel are not selected in ZTest cursor because of it's child part with Inactive status, so the parent part ;
--didn't get update with 0 price. the new cursor will get and append back to ZTest
-- 06/05/14 VL filter out MAKE_BUY part, it's included in BUY part roll up
	SELECT DISTINCT I2.Uniq_key, 
	0000000.00000 AS CalcCost, 
	I2.Matl_Cost, dbo.fn_InterQtyOnly(I2.Uniq_Key) AS Roll_Qty, Eff_Dt, Term_Dt, Bom_det.Uniq_key AS BomChildUniq_key, Item_no, 
	I2.LaborCost, I2.Overhead, I2.Othercost2, I2.Other_Cost, Bom_det.Dept_id, I1.U_of_meas,
	-- 05/03/17 VL added functional currency code 
	0000000.00000 AS CalcCostPR, 
	I2.Matl_CostPR, I2.LaborCostPR, I2.OverheadPR, I2.Othercost2PR, I2.Other_CostPR
	FROM Bom_det, Inventor AS I1, Inventor AS I2 
	WHERE I1.Uniq_Key = Bom_Det.Uniq_Key 
		AND I2.Uniq_Key = Bom_Det.BomParent 
		AND I2.Mrp_Code = @lnCurLevel 
		AND I2.UseSetScrp = 1
		AND I2.StdBldQty > 0 
		AND I1.Status<>'Active'
		AND I2.Status='Active'
		AND ((I2.PART_SOURC = 'MAKE' AND I2.MAKE_BUY = 0)
		OR I2.PART_SOURC = 'PHANTOM');

-- Get only has effect date
INSERT #tChkEffDt
	-- 05/03/17 VL added functional currency code 
	SELECT Uniq_key, SUM(CalcCost) AS CalcCost, SUM(CalcCostPR) AS CalcCostPR
		FROM #tCostMakePartPrep
		WHERE 1 = CASE WHEN (Eff_dt IS NULL OR DATEDIFF(day,EFF_DT,ISNULL(GETDATE(),EFF_DT))>=0)
			AND (Term_dt IS NULL OR DATEDIFF(day,ISNULL(GETDATE(),TERM_DT),Term_dt)>0) THEN 1 ELSE 0 END	
		GROUP BY Uniq_Key
		ORDER BY Uniq_Key 
		

-- Insert with effect date
-- 05/03/17 VL added functional currency code 
INSERT INTO #tCostMakePartFinal (Uniq_key, CalcCost, Matl_Cost, Uniq_Roll, RollType, Roll_Qty, LaborCost, Overhead, Othercost2, Other_Cost, WIPQty, UseCalc,
									CalcCostPR, Matl_CostPR, LaborCostPR, OverheadPR, Othercost2PR, Other_CostPR)
SELECT DISTINCT ZC.Uniq_key, ZC.CalcCost, Matl_Cost, SPACE(10) AS Uniq_Roll, 'MAKE' AS RollType, 
		Roll_Qty, LaborCost, Overhead, Othercost2, Other_Cost, 000000000.00 AS WIPQty, 0 AS UseCalc,
		-- 05/03/17 VL added functional currency code 
		ZC.CalcCostPR, Matl_CostPR, LaborCostPR, OverheadPR, Othercost2PR, Other_CostPR
    FROM #tChkEffDt ZC, #tCostMakePartPrep tC 
    WHERE ZC.Uniq_key = tC.Uniq_key  


-- Get parts where all components are not effective
-- 05/03/17 VL added functional currency code 
INSERT INTO #tCostMakePartFinal (Uniq_key, CalcCost, Matl_Cost, Uniq_Roll, RollType, Roll_Qty, LaborCost, Overhead, Othercost2, Other_Cost, WIPQty, UseCalc,
									CalcCostPR, Matl_CostPR, LaborCostPR, OverheadPR, Othercost2PR, Other_CostPR)
SELECT DISTINCT Uniq_key, 0000000.00000 AS CalcCost, Matl_Cost, SPACE(10) AS Uniq_Roll, 'MAKE' AS RollType, 
		Roll_Qty, LaborCost, Overhead, OtherCost2, Other_Cost, 000000000.00 AS WIPQty, 0 AS UseCalc,
		-- 05/03/17 VL added functional currency code 
		0000000.00000 AS CalcCostPR, Matl_CostPR, LaborCostPR, OverheadPR, OtherCost2PR, Other_CostPR
	FROM #tCostMakePartPrep t
	-- 12/14/17 VL changed to use EXISTS
	--WHERE Uniq_Key NOT IN (SELECT Uniq_Key FROM #tChkEffDt) 
	WHERE NOT EXISTS (SELECT Uniq_Key FROM #tChkEffDt WHERE Uniq_key = t.Uniq_key) 


-- Now start to work with no setup scrap or StdBldQty = 0
DELETE FROM #tCostMakePartPrep WHERE 1 = 1

-- 06/05/14 VL filter out MAKE_BUY part, it's included in BUY part roll up		
INSERT #tCostMakePartPrep
SELECT DISTINCT I2.Uniq_key, 
	CASE WHEN Bom_det.Qty<>0 THEN 
		CASE WHEN @llCostRollIgnoreScrap = 0 THEN 
			ROUND(Bom_Det.Qty * I1.StdCost * (1 + I1.Scrap/100),5) 
			ELSE ROUND(Bom_Det.Qty * I1.StdCost,5) END 
		ELSE 0000000.00000 END AS CalcCost,
	I2.Matl_Cost, dbo.fn_InterQtyOnly(I2.Uniq_Key) AS Roll_Qty, Eff_Dt, Term_Dt, Bom_det.Uniq_key AS BomChildUniq_key, Item_no, 
	I2.LaborCost, I2.Overhead, I2.Othercost2, I2.Other_Cost, Bom_det.Dept_id, I1.U_of_meas, 
	-- 05/03/17 VL added functional currency code  
	CASE WHEN Bom_det.Qty<>0 THEN 
		CASE WHEN @llCostRollIgnoreScrap = 0 THEN 
			ROUND(Bom_Det.Qty * I1.StdCostPR * (1 + I1.Scrap/100),5) 
			ELSE ROUND(Bom_Det.Qty * I1.StdCostPR,5) END 
		ELSE 0000000.00000 END AS CalcCostPR,
	I2.Matl_CostPR, I2.LaborCostPR, I2.OverheadPR, I2.Othercost2PR, I2.Other_CostPR
	FROM Bom_det, Inventor AS I1, Inventor AS I2 
	WHERE I1.Uniq_Key = Bom_Det.Uniq_Key 
		AND I2.Uniq_Key = Bom_Det.BomParent 
		AND I2.Mrp_Code = @lnCurLevel
		AND (I2.UseSetScrp = 0
		OR I2.StdBldQty = 0 )
		AND I1.Status = 'Active'
		AND I2.Status = 'Active'
		AND ((I2.PART_SOURC = 'MAKE' AND I2.MAKE_BUY = 0)
		OR I2.PART_SOURC = 'PHANTOM')		
UNION ALL
--09/18/08 VL found some parts in lnCurLevel are not selected in ZTest cursor because of it's child part with Inactive status, so the parent part ;
--didn't get update with 0 price. the new cursor will get and append back to ZTest
	SELECT DISTINCT I2.Uniq_key, 
	0000000.00000 AS CalcCost, 
	I2.Matl_Cost, dbo.fn_InterQtyOnly(I2.Uniq_Key) AS Roll_Qty, Eff_Dt, Term_Dt, Bom_det.Uniq_key AS BomChildUniq_key, Item_no, 
	I2.LaborCost, I2.Overhead, I2.Othercost2, I2.Other_Cost, Bom_det.Dept_id, I1.U_of_meas,
	-- 05/03/17 VL added functional currency code  
	0000000.00000 AS CalcCostPR, 
	I2.Matl_CostPR, I2.LaborCostPR, I2.OverheadPR, I2.Othercost2PR, I2.Other_CostPR
	FROM Bom_det, Inventor AS I1, Inventor AS I2 
	WHERE I1.Uniq_Key = Bom_Det.Uniq_Key 
		AND I2.Uniq_Key = Bom_Det.BomParent 
		AND I2.Mrp_Code = @lnCurLevel 
		AND (I2.UseSetScrp = 0
		OR I2.StdBldQty = 0 )
		AND I1.Status<>'Active'
		AND I2.Status='Active'
		AND ((I2.PART_SOURC = 'MAKE' AND I2.MAKE_BUY = 0)
		OR I2.PART_SOURC = 'PHANTOM');
		
-- Get only has effect date
DELETE FROM #tChkEffDt WHERE 1 = 1
INSERT #tChkEffDt
	-- 05/03/17 VL added functional currency code  
	SELECT Uniq_key, SUM(CalcCost) AS CalcCost, SUM(CalcCostPR) AS CalcCostPR
		FROM #tCostMakePartPrep
		WHERE 1 = CASE WHEN (Eff_dt IS NULL OR DATEDIFF(day,EFF_DT,ISNULL(GETDATE(),EFF_DT))>=0)
			AND (Term_dt IS NULL OR DATEDIFF(day,ISNULL(GETDATE(),TERM_DT),Term_dt)>0) THEN 1 ELSE 0 END	
		GROUP BY Uniq_Key
		ORDER BY Uniq_Key 

-- Insert with effect date
-- 05/03/17 VL added functional currency code  
INSERT INTO #tCostMakePartFinal (Uniq_key, CalcCost, Matl_Cost, Uniq_Roll, RollType, Roll_Qty, LaborCost, Overhead, Othercost2, Other_Cost, WIPQty, UseCalc, 
								CalcCostPR, Matl_CostPR, LaborCostPR, OverheadPR, Othercost2PR, Other_CostPR)
SELECT DISTINCT ZC.Uniq_key, ZC.CalcCost, Matl_Cost, SPACE(10) AS Uniq_Roll, 'MAKE' AS RollType, 
		Roll_Qty, LaborCost, Overhead, Othercost2, Other_Cost, 000000000.00 AS WIPQty, 0 AS UseCalc,
		-- 05/03/17 VL added functional currency code 
		ZC.CalcCostPR, Matl_CostPR, LaborCostPR, OverheadPR, Othercost2PR, Other_CostPR
    FROM #tChkEffDt ZC, #tCostMakePartPrep tC 
    WHERE ZC.Uniq_key = tC.Uniq_key  

-- Get parts where all components are not effective
-- 05/03/17 VL added functional currency code 
INSERT INTO #tCostMakePartFinal (Uniq_key, CalcCost, Matl_Cost, Uniq_Roll, RollType, Roll_Qty, LaborCost, Overhead, Othercost2, Other_Cost, WIPQty, UseCalc,
								CalcCostPR, Matl_CostPR, LaborCostPR, OverheadPR, Othercost2PR, Other_CostPR)
SELECT DISTINCT Uniq_key, 0000000.00000 AS CalcCost, Matl_Cost, SPACE(10) AS Uniq_Roll, 'MAKE' AS RollType, 
		Roll_Qty, LaborCost, Overhead, OtherCost2, Other_Cost, 000000000.00 AS WIPQty, 0 AS UseCalc,
		-- 05/03/17 VL added functional currency code
		0000000.00000 AS CalcCostPR, Matl_CostPR, LaborCostPR, OverheadPR, OtherCost2PR, Other_CostPR
	FROM #tCostMakePartPrep t
	-- 12/14/17 VL changed to use EXISTS
	--WHERE Uniq_Key NOT IN (SELECT Uniq_Key FROM #tChkEffDt) 
	WHERE NOT EXISTS (SELECT Uniq_Key FROM #tChkEffDt WHERE Uniq_key = t.Uniq_key) 


IF @lnnCostDiffPct <> 0 AND @lnnCostDiffAmt <> 0
BEGIN
	DELETE FROM #tCostMakePartFinal
		WHERE CASE WHEN CalcCost = 0 THEN 0 ELSE CASE WHEN Matl_Cost = 0 THEN 100 ELSE ABS((CalcCost- Matl_Cost)/Matl_Cost * 100) END END < @lnnCostDiffPct
		AND ABS(CalcCost- Matl_Cost) >= @lnnCostDiffAmt 
END 

IF @lnnCostDiffPct = 0 AND @lnnCostDiffAmt <> 0
BEGIN
	DELETE FROM #tCostMakePartFinal
		WHERE ABS(CalcCost- Matl_Cost) < @lnnCostDiffAmt 
END

IF @lnnCostDiffPct <> 0 AND @lnnCostDiffAmt = 0
BEGIN
	DELETE FROM #tCostMakePartFinal
		WHERE CASE WHEN CalcCost = 0 THEN 0 ELSE CASE WHEN Matl_Cost = 0 THEN 100 ELSE ABS((CalcCost- Matl_Cost)/Matl_Cost * 100) END END  < @lnnCostDiffPct
END;

--IF @lnnCostDiffPct = 0 AND @lnnCostDiffAmt = 0
-- won't delete any record, will select all


-- Now will get WIP Qty from Kamain, then to update @tCostRoll.WipQty
-- 12/14/17 VL changed to use table variable to speed up
--WITH zShort AS
--(
--	SELECT Kamain.Uniq_key, SUM(Act_qty) AS Act_qty, LineShort, SUM(ShortQty) AS ShortQty, Woentry.Wono, Woentry.Balance,
--			Woentry.Uniq_key AS ParentUniq, Woentry.Bldqty
--		FROM Kamain, Woentry
--		WHERE Kamain.Wono = Woentry.Wono
--		AND Balance > 0 
--		AND (OPENCLOS <> 'Closed' 
--		AND OPENCLOS <> 'Cancel')
--		AND Kamain.Uniq_key IN 
--			(SELECT Uniq_key 
--				FROM @tCostMakePartFinal)
--		GROUP BY Woentry.Wono, Kamain.Uniq_key, LineShort, Woentry.Balance, Woentry.Uniq_key, Woentry.Bldqty
--),
--ZShortWip AS
--(
--	SELECT Uniq_key, 
--		CASE WHEN LineShort = 0 THEN (((Act_Qty+ShortQty)/BldQty)*Balance) - CASE WHEN (ShortQty>0.00 AND ShortQty <=(((Act_Qty+ShortQty)/BldQty)*Balance)) THEN ShortQty ELSE CASE WHEN ShortQty <=0 THEN 0 ELSE (((Act_Qty+ShortQty)/BldQty)*Balance) END END
--			ELSE 
--				CASE WHEN Uniq_key = ParentUniq THEN CASE WHEN (Act_Qty + CASE WHEN ShortQty < 0.00 THEN ShortQty ELSE 0.00 END) > Balance THEN BALANCE ELSE (Act_Qty + CASE WHEN ShortQty < 0.00 THEN ShortQty ELSE 0.00 END) END
--					ELSE Act_Qty + CASE WHEN ShortQty < 0.00 THEN ShortQty ELSE 0.00 END
--					END
--			END AS WipQty
--		FROM zShort
--),
--ZShortWipGroup AS
--(
--	SELECT Uniq_key, SUM(WipQty) AS WipQty
--		FROM ZShortWip
--		GROUP BY Uniq_key
--)
INSERT INTO #ZShort
SELECT Kamain.Uniq_key, SUM(Act_qty) AS Act_qty, LineShort, SUM(ShortQty) AS ShortQty, Woentry.Wono, Woentry.Balance,
			Woentry.Uniq_key AS ParentUniq, Woentry.Bldqty
		FROM Kamain, Woentry
		WHERE Kamain.Wono = Woentry.Wono
		AND Balance > 0 
		AND (OPENCLOS <> 'Closed' 
		AND OPENCLOS <> 'Cancel')
		AND Kamain.Uniq_key IN 
			(SELECT Uniq_key 
				FROM #tCostMakePartFinal)
		GROUP BY Woentry.Wono, Kamain.Uniq_key, LineShort, Woentry.Balance, Woentry.Uniq_key, Woentry.Bldqty

INSERT INTO #ZShortWipGroup
	SELECT Uniq_key, ISNULL(SUM(CASE WHEN LineShort = 0 THEN (((Act_Qty+ShortQty)/BldQty)*Balance) - CASE WHEN (ShortQty>0.00 AND ShortQty <=(((Act_Qty+ShortQty)/BldQty)*Balance)) THEN ShortQty ELSE CASE WHEN ShortQty <=0 THEN 0 ELSE (((Act_Qty+ShortQty)/BldQty)*Balance) END END
			ELSE 
				CASE WHEN Uniq_key = ParentUniq THEN CASE WHEN (Act_Qty + CASE WHEN ShortQty < 0.00 THEN ShortQty ELSE 0.00 END) > Balance THEN BALANCE ELSE (Act_Qty + CASE WHEN ShortQty < 0.00 THEN ShortQty ELSE 0.00 END) END
					ELSE Act_Qty + CASE WHEN ShortQty < 0.00 THEN ShortQty ELSE 0.00 END
					END
			END),0) AS WipQty
	FROM #ZShort
	GROUP BY Uniq_key

UPDATE #tCostMakePartFinal
	SET WIPQty = ZS.WipQty
	FROM #tCostMakePartFinal t, #ZShortWipGroup ZS
	WHERE t.Uniq_key = ZS.UNIQ_KEY
-- 12/14/17 VL End}

UPDATE #tCostMakePartFinal
	SET NewStdCost = 0000000.00000,
		Manual = 0,
		Delta = 000000000.00,
		RunDate = GETDATE(),
		Pct = @lnnCostDiffPct,
		ManualCost = 0000000.00000,
		NewMatlCst = I.MATL_COST,
		NewLabrCst = I.LaborCost,
		NewOvhdCst = I.Overhead,
		NewOthrCst = I.Othercost2,
		NewUdCst = I.Other_Cost,
		NAMOUNTDIFF = @lnnCostDiffAmt,
		Uniq_Roll = dbo.fn_GenerateUniqueNumber(),
		-- 05/03/17 VL added functional currency code
		NewStdCostPR = 0000000.00000,
		DeltaPR = 000000000.00,
		ManualCostPR = 0000000.00000,
		NewMatlCstPR = I.MATL_COSTPR,
		NewLabrCstPR = I.LaborCostPR,
		NewOvhdCstPR = I.OverheadPR,
		NewOthrCstPR = I.Othercost2PR,
		NewUdCstPR = I.Other_CostPR,
		NAMOUNTDIFFPR = @lnnCostDiffAmtPR
	FROM #tCostMakePartFinal t, INVENTOR I
	WHERE t.Uniq_key = I.Uniq_key

-- 03/21/08 VL check to make UseCalc to be .T. for Phantom part, because it's reset to 0 at max level, but when user roll up from lower level, the user might forget;
-- to check to use calculate cost, so automatically checked here to make the cost correctly to roll up
-- 12/12/14 VL found also need to change the NewMatlCst to CalcCost, otherwise, just make UseCalc = 1, the cost still not correct
-- Also update Manual, ManualCost and Delta just like form checkbox did
UPDATE #tCostMakePartFinal
	SET UseCalc = 1,
		NewMatlCst = CalcCost,
		Manual = 0,
		ManualCost = 0.00, 
		Delta = 0,
		-- 05/03/17 VL added functional currency code
		NewMatlCstPR = CalcCostPR,
		ManualCostPR = 0.00, 
		DeltaPR = 0
	WHERE Uniq_key IN 
		(SELECT Uniq_key 
			FROM Inventor 
			WHERE Part_Sourc = 'PHANTOM')
				
DELETE FROM ROLLUP WHERE ROLLTYPE = 'MAKE'

INSERT ROLLUP 
	SELECT Uniq_key, Uniq_Roll, Roll_Qty, NewStdCost, UseCalc, Manual, Delta, RunDate, Pct, RollType, CalcCost, 
			ManualCost, NewMatlCst, NewLabrCst, NewOvhdCst, NewOthrCst, NewUdCst, WIPQty, nAmountDiff,
			-- 05/03/17 VL added functional currency code
			NewStdCostPR, DeltaPR, CalcCostPR, ManualCostPR, NewMatlCstPR, NewLabrCstPR, NewOvhdCstPR, NewOthrCstPR, NewUdCstPR, nAmountDiffPR,
			dbo.fn_GetPresentationCurrency(), dbo.fn_GetFunctionalCurrency()
		FROM #tCostMakePartFinal

-- Recalculate based on user's selection 
IF @llChkUseCalc = 1 OR @llChkUseCalcnotzero = 1
BEGIN
	IF @llChkUseCalc = 1
	BEGIN
		UPDATE Rollup
			SET Usecalc = 1,
				Manual = 0,
				NewMatlCst = CalcCost,
    			ManualCost = 0.00,
    			Delta = (ROUND((Roll_Qty+WIPQty) * NewMatlCst,2) - ROUND((Roll_Qty+WIPQty) * Matl_Cost,2)) +
						(ROUND((Roll_Qty+WIPQty) * NewLabrCst,2) - ROUND((Roll_Qty+WIPQty) * LaborCost,2)) +
						(ROUND((Roll_Qty+WIPQty) * NewOvhdCst,2) - ROUND((Roll_Qty+WIPQty) * Overhead,2)) + 
						(ROUND((Roll_Qty+WIPQty) * NewOthrCst,2) - ROUND((Roll_Qty+WIPQty) * OtherCost2,2)) +
						(ROUND((Roll_Qty+WIPQty) * NewUdCst,2) - ROUND((Roll_Qty+WIPQty) * Other_Cost,2)),
				-- 05/03/17 VL added functional currency code 
				NewMatlCstPR = CalcCostPR,
    			ManualCostPR = 0.00,
    			DeltaPR = (ROUND((Roll_Qty+WIPQty) * NewMatlCstPR,2) - ROUND((Roll_Qty+WIPQty) * Matl_CostPR,2)) +
						(ROUND((Roll_Qty+WIPQty) * NewLabrCstPR,2) - ROUND((Roll_Qty+WIPQty) * LaborCostPR,2)) +
						(ROUND((Roll_Qty+WIPQty) * NewOvhdCstPR,2) - ROUND((Roll_Qty+WIPQty) * OverheadPR,2)) + 
						(ROUND((Roll_Qty+WIPQty) * NewOthrCstPR,2) - ROUND((Roll_Qty+WIPQty) * OtherCost2PR,2)) +
						(ROUND((Roll_Qty+WIPQty) * NewUdCstPR,2) - ROUND((Roll_Qty+WIPQty) * Other_CostPR,2))
			FROM ROLLUP, Inventor
			WHERE RollUp.Uniq_key = Inventor.Uniq_key
			AND ROLLTYPE = 'MAKE'
	END
	
	IF @llChkUseCalcnotzero = 1
	BEGIN
		UPDATE Rollup
			SET Usecalc = 1,
				Manual = 0,
				NewMatlCst = CalcCost,
    			ManualCost = 0.00,
    			Delta = (ROUND((Roll_Qty+WIPQty) * NewMatlCst,2) - ROUND((Roll_Qty+WIPQty) * Matl_CostPR,2)) + 
						(ROUND((Roll_Qty+WIPQty) * NewLabrCst,2) - ROUND((Roll_Qty+WIPQty) * LaborCostPR,2)) + 
						(ROUND((Roll_Qty+WIPQty) * NewOvhdCst,2) - ROUND((Roll_Qty+WIPQty) * OverheadPR,2)) + 
						(ROUND((Roll_Qty+WIPQty) * NewOthrCst,2) - ROUND((Roll_Qty+WIPQty) * OtherCost2PR,2)) + 
						(ROUND((Roll_Qty+WIPQty) * NewUdCst,2) - ROUND((Roll_Qty+WIPQty) * Other_CostPR,2)),
				-- 05/03/17 VL added functional currency code  
				NewMatlCstPR = CalcCostPR,
    			ManualCostPR = 0.00,
    			DeltaPR = (ROUND((Roll_Qty+WIPQty) * NewMatlCstPR,2) - ROUND((Roll_Qty+WIPQty) * Matl_CostPR,2)) + 
						(ROUND((Roll_Qty+WIPQty) * NewLabrCstPR,2) - ROUND((Roll_Qty+WIPQty) * LaborCostPR,2)) + 
						(ROUND((Roll_Qty+WIPQty) * NewOvhdCstPR,2) - ROUND((Roll_Qty+WIPQty) * OverheadPR,2)) + 
						(ROUND((Roll_Qty+WIPQty) * NewOthrCstPR,2) - ROUND((Roll_Qty+WIPQty) * OtherCost2PR,2)) + 
						(ROUND((Roll_Qty+WIPQty) * NewUdCstPR,2) - ROUND((Roll_Qty+WIPQty) * Other_CostPR,2))
			FROM ROLLUP, Inventor
			WHERE RollUp.Uniq_key = Inventor.Uniq_key						
			AND ROLLTYPE = 'MAKE'
			AND CalcCost <> 0.00	
	END
	
END

-- 04/18/12 VL moved this part to be updated in form level
--IF @lnCurLevel <> @lnMaxLevel
--BEGIN
--	UPDATE ROLLMAKE	
--		SET CurLevel = CURLEVEL + 1
--END	

-- 01/02/18 VL use temp table instead of table variable, Paramit is still using SQL2012 and can not use regular index on table variable, drop all temp tables
IF OBJECT_ID('tempdb..#tCostMakePartPrep') IS NOT NULL
    DROP TABLE #tCostMakePartPrep
IF OBJECT_ID('tempdb..#tChkEffDt') IS NOT NULL
    DROP TABLE #tChkEffDt
IF OBJECT_ID('tempdb..#tCostMakePartFinal') IS NOT NULL
    DROP TABLE #tCostMakePartFinal
IF OBJECT_ID('tempdb..#ZShortWipGroup') IS NOT NULL
    DROP TABLE #ZShortWipGroup
IF OBJECT_ID('tempdb..#ZShort') IS NOT NULL
    DROP TABLE #ZShort 


END TRY

BEGIN CATCH
	RAISERROR('Error occurred in cost roll leveling. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;


END


