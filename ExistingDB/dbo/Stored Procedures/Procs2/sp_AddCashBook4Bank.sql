-- =============================================
-- Author:		Vicky Lu/Barbara Paltiel
-- Create date: 2015/11/17
-- Description:	Create cashbook records for selected bank to the end of current fiscal year
-- Modification:
-- 04/27/17 VL added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[sp_AddCashBook4Bank] @Bk_uniq char(10), @Period numeric(2,0) = 0
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

BEGIN TRANSACTION
DECLARE @Cur_FY char(4), @Cur_Period numeric(2,0), @LatestFY char(4), @LatestPeriod numeric(2,0), @NewPeriod numeric(2,0),
		@Begbkbal numeric(12,2), @Endbal numeric(12,2), @BegbkbalFC numeric(12,2), @EndbalFC numeric(12,2),
		-- 04/27/17 VL added functional currency code
		@BegbkbalPR numeric(12,2), @EndbalPR numeric(12,2)
DECLARE @ZAllPeriods TABLE (Period numeric(2,0), BegDate smalldatetime, EndDate smalldatetime, FiscalYr char(4))

SELECT @Cur_FY = Cur_fy, @Cur_Period = Cur_Period FROM GlSys
-- @Period is from user selection of periods, if no max period is found for this bank for this FY, then use @Period
SELECT @LatestFY = ISNULL(MAX(Fiscalyr),@Cur_FY) FROM CashBook WHERE Bk_uniq = @Bk_uniq
SELECT @LatestPeriod = ISNULL(MAX(Period),0) FROM CashBook WHERE Bk_Uniq = @Bk_Uniq AND Fiscalyr = @LatestFY

SELECT @Begbkbal = ISNULL(Begbkbal,0.00), @Endbal = ISNULL(Endbal,0.00), @BegbkbalFC = ISNULL(BegbkbalFC,0.00), @EndbalFC = ISNULL(EndbalFC,0.00),
	-- 04/27/17 VL added functional currency code
	@BegbkbalPR = ISNULL(BegbkbalPR,0.00), @EndbalPR = ISNULL(EndbalPR,0.00)
	FROM Cashbook 
	WHERE Bk_Uniq = @Bk_Uniq
	AND FISCALYR = @LatestFY 
	AND Period = @LatestPeriod

IF @@ROWCOUNT= 0
	BEGIN
	SET @Begbkbal = 0.00
	SET @Endbal = 0.00
	SET @BegbkbalFC = 0.00
	SET @EndbalFC = 0.00
	-- 04/27/17 VL added functional currency code
	SET @BegbkbalPR = 0.00
	SET @EndbalPR = 0.00
END

--IF (@@ROWCOUNT=0)
--BEGIN
--	RAISERROR('Cannot find cash book records for current fiscal year/period. This operation will be cancelled.',11,1)
--	ROLLBACK TRANSACTION
--	RETURN 
--END

-- If no latest period is found for current FY, then use @period that user selected from user interface
--SELECT @NewPeriod = CASE WHEN @LatestPeriod = 0 THEN @Period ELSE 
--	CASE WHEN @LatestPeriod + 1 < 13 THEN @LatestPeriod + 1 ELSE 1 END
--	END
SELECT @NewPeriod = CASE WHEN @LatestPeriod = 0 THEN @Period ELSE @LatestPeriod + 1 END

-- Load This FY start/end date into @ZAllPeriods and used in last insert into Cashbook
INSERT @ZAllPeriods (Period, BegDate, EndDate, FiscalYr) 
	SELECT Period, BegDate, EndDate, FiscalYr 
	FROM dbo.fn_GetFiscalPeriodBeginEndDate(@Cur_FY)

IF (@@ROWCOUNT=0)
BEGIN
	RAISERROR('Cannot find any fiscal year/period records for current year. This operation will be cancelled.',11,1)
	ROLLBACK TRANSACTION
	RETURN 
END

-- 04/27/17 VL added functional currency code
INSERT INTO CashBook (CBUnique, Bk_Uniq, Stmtdate, FiscalYr, Period, BegBkBal, BegBkBalFC, EndBal, EndBalFC, PerStart, PerEnd, BegBkBalPR, EndBalPR)
	SELECT dbo.fn_GenerateUniqueNumber() AS CBUnique, @Bk_uniq AS Bk_Uniq, GETDATE() AS StmtDate, @Cur_FY, Period, @BegBkBal, @BegBkBalFC, 
			@EndBal, @EndBalFC, BegDate AS PerStart, EndDate AS PerEnd, @BegBkBalPR, @EndBalPR
			FROM @ZAllPeriods ZAllPeriods
			WHERE ZAllPeriods.Period>=@NewPeriod
			AND Period NOT IN (SELECT Period FROM CashBook WHERE Bk_Uniq = @Bk_uniq AND FiscalYr = @Cur_FY)
			ORDER BY ZAllPeriods.Period
	-- I think BegBkBal, BegBkBalFC, EndBal, EndBalFC will be updated in Fy closed


COMMIT

END