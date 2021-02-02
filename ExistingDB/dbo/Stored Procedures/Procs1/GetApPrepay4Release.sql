-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 11/15/2011 - modified>
-- Description:	<Get all AP prepay un-released,>
-- 10/07/15 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
-- 10/16/15 VL Added Currency field for FC
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 05/24/16 VL Added to include DM records, if it's DM, only need to insert ER difference, but if it's prepaid, will have to have 2 pairs of amt itself and ER
--- 07/13/16 YS make sure that the value in GL is not negative, if negative reverse credit and debit sides.
-- 07/25/16 VL In ER Variance SQL, changed criteria from Credit<>0 OR Debit<>0 to ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0 because sometimes the credit/debit has number after decimal point 3 digits (eg 0.001), although it <> 0, 
-- but in GL release/post, it only allows 2 digits, so user would only see 0.00 on screen, so here if ROUND()=0, then don't bother to get the records
-- 12/14/16 VL: added functional and presentation currency fields
-- 01/11/17 VL added = sign for SUM(Apoffset.AmountPR)>0, so it includes = 0 values and won't cause null values
-- 06/29/17 VL YS found when created ER variance, have to check for any variance functional or presentation, it is possible to have only one type of variance
---07/04/17 YS Copy and Paste error and too many un-necessary function calls
-- =============================================
CREATE PROCEDURE [dbo].[GetApPrepay4Release] 
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--declare @T TABLE (FiscalYr char(4),fk_fy_uniq char(10),Period Numeric(2,0),StartDate smalldatetime,EndDate smallDateTime,fyDtlUniq uniqueidentifier)
	declare @T as [dbo].[AllFYPeriods]
insert into @T EXEC GlFyrstartEndView	;

-- 10/02/15 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
IF @lFCInstalled = 0
	BEGIN
	;WITH D as
	(		
	SELECT  [DATE] as Trans_dt,CAST(Apmaster.Reason as varchar(50)) as DisplayValue,
		uniq_apoff,UNIQ_SAVE,SUM(Apoffset.Amount) as nTransAmount,
		CASE WHEN SUM(Apoffset.Amount)>0 THEN cast(SUM(Apoffset.Amount) AS numeric(14,2))
			WHEN SUM(Apoffset.Amount)<0 THEN CAST(0.00 as numeric(14,2)) END AS Debit,
		CASE WHEN SUM(Apoffset.Amount)>0 THEN CAST(0.00 as numeric(14,2))
			WHEN SUM(Apoffset.Amount)<0 THEN  cast(ABS(SUM(Apoffset.Amount)) AS numeric(14,2)) END AS Credit,	
			CAST(' ' as CHAR(8)) as Saveinit,
			CAST('APPREPAY' as varchar(50)) as TransactionType,    -- assign the same value as in glpostdef.PostType
			CAST('APOFFSET' as varchar(25)) as SourceTable,
			'UNIQ_SAVE' as cIdentifier,
			UNIQ_SAVE as cDrill,
			CAST('APMASTER' as varchar(25)) as SourceSubTable,
			'UNIQAPHEAD' as cSubIdentifier,
			Apmaster.UNIQAPHEAD as cSubDrill,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
			Apsetup.AP_GL_NO ,Apsetup.PREPAYGLNO
	  from APOFFSET CROSS JOIN APSETUP
	  INNER JOIN APMASTER ON Apmaster.UNIQAPHEAD = APOFFSET .UNIQAPHEAD  
	  OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
	  WHERE CAST(APOFFSET.DATE as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
	   where Apmaster.lPrepay=1 
	   AND Apoffset.is_rel_gl =0
	   GROUP BY DATE,uniq_apoff,UNIQ_SAVE,apmaster.reason,Apsetup.AP_GL_NO,Apsetup.PREPAYGLNO,FiscalYr,Period,fyDtlUniq ,Apmaster.UNIQAPHEAD),
	   FinalApOff as 
	   (
	   SELECT cast(0 as bit) as lSelect,Trans_dt,Debit,Credit,Saveinit,TransactionType ,DisplayValue,
	   SourceTable ,cIdentifier ,cDrill ,
	   SourceSubTable ,cSubIdentifier ,cSubDrill, 
	   FY,Period,fk_fyDtlUniq,AP_GL_NO as GL_NBR,
	   Gl_nbrs.GL_descr, SPACE(10) AS AtdUniq_key 
	   FROM D INNER JOIN GL_nbrs on D.Ap_gl_no=Gl_nbrs.GL_NBR
	   UNION ALL
	   SELECT cast(0 as bit) as lSelect,Trans_dt,Credit As Debit,Debit as Credit,Saveinit,TransactionType ,DisplayValue,
	   SourceTable ,cIdentifier ,cDrill ,
	   SourceSubTable ,cSubIdentifier ,cSubDrill, 
	   FY,Period,fk_fyDtlUniq,
	   PREPAYGLNO as GL_NBR , Gl_nbrs.GL_descr, SPACE(10) AS AtdUniq_key 
	   FROM D INNER JOIN GL_nbrs on D.PREPAYGLNO=Gl_nbrs.GL_NBR)
   
	   SELECT FinalApoff.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalApOff ORDER BY cDrill
	END
ELSE
	-- FC code
	BEGIN
	;WITH D as
	(
	-- 10/07/15 VL added FC fields		
	SELECT  [DATE] as Trans_dt,CAST(Apmaster.Reason as varchar(50)) as DisplayValue,
		uniq_apoff,UNIQ_SAVE,SUM(Apoffset.Amount) as nTransAmount,
		CASE WHEN SUM(Apoffset.Amount)>=0 THEN cast(SUM(Apoffset.Amount) AS numeric(14,2))
			WHEN SUM(Apoffset.Amount)<0 THEN CAST(0.00 as numeric(14,2)) END AS Debit,
		CASE WHEN SUM(Apoffset.Amount)>=0 THEN CAST(0.00 as numeric(14,2))
			WHEN SUM(Apoffset.Amount)<0 THEN  cast(ABS(SUM(Apoffset.Amount)) AS numeric(14,2)) END AS Credit,	
			CAST(' ' as CHAR(8)) as Saveinit,
			CAST('APPREPAY' as varchar(50)) as TransactionType,    -- assign the same value as in glpostdef.PostType
			CAST('APOFFSET' as varchar(25)) as SourceTable,
			'UNIQ_SAVE' as cIdentifier,
			UNIQ_SAVE as cDrill,
			CAST('APMASTER' as varchar(25)) as SourceSubTable,
			'UNIQAPHEAD' as cSubIdentifier,
			Apmaster.UNIQAPHEAD as cSubDrill,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
			Apsetup.AP_GL_NO ,Apsetup.PREPAYGLNO,
			SUM(Apoffset.AmountFC) AS nTransAmountFC, Apoffset.Fcused_uniq, Apoffset.Fchist_key, Apoffset.Orig_Fchist_key, 
			-- 05/24/16 VL added next line and used in final SQL to get different record based on if it's AP prepaid or DM
			CASE WHEN Apmaster.lPrepay = 1 THEN 1 ELSE 0 END AS lPrePay,
			-- 12/14/16 VL added presentation currency fields
			SUM(Apoffset.AmountPR) as nTransAmountPR,
			CASE WHEN SUM(Apoffset.AmountPR)>=0 THEN cast(SUM(Apoffset.AmountPR) AS numeric(14,2))
				WHEN SUM(Apoffset.AmountPR)<0 THEN CAST(0.00 as numeric(14,2)) END AS DebitPR,
			CASE WHEN SUM(Apoffset.AmountPR)>=0 THEN CAST(0.00 as numeric(14,2))
				WHEN SUM(Apoffset.AmountPR)<0 THEN  cast(ABS(SUM(Apoffset.AmountPR)) AS numeric(14,2)) END AS CreditPR, 
			FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency, TF.Symbol AS Transaction_Currency,
			APOFFSET.FuncFcused_uniq, APOFFSET.PrFcused_uniq 
	  from APOFFSET
		INNER JOIN Fcused TF ON APOFFSET.Fcused_uniq = TF.Fcused_uniq
	  	INNER JOIN Fcused PF ON APOFFSET.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON APOFFSET.FuncFcused_uniq = FF.Fcused_uniq
	  CROSS JOIN APSETUP
	  INNER JOIN APMASTER ON Apmaster.UNIQAPHEAD = APOFFSET .UNIQAPHEAD  
	  OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
	  WHERE CAST(APOFFSET.DATE as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
	  -- 05/24/16 VL added to include DM offset
	   --where Apmaster.lPrepay=1 
	   where (Apmaster.lPrepay=1 OR ApMaster.aptype = 'DM')
	   AND Apoffset.is_rel_gl =0
	   GROUP BY DATE,uniq_apoff,UNIQ_SAVE,apmaster.reason,Apsetup.AP_GL_NO,Apsetup.PREPAYGLNO,FiscalYr,Period,fyDtlUniq ,Apmaster.UNIQAPHEAD,
	   -- 05/24/16 VL added Group by lPrepay
	   Apoffset.Fcused_uniq, Apoffset.Fchist_key, Apoffset.Orig_Fchist_key, lPrepay,FF.Symbol, PF.Symbol,TF.Symbol,APOFFSET.FuncFcused_uniq, APOFFSET.PrFcused_uniq ),

	   -- 05/24/16 VL rewrite this part, check Barbara did in mreleasedm
	   -- if it's prepaid:						I changed to be
	   --				Debit		Credit					Debit		Credit
	   -- ER			0			ER diff						0		ER diff	
	   -- prepaid		0			Amt							0			Amt
	   -- acct payable	ER diff+Amt	0	    acct payable	ER diff			0
	   --									acct payable	Amt				0

	   -- if DM offset							
	   --				Debit		Credit			
	   -- ER			0			ER diff			
	   -- acct payable	ER diff		0

		-- 10/07/15 added code to get the difference caused by exchange rate (for FC)
		--ERVariance AS
		--(
		--SELECT Trans_dt, DisplayValue, UNIQ_ApOFF, Uniq_save, nTransAmount, 
		--	CASE WHEN dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, Orig_Fchist_key) - nTransAmount > 0
		--		THEN CAST(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, Orig_Fchist_key) - nTransAmount AS Numeric(14,2))
		--		ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
		--	CASE WHEN dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, Orig_Fchist_key) - nTransAmount > 0
		--		THEN CAST(0.00 as numeric(14,2)) 
		--		ELSE CAST(ABS(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, Orig_Fchist_key) - nTransAmount) AS Numeric(14,2)) END AS Credit,
		--	Saveinit, TransactionType, SourceTable, cIdentifier,cDrill,SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fyDtlUniq, 
		--	Apsetup.AP_GL_NO AS GL_NBR, Currency
		--FROM D, APsetup
		--UNION ALL
		--SELECT Trans_dt, DisplayValue, UNIQ_ApOFF, Uniq_save, nTransAmount, 
		--	CASE WHEN dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, Orig_Fchist_key) - nTransAmount > 0
		--		THEN CAST(0.00 as numeric(14,2))
		--		ELSE CAST(ABS(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, Orig_Fchist_key) - nTransAmount) AS Numeric(14,2)) END AS Debit,
		--	CASE WHEN dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, Orig_Fchist_key) - nTransAmount > 0
		--		THEN CAST(ABS(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, Orig_Fchist_key) - nTransAmount) AS Numeric(14,2))
		--		ELSE CAST(0.00 as numeric(14,2)) END AS Credit,
		--	Saveinit, TransactionType, SourceTable, cIdentifier,cDrill,SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fyDtlUniq, 
		--	Cev_gl_no AS GL_NBR, Currency
		--FROM D, ApSetup
		--),
		---07/04/17 YS Copy and Paste error and too many un-necessary function calls
		--ERVariance AS
		--(
		----- 07/13/16 YS make sure that the value in GL is not negative, if negative reverse credit and debit sides.
		---- 12/14/16 VL added presentation currency fields and change for fn_Convert4FCHC()
		--SELECT Trans_dt, DisplayValue, UNIQ_ApOFF, Uniq_save, nTransAmount, 
		--	CASE WHEN 
		--	(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetFunctionalCurrency(), Orig_Fchist_key) - nTransAmount)>0 
		--		THEN (dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetFunctionalCurrency(), Orig_Fchist_key) - nTransAmount) ELSE 0.00 END AS Debit, 
		--	CASE WHEN 
		--	(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetFunctionalCurrency(),Orig_Fchist_key) - nTransAmount)>0 THEN 0.00 ELSE
		--	ABS(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetFunctionalCurrency(), Orig_Fchist_key) - nTransAmount) END AS Credit,
		--	Saveinit, TransactionType, SourceTable, cIdentifier,cDrill,SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fyDtlUniq, 
		--	Apsetup.AP_GL_NO AS GL_NBR, 
		--	nTransAmountPR, 
		--	CASE WHEN 
		--	(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(), Orig_Fchist_key) - nTransAmountPR)>0 
		--		THEN (dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmountPR) ELSE 0.00 END AS DebitPR, 
		--	CASE WHEN 
		--	(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmountPR)>0 THEN 0.00 ELSE
		--	ABS(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmountPR) END AS CreditPR,
		--	Functional_Currency, Presentation_Currency, Transaction_Currency,FuncFcused_uniq, PrFcused_uniq 
		--FROM D, APsetup
		--UNION ALL
		--SELECT Trans_dt, DisplayValue, UNIQ_ApOFF, Uniq_save, nTransAmount, 
		--	CASE WHEN dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmount < 0 THEN 
		--	ABS(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmount) ELSE 0.00 END AS Debit, 
		--	CASE WHEN (dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmount)<0 THEN 0.00 ELSE
		--	dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmount END AS Credit,
		--	Saveinit, TransactionType, SourceTable, cIdentifier,cDrill,SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fyDtlUniq, 
		--	Cev_gl_no AS GL_NBR,
		--	nTransAmountPR, 
		--	CASE WHEN dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmountPR < 0 THEN 
		--	ABS(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmountPR) ELSE 0.00 END AS DebitPR, 
		--	CASE WHEN (dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmountPR)<0 THEN 0.00 ELSE
		--	dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmountPR END AS CreditPR,
		--	Functional_Currency, Presentation_Currency, Transaction_Currency,FuncFcused_uniq, PrFcused_uniq 
		--FROM D, ApSetup
		---07/04/17 YS Copy and Paste error and too many un-necessary function calls
		ERVarianceD AS
		(
		--- 07/13/16 YS make sure that the value in GL is not negative, if negative reverse credit and debit sides.
		-- 12/14/16 VL added presentation currency fields and change for fn_Convert4FCHC()
		
		SELECT Trans_dt, DisplayValue, UNIQ_ApOFF, Uniq_save, nTransAmount, 
			CASE WHEN 
			(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetFunctionalCurrency(), Orig_Fchist_key) - nTransAmount)>0 
				THEN (dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetFunctionalCurrency(), Orig_Fchist_key) - nTransAmount) 
				ELSE 0.00 END AS Debit, 
			CASE WHEN 
			(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetFunctionalCurrency(),Orig_Fchist_key) - nTransAmount)>0 THEN 0.00 ELSE
			ABS(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetFunctionalCurrency(), Orig_Fchist_key) - nTransAmount) END AS Credit,
			Saveinit, TransactionType, SourceTable, cIdentifier,cDrill,SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fyDtlUniq, 
			Apsetup.AP_GL_NO AS GL_NBR, 
			nTransAmountPR, 
			CASE WHEN 
			(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(), Orig_Fchist_key) - nTransAmountPR)>0 
				THEN (dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmountPR) ELSE 0.00 END AS DebitPR, 
			CASE WHEN 
			(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmountPR)>0 THEN 0.00 ELSE
			ABS(dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) - nTransAmountPR) END AS CreditPR,
			Functional_Currency, Presentation_Currency, Transaction_Currency,FuncFcused_uniq, PrFcused_uniq 
		FROM D, APsetup
		)
		---07/04/17 YS Copy and Paste error and too many un-necessary function calls
		,
		ErVarianceC
		as
		(
			SELECT Trans_dt, DisplayValue, UNIQ_ApOFF, Uniq_save, nTransAmount, 
			Credit as Debit,
			Debit as Credit,
			Saveinit, TransactionType, SourceTable, cIdentifier,cDrill,SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fyDtlUniq, 
			nTransAmountPR, 
			CreditPr as DebitPr,
			DebitPr as CreditPr,
			Cev_gl_no AS GL_NBR,
			Functional_Currency, Presentation_Currency, Transaction_Currency,FuncFcused_uniq, PrFcused_uniq 
			from ERVarianceD cross join ApSetup
	
		),
	   FinalApOff as 
	   (
	   -- 12/14/16 VL added presentation currency fields 
	   SELECT cast(0 as bit) as lSelect,Trans_dt,Debit,Credit,Saveinit,TransactionType ,DisplayValue,
	   SourceTable ,cIdentifier ,cDrill ,
	   SourceSubTable ,cSubIdentifier ,cSubDrill, 
	   FY,Period,fk_fyDtlUniq,AP_GL_NO as GL_NBR,
	   Gl_nbrs.GL_descr, SPACE(10) AS AtdUniq_key,
	   DebitPR,CreditPR, Functional_Currency, Presentation_Currency,Transaction_Currency,FuncFcused_uniq, PrFcused_uniq 
	   FROM D INNER JOIN GL_nbrs on D.Ap_gl_no=Gl_nbrs.GL_NBR
		-- 05/24/16 VL added next line to filter out lPrepay = 0 (DM records which does not need it's own amt records, only need ER amt)
		WHERE lPrepay = 1
	   UNION ALL
	   SELECT cast(0 as bit) as lSelect,Trans_dt,Credit As Debit,Debit as Credit,Saveinit,TransactionType ,DisplayValue,
	   SourceTable ,cIdentifier ,cDrill ,
	   SourceSubTable ,cSubIdentifier ,cSubDrill, 
	   FY,Period,fk_fyDtlUniq,
	   PREPAYGLNO as GL_NBR , Gl_nbrs.GL_descr, SPACE(10) AS AtdUniq_key,
	   ---07/04/17 YS forgot to switch Creditpr and debitPr
	   --DebitPR,CreditPR, 
	   CreditPr As DebitPr,DebitPr as CreditPr,
	   Functional_Currency, Presentation_Currency,Transaction_Currency, FuncFcused_uniq, PrFcused_uniq 
	   FROM D INNER JOIN GL_nbrs on D.PREPAYGLNO=Gl_nbrs.GL_NBR
		-- 05/24/16 VL added next line to filter out lPrepay = 0 (DM records which does not need it's own amt records, only need ER amt)
		WHERE lPrepay = 1
		-- 10/07/15 VL added FC exchange rate
		-- 07/25/16 VL In ER Variance SQL, changed criteria from Credit<>0 OR Debit<>0 to ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0 because sometimes the credit/debit has number after decimal point 3 digits (eg 0.001), although it <> 0, 
		-- but in GL release/post, it only allows 2 digits, so user would only see 0.00 on screen, so here if ROUND()=0, then don't bother to get the records
		UNION ALL
		---07/04/17 YS Copy and Paste error and too many un-necessary function calls
		SELECT cast(0 as bit) as lSelect,Trans_dt,Debit,Credit,Saveinit,TransactionType ,DisplayValue,
		SourceTable ,cIdentifier ,cDrill ,
		SourceSubTable ,cSubIdentifier ,cSubDrill ,
		FY,Period,fk_fyDtlUniq,
		ERVarianceD.GL_NBR , Gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key,
		DebitPR,CreditPR, Functional_Currency, Presentation_Currency,Transaction_Currency, FuncFcused_uniq, PrFcused_uniq 
		FROM ERVarianceD inner join GL_NBRS on ERVarianceD.Gl_nbr = gl_nbrs.gl_nbr
		WHERE (ROUND(Credit,2) <> 0 OR ROUND(Debit,2) <> 0)
		-- 06/29/17 VL YS found when created ER variance, have to check for any variance functional or presentation, it is possible to have only one type of variance
		OR (ROUND(CreditPR,2) <> 0 OR ROUND(DebitPR,2) <> 0)
		UNION ALL
		SELECT cast(0 as bit) as lSelect,Trans_dt,Debit,Credit,Saveinit,TransactionType ,DisplayValue,
		SourceTable ,cIdentifier ,cDrill ,
		SourceSubTable ,cSubIdentifier ,cSubDrill ,
		FY,Period,fk_fyDtlUniq,
		ERVarianceC.GL_NBR , Gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key,
		DebitPR,CreditPR, Functional_Currency, Presentation_Currency,Transaction_Currency, FuncFcused_uniq, PrFcused_uniq 
		FROM ERVarianceC inner join GL_NBRS on ERVarianceC.Gl_nbr = gl_nbrs.gl_nbr
		WHERE (ROUND(Credit,2) <> 0 OR ROUND(Debit,2) <> 0)
		-- 06/29/17 VL YS found when created ER variance, have to check for any variance functional or presentation, it is possible to have only one type of variance
		OR (ROUND(CreditPR,2) <> 0 OR ROUND(DebitPR,2) <> 0))
		   
	   SELECT FinalApoff.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalApOff ORDER BY cDrill
	END
END