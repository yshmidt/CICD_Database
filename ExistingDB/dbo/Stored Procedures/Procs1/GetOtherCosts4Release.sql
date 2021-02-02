-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/30/2011
-- Description:	Get Other cost variance information located in Confgvar table 
-- 10/16/15 VL added AtdUniq_key
-- 12/21/16 VL added functional and presentation currency fields and separate FC and non-FC
-- =============================================
CREATE PROCEDURE [dbo].[GetOtherCosts4Release]
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

	; WITH OtherCostCnfg as (
	SELECT Confgvar.wono, Confgvar.uniq_key, Confgvar.cnfg_gl_nb,
		CAST(RTRIM(VarType)+' Cost '+RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) as DisplayValue,
	  Confgvar.wip_gl_nbr, UniqConf,
	  CASE WHEN SIGN(Confgvar.Variance)=SIGN(Confgvar.StdCost-Confgvar.WipCost) THEN Confgvar.qtytransf ELSE -Confgvar.qtytransf end as qtytransf, 
	  Confgvar.stdcost, Confgvar.wipcost, Confgvar.variance, totalvar,
	  Confgvar.datetime as Trans_dt, 
	  Confgvar.invtxfer_n, Confgvar.transftble,
	 VarType, PoNum ,
	 cnfg_gl_nb as gl_nbr,gl_nbrs.GL_DESCR,
	 CASE WHEN totalvar > 0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(totalvar) END as Debit,
	 CASE WHEN totalvar > 0 THEN totalvar ELSE CAST(0.00 as numeric(14,2)) END as Credit ,
		CAST('INVTCOSTS' as varchar(50)) as TransactionType, 
		CAST('ConfgVar' as varchar(25)) as SourceTable,
		'UniqConf' as cIdentifier,
		ConfgVar.UNIQCONF  as cDrill,
		CAST('INVENTOR' as varchar(25)) as SourceSubTable,
		'Uniq_key' as cSubIdentifier,
		ConfgVar.UNIQ_KEY  as cSubDrill,
	 fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
	FROM  confgvar OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(Confgvar.datetime as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
			INNER JOIN GL_NBRS on cnfg_gl_nb=gl_nbrs.GL_NBR 
			INNER JOIN INVENTOR ON CONFGVAR.UNIQ_KEY =Inventor.UNIQ_KEY 
		WHERE is_Rel_Gl=0	
		and VarType <> 'CONFG' 
		),
		OTherCostWip AS
		(SELECT OtherCostCnfg.wono, OtherCostCnfg.uniq_key, OtherCostCnfg.cnfg_gl_nb,
		OtherCostCnfg.DisplayValue,
	  OtherCostCnfg.wip_gl_nbr, UniqConf,
	 OtherCostCnfg.qtytransf, 
	  OtherCostCnfg.stdcost, OtherCostCnfg.wipcost, OtherCostCnfg.variance, totalvar,
	  OtherCostCnfg.Trans_dt, 
	  OtherCostCnfg.invtxfer_n, OtherCostCnfg.transftble,
	 VarType, PoNum ,
	 wip_gl_nbr as gl_nbr,gl_nbrs.GL_DESCR ,
	 CASE WHEN totalvar > 0 THEN totalvar ELSE CAST(0.00 as numeric(14,2)) END as Debit ,
	 CASE WHEN totalvar > 0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(totalvar) END as Credit,
	 CAST('INVTCOSTS' as varchar(50)) as TransactionType, 
		CAST('ConfgVar' as varchar(25)) as SourceTable,
		'UniqConf' as cIdentifier,
		OtherCostCnfg.UNIQCONF  as cDrill,
		CAST('INVENTOR' as varchar(25)) as SourceSubTable,
		'Uniq_key' as cSubIdentifier,
		OtherCostCnfg.UNIQ_key  as cSubDrill,
		OtherCostCnfg.FY,OtherCostCnfg.Period ,OtherCostCnfg.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
	FROM  OtherCostCnfg
	INNER JOIN GL_NBRS on wip_gl_nbr=gl_nbrs.GL_NBR 
		),FinalOtherCost as
		(
		select cast(0 as bit) as lSelect,OtherCostCnfg.* from OtherCostCnfg
		UNION ALL
		SELECT cast(0 as bit) as lSelect,OTherCostWip.* FROM OTherCostWip)
	SELECT FinalOtherCost.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY Uniq_key) as GroupIdNumber FROM FinalOtherCost  ORDER BY UNIQ_KEY
	END
ELSE
	BEGIN
 
	; WITH OtherCostCnfg as (
	SELECT Confgvar.wono, Confgvar.uniq_key, Confgvar.cnfg_gl_nb,
		CAST(RTRIM(VarType)+' Cost '+RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) as DisplayValue,
	  Confgvar.wip_gl_nbr, UniqConf,
	  CASE WHEN SIGN(Confgvar.Variance)=SIGN(Confgvar.StdCost-Confgvar.WipCost) THEN Confgvar.qtytransf ELSE -Confgvar.qtytransf end as qtytransf, 
	  Confgvar.stdcost, Confgvar.wipcost, Confgvar.variance, totalvar,
	  Confgvar.datetime as Trans_dt, 
	  Confgvar.invtxfer_n, Confgvar.transftble,
	 VarType, PoNum ,
	 cnfg_gl_nb as gl_nbr,gl_nbrs.GL_DESCR,
	 CASE WHEN totalvar > 0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(totalvar) END as Debit,
	 CASE WHEN totalvar > 0 THEN totalvar ELSE CAST(0.00 as numeric(14,2)) END as Credit ,
		CAST('INVTCOSTS' as varchar(50)) as TransactionType, 
		CAST('ConfgVar' as varchar(25)) as SourceTable,
		'UniqConf' as cIdentifier,
		ConfgVar.UNIQCONF  as cDrill,
		CAST('INVENTOR' as varchar(25)) as SourceSubTable,
		'Uniq_key' as cSubIdentifier,
		ConfgVar.UNIQ_KEY  as cSubDrill,
	 fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
	 -- 12/21/16 VL added functional and presentation currency fields
	 Confgvar.stdcostPR, Confgvar.wipcostPR, Confgvar.variancePR, totalvarPR,
	 CASE WHEN totalvarPR > 0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(totalvarPR) END as DebitPR,
	 CASE WHEN totalvarPR > 0 THEN totalvarPR ELSE CAST(0.00 as numeric(14,2)) END as CreditPR,
	 FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
	 Confgvar.FuncFcused_uniq, Confgvar.PrFcused_uniq 
	FROM  confgvar 
		INNER JOIN Fcused PF ON confgvar.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON confgvar.FuncFcused_uniq = FF.Fcused_uniq
	OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(Confgvar.datetime as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
			INNER JOIN GL_NBRS on cnfg_gl_nb=gl_nbrs.GL_NBR 
			INNER JOIN INVENTOR ON CONFGVAR.UNIQ_KEY =Inventor.UNIQ_KEY 
		WHERE is_Rel_Gl=0	
		and VarType <> 'CONFG' 
		),
		OTherCostWip AS
		(SELECT OtherCostCnfg.wono, OtherCostCnfg.uniq_key, OtherCostCnfg.cnfg_gl_nb,
		OtherCostCnfg.DisplayValue,
	  OtherCostCnfg.wip_gl_nbr, UniqConf,
	 OtherCostCnfg.qtytransf, 
	  OtherCostCnfg.stdcost, OtherCostCnfg.wipcost, OtherCostCnfg.variance, totalvar,
	  OtherCostCnfg.Trans_dt, 
	  OtherCostCnfg.invtxfer_n, OtherCostCnfg.transftble,
	 VarType, PoNum ,
	 wip_gl_nbr as gl_nbr,gl_nbrs.GL_DESCR ,
	 CASE WHEN totalvar > 0 THEN totalvar ELSE CAST(0.00 as numeric(14,2)) END as Debit ,
	 CASE WHEN totalvar > 0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(totalvar) END as Credit,
	 CAST('INVTCOSTS' as varchar(50)) as TransactionType, 
		CAST('ConfgVar' as varchar(25)) as SourceTable,
		'UniqConf' as cIdentifier,
		OtherCostCnfg.UNIQCONF  as cDrill,
		CAST('INVENTOR' as varchar(25)) as SourceSubTable,
		'Uniq_key' as cSubIdentifier,
		OtherCostCnfg.UNIQ_key  as cSubDrill,
		OtherCostCnfg.FY,OtherCostCnfg.Period ,OtherCostCnfg.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/21/16 VL added functional and presentation currency fields
		OtherCostCnfg.stdcostPR, OtherCostCnfg.wipcostPR, OtherCostCnfg.variancePR, totalvarPR,
	 CASE WHEN totalvarPR > 0 THEN totalvarPR ELSE CAST(0.00 as numeric(14,2)) END as DebitPR ,
	 CASE WHEN totalvarPR > 0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(totalvarPR) END as CreditPR,
	Functional_Currency, Presentation_Currency,
	FuncFcused_uniq, PrFcused_uniq 
	FROM  OtherCostCnfg
	INNER JOIN GL_NBRS on wip_gl_nbr=gl_nbrs.GL_NBR 
		),FinalOtherCost as
		(
		select cast(0 as bit) as lSelect,OtherCostCnfg.* from OtherCostCnfg
		UNION ALL
		SELECT cast(0 as bit) as lSelect,OTherCostWip.* FROM OTherCostWip)
	SELECT FinalOtherCost.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY Uniq_key) as GroupIdNumber FROM FinalOtherCost  ORDER BY UNIQ_KEY
	END	
END