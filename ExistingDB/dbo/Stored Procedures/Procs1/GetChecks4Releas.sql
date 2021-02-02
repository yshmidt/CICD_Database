-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/24/11
-- Description:	Get Checks information for Release to GL
-- 10/09/15 VL added FC code with ER vaiance code
-- 10/16/15 VL added Currency field for FC
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 07/25/16 VL In ER Variance SQL, changed criteria from Credit<>0 OR Debit<>0 to ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0 because sometimes the credit/debit has number after decimal point 3 digits (eg 0.001), although it <> 0, 
-- but in GL release/post, it only allows 2 digits, so user would only see 0.00 on screen, so here if ROUND()=0, then don't bother to get the records
-- 12/14/16 VL: added functional and presentation currency fields
-- 06/29/17 VL YS found when created ER variance, have to check for any variance functional or presentation, it is possible to have only one type of variance
--- 07/11/18 YS supname increased from 30 to 50
-- =============================================
CREATE PROCEDURE [dbo].[GetChecks4Releas]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- get auto deposits (uniqSupno will have an empty value)
	DECLARE @T as dbo.AllFYPeriods
	INSERT INTO @T EXEC GlFyrstartEndView

-- 10/09/15 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
	BEGIN

	;WITH
    Checks AS
	(
	--- 07/11/18 YS supname increased from 30 to 50
	SELECT CheckDate as Trans_Dt, ISNULL(SupName,cast(' ' as CHAR(50))) as SupName,  
		CHECKNO,CheckAmt,ApChk_Uniq,CAST('Check Number: '+checkno as varchar(50)) as DisplayValue,
		CASE WHEN CHECKAMT >0 THEN CHECKAMT ELSE CAST(0.00 as Numeric(14,2)) END as Credit,
		CASE WHEN CHECKAMT >0 THEN CAST(0.00 as Numeric(14,2)) ELSE ABS(CHECKAMT) END as Debit,
		CAST('CHECKS' as varchar(50)) as TransactionType, 
		CAST('APCHKMST' as varchar(25)) as SourceTable,
		'ApChk_Uniq' as cIdentifier,
		ApChk_Uniq as cDrill,
		CAST('APCHKMST' as varchar(25)) as SourceSubTable,
		'ApChk_Uniq' as cSubIdentifier,
		ApChk_Uniq as cSubDrill,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fydtluniq,
		ApChkMst.Bk_Uniq ,
		Banks.BANK,
		Banks.BK_ACCT_NO  ,Banks.gl_nbr
	FROM ApChkMst LEFT OUTER JOIN SupInfo ON APCHKMST.UNIQSUPNO = Supinfo.UNIQSUPNO  
	INNER JOIN Banks ON Banks.Bk_Uniq = ApChkMst.Bk_Uniq 
	OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(ApChkMst.CheckDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
	WHERE ApChkMst.Is_Rel_Gl=0
	AND ApChkMst.CheckAmt <> 0 
	),
	FinalChecks AS
	(select cast(0 as bit) as lSelect,Trans_Dt,SupName,CHECKNO,CheckAmt,ApChk_Uniq,CAST('Check Number: '+checkno as varchar(50)) as DisplayValue,
	Credit,Debit,TransactionType,
	SourceTable,cIdentifier,cDrill,
	SourceSubTable,cSubIdentifier,cSubDrill,
	Fy,Period,fk_fyDtlUniq,
	Bk_Uniq,Bank,BK_ACCT_NO,checks.gl_nbr,gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key
	from checks inner join GL_NBRS on checks.GL_NBR = gl_nbrs.GL_NBR 
	UNION ALL  -- add discount info if any
	SELECT cast(0 as bit) as lSelect, Trans_Dt, SupName,  
		Checks.CHECKNO,CheckAmt,Checks.ApChk_Uniq,CAST('Discount for Check Number: '+ Checks.checkno as varchar(50)) as DisplayValue,
		CASE WHEN Apchkdet.Disc_Tkn >0 THEN Apchkdet.Disc_Tkn ELSE CAST(0.00 as Numeric(14,2)) END as Credit,
		CASE WHEN Apchkdet.Disc_Tkn >0 THEN CAST(0.00 as Numeric(14,2)) ELSE ABS(Apchkdet.Disc_Tkn) END as Debit,
		TransactionType, 
		SourceTable,
		cIdentifier,
		cDrill,
		CAST('APCHKDET' as varchar(25)) as SourceSubTable,
		'APCKD_UNIQ' as  cSubIdentifier,
		APCHKDET.APCKD_UNIQ as cSubDrill,
		FY,Period ,fk_fyDtlUniq,
		Bk_Uniq ,
		BANK,
		BK_ACCT_NO  ,ApSetUp.Disc_gl_no as gl_nbr,gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key
		FROM Checks INNER JOIN APCHKDET ON checks.APCHK_UNIQ =ApchkDet.APCHK_UNIQ 
		CROSS JOIN ApSetUp
		INNER JOIN GL_NBRS on apsetup.DISC_GL_NO =gl_nbrs.GL_NBR 
		WHERE APCHKDET.DISC_TKN <>0.00 
		AND ApChkdet.Apchk_Uniq<>' '   -- This code comes from 9.6.2 was added specifacly on 11/24/2008. I am not sure why yet
	UNION ALL -- add detail info
	SELECT cast(0 as bit) as lSelect,Checks.Trans_Dt, Checks.SupName,  
		Checks.CHECKNO,CheckAmt,Checks.ApChk_Uniq,CAST('Details for Check Number: '+Checks.checkno as varchar(50)) as DisplayValue,
		CASE WHEN Apchkdet.AprPay + Disc_Tkn <0 THEN ABS(Apchkdet.AprPay + Disc_Tkn) ELSE CAST(0.00 as Numeric(14,2)) END as Credit,
		CASE WHEN Apchkdet.AprPay+Apchkdet.Disc_Tkn >0 THEN Apchkdet.AprPay+Apchkdet.Disc_Tkn ELSE CAST(0.00 as Numeric(14,2)) END as Debit,
		Checks.TransactionType, 
		Checks.SourceTable,
		Checks.cIdentifier,
		Checks.cDrill,
		CAST('APCHKDET' as varchar(25)) as SourceSubTable,
		'APCKD_UNIQ' as  cSubIdentifier,
		APCHKDET.APCKD_UNIQ as cSubDrill,
		Checks.FY,Checks.Period ,Checks.fk_fyDtlUniq ,
		Checks.Bk_Uniq ,
		Checks.BANK,
		Checks.BK_ACCT_NO  ,Apchkdet.gl_nbr as gl_nbr,gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key
		FROM Checks INNER JOIN APCHKDET ON checks.APCHK_UNIQ =ApchkDet.APCHK_UNIQ 
		inner join GL_NBRS on APCHKDET.GL_NBR =gl_nbrs.GL_NBR  
		WHERE ApChkdet.Apchk_Uniq<>' ' ) ----- This code comes from 9.6.2 was added specifacly on 11/24/2008. I am not sure why yet	

		SELECT FinalChecks.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY Checkno) as GroupIdNumber FROM FinalChecks 
	END
ELSE
	BEGIN

	;WITH
    Checks AS
	(
	--- 07/11/18 YS supname increased from 30 to 50
	SELECT CheckDate as Trans_Dt, ISNULL(SupName,cast(' ' as CHAR(50))) as SupName,  
		CHECKNO,CheckAmt,ApChk_Uniq,CAST('Check Number: '+checkno as varchar(50)) as DisplayValue,
		CASE WHEN CHECKAMT >0 THEN CHECKAMT ELSE CAST(0.00 as Numeric(14,2)) END as Credit,
		CASE WHEN CHECKAMT >0 THEN CAST(0.00 as Numeric(14,2)) ELSE ABS(CHECKAMT) END as Debit,
		CAST('CHECKS' as varchar(50)) as TransactionType, 
		CAST('APCHKMST' as varchar(25)) as SourceTable,
		'ApChk_Uniq' as cIdentifier,
		ApChk_Uniq as cDrill,
		CAST('APCHKMST' as varchar(25)) as SourceSubTable,
		'ApChk_Uniq' as cSubIdentifier,
		ApChk_Uniq as cSubDrill,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fydtluniq,
		ApChkMst.Bk_Uniq ,
		Banks.BANK,
		Banks.BK_ACCT_NO  ,Banks.gl_nbr, ApChkMst.Fcused_Uniq, Fchist_key, 
		-- 12/14/16 VL: added functional and presentation currency fields
		CheckAmtPR,
		CASE WHEN CHECKAMTPR >0 THEN CHECKAMTPR ELSE CAST(0.00 as Numeric(14,2)) END as CreditPR,
		CASE WHEN CHECKAMTPR >0 THEN CAST(0.00 as Numeric(14,2)) ELSE ABS(CHECKAMTPR) END as DebitPR,
		FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency, TF.Symbol AS Transaction_Currency,
		APChkmst.FuncFcused_uniq, Apchkmst.PrFcused_uniq 
	FROM Apchkmst
		INNER JOIN Fcused TF ON Apchkmst.Fcused_uniq = TF.Fcused_uniq
	  	INNER JOIN Fcused PF ON Apchkmst.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON Apchkmst.FuncFcused_uniq = FF.Fcused_uniq
	LEFT OUTER JOIN SupInfo ON APCHKMST.UNIQSUPNO = Supinfo.UNIQSUPNO  
	INNER JOIN Banks ON Banks.Bk_Uniq = ApChkMst.Bk_Uniq 
	OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(ApChkMst.CheckDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
	WHERE ApChkMst.Is_Rel_Gl=0
	AND ApChkMst.CheckAmt <> 0 
	),
	-- 10/09/15 VL create only ER variance (Aprpay+Disc_tkn) with Apchkdet.Orig_Fchist_key - (Aprpay+Disc_tkn) with Apchkmst.Fchist_key, will be used in calculating ER variance
	ERVariance AS
	(
	-- 12/14/16 VL added presentation currency fields and add one more parameter for fn_Convert4FCHC
	SELECT cast(0 as bit) as lSelect,Checks.Trans_Dt, Checks.SupName,  
			Checks.CHECKNO,CheckAmt,Checks.ApChk_Uniq,CAST('Details for Check Number: '+Checks.checkno as varchar(50)) as DisplayValue,
			CASE WHEN (dbo.fn_Convert4FCHC('F',Fcused_uniq, Apchkdet.AprPayFC + Disc_TknFC, dbo.fn_GetFunctionalCurrency(),Orig_Fchist_key) - (Apchkdet.AprPay + Disc_Tkn)) < 0
				THEN ABS(dbo.fn_Convert4FCHC('F',Fcused_uniq, Apchkdet.AprPayFC + Disc_TknFC, dbo.fn_GetFunctionalCurrency(),Orig_Fchist_key) - (Apchkdet.AprPay + Disc_Tkn))
				ELSE CAST(0.00 as Numeric(14,2)) END AS Credit,
			CASE WHEN (dbo.fn_Convert4FCHC('F',Fcused_uniq, Apchkdet.AprPayFC + Disc_TknFC, dbo.fn_GetFunctionalCurrency(),Orig_Fchist_key) - (Apchkdet.AprPay + Disc_Tkn)) < 0
				THEN CAST(0.00 as Numeric(14,2))
				ELSE ABS(dbo.fn_Convert4FCHC('F',Fcused_uniq, Apchkdet.AprPayFC + Disc_TknFC, dbo.fn_GetFunctionalCurrency(),Orig_Fchist_key) - (Apchkdet.AprPay + Disc_Tkn))
				END AS Debit,
			Checks.TransactionType, 
			Checks.SourceTable,
			Checks.cIdentifier,
			Checks.cDrill,
			CAST('APCHKDET' as varchar(25)) as SourceSubTable,
			'APCKD_UNIQ' as  cSubIdentifier,
			APCHKDET.APCKD_UNIQ as cSubDrill,
			Checks.FY,Checks.Period ,Checks.fk_fyDtlUniq ,
			Checks.Bk_Uniq ,
			Checks.BANK,
			Checks.BK_ACCT_NO  ,Apchkdet.gl_nbr as gl_nbr,gl_nbrs.GL_DESCR,
			-- 12/14/16 VL added presentation currency fields
			CheckAmtPR,
			CASE WHEN (dbo.fn_Convert4FCHC('F',Fcused_uniq, Apchkdet.AprPayFC + Disc_TknFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - (Apchkdet.AprPayPR + Disc_TknPR)) < 0
				THEN ABS(dbo.fn_Convert4FCHC('F',Fcused_uniq, Apchkdet.AprPayFC + Disc_TknFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - (Apchkdet.AprPayPR + Disc_TknPR))
				ELSE CAST(0.00 as Numeric(14,2)) END AS CreditPR,
			CASE WHEN (dbo.fn_Convert4FCHC('F',Fcused_uniq, Apchkdet.AprPayFC + Disc_TknFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - (Apchkdet.AprPayPR + Disc_TknPR)) < 0
				THEN CAST(0.00 as Numeric(14,2))
				ELSE ABS(dbo.fn_Convert4FCHC('F',Fcused_uniq, Apchkdet.AprPayFC + Disc_TknFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - (Apchkdet.AprPayPR + Disc_TknPR))
				END AS DebitPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
				FuncFcused_uniq, PrFcused_uniq 
			FROM Checks INNER JOIN APCHKDET ON checks.APCHK_UNIQ =ApchkDet.APCHK_UNIQ 
			inner join GL_NBRS on APCHKDET.GL_NBR =gl_nbrs.GL_NBR  
			WHERE ApChkdet.Apchk_Uniq<>' '
	),
	ERVarianceSUM AS
	(
	-- 12/14/16 VL added presentation currency fields
	SELECT lSelect, Trans_Dt, SupName, Checkno, CheckAmt, ApChk_uniq, DisplayValue,	SUM(Debit) AS Credit, SUM(Credit) AS Debit, 
		TransactionType, SourceTable, cIdentifier, cDrill, SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fyDtlUniq, Bk_uniq,
		Bank, Bk_Acct_no, Apsetup.Cev_gl_no AS Gl_nbr, gl_nbrs.GL_DESCR,
		CheckAmtPR,SUM(DebitPR) AS CreditPR, SUM(CreditPR) AS DebitPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM ERVariance, Apsetup, gl_nbrs
		WHERE Apsetup.Cev_gl_no = gl_nbrs.GL_NBR
		GROUP BY lSelect, Trans_Dt, SupName, Checkno, CheckAmt, ApChk_uniq, DisplayValue, TransactionType, SourceTable, cIdentifier, 
		cDrill, SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fyDtlUniq, Bk_uniq, Bank, Bk_Acct_no, Apsetup.Cev_gl_no, gl_nbrs.GL_DESCR, CheckAmtPR,Functional_Currency, Presentation_Currency, Transaction_Currency, FuncFcused_uniq, PrFcused_uniq 
	),
	-- 10/09/15 VL End}
	FinalChecks AS
	-- 12/14/16 VL added presentation currency fields
	(select cast(0 as bit) as lSelect,Trans_Dt,SupName,CHECKNO,CheckAmt,ApChk_Uniq,CAST('Check Number: '+checkno as varchar(50)) as DisplayValue,
	Credit,Debit,TransactionType,
	SourceTable,cIdentifier,cDrill,
	SourceSubTable,cSubIdentifier,cSubDrill,
	Fy,Period,fk_fyDtlUniq,
	Bk_Uniq,Bank,BK_ACCT_NO,checks.gl_nbr,gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key  ,
	CheckAmtPR,CreditPR,DebitPR,Functional_Currency, Presentation_Currency, Transaction_Currency,
	FuncFcused_uniq, PrFcused_uniq 
	from checks inner join GL_NBRS on checks.GL_NBR = gl_nbrs.GL_NBR 
	UNION ALL  -- add discount info if any
	SELECT cast(0 as bit) as lSelect, Trans_Dt, SupName,  
		Checks.CHECKNO,CheckAmt,Checks.ApChk_Uniq,CAST('Discount for Check Number: '+ Checks.checkno as varchar(50)) as DisplayValue,
		CASE WHEN Apchkdet.Disc_Tkn >0 THEN Apchkdet.Disc_Tkn ELSE CAST(0.00 as Numeric(14,2)) END as Credit,
		CASE WHEN Apchkdet.Disc_Tkn >0 THEN CAST(0.00 as Numeric(14,2)) ELSE ABS(Apchkdet.Disc_Tkn) END as Debit,
		TransactionType, 
		SourceTable,
		cIdentifier,
		cDrill,
		CAST('APCHKDET' as varchar(25)) as SourceSubTable,
		'APCKD_UNIQ' as  cSubIdentifier,
		APCHKDET.APCKD_UNIQ as cSubDrill,
		FY,Period ,fk_fyDtlUniq,
		Bk_Uniq ,
		BANK,
		BK_ACCT_NO  ,ApSetUp.Disc_gl_no as gl_nbr,gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key  ,
		CheckAmtPR,CASE WHEN Apchkdet.Disc_TknPR >0 THEN Apchkdet.Disc_TknPR ELSE CAST(0.00 as Numeric(14,2)) END as CreditPR,
		CASE WHEN Apchkdet.Disc_TknPR >0 THEN CAST(0.00 as Numeric(14,2)) ELSE ABS(Apchkdet.Disc_TknPR) END as DebitPR,
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM Checks INNER JOIN APCHKDET ON checks.APCHK_UNIQ =ApchkDet.APCHK_UNIQ 
		CROSS JOIN ApSetUp
		INNER JOIN GL_NBRS on apsetup.DISC_GL_NO =gl_nbrs.GL_NBR 
		WHERE APCHKDET.DISC_TKN <>0.00 
		AND ApChkdet.Apchk_Uniq<>' '   -- This code comes from 9.6.2 was added specifacly on 11/24/2008. I am not sure why yet
	UNION ALL -- add detail info
	SELECT cast(0 as bit) as lSelect,Checks.Trans_Dt, Checks.SupName,  
		Checks.CHECKNO,CheckAmt,Checks.ApChk_Uniq,CAST('Details for Check Number: '+Checks.checkno as varchar(50)) as DisplayValue,
		CASE WHEN Apchkdet.AprPay + Disc_Tkn <0 THEN ABS(Apchkdet.AprPay + Disc_Tkn) ELSE CAST(0.00 as Numeric(14,2)) END as Credit,
		CASE WHEN Apchkdet.AprPay+Apchkdet.Disc_Tkn >0 THEN Apchkdet.AprPay+Apchkdet.Disc_Tkn ELSE CAST(0.00 as Numeric(14,2)) END as Debit,
		Checks.TransactionType, 
		Checks.SourceTable,
		Checks.cIdentifier,
		Checks.cDrill,
		CAST('APCHKDET' as varchar(25)) as SourceSubTable,
		'APCKD_UNIQ' as  cSubIdentifier,
		APCHKDET.APCKD_UNIQ as cSubDrill,
		Checks.FY,Checks.Period ,Checks.fk_fyDtlUniq ,
		Checks.Bk_Uniq ,
		Checks.BANK,
		Checks.BK_ACCT_NO  ,Apchkdet.gl_nbr as gl_nbr,gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key  ,
		CheckAmtPR, CASE WHEN Apchkdet.AprPayPR + Disc_TknPR <0 THEN ABS(Apchkdet.AprPayPR + Disc_TknPR) ELSE CAST(0.00 as Numeric(14,2)) END as CreditPR,
		CASE WHEN Apchkdet.AprPayPR+Apchkdet.Disc_TknPR >0 THEN Apchkdet.AprPayPR+Apchkdet.Disc_TknPR ELSE CAST(0.00 as Numeric(14,2)) END as DebitPR,
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM Checks INNER JOIN APCHKDET ON checks.APCHK_UNIQ =ApchkDet.APCHK_UNIQ 
		inner join GL_NBRS on APCHKDET.GL_NBR =gl_nbrs.GL_NBR  
		WHERE ApChkdet.Apchk_Uniq<>' '  ----- This code comes from 9.6.2 was added specifacly on 11/24/2008. I am not sure why yet	
	-- 10/09/15 VL added ER variance with two side
	-- 07/25/16 VL changed from Credit<>0 OR Debit<>0 to ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0 because sometimes the credit/debit has number after decimal point 3 digits (eg 0.001), although it <> 0, 
	-- but in GL release/post, it only allows 2 digits, so user would only see 0.00 on screen, so here if ROUND()=0, then don't bother to get the records
	UNION ALL
	SELECT lSelect, Trans_Dt, SupName, Checkno, CheckAmt, ApChk_uniq, DisplayValue,	Credit, Debit, 
		TransactionType, SourceTable, cIdentifier, cDrill, SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fyDtlUniq, Bk_uniq,
		Bank, Bk_Acct_no, Gl_nbr, GL_DESCR, SPACE(10) AS AtdUniq_key,
		CheckAmtPR,CreditPR, DebitPR,Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM ERVariance
		WHERE ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0
		-- 06/29/17 VL YS found when created ER variance, have to check for any variance functional or presentation, it is possible to have only one type of variance
		OR ROUND(CreditPR,2)<>0 OR ROUND(DebitPR,2)<>0
	UNION ALL
	SELECT lSelect, Trans_Dt, SupName, Checkno, CheckAmt, ApChk_uniq, DisplayValue,	Credit, Debit, 
		TransactionType, SourceTable, cIdentifier, cDrill, SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fyDtlUniq, Bk_uniq,
		Bank, Bk_Acct_no, Gl_nbr, GL_DESCR, SPACE(10) AS AtdUniq_key,
		CheckAmtPR,CreditPR, DebitPR,Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM ERVarianceSUM
		WHERE ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0
		-- 06/29/17 VL YS found when created ER variance, have to check for any variance functional or presentation, it is possible to have only one type of variance
		OR ROUND(CreditPR,2)<>0 OR ROUND(DebitPR,2)<>0
	-- 10/09/15 VL End}
		)
			
		SELECT FinalChecks.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY Checkno) as GroupIdNumber FROM FinalChecks 
	END
END