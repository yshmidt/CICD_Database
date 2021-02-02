-- =============================================
-- Author:		Vicky Lu
-- Create date: 2011/11/15
-- Description:	This stored procedure will get first part of Qainsp, Qadef and Qadefloc data for selected Wono and date range for later use in form
-- =============================================
CREATE PROCEDURE [dbo].[QaChart4WonoView] 
	@ltWonoList AS tWono READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
-- @lnChartType lnChart='1'	- Pareto or Pie Charts
-- @lnChartType lnChart='2'	- cChart
-- @lnChartType lnChart='3'	- pChart	
-- @lnChartType lnChart='4'	- Distribution Chart
-- @lnChartType lnChart='5'	- pChart for Defects parts per million
-- @lnChartType lnChart='6'	- Yield Chart
-- @lnChartType lnChart='7' - 1st Yield Chart

-- 11/18/11 VL changed from smalldatetime to date because even created in same date, different time might cause not show in chart
-- 08/24/12 VL Changed to use table variable, also the charttype is added into table QaChrtDt
-- 09/29/14 VL found has to use outer join for Qadef and qadefloc because it might have records on qainsp, qadef level but not in qadefloc level

DECLARE @ldStartDt date, @ldEndDt date, @lcChartType char(1), @lnPassTime numeric(2,0)

DECLARE @QaTemp TABLE (LotSize numeric(7,0), InspQty numeric(7,0), [Date] smalldatetime, Inspby char(10), Qaseqmain char(10), 
	Is_Passed bit, Locseqno char(10), Serialno char(30), Dept_id char(4), Def_code char(10))
		
SELECT @ldStartDt = dStartDt, @ldEndDt = dEndDt, @lcChartType = cChartType FROM QaChrtDt
SET @lnPassTime = 1

IF @lcChartType = '1' -- Pareto or Pie Charts
BEGIN
	SELECT LocQty AS DefQty, Def_code, ChgDept_id AS Dept_id
		FROM Qadef,QadefLoc
	WHERE Wono IN 
		(SELECT Wono FROM @ltWonoList)
	AND LocQty<>0
	AND CAST(DefDate AS DATE) BETWEEN @ldStartDt AND @ldEndDt
	AND QadefLoc.LocSeqNo = Qadef.LocSeqNo
	ORDER BY 1 DESC
END

IF @lcChartType = '2' -- cChart
BEGIN
	SELECT ISNULL(LocQty,0) AS QTY, Inspqty, Qainsp.Date, Qainsp.Dept_id
		--FROM Qadef, Qainsp, QadefLoc
	FROM Qainsp INNER JOIN Qadef ON Qainsp.Qaseqmain = qadef.qaseqmain
		LEFT OUTER JOIN Qadefloc on qadef.locseqno = qadefloc.locseqno 
	WHERE Qainsp.Wono IN 
		(SELECT Wono FROM @ltWonoList)
	--AND Qadef.Qaseqmain = Qainsp.Qaseqmain
	--AND QadefLoc.LocSeqNo = Qadef.LocSeqNo 
	AND Qainsp.Inspqty <> 0
	AND CAST(Qainsp.Date AS DATE) BETWEEN @ldStartDt AND @ldEndDt
	UNION
	(SELECT 00000 AS QTY, Qainsp.Inspqty, Qainsp.Date, Qainsp.Dept_id --- Select all inspections for all customers without defects
		FROM Qainsp
	WHERE Qainsp.Wono In 
		(SELECT Wono FROM @ltWonoList) 
	AND Qainsp.Qaseqmain NOT IN
		(SELECT Qaseqmain FROM Qadef)
	AND Qainsp.Inspqty <> 0
	AND CAST(Qainsp.Date AS DATE) BETWEEN @ldStartDt AND @ldEndDt)
	ORDER BY Qainsp.Date
END


IF @lcChartType = '3' -- pChart
BEGIN
	SELECT DISTINCT Inspqty, FailQty,Qainsp.Date, Wono, Dept_id
		FROM Qainsp
	WHERE Qainsp.Wono IN 
		(SELECT Wono FROM @ltWonoList)
	AND Inspqty <> 0
	AND CAST(DATE AS DATE) BETWEEN @ldStartDt AND @ldEndDt
	ORDER BY Qainsp.Date
END

IF @lcChartType = '4' -- Distribution Chart
BEGIN
	SELECT Part_no, Revision, WOENTRY.Uniq_key, Woentry.WONO, DEF_CODE, QadefLoc.ChgDept_id AS Dept_id, LocQTY AS DefQty, QADEF.DEFDATE
	FROM Inventor, WOENTRY, QADEF, QadefLoc
	WHERE Inventor.UNIQ_KEY = Woentry.Uniq_key
	AND QADEF.WONO = WOENTRY.WONO
	AND WOENTRY.WONO IN 
		(SELECT Wono FROM @ltWonoList)
	AND Qadefloc.LocSeqNo = Qadef.LocSeqNo
	AND QadefLoc.LocQTY <> 0
	AND CAST(DEFDATE AS DATE) BETWEEN @ldStartDt AND @ldEndDt
	ORDER BY DEF_CODE,WOENTRY.Uniq_key
	
END

IF @lcChartType = '5' -- pChart for Defects parts per million
BEGIN
WITH ZDpmoChrt AS
(
	SELECT Qainsp.Wono, ISNULL(Qadefloc.Locqty,0) AS QTY, Qainsp.Inspqty, Qainsp.Date, Qainsp.Qaseqmain, Qadefloc.ChgDept_id AS Dept_id
		--FROM Qadef,Qainsp,QadefLoc
		FROM Qainsp INNER JOIN Qadef ON Qainsp.Qaseqmain = qadef.qaseqmain
		LEFT OUTER JOIN Qadefloc on qadef.locseqno = qadefloc.locseqno 
	WHERE Qainsp.Wono IN 
		(SELECT Wono FROM @ltWonoList) 
	--AND Qadef.Qaseqmain = Qainsp.Qaseqmain
	--AND Qadefloc.LocSeqNo = Qadef.LocSeqNo
	AND Qainsp.Inspqty <> 0
	AND CAST(Qainsp.Date AS DATE) BETWEEN @ldStartDt AND @ldEndDt
	UNION--- Select all inspections for all customers without defects
	(SELECT Qainsp.Wono, 00000 AS QTY, Qainsp.Inspqty, Qainsp.Date, Qainsp.Qaseqmain, Qainsp.Dept_id
		FROM Qainsp
	WHERE Qainsp.Wono In 
		(SELECT Wono FROM @ltWonoList) 
	AND Qainsp.Qaseqmain NOT IN
		(SELECT Qaseqmain FROM Qadef)	
	AND Qainsp.Inspqty <> 0
	AND CAST(Qainsp.Date AS DATE) BETWEEN @ldStartDt AND @ldEndDt)
)
	SELECT Qty, InspQty, ZDpmoChrt.Date, ZDpmoChrt.Dept_id, PartPerUnt, Qaseqmain, ZDpmoChrt.Wono, Woentry.BldQty, dbo.fn_GenerateUniqueNumber() AS UniqField
		FROM ZDpmoChrt, Woentry, Quotdept
	WHERE Woentry.Wono = ZDpmoChrt.Wono	
	AND Quotdept.Uniq_key = Woentry.Uniq_key
	AND Quotdept.Dept_id = ZDpmoChrt.Dept_id
	AND PartPerUnt<>0
	ORDER BY Qaseqmain 

END

IF @lcChartType = '6' -- Yield Chart
BEGIN
	--find all the records with defects
	SELECT Inspqty, PassQty, Qainsp.Date, ChgDept_id AS Dept_id, Qainsp.Qaseqmain, Def_code
	--FROM Qainsp,Qadef,Qadefloc
	FROM Qainsp INNER JOIN Qadef ON Qainsp.Qaseqmain = qadef.qaseqmain
			LEFT OUTER JOIN Qadefloc on qadef.locseqno = qadefloc.locseqno 
	WHERE Qainsp.Wono IN 
		(SELECT Wono FROM @ltWonoList)
	AND Inspqty <> 0
	AND CAST(Date AS DATE) BETWEEN @ldStartDt AND @ldEndDt
	--AND Qadef.Qaseqmain = Qainsp.Qaseqmain
	--AND qadef.locseqno = qadefloc.locseqno 
	UNION		--find all the records with no defects
	(SELECT Inspqty, PassQty, Date, Dept_id, Qaseqmain, SPACE(10) AS Def_Code 
		FROM Qainsp
	WHERE Qainsp.Wono In 
		(SELECT Wono FROM @ltWonoList) 
	AND Qainsp.Qaseqmain NOT IN
		(SELECT Qaseqmain FROM Qadef)	
	AND Qainsp.Inspqty <> 0
	AND CAST(Qainsp.Date AS DATE) BETWEEN @ldStartDt AND @ldEndDt)
		

END

IF @lcChartType = '7' -- 1st Yield Chart
-- Kind of wierd about the grouping, should check again
BEGIN
	-- 1. Has Serial number, Has Qadef, Has Qadefloc
	WITH ZQaHasLoc AS
	(
	SELECT COUNT(*) AS InspQty, Qadefloc.Uniq_loc
		FROM Qainsp, Qadef, Qadefloc 
		WHERE Qainsp.Wono IN (SELECT Wono FROM @ltWonoList) 
		AND Inspqty <> 0 
		AND CAST(Date AS DATE) BETWEEN @ldStartDt AND @ldEndDt
		AND qainsp.qaseqmain = qadef.qaseqmain
		AND qadef.locseqno = qadefloc.locseqno 
		AND Qadef.Serialno <> ''
		AND PassNum = @lnPassTime
		GROUP BY Qadefloc.Uniq_loc
	)

	INSERT @QaTemp
	SELECT DISTINCT Qainsp.LotSize, ZQaHasLoc.InspQty, Qainsp.Date, Inspby, Qainsp.Qaseqmain, Is_Passed, Qadef.Locseqno, Serialno, SPACE(4) AS Dept_id, SPACE(10) AS Def_code
		FROM ZQaHasLoc, Qainsp, Qadef, Qadefloc
		WHERE qainsp.qaseqmain = qadef.qaseqmain
		AND qadef.locseqno = qadefloc.locseqno
		AND Qadefloc.Uniq_loc = ZQaHasLoc.Uniq_loc 

	UPDATE @QaTemp
		SET Dept_id = Qadefloc.CHGDEPT_ID,
			Def_code = Qadefloc.DEF_CODE
		FROM @QaTemp ZQa, Qadefloc
		WHERE ZQa.Locseqno = Qadefloc.LocSeqno;
		
	-- 2. Has Serial number, Has Qadef, Has no Qadefloc
	WITH ZQaNoLoc AS
	(
	SELECT COUNT(*) AS InspQty, Qadef.Locseqno
		FROM Qainsp, Qadef
		WHERE Qainsp.Wono IN (SELECT Wono FROM @ltWonoList)
		AND Inspqty <> 0 
		AND CAST(Date AS DATE) BETWEEN @ldStartDt AND @ldEndDt
		AND qainsp.qaseqmain = qadef.qaseqmain
		AND Qadef.Locseqno NOT IN (SELECT Locseqno FROM Qadefloc)
		AND Qadef.Serialno <> ''
		AND PassNum = @lnPassTime
		GROUP BY Qadef.Locseqno
	)
	
	INSERT @QaTemp
	SELECT Qainsp.LotSize, ZQaNoLoc.InspQty, Qainsp.Date, Inspby, Qainsp.Qaseqmain, Is_Passed, Qadef.Locseqno, Serialno, Qadef.Dept_id, SPACE(10) AS Def_code 
		FROM ZQaNoLoc, Qainsp, Qadef 
		WHERE qainsp.qaseqmain = qadef.qaseqmain
		AND ZQaNoLoc.Locseqno = Qadef.Locseqno 
	
	SELECT * FROM @QaTemp
		
END



END