-- =============================================
-- Author:		Vicky Lu/Barbara Paltiel
-- Create date: 2015/11/18
-- Description:	Update cashbook records for all banks, called in fysical year close (frmGlrelpostsql)
-- Modification:
-- 08/16/16	VL	Currtrfr need to correct from 'AND Currtrfr.JEODKEY = GlTransDetails.cSubDrill' to 'AND Currtrfr.JEOHKEY = GlTransDetails.cDrill', also add one more criteria AND GLJEDET.GL_NBR=Banks.GL_NBR
-- 01/11/17 VL added one more parameter for dbo.fn_Convert4FCHC()
-- 04/27/17 VL added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdCashBook]
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

BEGIN TRANSACTION
-- 08/18/16 VL added @ZAllChecks to update FC values to use bank currency, the checkFC is saving check currency, might not be bank currency, need to convert to bank currency before update cashbook
DECLARE @ZAllChecks TABLE (Apchk_uniq char(10), Checkno char(10), CheckDate smalldatetime, Bk_Acct_no char(15), 
		Bk_Uniq char(10), BatchUniq char(10), CheckAmt numeric(12,2), CheckAmtFC numeric(12,2), Fcused_uniq char(10), Fchist_key char(10),
		Post_date smalldatetime, CheckAmtFCOrig numeric(12,2), BkFcused_uniq char(10), BkFchist_key char(10),
		-- 04/27/17 VL added functional currency code
		CheckAmtPR numeric(12,2))
-- 08/16/16 VL added Tot_DepFCOrig, also added BkFchit_key to save the bank fchist_key at the time when deposit record is created, so can use the right rate to calculate bank currency value
DECLARE @ZDepositsDet TABLE (Bk_Uniq char(10), Bk_Acct_no char(50), Gl_nbr char(13), Tot_Dep numeric(12,2), Tot_DepFC numeric(12,2), Fcused_uniq char(10), 
		Fchist_key char(10), Tot_DepFCOrig numeric(12,2), BkFcused_Uniq char(10), BkFchist_key char(10),
		-- 04/27/17 VL added functional currency code
		Tot_DepPR numeric(12,2))

-- 04/27/17 VL added functional currency code
DECLARE @ZChecks TABLE (Bk_uniq char(10), Bk_acct_no char(50), Gl_nbr char(13), TotCheck numeric(12,2), TotCheckFC numeric(12,2), TotCheckPR numeric(12,2))
-- 04/27/17 VL added functional currency code
DECLARE @ZDeposits TABLE (Bk_uniq char(10), Bk_acct_no char(50), Gl_nbr char(13), TotDeposit numeric(12,2), TotDepositFC numeric(12,2), TotDepositPR numeric(12,2))
-- 04/27/17 VL added functional currency code
DECLARE @ZCurrtrfr TABLE (Bk_uniq char(10), Bk_acct_no char(50), Gl_nbr char(13), TotTrfrDebitFC numeric(12,2), TotTrfrCreditFC numeric(12,2),
	TotTrfrDebit numeric(12,2), TotTrfrCredit numeric(12,2), TotTrfrDebitPR numeric(12,2), TotTrfrCreditPR numeric(12,2))
DECLARE @ZAllPeriods TABLE (Period numeric(2,0), BegDate smalldatetime, EndDate smalldatetime, FiscalYr char(4))

-- 08/16/16 VL added @lFCInstalled
DECLARE @Cur_FY char(4), @Cur_Period numeric(2,0), @Next_FY char(4), @Next_Period numeric(2,0), @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
SELECT @Cur_FY = Cur_fy, @Cur_Period = Cur_Period FROM GlSys

-- CHECK
-- 08/16/16 VL added @ZAllChecks and calculate the correct bank currency value (will update CheckAmtFC)
-- 04/27/17 VL added functional currency code
INSERT @ZAllChecks
SELECT Apchk_Uniq, Checkno, CheckDate, Banks.Bk_Acct_no, Banks.Bk_Uniq, Batchuniq, CheckAmt, CheckAmtFC, 
	Apchkmst.Fcused_uniq, Fchist_key, Post_date, CheckAmtFC, Banks.Fcused_uniq, SPACE(10), CheckAmtPR
	FROM Banks, Apchkmst, GlTransDetails, GlTrans, GLTRANSHEADER
	WHERE Banks.Bk_Uniq = Apchkmst.Bk_Uniq
	AND Apchkmst.Apchk_uniq = GlTransDetails.cSubDrill
	AND GlTransDetails.fk_gluniq_key = GlTrans.GLUNIQ_KEY
	AND GlTrans.Fk_GlTransUnique = GLTRANSHEADER.GltransUnique
	AND GLTRANS.GL_NBR = Banks.GL_NBR
	AND GLTRANSHEADER.TransactionType = 'CHECKS'
	AND FY = @Cur_FY
	AND Period = @Cur_Period
	AND Banks.InternalUse = 1

-- to update the CheckAmtFC if bankd currency is different from check currency
IF @lFCInstalled = 1
BEGIN
-- update the BkFchist_key to save the right rate for the bank currency at the same time when the check is created
UPDATE @ZAllChecks 
	SET BkFchist_key = B.Fchist_key 
	FROM Fchistory B, Fchistory F, @ZAllChecks ZallChecks 
	WHERE B.Fcused_Uniq = ZallChecks.BkFcused_uniq 
	AND DATEDIFF(day, B.FcDateTime, F.fcdatetime) = 0 
	AND ZallChecks.Fchist_key = F.Fchist_key
	AND ZallChecks.Fcused_uniq <> ZallChecks.BkFcused_uniq

UPDATE @ZAllChecks
	SET CheckAmtFC = dbo.fn_Convert4FCHC('H',BkFcused_uniq, CheckAmt, dbo.fn_GetFunctionalCurrency(), BkFchist_key)
	WHERE Fcused_uniq <> BkFcused_uniq
END

-- Get all checks in this FY/Period, group by bank
-- 04/27/17 VL added functional currency code
INSERT INTO @ZChecks (Bk_uniq, Bk_acct_no, Gl_nbr, TotCheck, TotCheckFC, TotCheckPR)
SELECT Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr, ISNULL(SUM(ZAllChecks.CheckAmt),0.00) AS TotCheck, ISNULL(SUM(ZAllChecks.CheckAmtFC),0.00) AS TotCheckFC,
	ISNULL(SUM(ZAllChecks.CheckAmtPR),0.00) AS TotCheckPR
	FROM Banks, @ZAllChecks ZAllChecks
	WHERE Banks.BK_UNIQ = ZAllChecks.Bk_Uniq
	GROUP BY Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr

-- 08/16/16 VL comment out old code which just sum the check amt without considering the bank currency might be different from check currency
---- Get all checks in this FY/Period, group by bank
--INSERT INTO @ZChecks (Bk_uniq, Bk_acct_no, Gl_nbr, TotCheck, TotCheckFC)
--SELECT Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr, ISNULL(SUM(Apchkmst.CheckAmt),0.00) AS TotCheck, ISNULL(SUM(Apchkmst.CheckAmtFC),0.00) AS TotCheckFC
--	FROM Banks, Apchkmst, GlTransDetails, GlTrans, GLTRANSHEADER
--	WHERE Banks.Bk_Uniq = Apchkmst.Bk_Uniq
--	AND Apchkmst.Apchk_uniq = GlTransDetails.cSubDrill
--	AND GlTransDetails.fk_gluniq_key = GlTrans.GLUNIQ_KEY
--	AND GlTrans.Fk_GlTransUnique = GLTRANSHEADER.GltransUnique
--	AND GLTRANS.GL_NBR = Banks.GL_NBR
--	AND GLTRANSHEADER.TransactionType = 'CHECKS'
--	AND FY = @Cur_FY
--	AND Period = @Cur_Period
--	AND Banks.InternalUse = 1
--	GROUP BY Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr
-- 08/16/16 VL End}

-- Deposit
-- 08/16/16 VL added @zDepositsDet to calculate bank currency later
-- 04/27/17 VL added functional currency code
INSERT INTO @ZDepositsDet (Bk_Uniq , Bk_Acct_no , Gl_nbr, Tot_Dep , Tot_DepFC , Fcused_uniq ,Fchist_key, BkFcused_Uniq , BkFchist_key, Tot_DepPR )
SELECT Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr, Gltrans.Debit AS Tot_Dep, Tot_DepFC, Deposits.FcUsed_uniq, Deposits.Fchist_key, Banks.Fcused_uniq, SPACE(10), Gltrans.DebitPR AS Tot_DepPR
	FROM Banks, Deposits, GlTransDetails, GlTrans, GLTRANSHEADER
	WHERE Banks.Bk_Uniq = Deposits.Bk_Uniq
	AND Deposits.Dep_no = GlTransDetails.cSubDrill
	AND GlTransDetails.fk_gluniq_key = GlTrans.GLUNIQ_KEY
	AND GlTrans.Fk_GlTransUnique = GLTRANSHEADER.GltransUnique
	AND GLTRANS.GL_NBR = Banks.GL_NBR
	AND GLTRANSHEADER.TransactionType = 'DEP'
	AND FY = @Cur_FY
	AND Period = @Cur_Period
	AND Banks.InternalUse = 1

--  added code to update the Tot_depfc if bank currency is different from deposit currency
IF @lFCInstalled = 1
BEGIN
--  update the BkFchist_key to save the right rate for the bank currency at the same time when the check is created
UPDATE @ZDepositsDet 
	SET BkFchist_key = B.Fchist_key 
	FROM Fchistory B, Fchistory F, @ZDepositsDet ZDepositsDet
	WHERE B.Fcused_Uniq = ZDepositsDet.BkFcused_uniq 
	AND DATEDIFF(day, B.FcDateTime, F.fcdatetime) = 0 
	AND ZDepositsDet.Fchist_key = F.Fchist_key
	AND ZDepositsDet.Fcused_uniq <> ZDepositsDet.BkFcused_uniq

UPDATE @ZDepositsDet
	SET Tot_DepFC = dbo.fn_Convert4FCHC('H',BkFcused_uniq, Tot_Dep, dbo.fn_GetFunctionalCurrency(), BkFchist_key)
	WHERE Fcused_uniq <> BkFcused_uniq
END

-- 04/27/17 VL added functional currency code
INSERT INTO @ZDeposits (Bk_uniq, Bk_acct_no, Gl_nbr, TotDeposit, TotDepositFC, TotDepositPR)
SELECT Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr, ISNULL(SUM(Tot_Dep),0.00) AS TotDeposit, ISNULL(SUM(Tot_DepFC),0.00) AS TotDepsitFC, ISNULL(SUM(Tot_DepPR),0.00) AS TotDepositPR
	FROM Banks, @ZDepositsDet ZDepositDet
	WHERE Banks.BK_UNIQ = ZDepositDet.Bk_Uniq
	GROUP BY Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr
-- 08/16/16 VL End}
-- 08/16/16 VL comment out old code which only sum deposit withoug considering the bank currency might be different from deposit currency
-- Get all deposits in this FY/Period, group by bank	
--INSERT INTO @ZDeposits (Bk_uniq, Bk_acct_no, Gl_nbr, TotDeposit, TotDepositFC)
--SELECT Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr, ISNULL(SUM(Gltrans.Debit),0.00) AS TotDeposit, ISNULL(SUM(Deposits.Tot_DepFC),0.00) AS TotDepsitFC
--	FROM Banks, Deposits, GlTransDetails, GlTrans, GLTRANSHEADER
--	WHERE Banks.Bk_Uniq = Deposits.Bk_Uniq
--	AND Deposits.Dep_no = GlTransDetails.cSubDrill
--	AND GlTransDetails.fk_gluniq_key = GlTrans.GLUNIQ_KEY
--	AND GlTrans.Fk_GlTransUnique = GLTRANSHEADER.GltransUnique
--	AND GLTRANS.GL_NBR = Banks.GL_NBR
--	AND GLTRANSHEADER.TransactionType = 'DEP'
--	AND FY = @Cur_FY
--	AND Period = @Cur_Period
--	AND Banks.InternalUse = 1
--	GROUP BY Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr
-- 08/16/16 VL End}

-- Get all currency transfer and sundry records
-- 04/27/17 VL added functional currency code
INSERT @ZCurrtrfr (Bk_uniq, Bk_acct_no, Gl_nbr, TotTrfrDebitFC, TotTrfrCreditFC, TotTrfrDebit, TotTrfrCredit, TotTrfrDebitPR, TotTrfrCreditPR)
SELECT Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr, ISNULL(SUM(Currtrfr.DebitFC), 0.00) AS TotTrfrDebitFC, 
	ISNULL(SUM(Currtrfr.CreditFC), 0.00) AS TotTrfrCreditFC, ISNULL(SUM(GlJeDet.Debit), 0.00) AS TotTrfrDebit, ISNULL(SUM(GlJeDet.Credit), 0.00) AS TotTrfrCredit,
	ISNULL(SUM(GlJeDet.DebitPR), 0.00) AS TotTrfrDebitPR, ISNULL(SUM(GlJeDet.CreditPR), 0.00) AS TotTrfrCreditPR
	FROM Banks, Currtrfr, GlTransDetails, GlTrans, GLTRANSHEADER, Gljedet
	-- 08/16/16 VL fixed next line
	--WHERE Banks.Bk_Uniq = Currtrfr.Gl_nbr
	WHERE Banks.Bk_Uniq = Currtrfr.Bk_Uniq
	AND Currtrfr.JEOHKEY = Gljedet.UNIQJEHEAD
	AND Currtrfr.JEODKEY = Gljedet.UNIQJEDET
	-- 08/16/16 VL change the criteria
	--AND Currtrfr.JEODKEY = GlTransDetails.cSubDrill
	AND CurrTrfr.JEOHKEY = GlTransDetails.cDrill
	AND GlTransDetails.fk_gluniq_key = GlTrans.GLUNIQ_KEY
	AND GlTrans.Fk_GlTransUnique = GLTRANSHEADER.GltransUnique
	AND GLTRANS.GL_NBR = Banks.GL_NBR
	AND GLTRANSHEADER.TransactionType = 'JE'
--	AND Currtrfr.SUNDRY = ''
	AND FY = @Cur_FY
	AND Period = @Cur_Period
	AND Banks.InternalUse = 1
	-- 08/16/16 VL added next line
	AND GLJEDET.GL_NBR=Banks.GL_NBR
	GROUP BY Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr
-- 11/20/15 VL didn't use join, I think the 1st took out 'currtrfr.Sundry=''' should include sundry records as well
--UNION ALL
--SELECT Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr, ISNULL(SUM(Currtrfr.DebitFC), 0.00) AS TotTrfrDebitFC, 
--	ISNULL(SUM(Currtrfr.CreditFC), 0.00) AS TotTrfrCreditFC, ISNULL(SUM(GlJeDet.Debit), 0.00) AS TotTrfrDebit, ISNULL(SUM(GlJeDet.Credit), 0.00) AS TotTrfrCredit
--	FROM Banks, Currtrfr, GlTransDetails, GlTrans, GLTRANSHEADER, Gljedet
--	WHERE Banks.Bk_Uniq = Currtrfr.Gl_nbr
--	AND Currtrfr.JEOHKEY = Gljedet.UNIQJEHEAD
--	AND Currtrfr.JEODKEY = Gljedet.UNIQJEDET
--	AND Currtrfr.JEODKEY = GlTransDetails.cSubDrill
--	AND GlTransDetails.fk_gluniq_key = GlTrans.GLUNIQ_KEY
--	AND GlTrans.Fk_GlTransUnique = GLTRANSHEADER.GltransUnique
--	AND GLTRANS.GL_NBR = Banks.GL_NBR
--	AND GLTRANSHEADER.TransactionType = 'JE'
--	AND (Currtrfr.SUNDRY = 'SUNDRY DISB' OR Currtrfr.SUNDRY = 'SUNDRY RECPT')
--	AND Currtrfr.debit+Currtrfr.credit <> 0
--	AND FY = @Cur_FY
--	AND Period = @Cur_Period
--	GROUP BY Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr

-- Update Deposits
-- 04/27/17 VL added functional currency code
UPDATE CashBook	
	SET BkDepClearedfc = ZDeposits.Totdepositfc,
		BkDepCleared = ZDeposits.Totdeposit, 
		BkDepClearedPR = ZDeposits.TotdepositPR
	FROM Cashbook, @ZDeposits ZDeposits
	WHERE Cashbook.Bk_uniq = ZDeposits.Bk_uniq
	AND Cashbook.fiscalyr = @Cur_FY
	AND Cashbook.Period = @Cur_Period 

-- Update Checks
-- 04/27/17 VL added functional currency code
UPDATE CashBook	
	SET BkCksClearedfc = ZChecks.Totcheckfc,
		BkCksCleared = ZChecks.totcheck,
		BkCksClearedPR = ZChecks.totcheckPR
	FROM Cashbook, @ZChecks ZChecks
	WHERE Cashbook.Bk_uniq = ZChecks.Bk_uniq
	AND Cashbook.fiscalyr = @Cur_FY
	AND Cashbook.Period = @Cur_Period 

-- Update Currtrfr
-- 04/27/17 VL added functional currency code
UPDATE CashBook	
	SET Bktrfrcreditclfc = ZCurrtrfr.TotTrfrCreditFC,
		Bktrfrcreditcl = ZCurrtrfr.TotTrfrCredit,
		Bktrfrdebitclfc = ZCurrtrfr.TotTrfrDebitFC,
		Bktrfrdebitcl = ZCurrtrfr.TotTrfrDebit,
		BktrfrcreditclPR = ZCurrtrfr.TotTrfrCreditPR,
		BktrfrdebitclPR = ZCurrtrfr.TotTrfrDebitPR
	FROM Cashbook, @ZCurrtrfr ZCurrtrfr
	WHERE Cashbook.Bk_uniq = ZCurrtrfr.Bk_uniq
	AND Cashbook.fiscalyr = @Cur_FY
	AND Cashbook.Period = @Cur_Period 

UPDATE CashBook
	SET EndBal = BegBkBal + BkDepCleared - BkCksCleared + BktrfrDebitCL - BktrfrCreditCL,
		EndBalFC = BegBkBalFC + BkDepClearedFC - BkCksClearedFC + BktrfrDebitCLFC - BktrfrCreditCLFC,
		-- 04/27/17 VL added functional currency code
		EndBalPR = BegBkBalPR + BkDepClearedPR - BkCksClearedPR + BktrfrDebitCLPR - BktrfrCreditCLPR
	WHERE Cashbook.fiscalyr = @Cur_FY
	AND Cashbook.Period = @Cur_Period 

-- Get the end balances for the next CB record 
SELECT @Next_Period = CASE WHEN @Cur_Period = 12 THEN 1 ELSE @Cur_Period + 1 END
SELECT @Next_FY = CASE WHEN @Cur_Period = 12 THEN CAST(CAST(@Cur_FY as int)+1 as char(4)) ELSE @Cur_FY END

-- first need to get what bank has no cashbook records, and insesrt
-- second, update all cashbook next period records

-- prepare to get start/end date for next period
INSERT @ZAllPeriods (Period, BegDate, EndDate, FiscalYr) 
	SELECT Period, BegDate, EndDate, FiscalYr 
	FROM dbo.fn_GetFiscalPeriodBeginEndDate(@Next_FY)

IF @@ROWCOUNT = 0
BEGIN
	RAISERROR('Cannot find any fiscal year/period records for next period. This operation will be cancelled.',11,1)
	ROLLBACK TRANSACTION
	RETURN 
END

-- Only insert into Cashbook, if the bank has no cashbook record for next FY/Period
INSERT CashBook (CBUnique, Bk_Uniq, StmtDate, Fiscalyr, Period, Perstart, Perend)
	SELECT dbo.fn_GenerateUniqueNumber() AS CBUnique, Banks.Bk_uniq, GETDATE(), @Next_FY, @Next_Period, ZAllPeriods.BegDate, ZAllPeriods.EndDate
		FROM Banks, @ZAllPeriods ZAllPeriods
		WHERE Banks.InternalUse = 1
		AND ZAllPeriods.FiscalYr = @Next_FY
		AND ZAllPeriods.Period = @Next_Period
		AND Bk_uniq NOT IN (SELECT Bk_Uniq FROM CashBook WHERE FiscalYr = @Next_FY AND Period = @Next_Period)

-- 04/27/17 VL added functional currency code
;WITH ZBalance4CurrentPeriod AS
(
SELECT Bk_uniq, EndBal, EndBalFC, EndBalPR
	FROM Cashbook
	WHERE FISCALYR = @Cur_FY
	AND Period = @Cur_Period
)
--Update beginning balance of next period
	
UPDATE CashBook
	SET BegbkBal = ZBalance4CurrentPeriod.EndBal, 
		BegbkBalFC = ZBalance4CurrentPeriod.EndBalFC,
		-- 04/27/17 VL added functional currency code
		BegbkBalPR = ZBalance4CurrentPeriod.EndBalPR
FROM CashBook, ZBalance4CurrentPeriod
WHERE Cashbook.Bk_uniq = ZBalance4CurrentPeriod.Bk_uniq
AND Cashbook.FISCALYR = @Next_FY
AND Cashbook.Period = @Next_Period


COMMIT

END