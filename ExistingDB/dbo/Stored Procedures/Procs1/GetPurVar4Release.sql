-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/01/2011
-- Description:	Get Purchase variance info for release
-- 10/16/15 VL added AtdUniq_key
-- 12/21/16 VL added functional and presentation currency fields and separate FC and non-FC
-- =============================================
CREATE PROCEDURE [dbo].[GetPurVar4Release]
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
		with PurVarDebit AS
		(
		SELECT  Pur_Var.Trans_Dt,
				Variance ,
				'Receiver No: '+Sinvoice.receiverno as DisplayValue,
				CAST('PURVAR' as varchar(50)) as TransactionType, 
				CAST('pur_var' as varchar(25)) as SourceTable,
					'var_key' as cIdentifier,
					pur_var.var_key as cDrill,
				CAST('Sinvoice' as varchar(25)) as SourceSubTable,
					'sinv_uniq' as cSubIdentifier,
					sinvoice.SINV_UNIQ as cSubDrill,
					pur_var.GL_NBR,pur_var.GL_NBR_VAR,
					CASE when Pur_Var.Variance > 0 THEN Pur_Var.Variance ELSE CAST(0.00 as numeric(14,2)) END as Debit, 
					CASE when  Pur_Var.Variance > 0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(Pur_Var.Variance) END as Credit, 
					fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq
			FROM Pur_Var OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
					WHERE CAST(pur_var.trans_dt as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
					INNER JOIN sinvdetl ON
			pur_var.SDET_UNIQ = sinvdetl.SDET_UNIQ
			inner join SINVOICE on sinvoice.SINV_UNIQ =sinvdetl.SINV_UNIQ 
			WHERE Pur_Var.is_Rel_Gl =0
				AND Variance <> 0 
		),
		PurVarCredit AS
		(
			SELECT  Trans_Dt,
				Variance ,
				PurVarDebit.DisplayValue,
				transactionType, 
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR_VAR as Gl_nbr,gl_nbrs.GL_DESCR,
				Credit as Debit, 
				Debit as Credit, 
				FY,Period ,fk_fyDtlUniq
				FROM PurVarDebit inner join GL_NBRS on PurVarDebit.GL_NBR_VAR = gl_nbrs.GL_NBR  
		), FinalPurVar AS
		(
		SELECT  cast(0 as bit) as lSelect,Trans_Dt,
				Variance ,
				PurVarDebit.DisplayValue,
				transactionType, 
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				PurVarDebit.Gl_nbr,gl_nbrs.GL_DESCR ,
				Debit, 
				Credit, 
				FY,Period ,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
				FROM PurVarDebit inner join GL_NBRS on PurVarDebit.GL_NBR = gl_nbrs.GL_NBR  
			UNION ALL
		SELECT  cast(0 as bit) as lSelect,Trans_Dt,
				Variance ,
				PurVarCredit.DisplayValue,
				transactionType, 
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				PurVarCredit.Gl_nbr,GL_DESCR , 
				Debit, 
				Credit, 
				FY,Period ,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
				FROM PurVarCredit)

	SELECT FinalPurVar.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalPurVar ORDER BY cDrill 
	END
ELSE
	BEGIN
		with PurVarDebit AS
		(
		SELECT  Pur_Var.Trans_Dt,
				Variance ,
				'Receiver No: '+Sinvoice.receiverno as DisplayValue,
				CAST('PURVAR' as varchar(50)) as TransactionType, 
				CAST('pur_var' as varchar(25)) as SourceTable,
					'var_key' as cIdentifier,
					pur_var.var_key as cDrill,
				CAST('Sinvoice' as varchar(25)) as SourceSubTable,
					'sinv_uniq' as cSubIdentifier,
					sinvoice.SINV_UNIQ as cSubDrill,
					pur_var.GL_NBR,pur_var.GL_NBR_VAR,
					CASE when Pur_Var.Variance > 0 THEN Pur_Var.Variance ELSE CAST(0.00 as numeric(14,2)) END as Debit, 
					CASE when  Pur_Var.Variance > 0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(Pur_Var.Variance) END as Credit, 
					fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
				-- 12/21/16 VL added functional and presentation currency fields
				VariancePR,
				CASE when Pur_Var.VariancePR > 0 THEN Pur_Var.VariancePR ELSE CAST(0.00 as numeric(14,2)) END as DebitPR, 
				CASE when  Pur_Var.VariancePR > 0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(Pur_Var.VariancePR) END as CreditPR, 
				FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
				Pur_var.FuncFcused_uniq, Pur_var.PrFcused_uniq  	
			FROM Pur_Var 
				INNER JOIN Fcused PF ON Pur_Var.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON Pur_Var.FuncFcused_uniq = FF.Fcused_uniq
			OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
					WHERE CAST(pur_var.trans_dt as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
					INNER JOIN sinvdetl ON
			pur_var.SDET_UNIQ = sinvdetl.SDET_UNIQ
			inner join SINVOICE on sinvoice.SINV_UNIQ =sinvdetl.SINV_UNIQ 
			WHERE Pur_Var.is_Rel_Gl =0
				AND Variance <> 0 
		),
		PurVarCredit AS
		(
			SELECT  Trans_Dt,
				Variance ,
				PurVarDebit.DisplayValue,
				transactionType, 
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR_VAR as Gl_nbr,gl_nbrs.GL_DESCR,
				Credit as Debit, 
				Debit as Credit, 
				FY,Period ,fk_fyDtlUniq,
				-- 12/21/16 VL added functional and presentation currency fields
				CreditPR as DebitPR, 
				DebitPR as CreditPR, 
				Functional_Currency, Presentation_Currency,
				FuncFcused_uniq, PrFcused_uniq 
				FROM PurVarDebit inner join GL_NBRS on PurVarDebit.GL_NBR_VAR = gl_nbrs.GL_NBR  
		), FinalPurVar AS
		(
		SELECT  cast(0 as bit) as lSelect,Trans_Dt,
				Variance ,
				PurVarDebit.DisplayValue,
				transactionType, 
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				PurVarDebit.Gl_nbr,gl_nbrs.GL_DESCR ,
				Debit, 
				Credit, 
				FY,Period ,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
				-- 12/21/16 VL added functional and presentation currency fields
				DebitPR, 
				CreditPR, 
				Functional_Currency, Presentation_Currency,
				FuncFcused_uniq, PrFcused_uniq 
				FROM PurVarDebit inner join GL_NBRS on PurVarDebit.GL_NBR = gl_nbrs.GL_NBR  
			UNION ALL
		SELECT  cast(0 as bit) as lSelect,Trans_Dt,
				Variance ,
				PurVarCredit.DisplayValue,
				transactionType, 
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				PurVarCredit.Gl_nbr,GL_DESCR , 
				Debit, 
				Credit, 
				FY,Period ,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
				-- 12/21/16 VL added functional and presentation currency fields
				DebitPR, 
				CreditPR, 
				Functional_Currency, Presentation_Currency,
				FuncFcused_uniq, PrFcused_uniq 
				FROM PurVarCredit)

	SELECT FinalPurVar.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalPurVar ORDER BY cDrill 
	END
END