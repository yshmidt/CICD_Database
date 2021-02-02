-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/01/2011
-- Description:	Get Scrap information for release
-- 10/16/15 VL added AtdUniq_key
-- 06/22/16 VL added ROUND(,2) to the WHERE clause AND qtytransf*stdcost <>0.00, so the value < 0.01 won't show
-- 12/21/16 VL added functional and presentation currency fields and separate FC and non FC
-- =============================================
CREATE PROCEDURE [dbo].[GetScrap4Release]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @T as dbo.AllFYPeriods
	INSERT INTO @T EXEC GlFyrstartEndView	;
-- 12/21/16 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
	BEGIN 
	with ScrapDebit AS
	(
	SELECT SCRAPREL.wono, SCRAPREL.uniq_key, SCRAPREL.SHRI_GL_NO ,
	  SCRAPREL.wip_gl_nbr,  SCRAPREL.STDCOST ,SCRAPREL.QTYTRANSF ,
	  scraprel.TRANS_NO ,scraprel.shri_gl_no as GL_NBR, GL_NBRS.gl_descr ,
	  SCRAPREL.datetime AS Trans_dt,
	  'Work Order: '+SCRAPREL.wono as DisplayValue,
	  CASE WHEN  ROUND(qtytransf*stdcost,2)>0 THEN ROUND(qtytransf*stdcost,2) ELSE CAST(0.00 as numeric(14,2)) END as DEBIT,
	  CASE WHEN ROUND(qtytransf*stdcost,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(qtytransf*stdcost,2)) END as Credit,
	  CAST('SCRAP' as varchar(50)) as TransactionType, 
		CAST('scraprel' as varchar(25)) as SourceTable,
			'trans_no' as cIdentifier,
			scraprel.trans_no as cDrill,
			CAST('scraprel' as varchar(25)) as SourceSubTable,
			'trans_no' as cSubIdentifier,
			scraprel.trans_no as cSubDrill,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq
	  FROM  SCRAPREL OUTER APPLY (SELECT FiscalYr,Period,FyDtlUniq FROM @T as T 
			WHERE CAST(scraprel.datetime as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
			INNER JOIN GL_NBRS on SCRAPREL.SHRI_GL_NO =gl_nbrs.gl_nbr
		WHERE is_Rel_Gl=0 
		-- 06/22/16 VL added ROUND()
		and ROUND(qtytransf*stdcost,2) <>0.00
		
	),ScrapCredit AS
	(
		SELECT ScrapDebit.wono, ScrapDebit.uniq_key, 
			ScrapDebit.STDCOST ,ScrapDebit.QTYTRANSF ,
		  ScrapDebit.TRANS_NO ,ScrapDebit.wip_gl_nbr as GL_NBR,gl_nbrs.GL_DESCR, 
		 ScrapDebit.Trans_dt,
		 ScrapDebit.DisplayValue,
		 ScrapDebit.Credit as DEBIT,
		  ScrapDebit.Debit as Credit,
		  ScrapDebit.TransactionType, 
		ScrapDebit.SourceTable,
		ScrapDebit.cIdentifier,
		ScrapDebit.cDrill,
		ScrapDebit.SourceSubTable,
		ScrapDebit.cSubIdentifier,
		ScrapDebit.cSubDrill,
		ScrapDebit.FY,ScrapDebit.Period,ScrapDebit.fk_fyDtlUniq 
		  FROM  ScrapDebit inner join GL_NBRS on ScrapDebit.WIP_GL_NBR =gl_nbrs.gl_nbr
		),FinalScrap as
		(
		SELECT cast(0 as bit) as lSelect,wono, uniq_key, 
			 TRANS_NO ,GL_NBR,GL_DESCR,
			Trans_dt,
			ScrapDebit.DisplayValue,
			DEBIT,
			Credit,
		   TransactionType, 
		SourceTable,
		cIdentifier,
		cDrill,
		SourceSubTable,
		cSubIdentifier,
		cSubDrill,
		FY,Period ,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
		  FROM  ScrapDebit 
		 UNION ALL
		SELECT cast(0 as bit) as lSelect,wono, uniq_key, 
			 TRANS_NO ,GL_NBR,GL_DESCR,
			Trans_dt,
			ScrapCredit.DisplayValue,
			DEBIT,
			Credit,
		   TransactionType, 
		SourceTable,
		cIdentifier,
		cDrill,
		SourceSubTable,
		cSubIdentifier,
		cSubDrill,
		FY,Period ,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
		  FROM  ScrapCredit)
	SELECT FinalScrap.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY Wono,Trans_dt) as GroupIdNumber FROM FinalScrap ORDER BY WONO,trans_dt	  
	
	END
ELSE
	BEGIN
	with ScrapDebit AS
	(
	SELECT SCRAPREL.wono, SCRAPREL.uniq_key, SCRAPREL.SHRI_GL_NO ,
	  SCRAPREL.wip_gl_nbr,  SCRAPREL.STDCOST ,SCRAPREL.QTYTRANSF ,
	  scraprel.TRANS_NO ,scraprel.shri_gl_no as GL_NBR, GL_NBRS.gl_descr ,
	  SCRAPREL.datetime AS Trans_dt,
	  'Work Order: '+SCRAPREL.wono as DisplayValue,
	  CASE WHEN  ROUND(qtytransf*stdcost,2)>0 THEN ROUND(qtytransf*stdcost,2) ELSE CAST(0.00 as numeric(14,2)) END as DEBIT,
	  CASE WHEN ROUND(qtytransf*stdcost,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(qtytransf*stdcost,2)) END as Credit,
	  CAST('SCRAP' as varchar(50)) as TransactionType, 
		CAST('scraprel' as varchar(25)) as SourceTable,
			'trans_no' as cIdentifier,
			scraprel.trans_no as cDrill,
			CAST('scraprel' as varchar(25)) as SourceSubTable,
			'trans_no' as cSubIdentifier,
			scraprel.trans_no as cSubDrill,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
		-- 12/21/16 VL added functional and presentation currency fields
		SCRAPREL.STDCOSTPR,
		CASE WHEN  ROUND(qtytransf*stdcostPR,2)>0 THEN ROUND(qtytransf*stdcostPR,2) ELSE CAST(0.00 as numeric(14,2)) END as DEBITPR,
		CASE WHEN ROUND(qtytransf*stdcostPR,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(qtytransf*stdcostPR,2)) END as CreditPR,
		FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
		Scraprel.FuncFcused_uniq, Scraprel.PrFcused_uniq  
	  FROM  SCRAPREL 
		INNER JOIN Fcused PF ON SCRAPREL.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON SCRAPREL.FuncFcused_uniq = FF.Fcused_uniq
	  OUTER APPLY (SELECT FiscalYr,Period,FyDtlUniq FROM @T as T 
			WHERE CAST(scraprel.datetime as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
			INNER JOIN GL_NBRS on SCRAPREL.SHRI_GL_NO =gl_nbrs.gl_nbr
		WHERE is_Rel_Gl=0 
		-- 06/22/16 VL added ROUND()
		and ROUND(qtytransf*stdcost,2) <>0.00
		
	),ScrapCredit AS
	(
		SELECT ScrapDebit.wono, ScrapDebit.uniq_key, 
			ScrapDebit.STDCOST ,ScrapDebit.QTYTRANSF ,
		  ScrapDebit.TRANS_NO ,ScrapDebit.wip_gl_nbr as GL_NBR,gl_nbrs.GL_DESCR, 
		 ScrapDebit.Trans_dt,
		 ScrapDebit.DisplayValue,
		 ScrapDebit.Credit as DEBIT,
		  ScrapDebit.Debit as Credit,
		  ScrapDebit.TransactionType, 
		ScrapDebit.SourceTable,
		ScrapDebit.cIdentifier,
		ScrapDebit.cDrill,
		ScrapDebit.SourceSubTable,
		ScrapDebit.cSubIdentifier,
		ScrapDebit.cSubDrill,
		ScrapDebit.FY,ScrapDebit.Period,ScrapDebit.fk_fyDtlUniq,
		-- 12/21/16 VL added functional and presentation currency fields
		ScrapDebit.STDCOSTPR, 
		ScrapDebit.CreditPR as DEBITPR,
		ScrapDebit.DebitPR as CreditPR,
		Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		  FROM  ScrapDebit inner join GL_NBRS on ScrapDebit.WIP_GL_NBR =gl_nbrs.gl_nbr
		),FinalScrap as
		(
		SELECT cast(0 as bit) as lSelect,wono, uniq_key, 
			 TRANS_NO ,GL_NBR,GL_DESCR,
			Trans_dt,
			ScrapDebit.DisplayValue,
			DEBIT,
			Credit,
		   TransactionType, 
		SourceTable,
		cIdentifier,
		cDrill,
		SourceSubTable,
		cSubIdentifier,
		cSubDrill,
		FY,Period ,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/21/16 VL added functional and presentation currency fields
		DEBITPR,
		CreditPR,
		Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		  FROM  ScrapDebit 
		 UNION ALL
		SELECT cast(0 as bit) as lSelect,wono, uniq_key, 
			 TRANS_NO ,GL_NBR,GL_DESCR,
			Trans_dt,
			ScrapCredit.DisplayValue,
			DEBIT,
			Credit,
		   TransactionType, 
		SourceTable,
		cIdentifier,
		cDrill,
		SourceSubTable,
		cSubIdentifier,
		cSubDrill,
		FY,Period ,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/21/16 VL added functional and presentation currency fields
		DEBITPR,
		CreditPR,
		Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		  FROM  ScrapCredit)
	SELECT FinalScrap.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY Wono,Trans_dt) as GroupIdNumber FROM FinalScrap ORDER BY WONO,trans_dt	  
	
	END	 
END