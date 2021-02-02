-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/01/2011
-- Description:	Get Unreconsile account info for release
-- 06/04/2013 YS fix GL # description was showing unreconcile account description for the Raw account
-- 10/16/15 VL added AtdUniq_key
-- 12/21/16 VL added functional and presentation currency fields and separate FC and non FC
-- =============================================
CREATE PROCEDURE [dbo].[GetUnreconcileAccount4Release]
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
	with UnrecDebit as
	(
	-- 06/04/2013 YS fix GL # description was showing unreconcile account description for the Raw account
	SELECT porecrelgl.TRANS_DATE as Trans_dt, DebitRawAcct,Raw_Gl_nbr,UnRecon_Gl_Nbr,Porecrelgl.UNIQRECREL,
			'Receiver Number: '+Porecloc.RECEIVERNO as DisplayValue,
			CASE WHEN DebitRawAcct=1 THEN PoRecRelGl.Raw_Gl_nbr ELSE PoRecRElGl.UnRecon_Gl_Nbr END as Gl_nbr, gl_nbrs.GL_DESCR,
			ABS(PORECRELGL.TOTALCOST) as Debit,
			CAST(0.00 as numeric(14,2)) as Credit, 
			CAST('UNRECREC' as varchar(50)) as TransactionType, 
			CAST('PORecRelGl' as varchar(25)) as SourceTable,
			'UNIQRECREL' as cIdentifier,
			PorecRelGl.UNIQRECREL as cDrill,
			CAST('PORecRelGl' as varchar(25)) as SourceSubTable,
			'UNIQRECREL' as cSubIdentifier,
			PorecRelGl.UNIQRECREL as cSubDrill,
			fy.FiscalYr as FY,fy.Period,fy.fyDtlUniq as fk_fyDtlUniq
		FROM  PoRecRelGl OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(TRANS_DATE as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
			INNER JOIN GL_NBRS on gl_nbrs.gl_nbr=CASE WHEN DEBITRAWACCT =1 THEN PoRecRelGl.Raw_Gl_nbr ELSE Porecrelgl.UNRECON_GL_NBR END 
			INNER JOIN PORECLOC on Porecrelgl.LOC_UNIQ = Porecloc.LOC_UNIQ 
			WHERE PORECRELGL.IS_REL_GL = 0 and TOTALCOST<>0.00
		),
		UnrecCredit as
		(
		-- 06/04/2013 YS fix GL # description was showing unreconcile account description for the Raw account
		SELECT UnrecDebit.Trans_dt, UNIQRECREL,
		 DisplayValue,
			CASE WHEN DebitRawAcct=1 THEN  UnRecon_Gl_Nbr  else Raw_Gl_nbr END as Gl_nbr, gl_nbrs.GL_DESCR,DebitRawAcct,
			UnrecDebit.Credit as Debit,
			UnrecDebit.Debit as Credit, 
			CAST('UNRECREC' as varchar(50)) as TransactionType, 
			CAST('PORecRelGl' as varchar(25)) as SourceTable,
			'UNIQRECREL' as cIdentifier,
			UnrecDebit.UNIQRECREL as cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			FY,Period,fk_fyDtlUniq
			FROM UnrecDebit inner join GL_NBRS on gl_nbrs.gl_nbr=CASE WHEN DebitRawAcct=1 THEN UnrecDebit.UnRecon_Gl_Nbr  ELSE UnrecDebit.RAW_GL_NBR END
		),
		--select * from UnrecCredit
		FinalUnrec as
		(
		
		SELECT cast(0 as bit) as lSelect,Trans_dt,GL_NBR,gl_descr,UNIQRECREL,
		DisplayValue,
		DebitRawAcct,
		TransactionType,SourceTable,
		cIdentifier,cDrill,
		SourceSubTable,
		cSubIdentifier,
		cSubDrill,
		Debit,
		Credit,
		Fy,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
		FROM UnrecDebit
		UNION ALL 
		SELECT cast(0 as bit) as lSelect,Trans_dt,GL_NBR,gl_descr,UNIQRECREL,
		DisplayValue, 
		DebitRawAcct,
		TransactionType,SourceTable,
		cIdentifier,cDrill,
		SourceSubTable,
		cSubIdentifier,
		cSubDrill,
		Debit,Credit,Fy,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
		FROM UnrecCredit)
	
	SELECT FinalUnrec.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY UNIQRECREL) as GroupIdNumber FROM FinalUnrec ORDER BY UNIQRECREL
	 
	END
ELSE
	BEGIN
	with UnrecDebit as
	(
	-- 06/04/2013 YS fix GL # description was showing unreconcile account description for the Raw account
	SELECT porecrelgl.TRANS_DATE as Trans_dt, DebitRawAcct,Raw_Gl_nbr,UnRecon_Gl_Nbr,Porecrelgl.UNIQRECREL,
			'Receiver Number: '+Porecloc.RECEIVERNO as DisplayValue,
			CASE WHEN DebitRawAcct=1 THEN PoRecRelGl.Raw_Gl_nbr ELSE PoRecRElGl.UnRecon_Gl_Nbr END as Gl_nbr, gl_nbrs.GL_DESCR,
			ABS(PORECRELGL.TOTALCOST) as Debit,
			CAST(0.00 as numeric(14,2)) as Credit, 
			CAST('UNRECREC' as varchar(50)) as TransactionType, 
			CAST('PORecRelGl' as varchar(25)) as SourceTable,
			'UNIQRECREL' as cIdentifier,
			PorecRelGl.UNIQRECREL as cDrill,
			CAST('PORecRelGl' as varchar(25)) as SourceSubTable,
			'UNIQRECREL' as cSubIdentifier,
			PorecRelGl.UNIQRECREL as cSubDrill,
			fy.FiscalYr as FY,fy.Period,fy.fyDtlUniq as fk_fyDtlUniq,
			-- 12/21/16 VL added functional and presentation currency fields
			ABS(PORECRELGL.TOTALCOSTPR) as DebitPR,
			CAST(0.00 as numeric(14,2)) as CreditPR, 
			FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
			Porecrelgl.FuncFcused_uniq, Porecrelgl.PrFcused_uniq  	 
		FROM  PoRecRelGl 
			INNER JOIN Fcused PF ON PoRecRelGl.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON PoRecRelGl.FuncFcused_uniq = FF.Fcused_uniq
		OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(TRANS_DATE as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
			INNER JOIN GL_NBRS on gl_nbrs.gl_nbr=CASE WHEN DEBITRAWACCT =1 THEN PoRecRelGl.Raw_Gl_nbr ELSE Porecrelgl.UNRECON_GL_NBR END 
			INNER JOIN PORECLOC on Porecrelgl.LOC_UNIQ = Porecloc.LOC_UNIQ 
			WHERE PORECRELGL.IS_REL_GL = 0 and TOTALCOST<>0.00
		),
		UnrecCredit as
		(
		-- 06/04/2013 YS fix GL # description was showing unreconcile account description for the Raw account
		SELECT UnrecDebit.Trans_dt, UNIQRECREL,
		 DisplayValue,
			CASE WHEN DebitRawAcct=1 THEN  UnRecon_Gl_Nbr  else Raw_Gl_nbr END as Gl_nbr, gl_nbrs.GL_DESCR,DebitRawAcct,
			UnrecDebit.Credit as Debit,
			UnrecDebit.Debit as Credit, 
			CAST('UNRECREC' as varchar(50)) as TransactionType, 
			CAST('PORecRelGl' as varchar(25)) as SourceTable,
			'UNIQRECREL' as cIdentifier,
			UnrecDebit.UNIQRECREL as cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			FY,Period,fk_fyDtlUniq,
			-- 12/21/16 VL added functional and presentation currency fields
			UnrecDebit.CreditPR as DebitPR,
			UnrecDebit.DebitPR as CreditPR,
			Functional_Currency,Presentation_Currency,
			FuncFcused_uniq, PrFcused_uniq   
			FROM UnrecDebit inner join GL_NBRS on gl_nbrs.gl_nbr=CASE WHEN DebitRawAcct=1 THEN UnrecDebit.UnRecon_Gl_Nbr  ELSE UnrecDebit.RAW_GL_NBR END
		),
		--select * from UnrecCredit
		FinalUnrec as
		(
		
		SELECT cast(0 as bit) as lSelect,Trans_dt,GL_NBR,gl_descr,UNIQRECREL,
		DisplayValue,
		DebitRawAcct,
		TransactionType,SourceTable,
		cIdentifier,cDrill,
		SourceSubTable,
		cSubIdentifier,
		cSubDrill,
		Debit,
		Credit,
		Fy,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/21/16 VL added functional and presentation currency fields
		DebitPR,
		CreditPR,
		Functional_Currency,Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq   
		FROM UnrecDebit
		UNION ALL 
		SELECT cast(0 as bit) as lSelect,Trans_dt,GL_NBR,gl_descr,UNIQRECREL,
		DisplayValue, 
		DebitRawAcct,
		TransactionType,SourceTable,
		cIdentifier,cDrill,
		SourceSubTable,
		cSubIdentifier,
		cSubDrill,
		Debit,Credit,Fy,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/21/16 VL added functional and presentation currency fields
		DebitPR,
		CreditPR,
		Functional_Currency,Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq   
		FROM UnrecCredit)
	
	SELECT FinalUnrec.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY UNIQRECREL) as GroupIdNumber FROM FinalUnrec ORDER BY UNIQRECREL
	 
	END	
END