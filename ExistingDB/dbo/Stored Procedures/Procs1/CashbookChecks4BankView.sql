-- =============================================
-- Author:		Vicky Lu
-- Create date: 11/24/2015
-- Modification:
-- 08/02/2016	VL	Convert CheckAmtFC to show bank currency value. For example, the bank currency is EUR, the check is USD, the Apchkmst.CheckAmtFC is saving the USD value, but in cashbook, all values should be converted to show in Bank currency
--					Also added a new field CheckAmtFCOrig to show whatever CheckAmtFC values from Apchkmst, so the header and detail records show the same values
-- 01/11/17		VL added one more parameter for dbo.fn_Convert4FCHC()
-- 02/07/17		VL	Added functional code
--- 07/11/18 YS supname increased from 30 to 50
-- =============================================
CREATE PROCEDURE [dbo].[CashbookChecks4BankView] 
	-- Add the parameters for the stored procedure here
	@Bk_Uniq char(10), @FiscalYr char(4), @Period numeric(2,0)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- 08/02/16 VL added CheckAmtFCOrig, also added BkFchit_key to save the bank fchist_key at the time when check record is created, so can use the right rate to calculate bank currency value
DECLARE @ZAllChecks TABLE (Apchk_uniq char(10), Checkno char(10), CheckDate smalldatetime, Bk_Acct_no char(15), Status char(15), UniqSUpno char(15),
		Bk_Uniq char(10), BatchUniq char(10), CheckAmt numeric(12,2), CheckAmtFC numeric(12,2), Pmttype char(50), Fcused_uniq char(10), Fchist_key char(10),
		--- 07/11/18 YS supname increased from 30 to 50
		Post_date smalldatetime, Supname char(50), CheckAmtFCOrig numeric(12,2), BkFchist_key char(10),
		-- 02/07/17 VL added functional currency code
		CheckAmtPR numeric(12,2), PRFcused_uniq char(10), FuncFcused_uniq char(10))

-- 02/07/17 VL added functional currency code
--- 07/11/18 YS supname increased from 30 to 50
DECLARE @ZCheckBatch TABLE (Batchdescr char(40), Post_date smalldatetime, Batch_totfc numeric(12,2), Batch_tot numeric(12,2), Batchuniq char(10), 
		Supname char(50), Apchk_Uniq char(10), Batch_totPR numeric(12,2))

-- 08/02/16 VL get bank currency
DECLARE @BkFcused_uniq char(10), @lFCInstalled bit
SELECT @BkFcused_uniq = Fcused_uniq FROM Banks WHERE Bk_Uniq = @Bk_Uniq
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

-- Get all checks in this FY/Period for the bank first
-- 08/02/16 VL added CheckAmtBc
-- 02/07/17 VL added functional currency code
INSERT @ZAllChecks
SELECT Apchk_Uniq, Checkno, CheckDate, Banks.Bk_Acct_no, Apchkmst.Status, Apchkmst.UniqSupno, Banks.Bk_Uniq, Batchuniq, CheckAmt, CheckAmtFC, Pmttype, 
	Apchkmst.Fcused_uniq, Fchist_key, Post_date, Supname, CheckAmtFC, SPACE(10), CheckAmtPR, APCHKMST.PRFcused_Uniq, Apchkmst.FUNCFCUSED_UNIQ
	FROM Banks, Apchkmst, GlTransDetails, GlTrans, GLTRANSHEADER, Supinfo
	WHERE Banks.Bk_Uniq = Apchkmst.Bk_Uniq
	AND Apchkmst.Apchk_uniq = GlTransDetails.cSubDrill
	AND GlTransDetails.fk_gluniq_key = GlTrans.GLUNIQ_KEY
	AND GlTrans.Fk_GlTransUnique = GLTRANSHEADER.GltransUnique
	AND GLTRANS.GL_NBR = Banks.GL_NBR
	AND GLTRANSHEADER.TransactionType = 'CHECKS'
	AND Apchkmst.Uniqsupno = Supinfo.Uniqsupno
	AND Apchkmst.Bk_Uniq = @Bk_Uniq
	AND FY = @FiscalYr
	AND Period = @Period
	AND Banks.InternalUse = 1

-- 08/02/16 VL added code to update the CheckAmtFC if bankd currency is different from check currency
IF @lFCInstalled = 1
BEGIN
-- 08/02/16 VL update the BkFchist_key to save the right rate for the bank currency at the same time when the check is created
UPDATE @ZAllChecks 
	SET BkFchist_key = B.Fchist_key 
	FROM Fchistory B, Fchistory F, @ZAllChecks ZallChecks 
	WHERE B.Fcused_Uniq = @BkFcused_uniq 
	AND DATEDIFF(day, B.FcDateTime, F.fcdatetime) = 0 
	AND ZallChecks.Fchist_key = F.Fchist_key
	AND ZallChecks.Fcused_uniq <> @BkFcused_uniq

-- 02/07/17 VL added functional currency code
UPDATE @ZAllChecks
	SET CheckAmtFC = dbo.fn_Convert4FCHC('H',@BkFcused_uniq, CheckAmt, dbo.fn_GetFunctionalCurrency(), BkFchist_key)
	WHERE Fcused_uniq <> @BkFcused_uniq
END
-- 08/02/16 VL End}

-- Get the batch records
-- 02/07/17 VL added functional currency code
INSERT INTO @ZCheckBatch (Batchdescr, Post_date, Batch_totfc, Batch_tot, Batchuniq, Batch_totPR)
SELECT ISNULL(Apbatch.batchdescr, ZAllChecks.checkno) AS Batchdescr, ZAllChecks.Post_date, ISNULL(SUM(ZAllChecks.Checkamtfc),0.00) AS Batch_totfc, 
	ISNULL(SUM(ZAllChecks.checkamt),0.00) AS Batch_tot, ZAllChecks.Batchuniq, ISNULL(SUM(ZAllChecks.checkamtPR),0.00) AS Batch_totPR
	FROM @ZAllChecks ZAllChecks LEFT OUTER JOIN Apbatch ON ZAllChecks.Batchuniq = apbatch.Batchuniq 
	GROUP BY ZAllChecks.Batchuniq, ZAllChecks.Post_date, ISNULL(Apbatch.batchdescr, ZAllChecks.checkno) 
	ORDER BY post_date

-- SQLResult (All header records)
SELECT * FROM @ZAllChecks

-- SQLResult1 (group by batch)
SELECT * FROM @ZCheckBatch

-- SQLResult2 (detail)
SELECT Apchkdet.* 
	FROM Apchkdet, @ZAllChecks ZAllChecks
	WHERE Apchkdet.Apchk_uniq = ZAllChecks.Apchk_uniq
      
END