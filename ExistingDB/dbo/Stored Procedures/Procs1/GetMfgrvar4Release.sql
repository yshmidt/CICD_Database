-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/31/2011
-- Description:	Get Mfgrvariance info for release
-- 10/16/15: added Currency field
-- 12/21/16 VL added functional and presentation currency fields and separate FC and non-FC
-- =============================================
CREATE PROCEDURE [dbo].[GetMfgrvar4Release]
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
	with MfgrVarDebit AS
	(
	SELECT mfgrvar.wono, mfgrvar.uniq_key, mfgrvar.man_gl_nbr,
	  mfgrvar.wip_gl_nbr,  mfgrvar.issuecost,
	  mfgrvar.bomcost, mfgrvar.totalvar,mfgrvar.uniqmfgvar,
	  mfgrvar.datetime AS Trans_dt,
	  CASE WHEN TotalVar>0 THEN TotalVar ELSE CAST(0.00 as numeric(14,2)) END as DEBIT,
	  CASE WHEN TotalVar>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(TotalVar) END as Credit,
	  Man_gl_nbr as Gl_Nbr,gl_nbrs.GL_DESCR,
	  CAST('MFGRVAR   ' as varchar(50)) as TransactionType, 
		CAST('mfgrvar' as varchar(25)) as SourceTable,
			'uniqmfgvar' as cIdentifier,
			mfgrvar.uniqmfgvar as cDrill,
		CAST('mfgrvar' as varchar(25)) as SourceSubTable,
			'uniqmfgvar' as cSubIdentifier,
			mfgrvar.uniqmfgvar as cSubDrill,	
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq
	  FROM  mfgrvar OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(mfgrvar.datetime as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
			INNER JOIN GL_NBRS ON Man_gl_nbr=Gl_nbrs.gl_nbr
		WHERE is_Rel_Gl=0 and TOTALVAR <>0.00
		and VARTYPE='MFGRV'
	),MfgrVarCredit AS
	(
	SELECT MfgrVarDebit.wono, MfgrVarDebit.uniq_key, MfgrVarDebit.man_gl_nbr,
	  MfgrVarDebit.wip_gl_nbr,  MfgrVarDebit.issuecost,
	  MfgrVarDebit.bomcost, MfgrVarDebit.totalvar,MfgrVarDebit.uniqmfgvar,
	  MfgrVarDebit.Trans_dt,
	  MfgrVarDebit.Credit as Debit,
	  MfgrVarDebit.DEBIT as Credit,
	  MfgrVarDebit.wip_gl_nbr as Gl_Nbr,gl_nbrs.GL_DESCR,
	  MfgrVarDebit.TransactionType, 
	  MfgrVarDebit.SourceTable,
	  MfgrVarDebit.cIdentifier,
	  MfgrVarDebit.cDrill ,
	  MfgrVarDebit.SourceSubTable,
	  MfgrVarDebit.cSubIdentifier,
	  MfgrVarDebit.cSubDrill ,
	  MfgrVarDebit.FY,MfgrVarDebit.Period ,MfgrVarDebit.fk_fyDtlUniq
	FROm MfgrVarDebit INNER JOIN GL_NBRS ON wip_gl_nbr=Gl_nbrs.Gl_nbr
	),
	FinalMfgrVar as
	(
	SELECT cast(0 as bit) as lSelect, MfgrVarDebit.wono, MfgrVarDebit.uniq_key,
		'Work Order: '+ MfgrVarDebit.wono+' '+CAST(trans_dt as CHAR(17)) as DisplayValue ,
		Trans_dt,DEBIT,Credit,MfgrVarDebit.GL_NBR,gl_nbrs.GL_DESCR,
		TransactionType,SourceTable,cIdentifier,cDrill,
		SourceSubTable,cSubIdentifier,cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
	 from MfgrVarDebit INNER JOIN GL_NBRS on MfgrVarDebit.Gl_Nbr=Gl_nbrs.GL_nbr
	 UNION ALL
	SELECT cast(0 as bit) as lSelect,wono,uniq_key,
		'Work Order: '+MfgrVarCredit.wono+' '+CAST(trans_dt as CHAR(17)) as DisplayValue ,
		Trans_dt,DEBIT,Credit,MfgrVarCredit.GL_NBR,gl_nbrs.GL_DESCR,
		TransactionType,SourceTable,cIdentifier,cDrill,
		SourceSubTable,cSubIdentifier,cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
	 from MfgrVarCredit INNER JOIN GL_NBRS on MfgrVarCredit.Gl_Nbr=Gl_nbrs.GL_nbr
	 )
	 SELECT FinalMfgrVar.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY WONO,Trans_dt) as GroupIdNumber FROM FinalMfgrVar ORDER BY WONO,Trans_dt 
	 
	END
ELSE
	BEGIN
	with MfgrVarDebit AS
	(
	SELECT mfgrvar.wono, mfgrvar.uniq_key, mfgrvar.man_gl_nbr,
	  mfgrvar.wip_gl_nbr,  mfgrvar.issuecost,
	  mfgrvar.bomcost, mfgrvar.totalvar,mfgrvar.uniqmfgvar,
	  mfgrvar.datetime AS Trans_dt,
	  CASE WHEN TotalVar>0 THEN TotalVar ELSE CAST(0.00 as numeric(14,2)) END as DEBIT,
	  CASE WHEN TotalVar>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(TotalVar) END as Credit,
	  Man_gl_nbr as Gl_Nbr,gl_nbrs.GL_DESCR,
	  CAST('MFGRVAR   ' as varchar(50)) as TransactionType, 
		CAST('mfgrvar' as varchar(25)) as SourceTable,
			'uniqmfgvar' as cIdentifier,
			mfgrvar.uniqmfgvar as cDrill,
		CAST('mfgrvar' as varchar(25)) as SourceSubTable,
			'uniqmfgvar' as cSubIdentifier,
			mfgrvar.uniqmfgvar as cSubDrill,	
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
		-- 12/21/16 VL added functional and presentation currency fields
		mfgrvar.issuecostPR, mfgrvar.bomcostPR, mfgrvar.totalvarPR,
		CASE WHEN TotalVarPR>0 THEN TotalVarPR ELSE CAST(0.00 as numeric(14,2)) END as DEBITPR,
		CASE WHEN TotalVarPR>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(TotalVarPR) END as CreditPR,
		FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
		Mfgrvar.FuncFcused_uniq, Mfgrvar.PrFcused_uniq  	
	  FROM  mfgrvar 
		INNER JOIN Fcused PF ON mfgrvar.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON mfgrvar.FuncFcused_uniq = FF.Fcused_uniq
	  OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(mfgrvar.datetime as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
			INNER JOIN GL_NBRS ON Man_gl_nbr=Gl_nbrs.gl_nbr
		WHERE is_Rel_Gl=0 and TOTALVAR <>0.00
		and VARTYPE='MFGRV'
	),MfgrVarCredit AS
	(
	SELECT MfgrVarDebit.wono, MfgrVarDebit.uniq_key, MfgrVarDebit.man_gl_nbr,
	  MfgrVarDebit.wip_gl_nbr,  MfgrVarDebit.issuecost,
	  MfgrVarDebit.bomcost, MfgrVarDebit.totalvar,MfgrVarDebit.uniqmfgvar,
	  MfgrVarDebit.Trans_dt,
	  MfgrVarDebit.Credit as Debit,
	  MfgrVarDebit.DEBIT as Credit,
	  MfgrVarDebit.wip_gl_nbr as Gl_Nbr,gl_nbrs.GL_DESCR,
	  MfgrVarDebit.TransactionType, 
	  MfgrVarDebit.SourceTable,
	  MfgrVarDebit.cIdentifier,
	  MfgrVarDebit.cDrill ,
	  MfgrVarDebit.SourceSubTable,
	  MfgrVarDebit.cSubIdentifier,
	  MfgrVarDebit.cSubDrill ,
	  MfgrVarDebit.FY,MfgrVarDebit.Period ,MfgrVarDebit.fk_fyDtlUniq,
	  -- 12/21/16 VL added functional and presentation currency fields
	  MfgrVarDebit.issuecostPR,
	  MfgrVarDebit.bomcostPR, MfgrVarDebit.totalvarPR,
	  MfgrVarDebit.CreditPR as DebitPR,
	  MfgrVarDebit.DEBITPR as CreditPR,
	  Functional_Currency, Presentation_Currency,
	  FuncFcused_uniq, PrFcused_uniq 
	FROm MfgrVarDebit INNER JOIN GL_NBRS ON wip_gl_nbr=Gl_nbrs.Gl_nbr
	),
	FinalMfgrVar as
	(
	SELECT cast(0 as bit) as lSelect, MfgrVarDebit.wono, MfgrVarDebit.uniq_key,
		'Work Order: '+ MfgrVarDebit.wono+' '+CAST(trans_dt as CHAR(17)) as DisplayValue ,
		Trans_dt,DEBIT,Credit,MfgrVarDebit.GL_NBR,gl_nbrs.GL_DESCR,
		TransactionType,SourceTable,cIdentifier,cDrill,
		SourceSubTable,cSubIdentifier,cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/21/16 VL added functional and presentation currency fields
		DEBITPR,CreditPR, Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq 
	 from MfgrVarDebit INNER JOIN GL_NBRS on MfgrVarDebit.Gl_Nbr=Gl_nbrs.GL_nbr
	 UNION ALL
	SELECT cast(0 as bit) as lSelect,wono,uniq_key,
		'Work Order: '+MfgrVarCredit.wono+' '+CAST(trans_dt as CHAR(17)) as DisplayValue ,
		Trans_dt,DEBIT,Credit,MfgrVarCredit.GL_NBR,gl_nbrs.GL_DESCR,
		TransactionType,SourceTable,cIdentifier,cDrill,
		SourceSubTable,cSubIdentifier,cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/21/16 VL added functional and presentation currency fields
		DEBITPR,CreditPR, Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq 
	 from MfgrVarCredit INNER JOIN GL_NBRS on MfgrVarCredit.Gl_Nbr=Gl_nbrs.GL_nbr
	 )
	 SELECT FinalMfgrVar.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY WONO,Trans_dt) as GroupIdNumber FROM FinalMfgrVar ORDER BY WONO,Trans_dt 
	
	END
END