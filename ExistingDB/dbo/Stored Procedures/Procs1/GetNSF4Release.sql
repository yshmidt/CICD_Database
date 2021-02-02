-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/29/2011
-- Description:	Get NSF info for release
-- 10/15/15 VL added FC
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 07/10/16 VL connect to gl_nbrs to get gl_descr
-- 12/21/16 VL added functional and presentation currency fields
-- 06/29/17 VL YS found when created ER variance, have to check for any variance functional or presentation, it is possible to have only one type of variance
-- =============================================
CREATE PROCEDURE [dbo].[GetNSF4Release]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    Declare @T as dbo.AllFYPeriods
    insert into @T EXEC GlFyrstartEndView	
-- 10/13/15 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
	BEGIN        

	;WITH NSFCredit AS
	(
	SELECT Ret_date as Trans_dt, UniqRetno,Custno,Dep_No,
		 'Deposit Number: '+Dep_no as DisplayValue,
		 UniqLnno, 
		  Rec_Amount,
		  CAST(0.0 as numeric(14,2)) as Debit,
		  Rec_Amount as Credit,
		  ArretCk.GL_NBR, Gl_nbrs.GL_DESCR, 
		  CAST('NSF' as varchar(50)) as TransactionType, 
		  CAST('ArretCk' as varchar(25)) as SourceTable,
		  'UniqRetno' as cIdentifier,
		ArretCk.UniqRetno as cDrill,
		CAST('ArretCk' as varchar(25)) as SourceSubTable,
		'UniqRetno' as cSubIdentifier,
		ArretCk.UniqRetno as cSubDrill,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
	FROM ArretCk OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(ArRetck.Ret_date as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN  GL_NBRS on ArretCk.GL_NBR=Gl_nbrs.Gl_nbr 
	WHERE ArRetCk.Is_Rel_Gl =0
	),
	NSFDebit AS
	(
	SELECT NSFCredit.Trans_dt, NSFCredit.UniqRetno,NSFCredit.Custno,NSFCredit.Dep_No,
		  'Deposit Number: '+NSFCredit.Dep_no as DisplayValue,
		  NSFCredit.UniqLnno, 
		  ARRETDET.Rec_Amount,
		  CAST(ARRETDet.Rec_Amount+ArretDet.DISC_TAKEN  as numeric(14,2)) as Debit,
		  CAST(0.0 as numeric(14,2)) as Credit,
		  ArRetDet.GL_NBR,  Gl_nbrs.GL_DESCR, 
		  CAST('NSF' as varchar(50)) as TransactionType, 
		  NSFCredit.SourceTable,
		  NSFCredit.cIdentifier,
		  NSFCredit.UniqRetno as cDrill,
		  CAST('ArretDet' as varchar(25)) as SourceSubTable,
		  'UNIQDETNO' as cSubIdentifier,
		  ArretDet.UNIQDETNO  as cSubDrill,
		NSFCredit.FY,NSFCredit.Period ,NSFCredit.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key	
		FROM NSFCredit inner join ARRETDET on NSFCredit.UNIQRETNO =ARRETDET.UNIQRETNO   
		INNER JOIN  GL_NBRS on ArretDet.GL_NBR=Gl_nbrs.Gl_nbr 
	),
	NSFDescount as 
	(
	SELECT NSFCredit.Trans_dt, NSFCredit.UniqRetno,NSFCredit.Custno,NSFCredit.Dep_No,
			'Deposit Number: '+NSFCredit.Dep_no as DisplayValue,
			NSFCredit.UniqLnno, 
		  ARRETDET.DISC_TAKEN,
		 CAST(0.0 as numeric(14,2)) as Debit,
		 ArretDet.DISC_TAKEN as  Credit,
		 ArSetup.Disc_Gl_No,  Gl_nbrs.GL_DESCR,   
		 CAST('NSF' as varchar(50)) as TransactionType, 
		 NSFCredit.SourceTable,
		 NSFCredit.cIdentifier,
		 NSFCredit.UniqRetno as cDrill,
		 CAST('ArretDet' as varchar(25)) as SourceSubTable,
		 'UNIQDETNO' as cSubIdentifier,
		 ArretDet.UNIQDETNO  as cSubDrill,
		 NSFCredit.FY,NSFCredit.Period ,NSFCredit.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key	
		FROM NSFCredit inner join ARRETDET on NSFCredit.UNIQRETNO =ARRETDET.UNIQRETNO
		CROSS JOIN  ArSetup
		INNER JOIN  GL_NBRS on ArSetup.Disc_Gl_No=Gl_nbrs.Gl_nbr
		WHERE  ArretDet.DISC_TAKEN<>0.00
	),FinalNsf as 
	(
	SELECT cast(0 as bit) as lSelect,* FROM  NSFCredit
	UNION ALL
	SELECT cast(0 as bit) as lSelect,* from NSFDebit
	UNION ALL 
	SELECT cast(0 as bit) as lSelect,* FROM NSFDescount
	)
	SELECT FinalNsf.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY UniqRetno) as GroupIdNumber FROM FinalNsf ORDER BY UniqRetno
	
	END
ELSE
	BEGIN

	;WITH NSFCredit AS
	(
	SELECT Ret_date as Trans_dt, UniqRetno,Custno,Dep_No,
		 'Deposit Number: '+Dep_no as DisplayValue,
		 UniqLnno, 
		  Rec_Amount,
		-- 10/15/15 VL changed to use new ER to calculate		  
		 -- CAST(0.0 as numeric(14,2)) as Debit,
		 -- Rec_Amount as Credit,
		-- 12/21/16 VL added one more parameter for fn_Convert4FCHC
		CASE WHEN dbo.fn_Convert4FCHC('F',ArretCk.Fcused_uniq, ArretCk.Rec_AmountFC, dbo.fn_GetFunctionalCurrency(),ArretCk.Fchist_key) > 0
				THEN CAST(0.00 as Numeric(14,2)) 
				ELSE dbo.fn_Convert4FCHC('F',ArretCk.Fcused_uniq, ArretCk.Rec_AmountFC, dbo.fn_GetFunctionalCurrency(), ArretCk.Fchist_key) END AS Debit,
		CASE WHEN dbo.fn_Convert4FCHC('F',ArretCk.Fcused_uniq, ArretCk.Rec_AmountFC, dbo.fn_GetFunctionalCurrency(), ArretCk.Fchist_key) > 0
				THEN dbo.fn_Convert4FCHC('F',ArretCk.Fcused_uniq, ArretCk.Rec_AmountFC, dbo.fn_GetFunctionalCurrency(), ArretCk.Fchist_key)
				ELSE CAST(0.00 as Numeric(14,2)) END AS Credit,
		  ArretCk.GL_NBR, Gl_nbrs.GL_DESCR, 
		  CAST('NSF' as varchar(50)) as TransactionType, 
		  CAST('ArretCk' as varchar(25)) as SourceTable,
		  'UniqRetno' as cIdentifier,
		ArretCk.UniqRetno as cDrill,
		CAST('ArretCk' as varchar(25)) as SourceSubTable,
		'UniqRetno' as cSubIdentifier,
		ArretCk.UniqRetno as cSubDrill,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/21/16 VL added functional and presentation currency fields
		Rec_AmountPR, 
		-- 12/21/16 VL added one more parameter for fn_Convert4FCHC
		CASE WHEN dbo.fn_Convert4FCHC('F',ArretCk.Fcused_uniq, ArretCk.Rec_AmountFC, dbo.fn_GetPresentationCurrency(),ArretCk.Fchist_key) > 0
				THEN CAST(0.00 as Numeric(14,2)) 
				ELSE dbo.fn_Convert4FCHC('F',ArretCk.Fcused_uniq, ArretCk.Rec_AmountFC, dbo.fn_GetPresentationCurrency(), ArretCk.Fchist_key) END AS DebitPR,
		CASE WHEN dbo.fn_Convert4FCHC('F',ArretCk.Fcused_uniq, ArretCk.Rec_AmountFC, dbo.fn_GetPresentationCurrency(), ArretCk.Fchist_key) > 0
				THEN dbo.fn_Convert4FCHC('F',ArretCk.Fcused_uniq, ArretCk.Rec_AmountFC, dbo.fn_GetPresentationCurrency(), ArretCk.Fchist_key)
				ELSE CAST(0.00 as Numeric(14,2)) END AS CreditPR,
		FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency, TF.Symbol AS Transaction_Currency,
		Arretck.FuncFcused_uniq, Arretck.PrFcused_uniq 
	FROM ARRETCK
		INNER JOIN Fcused TF ON ARRETCK.Fcused_uniq = TF.Fcused_uniq
	  	INNER JOIN Fcused PF ON ARRETCK.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON ARRETCK.FuncFcused_uniq = FF.Fcused_uniq
	OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(ArRetck.Ret_date as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN  GL_NBRS on ArretCk.GL_NBR=Gl_nbrs.Gl_nbr 
	WHERE ArRetCk.Is_Rel_Gl =0
	),
	NSFDebit AS
	(
	SELECT NSFCredit.Trans_dt, NSFCredit.UniqRetno,NSFCredit.Custno,NSFCredit.Dep_No,
		  'Deposit Number: '+NSFCredit.Dep_no as DisplayValue,
		  NSFCredit.UniqLnno, 
		  ARRETDET.Rec_Amount,
		  CAST(ARRETDet.Rec_Amount+ArretDet.DISC_TAKEN  as numeric(14,2)) as Debit,
		  CAST(0.0 as numeric(14,2)) as Credit,
		  ArRetDet.GL_NBR,  Gl_nbrs.GL_DESCR, 
		  CAST('NSF' as varchar(50)) as TransactionType, 
		  NSFCredit.SourceTable,
		  NSFCredit.cIdentifier,
		  NSFCredit.UniqRetno as cDrill,
		  CAST('ArretDet' as varchar(25)) as SourceSubTable,
		  'UNIQDETNO' as cSubIdentifier,
		  ArretDet.UNIQDETNO  as cSubDrill,
		NSFCredit.FY,NSFCredit.Period ,NSFCredit.fk_fyDtlUniq, AtdUniq_key,
		-- 12/21/16 VL added functional and presentation currency fields	
		ARRETDET.Rec_AmountPR,
		CAST(ARRETDet.Rec_AmountPR+ArretDet.DISC_TAKENPR  as numeric(14,2)) as DebitPR,
		CAST(0.0 as numeric(14,2)) as CreditPR,
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM NSFCredit inner join ARRETDET on NSFCredit.UNIQRETNO =ARRETDET.UNIQRETNO   
		INNER JOIN  GL_NBRS on ArretDet.GL_NBR=Gl_nbrs.Gl_nbr 
	),
	NSFDescount as 
	(
	SELECT NSFCredit.Trans_dt, NSFCredit.UniqRetno,NSFCredit.Custno,NSFCredit.Dep_No,
			'Deposit Number: '+NSFCredit.Dep_no as DisplayValue,
			NSFCredit.UniqLnno, 
		  ARRETDET.DISC_TAKEN,
		 CAST(0.0 as numeric(14,2)) as Debit,
		 ArretDet.DISC_TAKEN as  Credit,
		 -- 10/15/15 VL changed next line
		 --ArSetup.Disc_Gl_No,  Gl_nbrs.GL_DESCR,   
		 ArSetup.Disc_Gl_No AS Gl_nbr,  Gl_nbrs.GL_DESCR,   
		 CAST('NSF' as varchar(50)) as TransactionType, 
		 NSFCredit.SourceTable,
		 NSFCredit.cIdentifier,
		 NSFCredit.UniqRetno as cDrill,
		 CAST('ArretDet' as varchar(25)) as SourceSubTable,
		 'UNIQDETNO' as cSubIdentifier,
		 ArretDet.UNIQDETNO  as cSubDrill,
		 NSFCredit.FY,NSFCredit.Period ,NSFCredit.fk_fyDtlUniq, AtdUniq_key,
		 -- 12/21/16 VL added functional and presentation currency fields	
		ARRETDET.DISC_TAKENPR,
		CAST(0.0 as numeric(14,2)) as DebitPR,
		ArretDet.DISC_TAKENPR as  CreditPR,
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 	
		FROM NSFCredit inner join ARRETDET on NSFCredit.UNIQRETNO =ARRETDET.UNIQRETNO
		CROSS JOIN  ArSetup
		INNER JOIN  GL_NBRS on ArSetup.Disc_Gl_No=Gl_nbrs.Gl_nbr
		WHERE  ArretDet.DISC_TAKEN<>0.00
	),
	-- 10/15/15 VL get ER from sum of detail - header and insert as ER varaiance because header has new value, and detail has old (invoice) value
	-- 12/21/16 VL added presentation fields
	NSFCreditSUM AS
	(SELECT ISNULL(SUM(Rec_amount),0.00) AS Rec_Amount, ISNULL(SUM(Rec_amountPR),0.00) AS Rec_AmountPR, cDrill FROM NSFCredit GROUP BY cDrill),
	NSFDebitSUM AS
	(SELECT ISNULL(SUM(Rec_Amount),0.00) AS Rec_Amount, ISNULL(SUM(Rec_AmountPR),0.00) AS Rec_AmountPR, cDrill FROM NSFDebit GROUP BY cDrill),
	NSFDescountSUM AS
	(SELECT ISNULL(SUM(DISC_TAKEN),0.00) AS DISC_TAKEN, ISNULL(SUM(DISC_TAKENPR),0.00) AS DISC_TAKENPR, cDrill FROM NSFDescount GROUP BY cDrill),
	-- Now Join them to get the ER variance group by dep_no
	EROnly AS
	-- 12/21/16 VL added presentation fields
	(SELECT (NSFDebitSUM.Rec_amount + NSFDescountSUM.DISC_TAKEN) - NSFCreditSUM.Rec_Amount AS ERVariance, 
			(NSFDebitSUM.Rec_amountPR + NSFDescountSUM.DISC_TAKENPR) - NSFCreditSUM.Rec_AmountPR AS ERVariancePR, NSFCreditSUM.cDrill		
		FROM NSFCreditSUM, NSFDebitSUM, NSFDescountSUM
		WHERE NSFCreditSUM.cDrill = NSFDebitSUM.cDrill
		AND NSFDebitSUM.cDrill = NSFDescountSUM.cDrill),
	ERVariance AS
	(
	--07/10/16 VL connect to gl_nbrs to get gl_descr
	-- 06/29/17 VL added UniqRetno, Custno, Uniqlnno fields
	SELECT Trans_Dt, UniqRetno, Custno, DEP_NO, DisplayValue, UniqLnno, ERVariance, CASE WHEN ERVariance > 0 THEN ERVariance ELSE CAST(0.0 as numeric(14,2)) END AS Debit,
		CASE WHEN ERVariance > 0 THEN CAST(0.0 as numeric(14,2)) ELSE ABS(ERVariance) END AS Credit,
		Cev_gl_No AS GL_NBR, GL_NBRS.GL_DESCR, TransactionType, SourceTable, cIdentifier, 
		NSFCredit.cDrill,	SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fyDtlUniq, AtdUniq_key,
		-- 12/21/16 VL added presentation fields 
		ERVariancePR, 
		CASE WHEN ERVariancePR > 0 THEN ERVariancePR ELSE CAST(0.0 as numeric(14,2)) END AS DebitPR,
		CASE WHEN ERVariancePR > 0 THEN CAST(0.0 as numeric(14,2)) ELSE ABS(ERVariancePR) END AS CreditPR,
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM NSFCredit INNER JOIN EROnly ON NSFCredit.cDrill = EROnly.cDrill
		CROSS APPLY ArSetup
		INNER JOIN GL_NBRS ON CEV_GL_NO = GL_NBRS.GL_NBR
	),	
	FinalNsf as 
	(
	SELECT cast(0 as bit) as lSelect,* FROM  NSFCredit
	UNION ALL
	SELECT cast(0 as bit) as lSelect,* from NSFDebit
	UNION ALL 
	SELECT cast(0 as bit) as lSelect,* FROM NSFDescount 
	-- 06/29/17 VL found the last ERVariance cursor was not added in FinalNsf, wonder if deleted by accidentally, add back
	UNION ALL
	-- 06/29/17 VL YS found when created ER variance, have to check for any variance functional or presentation, it is possible to have only one type of variance
	SELECT CAST(0 AS bit) AS lSelect, * FROM ERVariance WHERE ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0 OR ROUND(CreditPR,2)<>0 OR ROUND(DebitPR,2)<>0
	)
	SELECT FinalNsf.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY UniqRetno) as GroupIdNumber FROM FinalNsf ORDER BY UniqRetno

	END
END