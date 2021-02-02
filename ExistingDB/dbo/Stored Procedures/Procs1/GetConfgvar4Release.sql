-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/28/11
-- Description:	Get CongVar info for release
-- 06/22/15 YS use   dbo.AllFYPeriods
-- 10/16/15 VL added AtdUniq_key
-- 12/15/16 VL added functional and presentation currency fields, also added code to separate FC and non FC
-- =============================================
CREATE PROCEDURE [dbo].[GetConfgvar4Release]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
  -- 06/22/15 YS use   dbo.AllFYPeriods
  --  Declare @T TABLE (FiscalYr char(4),fk_fy_uniq char(10),Period Numeric(2,0),StartDate smalldatetime,EndDate smallDateTime,
		--fyDtlUniq uniqueidentifier)
	
	DECLARE @T as dbo.AllFYPeriods

    insert into @T EXEC GlFyrstartEndView	;

-- 12/15/16 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
	BEGIN    

    ;WITH ConfgCredit AS
    (
	SELECT Confgvar.wono, Confgvar.uniq_key, Confgvar.cnfg_gl_nb,
		Confgvar.wip_gl_nbr, VarType,ConfgVar.UNIQCONF ,
		CASE WHEN SIGN(Confgvar.Variance)=SIGN(Confgvar.StdCost-Confgvar.WipCost) 
			THEN Confgvar.qtytransf
			ELSE -Confgvar.qtytransf END as QtyTransf, 
		Confgvar.stdcost, Confgvar.wipcost, Confgvar.variance, totalvar,
		Confgvar.datetime as Trans_dt, 
		Confgvar.invtxfer_n, Confgvar.transftble,
		CAST('CONFGVAR' as varchar(50)) as TransactionType, 
		CAST('CONFGVAR' as varchar(25)) as SourceTable,
		'UniqConf' as cIdentifier,
		ConfgVar.UNIQCONF as cDrill,
		CAST('CONFGVAR' as varchar(25)) as SourceSubTable,
		'UniqConf' as cSubIdentifier,
		ConfgVar.UNIQCONF as cSubDrill,
		Cnfg_gl_nb as Gl_Nbr,gl_nbrs.GL_DESCR ,
		CASE WHEN TOTALVAR >0 THEN CAST(ROUND(TotalVar,2) as Numeric(14,2)) ELSE CAST(0.0 as Numeric(14,2)) END AS Credit,
		CASE WHEN TOTALVAR <0 THEN CAST(ABS(ROUND(TotalVar,2)) as Numeric(14,2)) ELSE CAST(0.0 as Numeric(14,2)) END AS Debit,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
	FROM  confgvar OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(Confgvar.datetime as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN GL_NBRS on confgvar.Cnfg_gl_nb=gl_nbrs.gl_nbr
	WHERE is_Rel_Gl=0 
	AND VarType = 'CONFG'
	),
	ConfgDebit AS
	(
	SELECT ConfgCredit.wono, ConfgCredit.uniq_key, ConfgCredit.cnfg_gl_nb,
		ConfgCredit.wip_gl_nbr, VarType,ConfgCredit.UNIQCONF ,
		ConfgCredit.QtyTransf, 
		ConfgCredit.stdcost, ConfgCredit.wipcost, ConfgCredit.variance, ConfgCredit.totalvar,
		ConfgCredit.Trans_dt, 
		ConfgCredit.invtxfer_n, ConfgCredit.transftble,
		CAST('CONFGVAR' as varchar(50)) as TransactionType, 
		CAST('CONFGVAR' as varchar(25)) as SourceTable,
		'UniqConf' as cIdentifier,
		ConfgCredit.UNIQCONF as cDrill,
		CAST('CONFGVAR' as varchar(25)) as SourceSubTable,
		'UniqConf' as cSubIdentifier,
		ConfgCredit.UNIQCONF as cSubDrill,
		ConfgCredit.wip_gl_nbr as Gl_Nbr,gl_nbrs.GL_DESCR,
		CASE WHEN TOTALVAR <0 THEN CAST(ABS(ROUND(TotalVar,2)) as Numeric(14,2)) ELSE CAST(0.0 as Numeric(14,2)) END AS Credit,
		CASE WHEN TOTALVAR >0 THEN CAST(ROUND(TotalVar,2) as Numeric(14,2)) ELSE CAST(0.0 as Numeric(14,2)) END AS Debit,
		ConfgCredit.FY,ConfgCredit.Period ,ConfgCredit.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
		FROM ConfgCredit INNER JOIN GL_NBRS on ConfgCredit.wip_gl_nbr=gl_nbrs.gl_nbr
	),FinalCnfg as 
	(
	SELECT cast(0 as bit) as lSelect,ConfgDebit.*,'Work Order: '+ConfgDebit.wono+' '+CAST(trans_dt as CHAR(17)) as DisplayValue FROM ConfgDebit
	UNION ALL
	SELECT cast(0 as bit) as lSelect,ConfgCredit.*,'Work Order: '+ConfgCredit.wono+' '+CAST(trans_dt as CHAR(17)) as DisplayValue FROM ConfgCredit)
	SELECT FinalCnfg.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY wono,trans_dt) as GroupIdNumber FROM FinalCnfg ORDER BY WONO,trans_dt
	END
ELSE
-- 12/15/16 VL added for FC that will add presentation currency fields
	BEGIN
    ;WITH ConfgCredit AS
    (
	SELECT Confgvar.wono, Confgvar.uniq_key, Confgvar.cnfg_gl_nb,
		Confgvar.wip_gl_nbr, VarType,ConfgVar.UNIQCONF ,
		CASE WHEN SIGN(Confgvar.Variance)=SIGN(Confgvar.StdCost-Confgvar.WipCost) 
			THEN Confgvar.qtytransf
			ELSE -Confgvar.qtytransf END as QtyTransf, 
		Confgvar.stdcost, Confgvar.wipcost, Confgvar.variance, totalvar,
		Confgvar.datetime as Trans_dt, 
		Confgvar.invtxfer_n, Confgvar.transftble,
		CAST('CONFGVAR' as varchar(50)) as TransactionType, 
		CAST('CONFGVAR' as varchar(25)) as SourceTable,
		'UniqConf' as cIdentifier,
		ConfgVar.UNIQCONF as cDrill,
		CAST('CONFGVAR' as varchar(25)) as SourceSubTable,
		'UniqConf' as cSubIdentifier,
		ConfgVar.UNIQCONF as cSubDrill,
		Cnfg_gl_nb as Gl_Nbr,gl_nbrs.GL_DESCR ,
		CASE WHEN TOTALVAR >0 THEN CAST(ROUND(TotalVar,2) as Numeric(14,2)) ELSE CAST(0.0 as Numeric(14,2)) END AS Credit,
		CASE WHEN TOTALVAR <0 THEN CAST(ABS(ROUND(TotalVar,2)) as Numeric(14,2)) ELSE CAST(0.0 as Numeric(14,2)) END AS Debit,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/15/16 VL added functional and presentation currency fields
		Confgvar.stdcostPR, Confgvar.wipcostPR, Confgvar.variancePR, totalvarPR,
		CASE WHEN TOTALVARPR >0 THEN CAST(ROUND(TotalVarPR,2) as Numeric(14,2)) ELSE CAST(0.0 as Numeric(14,2)) END AS CreditPR,
		CASE WHEN TOTALVARPR <0 THEN CAST(ABS(ROUND(TotalVarPR,2)) as Numeric(14,2)) ELSE CAST(0.0 as Numeric(14,2)) END AS DebitPR,
		FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
		Confgvar.FuncFcused_uniq, Confgvar.PrFcused_uniq 
	FROM  confgvar 
	  	INNER JOIN Fcused PF ON confgvar.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON confgvar.FuncFcused_uniq = FF.Fcused_uniq
	OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(Confgvar.datetime as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN GL_NBRS on confgvar.Cnfg_gl_nb=gl_nbrs.gl_nbr
	WHERE is_Rel_Gl=0 
	AND VarType = 'CONFG'
	),
	ConfgDebit AS
	(
	SELECT ConfgCredit.wono, ConfgCredit.uniq_key, ConfgCredit.cnfg_gl_nb,
		ConfgCredit.wip_gl_nbr, VarType,ConfgCredit.UNIQCONF ,
		ConfgCredit.QtyTransf, 
		ConfgCredit.stdcost, ConfgCredit.wipcost, ConfgCredit.variance, ConfgCredit.totalvar,
		ConfgCredit.Trans_dt, 
		ConfgCredit.invtxfer_n, ConfgCredit.transftble,
		CAST('CONFGVAR' as varchar(50)) as TransactionType, 
		CAST('CONFGVAR' as varchar(25)) as SourceTable,
		'UniqConf' as cIdentifier,
		ConfgCredit.UNIQCONF as cDrill,
		CAST('CONFGVAR' as varchar(25)) as SourceSubTable,
		'UniqConf' as cSubIdentifier,
		ConfgCredit.UNIQCONF as cSubDrill,
		ConfgCredit.wip_gl_nbr as Gl_Nbr,gl_nbrs.GL_DESCR,
		CASE WHEN TOTALVAR <0 THEN CAST(ABS(ROUND(TotalVar,2)) as Numeric(14,2)) ELSE CAST(0.0 as Numeric(14,2)) END AS Credit,
		CASE WHEN TOTALVAR >0 THEN CAST(ROUND(TotalVar,2) as Numeric(14,2)) ELSE CAST(0.0 as Numeric(14,2)) END AS Debit,
		ConfgCredit.FY,ConfgCredit.Period ,ConfgCredit.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/15/16 VL added functional and presentation currency fields
		ConfgCredit.stdcostPR, ConfgCredit.wipcostPR, ConfgCredit.variancePR, totalvarPR,
		CASE WHEN TOTALVARPR <0 THEN CAST(ABS(ROUND(TotalVarPR,2)) as Numeric(14,2)) ELSE CAST(0.0 as Numeric(14,2)) END AS CreditPR,
		CASE WHEN TOTALVARPR >0 THEN CAST(ROUND(TotalVarPR,2) as Numeric(14,2)) ELSE CAST(0.0 as Numeric(14,2)) END AS DebitPR,
		Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM ConfgCredit 
		INNER JOIN GL_NBRS on ConfgCredit.wip_gl_nbr=gl_nbrs.gl_nbr
	),FinalCnfg as 
	(
	SELECT cast(0 as bit) as lSelect,ConfgDebit.*,'Work Order: '+ConfgDebit.wono+' '+CAST(trans_dt as CHAR(17)) as DisplayValue FROM ConfgDebit
	UNION ALL
	SELECT cast(0 as bit) as lSelect,ConfgCredit.*,'Work Order: '+ConfgCredit.wono+' '+CAST(trans_dt as CHAR(17)) as DisplayValue FROM ConfgCredit)
	SELECT FinalCnfg.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY wono,trans_dt) as GroupIdNumber FROM FinalCnfg ORDER BY WONO,trans_dt
	END
END