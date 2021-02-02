-- =============================================
-- Author:		Vicky Lu
-- Create date: 11/24/2015
-- Modification:
-- 08/02/2016	VL	Convert Tot_DepFC to show bank currency value. For example, the bank currency is EUR, the deposit is USD, the deposits.tot_depfc is saving the USD value, but in cashbook, all values should be converted to show in Bank currency
--					Also added a new field Tot_depFCOrig to show whatever Tot_DepFC values from deposits, so the header and detail records show the same values
-- 01/11/17		VL  added one more parameter for dbo.fn_Convert4FCHC()
-- 01/13/17		VL	Added functional currency fields
-- 04/26/17 VL Changed the way how to convert from func value to PR value
-- =============================================
CREATE PROCEDURE [dbo].[CashbookDeposits4BankView] 
	-- Add the parameters for the stored procedure here
	@Bk_Uniq char(10), @FiscalYr char(4), @Period numeric(2,0)
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

-- 08/02/16 VL added Tot_DepFCOrig, also added BkFchit_key to save the bank fchist_key at the time when deposit record is created, so can use the right rate to calculate bank currency value
--	01/13/17	VL	Added functional currency fields
DECLARE @ZDepositsDet TABLE (Bk_Uniq char(10), Bk_Acct_no char(50), Gl_nbr char(13), Tot_Dep numeric(12,2), Tot_DepFC numeric(12,2), Fcused_uniq char(10), 
		Fchist_key char(10), BankCode char(10), Custno char(10), Invno char(10), Rec_Amount numeric(12,2), Rec_AmountFC numeric(12,2), Disc_taken numeric(12,2),
		Disc_takenFC numeric(12,2), BookFchist_key char(10), Dep_no char(10), post_date smalldatetime, Tot_DepFCOrig numeric(12,2), BkFchist_key char(10),
		Tot_DepPR numeric(12,2),Rec_AmountPR numeric(12,2), Disc_takenPR numeric(12,2), PRFcused_uniq char(10), FuncFcused_uniq char(10))

-- 08/02/16 VL get bank currency
DECLARE @BkFcused_uniq char(10), @lFCInstalled bit
SELECT @BkFcused_uniq = Fcused_uniq FROM Banks WHERE Bk_Uniq = @Bk_Uniq
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()


-- Get all deposits in this FY/Period
;WITH ZAllDeposits AS 
(
SELECT Banks.Bk_Uniq, Banks.Bk_Acct_no, Banks.Gl_nbr, Gltrans.Debit AS Tot_Dep, Tot_DepFC, 
	Deposits.FcUsed_uniq, Deposits.Fchist_key, Dep_no, POST_DATE,
	--	01/13/17	VL	Added functional currency fields
	Gltrans.DebitPR AS Tot_DepPR, Deposits.PRFCUSED_UNIQ, Deposits.FUNCFCUSED_UNIQ
	FROM Banks, Deposits, GlTransDetails, GlTrans, GLTRANSHEADER
	WHERE Banks.Bk_Uniq = Deposits.Bk_Uniq
	AND Deposits.Dep_no = GlTransDetails.cSubDrill
	AND GlTransDetails.fk_gluniq_key = GlTrans.GLUNIQ_KEY
	AND GlTrans.Fk_GlTransUnique = GLTRANSHEADER.GltransUnique
	AND GLTRANS.GL_NBR = Banks.GL_NBR
	AND GLTRANSHEADER.TransactionType = 'DEP'
	AND Deposits.Bk_Uniq = @Bk_Uniq
	AND FY = @FiscalYr
	AND Period = @Period
	AND Banks.InternalUse = 1
)
INSERT INTO @ZDepositsDet (Bk_Uniq, Bk_Acct_no, Gl_nbr, Tot_Dep, Tot_DepFC, Fcused_uniq, Fchist_key, BankCode, Custno, Invno, Rec_Amount, Rec_AmountFC,
	Disc_taken, Disc_takenFC, BookFchist_key, Dep_no, post_date, Tot_depFCOrig, BkFchist_key,
	--	01/13/17	VL	Added functional currency fields
	Tot_DepPR,Rec_AmountPR, Disc_takenPR, PRFcused_uniq, FuncFcused_uniq)
	SELECT Bk_Uniq, Bk_Acct_no, ZAllDeposits.Gl_nbr, Tot_Dep, Tot_DepFC, ZAllDeposits.Fcused_uniq, ZAllDeposits.Fchist_key, BankCode, Custno, Invno, 
	dbo.fn_Convert4FCHC('F',ZAllDeposits.Fcused_uniq, Arcredit.Rec_AmountFC, dbo.fn_GetFunctionalCurrency(),ZAllDeposits.Fchist_key) AS Rec_Amount, Rec_AmountFC,
	-- 01/13/17 VL found next line the parameter should be Disc_TakenFC, not Disk_Takcn
	dbo.fn_Convert4FCHC('F',ZAllDeposits.Fcused_uniq, Arcredit.Disc_takenFC, dbo.fn_GetFunctionalCurrency(),ZAllDeposits.Fchist_key) AS Disc_taken, Disc_takenFC, 
	Arcredit.Fchist_key AS BookFchist_keY, ZAllDeposits.Dep_no, ZAllDeposits.post_date, TOT_DEPFC, SPACE(10),
	--	01/13/17	VL	Added functional currency fields
	Tot_DepPR, dbo.fn_Convert4FCHC('F',ZAllDeposits.Fcused_uniq, Arcredit.Rec_AmountFC, dbo.fn_GetPresentationCurrency(),ZAllDeposits.Fchist_key) AS Rec_AmountPR,
	dbo.fn_Convert4FCHC('F',ZAllDeposits.Fcused_uniq, Arcredit.Disc_takenFC, dbo.fn_GetPresentationCurrency(),ZAllDeposits.Fchist_key) AS Disc_takenPR, 
	dbo.fn_GetPresentationCurrency(), dbo.fn_GetFunctionalCurrency()
	FROM ZAllDeposits, Arcredit
	WHERE ZAllDeposits.Dep_no = Arcredit.Dep_no


-- 08/02/16 VL added code to update the Tot_depfc if bank currency is different from deposit currency
IF @lFCInstalled = 1
BEGIN
-- 08/02/16 VL update the BkFchist_key to save the right rate for the bank currency at the same time when the check is created
UPDATE @ZDepositsDet 
	SET BkFchist_key = B.Fchist_key 
	FROM Fchistory B, Fchistory F, @ZDepositsDet ZDepositsDet
	WHERE B.Fcused_Uniq = @BkFcused_uniq 
	AND DATEDIFF(day, B.FcDateTime, F.fcdatetime) = 0 
	AND ZDepositsDet.Fchist_key = F.Fchist_key
	AND ZDepositsDet.Fcused_uniq <> @BkFcused_uniq

UPDATE @ZDepositsDet
	SET Tot_DepFC = dbo.fn_Convert4FCHC('H',@BkFcused_uniq, Tot_Dep, dbo.fn_GetFunctionalCurrency(),BkFchist_key)
	WHERE Fcused_uniq <> @BkFcused_uniq
END
-- 08/02/16 VL End}


-- SQLResult (All header records)
-- ** BHP 7/7/14  Do not take sum of parts - use GLTrans and Deposits values as the re-calculations have rounding errors
-- 08/02/16 VL added Tot_depfcorig field
--	01/13/17	VL	Added functional currency fields
SELECT DISTINCT ZDepositsDet.bankcode, custname, ZDepositsDet.post_date, tot_depfc, Tot_Dep, ZDepositsDet.dep_no, tot_depfcorig, tot_depPR
	FROM @ZDepositsDet ZDepositsDet, customer
	WHERE ZDepositsDet.Bk_Uniq = @Bk_Uniq
	AND ZDepositsDet.custno = customer.custno 
	ORDER BY post_date

-- SQLResult2 (detail)
SELECT * FROM @ZDepositsDet ZDepositsDet

    
END