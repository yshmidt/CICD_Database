-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/29/2011
-- Description:	Get AR Deposits
-- 10/13/15 VL added FC code to include ER variance
-- 10/15/15 VL: added Currency and AtdUniq_key
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 07/10/16 YS connect to gl_nbrs to get gl_descr
-- 07/25/16 VL In ER Variance SQL, changed criteria from Credit<>0 OR Debit<>0 to ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0 because sometimes the credit/debit has number after decimal point 3 digits (eg 0.001), although it <> 0, 
-- but in GL release/post, it only allows 2 digits, so user would only see 0.00 on screen, so here if ROUND()=0, then don't bother to get the records
-- 12/15/16 VL added functional and presentation currency fields, also added code to separate FC and non FC
-- 01/09/17 VL added ArDepDebit in front of Prfcused_uniq and funcFcused_uniq
-- 06/29/17 YS when created ER variance, have to check for any variance functional or presentation, it is possible to have only one type of variance
/*
 08/13/19 YS modified the foreign currency release. 
 we have changed the way we are saving the data in the arcredit table
	- new manex arcredit.fchist_key - key recorder during the deposit transaction
	- new manex orig_fchist_key - key matching acctsrec table
	- old manex arcredit.fchist_key - key matching in the acctsrec table
	- old manex orig_fchist_key - key of the deposit transaction
 the data is converted in the deposits and arcredit tables using fchist_key (key at the time of the deposit)
 This SP is changed to convert the values in the arcredit table using orig_fchist_key and if different between 
 deposits and arcredit create an ER transaction
*/
-- =============================================
CREATE PROCEDURE [dbo].[GetArDeposits4Release]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @T as dbo.AllFYPeriods
	INSERT INTO @T EXEC GlFyrstartEndView	;

-- 10/13/15 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
IF @lFCInstalled = 0
	BEGIN    
	WITH ArDepDebit AS
	(
	SELECT Deposits.Date as Trans_Dt,
		Deposits.Tot_dep,CAST('Deposit Number: '+DEPOSITS.Dep_no as varchar(50)) as DisplayValue,Deposits.DEP_NO,
		 CASE WHEN Deposits.Tot_dep>0 THEN Deposits.Tot_dep ELSE CAST(0.0 as numeric(14,2))END as Debit,
		 CASE WHEN Deposits.Tot_dep>0 THEN CAST(0.0 as numeric(14,2)) ELSE ABS(Deposits.Tot_dep) END as Credit,
		BANKS.GL_NBR, GL_NBRS.GL_DESCR,  
		CAST('DEP' as varchar(50)) as TransactionType, 
		CAST('Deposits' as varchar(25)) as SourceTable,
		'Dep_no' as cIdentifier,
		DEPOSITS.DEP_NO as cDrill,
		CAST('Deposits' as varchar(25)) as SourceSubTable,
		'Dep_no' as cSubIdentifier,
		DEPOSITS.DEP_NO as cSubDrill,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
    FROM Deposits inner join Banks ON DEPOSITS.BK_UNIQ = BANKS.BK_UNIQ   
    OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(Deposits.Date as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN GL_NBRS on Banks.GL_NBR =Gl_nbrs.GL_NBR 
    WHERE Deposits.Is_rel_gl=0
    ),
     ArDepCredit AS
     (
     SELECT ArDepDebit.Trans_Dt,
		ArCredit.Rec_Amount,ArDepDebit.DisplayValue ,ArDepDebit.Dep_no,
		 CASE WHEN ArCredit.Rec_Amount+ArCredit.DISC_TAKEN < 0 
			THEN ABS(ArCredit.Rec_Amount+ArCredit.DISC_TAKEN) 
			ELSE  CAST(0.0 as numeric(14,2)) END AS Debit,
		  CASE WHEN ArCredit.Rec_Amount+ArCredit.DISC_TAKEN < 0 
		 THEN CAST(0.0 as numeric(14,2)) 
		 ELSE ArCredit.Rec_Amount+ArCredit.DISC_TAKEN END as Credit,
		ARCREDIT.GL_NBR, gl_nbrs.GL_DESCR,  
		CAST('DEP' as varchar(50)) as TransactionType,
		CAST('Deposits' as varchar(25)) as SourceTable,
		'Dep_no' as cIdentifier,
		ArDepDebit.DEP_NO as cDrill, 
		CAST('ArCredit' as varchar(25)) as SourceSubTable,
		'UniqDetNo' as cSubIdentifier,
		ArCredit.UniqDetNo  as cSubDrill,
		ArDepDebit.FY,ArDepDebit.Period ,ArDepDebit.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
    FROM ArDepDebit inner join ArCredit  ON ArDepDebit.DEP_NO = ArCredit.DEP_NO 
    INNER JOIN GL_NBRS on arcredit.GL_NBR = gl_nbrs.GL_NBR   
     ),
     ArDepDiscount AS
     (
      SELECT ArDepDebit.Trans_Dt,
		ArCredit.DISC_TAKEN,ArDepDebit.DisplayValue ,ArDepDebit.dep_no,
		 CASE WHEN ArCredit.DISC_TAKEN>0 THEN 
		 ArCredit.DISC_TAKEN ELSE CAST(0.0 as numeric(14,2)) END AS Debit,
		 CASE WHEN ArCredit.DISC_TAKEN>0 THEN
		 CAST(0.0 as numeric(14,2)) ELSE 
		 ABS(ArCredit.DISC_TAKEN) END as Credit,
		 -- 10/13/15 VL changed next line
		 -- ArSetup.Disc_Gl_No,   gl_nbrs.GL_NBR,
		 ArSetup.Disc_gl_no AS Gl_nbr, Gl_nbrs.GL_DESCR,
		CAST('DEP' as varchar(50)) as TransactionType, 
		CAST('Deposits' as varchar(25)) as SourceTable,
		'Dep_no' as cIdentifier,
		ArDepDebit.DEP_NO as cDrill, 
		CAST('ArCredit' as varchar(25)) as SourceSubTable,
		'UniqDetNo' as cSubIdentifier,
		ArCredit.UniqDetNo  as cSubDrill,
		ArDepDebit.FY,ArDepDebit.Period ,ArDepDebit.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
    FROM ArDepDebit inner join ArCredit  ON ArDepDebit.DEP_NO = ArCredit.DEP_NO 
    CROSS JOIN  ArSetup
    inner join GL_NBRS on ARSETUP.DISC_GL_NO = gl_nbrs.gl_nbr 
    WHERE  ArCredit.DISC_TAKEN<>0.00 
     ),FinalArDep as
     (
    SELECT cast(0 as bit) as lSelect,* FROM  ArDepDebit
	UNION ALL
	SELECT cast(0 as bit) as lSelect,* from ArDepCredit
	UNION ALL
	SELECT cast(0 as bit) as lSelect,* FROM ArDepDiscount )
	SELECT FinalArDep.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY DisplayValue) as GroupIdNumber FROM FinalArDep ORDER BY DisplayValue
	
	END
ELSE   --- FC installed
	BEGIN
	/* 08/13/19 YS modified - see comments in the header   */
	-- 12/15/16 VL added one more parameter for fn_Convert4FCHC()
	;WITH ArDepDebit AS
	(
	SELECT Deposits.Date as Trans_Dt,
		Deposits.Tot_dep,
		CAST('Deposit Number: '+DEPOSITS.Dep_no as varchar(50)) as DisplayValue,Deposits.DEP_NO,
		-- 08/13/19 YS the value in the table converted at the time of the deposit
		case when deposits.TOT_DEP>0 then DEPOSITS.TOT_DEP else CAST(0.00 as Numeric(14,2)) end as debit, 
		case when deposits.TOT_DEP>0 then CAST(0.00 as Numeric(14,2)) else DEPOSITS.TOT_DEP  END AS Credit,
		BANKS.GL_NBR, GL_NBRS.GL_DESCR,  
		CAST('DEP' as varchar(50)) as TransactionType, 
		CAST('Deposits' as varchar(25)) as SourceTable,
		'Dep_no' as cIdentifier,
		DEPOSITS.DEP_NO as cDrill,
		CAST('Deposits' as varchar(25)) as SourceSubTable,
		'Dep_no' as cSubIdentifier,
		DEPOSITS.DEP_NO as cSubDrill,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		Tot_depPR,
		case when deposits.TOT_DEPPR>0 then DEPOSITS.TOT_DEPPR else CAST(0.00 as Numeric(14,2)) end as debitPR, 
		case when deposits.TOT_DEPPR>0 then CAST(0.00 as Numeric(14,2)) else DEPOSITS.TOT_DEPPR  END AS CreditPR,
		FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
		Deposits.FuncFcused_uniq, Deposits.PrFcused_uniq 
    FROM Deposits 
		INNER JOIN Fcused PF ON Deposits.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON Deposits.FuncFcused_uniq = FF.Fcused_uniq
	inner join Banks ON DEPOSITS.BK_UNIQ = BANKS.BK_UNIQ   
    OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(Deposits.Date as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN GL_NBRS on Banks.GL_NBR =Gl_nbrs.GL_NBR 
    WHERE Deposits.Is_rel_gl=0
    ),
     ArDepCredit AS
     (
	 --- 08/13/19 need to get the value at the time of the invoice 
	 -- in the new manex we are changing the way we save the data
	 --- fchist_key save the key at the time of the deposit and original key is the 
	 ---- key of the packing list
     SELECT ArDepDebit.Trans_Dt,
	 dbo.fn_Convert4FCHC('F',arcredit.FCUSED_UNIQ, ABS(ArCredit.Rec_AmountFc), 
			dbo.fn_GetFunctionalCurrency(),ArCredit.ORIG_FCHIST_KEY) as Rec_Amount,
		ArDepDebit.DisplayValue ,ArDepDebit.Dep_no,
		 --- 08/13/19 YS calculate the value using conversion from the invoice 
		 CASE WHEN ArCredit.Rec_Amount+ArCredit.DISC_TAKEN < 0 
			THEN dbo.fn_Convert4FCHC(
			'F',arcredit.FCUSED_UNIQ, ABS(ArCredit.Rec_AmountFc+ArCredit.DISC_TAKENFC), 
			dbo.fn_GetFunctionalCurrency(),ArCredit.ORIG_FCHIST_KEY) 
			ELSE  CAST(0.0 as numeric(14,2)) END AS Debit,
		  CASE WHEN ArCredit.Rec_Amount+ArCredit.DISC_TAKEN < 0 
		 THEN CAST(0.0 as numeric(14,2)) 
		 ELSE dbo.fn_Convert4FCHC(
			'F',arcredit.FCUSED_UNIQ, ABS(ArCredit.Rec_AmountFc+ArCredit.DISC_TAKENFC), 
			dbo.fn_GetFunctionalCurrency(),ArCredit.ORIG_FCHIST_KEY) 
			 END as Credit,
		ARCREDIT.GL_NBR, gl_nbrs.GL_DESCR,  
		CAST('DEP' as varchar(50)) as TransactionType,
		CAST('Deposits' as varchar(25)) as SourceTable,
		'Dep_no' as cIdentifier,
		ArDepDebit.DEP_NO as cDrill, 
		CAST('ArCredit' as varchar(25)) as SourceSubTable,
		'UniqDetNo' as cSubIdentifier,
		ArCredit.UniqDetNo  as cSubDrill,
		ArDepDebit.FY,ArDepDebit.Period ,ArDepDebit.fk_fyDtlUniq, AtdUniq_key,
		-- 12/15/16 VL added functional and presentation currency fields
		 dbo.fn_Convert4FCHC('F',arcredit.FCUSED_UNIQ, ABS(ArCredit.Rec_AmountFc), 
			dbo.fn_GetPresentationCurrency(),ArCredit.ORIG_FCHIST_KEY) as Rec_AmountPR,
		CASE WHEN ArCredit.Rec_AmountPR+ArCredit.DISC_TAKENPR < 0 
			THEN dbo.fn_Convert4FCHC(
			'F',arcredit.FCUSED_UNIQ, ABS(ArCredit.Rec_AmountFc+ArCredit.DISC_TAKENFc), 
			dbo.fn_GetPresentationCurrency(),ArCredit.ORIG_FCHIST_KEY) 
			ELSE  CAST(0.0 as numeric(14,2)) END AS DebitPr,
		  CASE WHEN ArCredit.Rec_Amount+ArCredit.DISC_TAKEN < 0 
		 THEN CAST(0.0 as numeric(14,2)) 
		 ELSE dbo.fn_Convert4FCHC(
			'F',arcredit.FCUSED_UNIQ, ABS(ArCredit.Rec_AmountFc+ArCredit.DISC_TAKENFC), 
			dbo.fn_GetPresentationCurrency(),ArCredit.ORIG_FCHIST_KEY) 
			 END as CreditPr,
		 Functional_Currency,Presentation_Currency,
		 ArDepDebit.FuncFcused_uniq, ArDepDebit.PrFcused_uniq 
    FROM ArDepDebit inner join ArCredit  ON ArDepDebit.DEP_NO = ArCredit.DEP_NO 
    INNER JOIN GL_NBRS on arcredit.GL_NBR = gl_nbrs.GL_NBR   
     ),
     ArDepDiscount AS
     (
      SELECT ArDepDebit.Trans_Dt,
	   dbo.fn_Convert4FCHC('F',arcredit.FCUSED_UNIQ, ABS(ArCredit.DISC_TAKENFc), 
			dbo.fn_GetFunctionalCurrency(),ArCredit.ORIG_FCHIST_KEY) as DISC_TAKEN,
		ArDepDebit.DisplayValue ,ArDepDebit.dep_no,
		 CASE WHEN ArCredit.DISC_TAKEN>0 THEN 
		 dbo.fn_Convert4FCHC(
			'F',arcredit.FCUSED_UNIQ, ArCredit.DISC_TAKENFC, 
			dbo.fn_GetFunctionalCurrency(),ArCredit.ORIG_FCHIST_KEY)
		 ELSE CAST(0.0 as numeric(14,2)) END AS Debit,
		 CASE WHEN ArCredit.DISC_TAKEN>0 THEN
		 CAST(0.0 as numeric(14,2)) ELSE 
		 dbo.fn_Convert4FCHC(
			'F',arcredit.FCUSED_UNIQ,ABS( ArCredit.DISC_TAKENFC), 
			dbo.fn_GetFunctionalCurrency(),ArCredit.ORIG_FCHIST_KEY) END as Credit,
		 -- 10/13/15 VL changed next line
		 -- ArSetup.Disc_Gl_No,   gl_nbrs.GL_NBR,
		 ArSetup.Disc_gl_no AS Gl_nbr, Gl_nbrs.GL_DESCR,
		CAST('DEP' as varchar(50)) as TransactionType, 
		CAST('Deposits' as varchar(25)) as SourceTable,
		'Dep_no' as cIdentifier,
		ArDepDebit.DEP_NO as cDrill, 
		CAST('ArCredit' as varchar(25)) as SourceSubTable,
		'UniqDetNo' as cSubIdentifier,
		ArCredit.UniqDetNo  as cSubDrill,
		ArDepDebit.FY,ArDepDebit.Period ,ArDepDebit.fk_fyDtlUniq, AtdUniq_key,
		-- 12/15/16 VL added functional and presentation currency fields 
		  dbo.fn_Convert4FCHC('F',arcredit.FCUSED_UNIQ, ABS(ArCredit.DISC_TAKENFc), 
			dbo.fn_GetPresentationCurrency(),ArCredit.ORIG_FCHIST_KEY) as DISC_TAKENPR,
		CASE WHEN ArCredit.DISC_TAKENPR>0 THEN 
		 dbo.fn_Convert4FCHC(
			'F',arcredit.FCUSED_UNIQ, ArCredit.DISC_TAKENFC, 
			dbo.fn_GetPresentationCurrency(),ArCredit.ORIG_FCHIST_KEY)
		 ELSE CAST(0.0 as numeric(14,2)) END AS DebitPR,
		 CASE WHEN ArCredit.DISC_TAKEN>0 THEN
		 CAST(0.0 as numeric(14,2)) ELSE 
		 dbo.fn_Convert4FCHC(
			'F',arcredit.FCUSED_UNIQ,ABS( ArCredit.DISC_TAKENFC), 
			dbo.fn_GetPresentationCurrency(),ArCredit.ORIG_FCHIST_KEY) END as CreditPR,
		 Functional_Currency,Presentation_Currency,
		 ArDepDebit.FuncFcused_uniq, ArDepDebit.PrFcused_uniq 
    FROM ArDepDebit inner join ArCredit  ON ArDepDebit.DEP_NO = ArCredit.DEP_NO 
    CROSS JOIN  ArSetup
    inner join GL_NBRS on ARSETUP.DISC_GL_NO = gl_nbrs.gl_nbr 
    WHERE  ArCredit.DISC_TAKEN<>0.00 
     ),
	-- 10/13/15 VL get ER from sum of detail - header and insert as ER varaiance because header has new value, and detail has old (invoice) value
	ArDepDebitSUM AS
	-- 12/15/16 VL added functional and presentation currency fields 
	(SELECT ISNULL(SUM(Tot_dep),0.00) AS Tot_Dep, ISNULL(SUM(Tot_depPR),0.00) AS Tot_DepPR, cDrill FROM ArDepDebit GROUP BY cDrill),
	ArDepCreditSUM AS
	-- 12/15/16 VL added functional and presentation currency fields 
	(SELECT ISNULL(SUM(Rec_Amount),0.00) AS Rec_Amount, ISNULL(SUM(Rec_AmountPR),0.00) AS Rec_AmountPR, cDrill FROM ArDepCredit GROUP BY cDrill),
	ArDepDiscountSUM AS
	-- 12/15/16 VL added functional and presentation currency fields 
	(SELECT ISNULL(SUM(DISC_TAKEN),0.00) AS DISC_TAKEN, ISNULL(SUM(DISC_TAKENPR),0.00) AS DISC_TAKENPR, cDrill FROM ArDepDiscount GROUP BY cDrill),
	-- Now Join them to get the ER variance group by dep_no
	EROnly AS
	-- 12/15/16 VL added functional and presentation currency fields 
	(SELECT (ArDepCreditSUM.Rec_amount + ISNULL(ArDepDiscountSUM.DISC_TAKEN,0.00)) - ArDepDebitSUM.Tot_dep AS ERVariance, ArDepDebitSUM.cDrill,
			(ArDepCreditSUM.Rec_amountPR + ISNULL(ArDepDiscountSUM.DISC_TAKENPR,0.00)) - ArDepDebitSUM.Tot_depPR AS ERVariancePR		
		FROM ArDepDebitSUM INNER JOIN ArDepCreditSUM ON ArDepCreditSUM.cDrill = ArDepDebitSUM.cDrill
		LEFT OUTER JOIN ArDepDiscountSUM ON ArDepDiscountSUM.cDrill = ArDepCreditSUM.cDrill),
	ERVariance AS
	(
	--07/10/16 YS connect to gl_nbrs to get gl_descr
	SELECT Trans_Dt, ERVariance, DisplayValue, DEP_NO, CASE WHEN ERVariance < 0 THEN CAST(0.0 as numeric(14,2)) ELSE ERVariance END AS Debit,
		CASE WHEN ERVariance < 0 THEN ABS(ERVariance) ELSE CAST(0.0 as numeric(14,2)) END AS Credit, Cev_gl_No AS GL_NBR, GL_NBRS.GL_DESCR, TransactionType, SourceTable, cIdentifier, 
		ArDepDebit.cDrill,	SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fyDtlUniq, AtdUniq_key,
		-- 12/15/16 VL added functional and presentation currency fields 
		ERVariancePR,
		CASE WHEN ERVariancePR < 0 THEN CAST(0.0 as numeric(14,2)) ELSE ERVariancePR END AS DebitPR,
		CASE WHEN ERVariancePR < 0 THEN ABS(ERVariancePR) ELSE CAST(0.0 as numeric(14,2)) END AS CreditPR,
		Functional_Currency,Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM ArDepDebit INNER JOIN EROnly ON ArDepDebit.cDrill = EROnly.cDrill
		CROSS APPLY ArSetup
		inner join GL_NBRS on Cev_gl_No = gl_nbrs.gl_nbr 
		 
	),
	 FinalArDep as
     (
    SELECT cast(0 as bit) as lSelect,* FROM  ArDepDebit
	UNION ALL
	SELECT cast(0 as bit) as lSelect,* from ArDepCredit
	UNION ALL
	SELECT cast(0 as bit) as lSelect,* FROM ArDepDiscount 
	UNION ALL
	-- 07/25/16 VL In ER Variance SQL, changed criteria from Credit<>0 OR Debit<>0 to ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0 because sometimes the credit/debit has number after decimal point 3 digits (eg 0.001), although it <> 0, 
	-- but in GL release/post, it only allows 2 digits, so user would only see 0.00 on screen, so here if ROUND()=0, then don't bother to get the records
	-- 06/29/17 YS when created ER variance, have to check for any variance functional or presentation, it is possible to have only one type of variance
	SELECT CAST(0 AS bit) AS lSelect, * FROM ERVariance WHERE ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0
	OR ROUND(CreditPR,2)<>0 OR ROUND(DebitPR,2)<>0
	)
	SELECT FinalArDep.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY DisplayValue) as GroupIdNumber FROM FinalArDep ORDER BY DisplayValue
	END
END