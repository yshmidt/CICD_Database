-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/04/18
-- Description:	Delete old RollUp records and insert new BUY RollUp from entered parameters
-- Modification:
-- 07/21/16 VL create @ZShortWipGroup to replace the CTE ZShortWipGroup, found in Penang's data, it took more than 7 min (I cancelled the code) if I used CTE ZShortWipGroup, after replacing to use table variable @ZShortWipGroup, it only took 10 seconds
-- 05/03/17 VL added functional currency code
-- 12/14/17 VL changed from using CTE cursor to table variable and added index to table variable to speed up
-- 12/22/17 YS none unique index cannot be created for the table variable prio to SQL 2014. I will create an unique index, but need to check if the speed is still improved.
-- 01/02/18 VL Changed from using table variable to temp table, because wanted to add index to speed up, but only SQL2014 can add regular index on table variable
---07/24/18 YS change inner join to outer join with invtmfgr. If no qty and no location fail to select the part
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[sp_CostRollUpdateBUYParts]	@lcPart_class char(8) = '', @lcPart_type char(8) = '',
													@lcStartPart_no char(35) = '', @lcStartRevision char(8) = '', 
													@lcEndPart_no char(35) = '', @lcEndRevision char(8) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @llSkipZero bit, @llAllowChgWt bit, @lnWeightedPO numeric(3,0), @lnnCostDiffPct numeric(3,0), @lnnCostDiffAmt numeric(13,5),
		@lnTotalCount int, @lnCount int, @lnNo_LastPO numeric(3,0), @lcUniq_key char(10), @lnCalcCost numeric(13,5), @lnMatl_Cost numeric(13,5),
		-- 05/03/17 VL added functional currency code
		@lnnCostDiffAmtPR numeric(13,5),@lnCalcCostPR numeric(13,5), @lnMatl_CostPR numeric(13,5)

-- 12/14/17 VL added index to speed up
-- 01/02/18 VL use temp table instead of table variable, Paramit is still using SQL2012 and can not use regular index on table variable
IF OBJECT_ID('tempdb..#tCostRoll') IS NOT NULL
    DROP TABLE #tCostRoll
-- DECLARE @tCostRoll TABLE 
CREATE TABLE #tCostRoll (Uniq_key char(10), Uniq_Roll char(10), Roll_Qty numeric(12,2), NewStdCost numeric(13,5), UseCalc bit, Manual bit,
						Delta numeric(12,2), RunDate smalldatetime, Pct numeric(3,0), RollType char(4), CalcCost numeric(13,5), 
						ManualCost numeric(13,5), NewMatlCst numeric(13,5), NewLabrCst numeric(13,5), NewOvhdCst numeric(13,5), 
						NewOthrCst numeric(13,5), NewUdCst numeric(13,5), WIPQty numeric(12,2), nAmountDiff numeric(12,2),
						Matl_Cost numeric(13,5), LaborCost numeric(13,5), Overhead numeric(13,5), OtherCost2 numeric(13,5), Other_Cost numeric(13,5),
						-- 05/03/17 VL added functional currency code
						NewStdCostPR numeric(13,5), DeltaPR numeric(12,2), CalcCostPR numeric(13,5), 
						ManualCostPR numeric(13,5), NewMatlCstPR numeric(13,5), NewLabrCstPR numeric(13,5), NewOvhdCstPR numeric(13,5), 
						NewOthrCstPR numeric(13,5), NewUdCstPR numeric(13,5), nAmountDiffPR numeric(12,2),
						Matl_CostPR numeric(13,5), LaborCostPR numeric(13,5), OverheadPR numeric(13,5), OtherCost2PR numeric(13,5), Other_CostPR numeric(13,5))
						--,
						-- 12/22/17 YS none unique index cannot be created for the table variable prio to SQL 2014. I will create an unique index, but need to check if the speed is still improved.
						--- looking at the code inserted in this table assuming that uniq__key is unique and not null
						--UNIQUE NONCLUSTERED (Uniq_key))
CREATE NONCLUSTERED INDEX IDX ON #tCostRoll (Uniq_key)

-- 07/21/16 VL create @ZShortWipGroup to replace the CTE ZShortWipGroup, found in Penang's data, it took more than 7 min (I cancelled the code) if I used CTE ZShortWipGroup, after replacing to use table variable @ZShortWipGroup, it only took 10 seconds
-- 12/14/17 VL added index to speed up
-- 01/02/18 VL use temp table instead of table variable, Paramit is still using SQL2012 and can not use regular index on table variable
IF OBJECT_ID('tempdb..#ZShortWipGroup') IS NOT NULL
    DROP TABLE #ZShortWipGroup
--DECLARE @ZShortWipGroup TABLE 
CREATE TABLE #ZShortWipGroup (Uniq_key char(10), WIPQty numeric(12,2))
--,
-- 12/22/17 YS none unique index cannot be created for the table variable prio to SQL 2014. I will create an unique index, but need to check if the speed is still improved.
		--- looking at the code inserted in this table assuming that uniq__key is unique and not null
		--INDEX Uniq_key NONCLUSTERED (Uniq_key))
		--UNIQUE NONCLUSTERED (Uniq_key))
CREATE NONCLUSTERED INDEX IDX ON #ZShortWipGroup (Uniq_key)


-- 12/14/17 VL change from CTE cursor to table variable to speed up
-- 01/02/18 VL use temp table instead of table variable, Paramit is still using SQL2012 and can not use regular index on table variable
IF OBJECT_ID('tempdb..#ZShort') IS NOT NULL
    DROP TABLE #ZShort
--DECLARE @ZShort TABLE 
CREATE TABLE #ZShort (Uniq_key char(10), Act_qty numeric(12,2), Lineshort bit, ShortQty numeric(12,2), wono char(10), Balance numeric(7,0), parentuniq char(10), bldqty numeric(7,0))
--,
						-- 12/22/17 YS none unique index cannot be created for the table variable prio to SQL 2014. I will create an unique index, but need to check if the speed is still improved.
						--- looking at the code inserted in this table assuming that uniq_key,wono,lineshort is unique and not null
						--UNIQUE NONCLUSTERED (Uniq_key,Wono,LineShort))
						--INDEX Uniq_key NONCLUSTERED (Uniq_key))
CREATE NONCLUSTERED INDEX IDX ON #ZShort (Uniq_key)

SELECT @llSkipZero = SKIPZERO, @llAllowChgWt = ALLOWCHGWT, @lnWeightedPO = WEIGHTEDPO, 
	@lnnCostDiffPct = nCostDiffPct, @lnnCostDiffAmt = nCostDiffAmt
	FROM INVTSETUP

-- 05/03/17 VL added to calcualte @lnnCostDiffAmtPR from ROUND(@lnnCostDiffAmt * Fcsys.StdCostExRate,5)
SELECT @lnnCostDiffAmtPR = CASE WHEN dbo.fn_IsFCInstalled() = 1 THEN ROUND(@lnnCostDiffAmt * StdCostExRate,5) ELSE 0 END FROM Fcsys

SELECT @lnNo_LastPO = CASE WHEN @llAllowChgWt = 1 AND @lnWeightedPO <> 0 THEN @lnWeightedPO ELSE 5 END

BEGIN TRANSACTION
BEGIN TRY

BEGIN	
IF @llSkipZero = 1
	BEGIN
	-- Get all BUY Uniq_key that has never been created in PO , union those Uniq_key that has no PO created this year, will be filter out in later SQL
	WITH ZFilterOutThisUniq_key AS
	(
		SELECT Uniq_key 
			FROM Inventor
			WHERE Uniq_key NOT IN 
			(SELECT Uniq_key 
				FROM Poitems, Pomain
				WHERE Poitems.Ponum = Pomain.Ponum 
				AND (Pomain.PoStatus = 'OPEN' 
				OR Pomain.PoStatus = 'CLOSED')) 
			AND (Part_sourc = 'BUY' 
			OR (PART_SOURC = 'MAKE' AND Make_Buy = 1))
			AND Status = 'Active'
			AND StdCost > 0
		UNION ALL
		(SELECT Poitems.Uniq_key
    		FROM Poitems, Pomain, Inventor
			WHERE Poitems.Ponum = Pomain.Ponum 
			AND (Pomain.PoStatus = 'OPEN' 
			OR Pomain.PoStatus = 'CLOSED')
			AND Poitems.Uniq_key = Inventor.Uniq_key 
			AND (Part_sourc = 'BUY' 
			OR (Part_sourc = 'MAKE' AND Make_buy = 1))
			AND Status = 'Active'
			AND	Poitems.Uniq_key NOT IN 
				(SELECT DISTINCT UNIQ_KEY 
					FROM POITEMS, POMAIN
					WHERE Poitems.Ponum = Pomain.Ponum
					AND YEAR(Pomain.VerDate) = YEAR(GETDATE()))
			AND StdCost > 0) 	
	),
	ZFilterOutThisUniq_keyNoQty AS	-- filter out qty_oh > 0, so only qty = 0 left
	(
		SELECT Uniq_key 
			FROM ZFilterOutThisUniq_key
			WHERE Uniq_key NOT IN 
				(SELECT Uniq_key 
				FROM Invtmfgr 
				WHERE Qty_oh > 0) 
	)
	
	INSERT #tCostRoll (Uniq_key, Roll_Qty)
	SELECT Inventor.Uniq_Key, SUM(Qty_oh) AS Roll_Qty
		FROM Inventor, InvtMfgr 
		WHERE Inventor.Uniq_Key = Invtmfgr.Uniq_Key
		AND Instore = 0
		AND Invtmfgr.Is_Deleted = 0
		AND (Part_sourc = 'BUY' 
		OR (Part_sourc ='MAKE' AND MAKE_BUY = 1))
		AND Status = 'Active'
		AND Inventor.Uniq_key NOT IN 
			(SELECT Uniq_key 
			FROM ZFilterOutThisUniq_keyNoQty) 
		AND 1 =
			CASE WHEN (@lcStartPart_no <> '' AND @lcEndPart_no <> '') THEN CASE WHEN (Inventor.Part_no+Inventor.Revision BETWEEN @lcStartPart_no+@lcStartRevision AND @lcEndPart_no+@lcEndRevision) THEN 1 ELSE 0 END
			ELSE 1 END
		AND 1 = 
			CASE WHEN @lcPart_class <> '' THEN CASE WHEN (Inventor.PART_CLASS = @lcPart_class) THEN 1 ELSE 0 END
			ELSE 1 END
		AND 1 = 
			CASE WHEN @lcPart_type <> '' THEN CASE WHEN (Inventor.PART_TYPE = @lcPart_type) THEN 1 ELSE 0 END
			ELSE 1 END
		GROUP BY Inventor.Uniq_Key
	END
ELSE
	---07/24/18 YS change inner join to outer join with invtmfgr. If no qty and no location fail to select the part
	BEGIN
	INSERT #tCostRoll (Uniq_key, Roll_Qty)
	SELECT Inventor.Uniq_Key, SUM(isnull(Qty_oh,0.00)) AS Roll_Qty
		FROM Inventor LEFT OUTER JOIN InvtMfgr  on Inventor.UNIQ_KEY=invtmfgr.UNIQ_KEY and invtmfgr.IS_DELETED=0 and INSTORE=0
		WHERE 
		--Inventor.Uniq_Key = Invtmfgr.Uniq_Key
		--AND Instore = 0
		--AND Invtmfgr.Is_Deleted = 0
		--AND 
		(Part_sourc = 'BUY' 
		OR (Part_sourc ='MAKE' AND MAKE_BUY = 1))
		AND Status = 'Active'	
		AND 1 =
			CASE WHEN (@lcStartPart_no <> '' AND @lcEndPart_no <> '') THEN CASE WHEN (Inventor.Part_no+Inventor.Revision BETWEEN @lcStartPart_no+@lcStartRevision AND @lcEndPart_no+@lcEndRevision) THEN 1 ELSE 0 END
			ELSE 1 END
		AND 1 = 
			CASE WHEN @lcPart_class <> '' THEN CASE WHEN (Inventor.PART_CLASS = @lcPart_class) THEN 1 ELSE 0 END
			ELSE 1 END
		AND 1 = 
			CASE WHEN @lcPart_type <> '' THEN CASE WHEN (Inventor.PART_TYPE = @lcPart_type) THEN 1 ELSE 0 END
			ELSE 1 END
		GROUP BY Inventor.Uniq_Key
	END
END

UPDATE #tCostRoll
	SET Uniq_Roll = dbo.fn_GenerateUniqueNumber(),
		NewStdCost = 0000000.00000,
		UseCalc = 0,
		Manual = 0,
		Delta = 000000000.00,
		RunDate = GETDATE(),
		Pct = @lnnCostDiffPct,
		RollType = 'BUY',
		CalcCost = 0000000.00000, 
		ManualCost = 0000000.00000,
		NewMatlCst = I.MATL_COST,
		NewLabrCst = I.LaborCost,
		NewOvhdCst = I.Overhead,
		NewOthrCst = I.Othercost2,
		NewUdCst = I.Other_Cost,
		WIPQty = 000000000.00, 
		NAMOUNTDIFF = @lnnCostDiffAmt,
		MATL_COST = I.MATL_COST,
		LaborCost = I.LaborCost,
		Overhead = I.Overhead,
		OtherCost2 = I.OtherCost2,
		Other_Cost = I.Other_Cost,
		-- 05/03/17 VL added functional currency code
		NewStdCostPR = 0000000.00000,
		DeltaPR = 000000000.00,
		CalcCostPR = 0000000.00000, 
		ManualCostPR = 0000000.00000,
		NewMatlCstPR = I.MATL_COSTPR,
		NewLabrCstPR = I.LaborCostPR,
		NewOvhdCstPR = I.OverheadPR,
		NewOthrCstPR = I.Othercost2PR,
		NewUdCstPR = I.Other_CostPR,
		NAMOUNTDIFFPR = @lnnCostDiffAmtPR,
		MATL_COSTPR = I.MATL_COSTPR,
		LaborCostPR = I.LaborCostPR,
		OverheadPR = I.OverheadPR,
		OtherCost2PR = I.OtherCost2PR,
		Other_CostPR = I.Other_CostPR
	FROM #tCostRoll t, INVENTOR I
	WHERE t.Uniq_key = I.Uniq_key
		

SET @lnTotalCount = @@ROWCOUNT;

-- Now will get WIP Qty from Kamain, then to update @tCostRoll.WipQty
-- 12/14/17 VL changed CTE cursor to table variable to speed up
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
--				FROM @tCostRoll)
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
				FROM #tCostRoll)
		GROUP BY Woentry.Wono, Kamain.Uniq_key, LineShort, Woentry.Balance, Woentry.Uniq_key, Woentry.Bldqty

-- 07/21/16 VL create @ZShortWipGroup to replace the CTE ZShortWipGroup, found in Penang's data, it took more than 7 min (I cancelled the code) if I used CTE ZShortWipGroup, after replacing to use table variable @ZShortWipGroup, it only took 10 seconds
--ZShortWipGroup AS
--(
--	SELECT Uniq_key, SUM(WipQty) AS WipQty
--		FROM ZShortWip
--		GROUP BY Uniq_key
--)
-- 12/14/17 VL changed from updating CTE cursor ZShortwip to update directly from @ZShort
--INSERT INTO @ZShortWipGroup 
--	SELECT Uniq_key, SUM(WipQty) AS WipQty
--		FROM ZShortWip
--		GROUP BY Uniq_key
---- 02/21/16 VL End}
INSERT INTO #ZShortWipGroup
	SELECT Uniq_key, ISNULL(SUM(CASE WHEN LineShort = 0 THEN (((Act_Qty+ShortQty)/BldQty)*Balance) - CASE WHEN (ShortQty>0.00 AND ShortQty <=(((Act_Qty+ShortQty)/BldQty)*Balance)) THEN ShortQty ELSE CASE WHEN ShortQty <=0 THEN 0 ELSE (((Act_Qty+ShortQty)/BldQty)*Balance) END END
			ELSE 
				CASE WHEN Uniq_key = ParentUniq THEN CASE WHEN (Act_Qty + CASE WHEN ShortQty < 0.00 THEN ShortQty ELSE 0.00 END) > Balance THEN BALANCE ELSE (Act_Qty + CASE WHEN ShortQty < 0.00 THEN ShortQty ELSE 0.00 END) END
					ELSE Act_Qty + CASE WHEN ShortQty < 0.00 THEN ShortQty ELSE 0.00 END
					END
			END),0) AS WipQty
		FROM #ZShort
		GROUP BY Uniq_key
-- 12/14/17 VL End}

UPDATE #tCostRoll
	SET WIPQty = ZS.WipQty
	FROM #tCostRoll t, #ZShortWipGroup ZS
	WHERE t.Uniq_key = ZS.UNIQ_KEY

-- Now start to update @tCostRoll and see if need to delete some records
UPDATE #tCostRoll
	SET CalcCost = dbo.fn_GetLastNPoAvgCost(Uniq_key,@lnNo_LastPO),
		-- 05/03/17 VL added functional currency code
		CalcCostPR = dbo.fn_GetLastNPoAvgCostPR(Uniq_key,@lnNo_LastPO)

-- Delete those records:
IF @lnnCostDiffPct <> 0 AND @lnnCostDiffAmt <> 0
BEGIN
	-- NOT IIF(lCalcCost=0,0,IIF(matl_cost=0,100,ABS((lCalcCost- Matl_Cost)/Matl_Cost * 100)))>= lnPct OR ABS(lCalcCost- Matl_Cost)>=lnAmountDiff
	DELETE FROM #tCostRoll
		WHERE CASE WHEN CalcCost = 0 THEN 0 ELSE CASE WHEN Matl_Cost = 0 THEN 100 ELSE ABS((CalcCost - Matl_Cost)/Matl_Cost * 100) END END < @lnnCostDiffPct
		AND ABS(CalcCost - Matl_Cost) < @lnnCostDiffAmt
END

IF @lnnCostDiffPct = 0 AND @lnnCostDiffAmt <> 0
BEGIN
	-- NOT ABS(lCalcCost- Matl_Cost)>=lnAmountDiff
	DELETE FROM #tCostRoll
		WHERE ABS(CalcCost - Matl_Cost) < @lnnCostDiffAmt
END

IF @lnnCostDiffPct <> 0 AND @lnnCostDiffAmt = 0
BEGIN
	-- NOT IF IIF(lCalcCost=0,0,IIF(matl_cost=0,100,ABS((lCalcCost- Matl_Cost)/Matl_Cost * 100)))>= lnPct 
	DELETE FROM #tCostRoll
		WHERE CASE WHEN CalcCost = 0 THEN 0 ELSE CASE WHEN Matl_Cost = 0 THEN 100 ELSE ABS((CalcCost - Matl_Cost)/Matl_Cost * 100) END END < @lnnCostDiffPct
END

-- @lnnCostDiffPct <> 0 AND @lnnCostDiffAmt = 0 will keep all records

-- Now, @tCostRoll has all the BUY parts that should be inserted into RollUp
-- Delete all Rollup records for BUY parts
DELETE FROM ROLLUP WHERE ROLLTYPE = 'BUY'

INSERT ROLLUP 
	SELECT Uniq_key, Uniq_Roll, Roll_Qty, NewStdCost, UseCalc, Manual, Delta, RunDate, Pct, RollType, CalcCost, 
			ManualCost, NewMatlCst, NewLabrCst, NewOvhdCst, NewOthrCst, NewUdCst, WIPQty, nAmountDiff,
			-- 05/03/17 VL added functional currency code
			NewStdCostPR, DeltaPR, CalcCostPR, ManualCostPR, NewMatlCstPR, NewLabrCstPR, NewOvhdCstPR, NewOthrCstPR, NewUdCstPR, nAmountDiffPR,
			dbo.fn_GetPresentationCurrency(), dbo.fn_GetFunctionalCurrency()
		FROM #tCostRoll


-- 01/02/18 VL use temp table instead of table variable, Paramit is still using SQL2012 and can not use regular index on table variable, drop all temp tables
IF OBJECT_ID('tempdb..#tCostRoll') IS NOT NULL
    DROP TABLE #tCostRoll
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
