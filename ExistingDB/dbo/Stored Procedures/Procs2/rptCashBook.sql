-- =============================================
-- Author:		Vicky Lu
-- Create date: 03/22/2016
-- Description:	procedure for the CashBook (Barbara created this report for Penang in 962 version)
-- Modified:
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 05/11/16 DRP:  originally planned to pass the cbunique to this procedure, but there were some limitations with the parameter sort order at this time.  So left the parameters as bk_uniq, fy and period 
--				inserted a new section for CachSumm where I will pull in all of the Cashbook header information. 
-- 07/07/16 DRP:  needed to change from Cross Apply to Outer Apply in the last select statement and also change the order the tables where pulled to address the situation where the Cash Book had Summary information but no matching detail at the time
-- 04/27/17 VL: added functional currency code
-- 10/09/17 VL: added symbol
-- 07/13/18 VL changed supname from char(30) to char(50) and Custname from char(35) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptCashBook] 
	---- Add the parameters for the stored procedure here


--declare
		@lcBk_Uniq as char(10)= ''
		,@lcFy as char(4)=''
		,@lcPer as int = ''
		,@userId uniqueidentifier = null  -- has to have valid userid to continue


AS
BEGIN



-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;


-- 07/13/18 VL changed supname from char(30) to char(50) and Custname from char(35) to char(50)
DECLARE @ZCashBook TABLE (BankCode char(10), Custname char(50), post_date smalldatetime, Tot_DepFC numeric(12,2), Tot_dep numeric(12,2), Dep_no char(10)
						,Batchdescr char(40), Supname char(50), Batch_totfc numeric(12,2), Batch_tot numeric(12,2), Status char(15)
						,Debitfc numeric(14,2), CreditFC numeric(14,2), Debit numeric(14,2), Credit numeric(14,2),Ref_no char(10), Je_no numeric(6,0)
						,RecType char(10),
						-- 04/27/17 VL added functional currencye code
						Tot_depPR numeric(12,2), Batch_totPR numeric(12,2), DebitPR numeric(14,2), CreditPR numeric(14,2),
						-- 10/09/17 VL added symbols
						FSymbol char(3), PSymbol char(3), TSymbol char(3))
-- 10/06/17 VL added symbols
DECLARE @ZCurrTrfr TABLE(Post_date smalldatetime, Debitfc numeric(14,2), CreditFC numeric(14,2), Debit numeric(14,2), Credit numeric(14,2)
						,Ref_no char(10), Je_no numeric(6,0), Endbank varchar(50), Notes Text,
						-- 04/27/17 VL added functional currencye code
						DebitPR numeric(14,2), CreditPR numeric(14,2), FSymbol char(3), PSymbol char(3), TSymbol char(3))


--05/11/16 DRP:  added the @zCashSumm 
DECLARE @ZCashSumm TABLE (CBUnique CHAR(10), Bk_Uniq CHAR(10), StmtDate DATE, FiscalYr char(4), Period numeric (2,0), Perstart date, Perend date, BegBkBal numeric(12,2)
						,BegBkBalFC numeric(12,2), BkDepCleared numeric(12,2), BkDepClearedFC numeric(12,2), BkCksCleared numeric(12,2), BkCksClearedFC numeric(12,2),BkTrfrDebitCl numeric(12,2)
						,BkTrfrDebitCLFC numeric(12,2), BkTrfrCreditCl numeric(12,2), BkTrfrCreditClFC numeric(12,2), EndBal numeric(12,2), EndBalFC numeric(12,2)
						,BANK CHAR(50),BK_ACCT_NO CHAR(50),ACCTTITLE CHAR(50),
						-- 04/27/17 VL added functional currencye code
						BegBkBalPR numeric(12,2), BkDepClearedPR numeric(12,2), BkCksClearedPR numeric(12,2), BkTrfrDebitClPR numeric(12,2), BkTrfrCreditClPR numeric(12,2),EndBalPR numeric(12,2))



-- 03/21/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 1
	BEGIN

	/*gather the header information*/	--05/11/16 DRP:  added
	insert into @ZCashSumm 
			select	CBUnique, cashbook.Bk_Uniq, cast(StmtDate as date), FiscalYr, Period, cast(Perstart as date), cast (Perend as date), BegBkBal
					,BegBkBalFC, BkDepCleared, BkDepClearedFC, BkCksCleared, BkCksClearedFC
					,BkTrfrDebitCl, BkTrfrDebitCLFC, BkTrfrCreditCl, BkTrfrCreditClFC, EndBal, EndBalFC
					,BANK,BK_ACCT_NO,ACCTTITLE,
					-- 04/27/17 VL added functional currencye code
					BegBkBalPR, BkDepClearedPR, BkCksClearedPR, BkTrfrDebitClPR, BkTrfrCreditClPR, EndBalPR
			from	cashbook 
					inner join banks on cashbook.bk_uniq = banks.bk_uniq
			where	cashbook.bk_uniq = @lcbk_uniq
					and cashbook.FISCALYR = @lcFy
					and CASHBOOK.PERIOD = @lcPer

--select * from @zcashsumm
-- Deposits
	-- Get all deposits in this FY/Period
	;WITH ZAllDeposits AS 
	(
		SELECT Gltrans.Debit AS Tot_Dep, Tot_DepFC, Dep_no, POST_DATE,
		-- 04/27/17 VL added functional currencye code
				Gltrans.DebitPR AS Tot_DepPR
		-- 10/06/17 VL added symbols
		,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
		FROM Banks, GlTransDetails, GlTrans, GLTRANSHEADER, Deposits
		-- 10/06/17 VL changed criteria to get 3 currencies
		INNER JOIN Fcused PF ON DEPOSITS.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON DEPOSITS.FuncFcused_uniq = FF.Fcused_uniq			
		INNER JOIN Fcused TF ON DEPOSITS.Fcused_uniq = TF.Fcused_uniq	
		WHERE Banks.Bk_Uniq = Deposits.Bk_Uniq
		AND Deposits.Dep_no = GlTransDetails.cSubDrill
		AND GlTransDetails.fk_gluniq_key = GlTrans.GLUNIQ_KEY
		AND GlTrans.Fk_GlTransUnique = GLTRANSHEADER.GltransUnique
		AND GLTRANS.GL_NBR = Banks.GL_NBR
		AND GLTRANSHEADER.TransactionType = 'DEP'
		AND Deposits.Bk_Uniq = @lcBk_Uniq
		AND FY = @lcFy
		AND Period = @lcPer
		AND Banks.InternalUse = 1
	)
	-- 04/27/17 VL added functional currencye code
	-- 10/06/17 VL changed criteria to get 3 currencies
	INSERT INTO @ZCashBook (BankCode, Custname, ZAllDeposits.post_date, Tot_DepFC, Tot_Dep, ZAllDeposits.Dep_no, RecType, Tot_DepPR, FSymbol, PSymbol, TSymbol)
		SELECT DISTINCT BankCode, Custname, ZAllDeposits.post_date, Tot_DepFC, Tot_Dep, ZAllDeposits.Dep_no, 'Deposit' AS RecType, Tot_DepPR, FSymbol, PSymbol, TSymbol
			FROM ZAllDeposits, Arcredit, customer
			WHERE ZAllDeposits.Dep_no = Arcredit.Dep_no
			AND Arcredit.Custno = Customer.Custno 
			ORDER BY Post_date


-- Checks   
	-- Get all checks in this FY/Period for the bank first
	;WITH ZAllChecks AS
	(
	-- 04/27/17 VL added functional currencye code
	-- 10/06/17 VL changed criteria to get 3 currencies
	SELECT Apchk_Uniq, Checkno, Apchkmst.UniqSupno, Banks.Bk_Uniq, Batchuniq, CheckAmt, CheckAmtFC, Post_date, Supname, Apchkmst.Status,CheckAmtPR,
		TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
		FROM Banks, GlTransDetails, GlTrans, GLTRANSHEADER, Supinfo, Apchkmst
		-- 10/06/17 VL changed criteria to get 3 currencies
		INNER JOIN Fcused PF ON Apchkmst.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON Apchkmst.FuncFcused_uniq = FF.Fcused_uniq			
		INNER JOIN Fcused TF ON Apchkmst.Fcused_uniq = TF.Fcused_uniq	
		WHERE Banks.Bk_Uniq = Apchkmst.Bk_Uniq
		AND Apchkmst.Apchk_uniq = GlTransDetails.cSubDrill
		AND GlTransDetails.fk_gluniq_key = GlTrans.GLUNIQ_KEY
		AND GlTrans.Fk_GlTransUnique = GLTRANSHEADER.GltransUnique
		AND GLTRANS.GL_NBR = Banks.GL_NBR
		AND GLTRANSHEADER.TransactionType = 'CHECKS'
		AND Apchkmst.Uniqsupno = Supinfo.Uniqsupno
		AND Apchkmst.Bk_Uniq = @lcbk_uniq
		AND FY = @lcFy
		AND Period = @lcPer
		AND Banks.InternalUse = 1
	)
	-- Get the batch records
	-- 04/27/17 VL added functional currencye code
	-- 10/06/17 VL changed criteria to get 3 currencies
	INSERT INTO @ZCashBook (Batchdescr, Supname, Post_date, Batch_totFC, Batch_tot, Status, RecType, Batch_totPR, FSymbol, PSymbol, TSymbol)
		SELECT ISNULL(Apbatch.batchdescr, ZAllChecks.checkno) AS Batchdescr, Supname, ZAllChecks.Post_date, ISNULL(SUM(ZAllChecks.Checkamtfc),0.00) AS Batch_totfc, 
			ISNULL(SUM(ZAllChecks.checkamt),0.00) AS Batch_tot, ZAllChecks.Status, 'Check' AS RecType, ISNULL(SUM(ZAllChecks.checkamtPR),0.00) AS Batch_totPR,
			FSymbol, PSymbol, TSymbol
			FROM ZAllChecks LEFT OUTER JOIN Apbatch ON ZAllChecks.Batchuniq = apbatch.Batchuniq 
			GROUP BY ZAllChecks.Batchuniq, ZAllChecks.Post_date, supname, ISNULL(Apbatch.batchdescr, ZAllChecks.checkno), ZAllChecks.Status, FSymbol, PSymbol, TSymbol 
			ORDER BY post_date,Batchdescr

-- Currency Transfer
	-- Get records from SP
	INSERT INTO @ZCurrTrfr EXEC CashbookCurrencyTransfer4BankView @lcbk_uniq, @lcFy,@lcPer
	-- Insesrt into @ZCashBook 
	-- 04/27/17 VL added functional currencye code
	INSERT INTO @ZCashBook (Post_date, Debitfc, CreditFC, Debit, Credit, Ref_no, Je_no, RecType, DebitPR, CreditPR, FSymbol, PSymbol, TSymbol)
		SELECT Post_date, Debitfc, CreditFC, Debit, Credit, Ref_no, Je_no, 'CurrTrfr' AS RecType, DebitPR, CreditPR, FSymbol, PSymbol, TSymbol FROM @ZCurrTrfr


	--05/11/16 DRP:  included the @zcashSumm within the results 
	select	A.*,C.* FROM	@ZCashSumm C outer apply @zCashBook A
	--select	A.*,C.* FROM	@ZCashBook A cross apply @ZCashSumm C	--07/07/16 DRP:  replaced with the above.   needed to switch the Cross Apply to be outer apply and have the @zCashSumm first.
		
	END--End of FC installed
END
END