-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/29/2011
-- Description:	Gat Cost Adjustment Information for GL release
-- Modified:	
-- 10/07/2013 YS wrong gl number need to use StdCostAdjGlNo, instead was using IADJ_GL_NO
-- 10/16/2015 VL added AtdUniq_key
-- 12/15/2016 VL added functional and presentation currency fields, also added code to separate FC and non FC
-- 05/11/17 VL Added code for the standard cost exchange rate adjustment (UPDTSTD.Is_ERAdj=1)
-- =============================================
CREATE PROCEDURE [dbo].[GetCostAdj4Release]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
  --  Declare @T TABLE (FiscalYr char(4),fk_fy_uniq char(10),Period Numeric(2,0),StartDate smalldatetime,EndDate smallDateTime,
		--fyDtlUniq uniqueidentifier)
    DECLARE @T AS dbo.AllFYPeriods 
    insert into @T EXEC GlFyrstartEndView	;
-- 12/15/16 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
	BEGIN    

    ;WITH CostAdjDebit
    AS
    (
	SELECT UpDtDate as Trans_Dt,UPDTSTD.UNIQ_KEY,
		UPDTSTD.UNIQ_UPDT,UPDTSTD.UniqWh,UPDTSTD.WH_GL_NBR,
		CAST('COSTADJ' as varchar(50)) as TransactionType, 
		CAST('UPDTSTD' as varchar(25)) as SourceTable,
		'UNIQ_UPDT' as cIdentifier,
		UPDTSTD.UNIQ_UPDT as cDrill,
		CAST('INVENTOR' as varchar(25)) as SourceSubTable,
		'UNIQ_KEY' as cSubIdentifier,
		UPDTSTD.UNIQ_KEY as cSubDrill,
		UPDTSTD.WH_GL_NBR AS GL_NBR,gl_nbrs.GL_DESCR, 
		CASE WHEN UpdtStd.Changeamt > 0.00 THEN CAST(ChangeAmt AS numeric(14,2)) ELSE CAST(0.0 as numeric(14,2)) END as Debit, 
		CASE WHEN UpdtStd.CHANGEAMT <0.00 THEN CAST(ABS(ChangeAmt) as Numeric(14,2)) ELSE CAST(0.0 as numeric(14,2)) END as Credit,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fydtluniq, SPACE(10) AS AtdUniq_Key
		FROM UpdtStd OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq  FROM @T as T 
		WHERE CAST(UPDTSTD.UpDtDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN GL_NBRS on Updtstd.WH_GL_NBR = gl_nbrs.gl_nbr
		WHERE UpDtStd.IS_rel_gl = 0
	),
	CostAdjCeridt
	AS
	(
	--10/07/13 YS wrong gl number need to use StdCostAdjGlNo, instead was using IADJ_GL_NO
	SELECT CostAdjDebit.Trans_Dt,CostAdjDebit.UNIQ_KEY,
		CostAdjDebit.UNIQ_UPDT,CostAdjDebit.UniqWh,CostAdjDebit.WH_GL_NBR,
		CAST('COSTADJ' as varchar(50)) as TransactionType, 
		CAST('UPDTSTD' as varchar(25)) as SourceTable,
		'UNIQ_UPDT' as cIdentifier,
		CostAdjDebit.UNIQ_UPDT as cDrill,
		CAST('INVENTOR' as varchar(25)) as SourceSubTable,
		'UNIQ_KEY' as cSubIdentifier,
		CostAdjDebit.UNIQ_KEY as cSubDrill,
		InvSetup.StdCostAdjGlNo  AS GL_NBR,gl_nbrs.GL_DESCR,
		CostAdjDebit.Credit as Debit, 
		CostAdjDebit.Debit as Credit,
		CostAdjDebit.FY,CostAdjDebit.Period ,CostAdjDebit.fk_fydtluniq, SPACE(10) AS AtdUniq_key
		FROM CostAdjDebit CROSS APPLY InvSetup
		INNER JOIN GL_NBRS on InvSetup.StdCostAdjGlNo = gl_nbrs.gl_nbr
		
	),FinalCostAdj as
	(	
	SELECT cast(0 as bit) as lSelect,CostAdjDebit.*,CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) as DisplayValue FROM CostAdjDebit INNER JOIN INVENTOR on CostAdjDebit.UNIQ_KEY =Inventor.UNIQ_KEY  
		UNION ALL
	SELECT cast(0 as bit) as lSelect,CostAdjCeridt.*,cast(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) as DisplayValue FROM CostAdjCeridt INNER JOIN INVENTOR on CostAdjCeridt.UNIQ_KEY = Inventor.UNIQ_KEY 	)
	SELECT FinalCostAdj.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalCostAdj ORDER BY cDrill
	END
ELSE
	BEGIN
   ;WITH CostAdjDebit
    AS
    (
	-- 05/11/17 VL I am not going to change CostAdjDebit part for UPDTSTD.Is_ERAdj, this part get GL numbers directly from UPDTSTD table, will change CostAdjCeridt to have different GL number, just add Is_ERadj that will be use later
	SELECT UpDtDate as Trans_Dt,UPDTSTD.UNIQ_KEY,
		UPDTSTD.UNIQ_UPDT,UPDTSTD.UniqWh,UPDTSTD.WH_GL_NBR,
		CAST('COSTADJ' as varchar(50)) as TransactionType, 
		CAST('UPDTSTD' as varchar(25)) as SourceTable,
		'UNIQ_UPDT' as cIdentifier,
		UPDTSTD.UNIQ_UPDT as cDrill,
		CAST('INVENTOR' as varchar(25)) as SourceSubTable,
		'UNIQ_KEY' as cSubIdentifier,
		UPDTSTD.UNIQ_KEY as cSubDrill,
		UPDTSTD.WH_GL_NBR AS GL_NBR,gl_nbrs.GL_DESCR, 
		CASE WHEN UpdtStd.Changeamt > 0.00 THEN CAST(ChangeAmt AS numeric(14,2)) ELSE CAST(0.0 as numeric(14,2)) END as Debit, 
		CASE WHEN UpdtStd.CHANGEAMT <0.00 THEN CAST(ABS(ChangeAmt) as Numeric(14,2)) ELSE CAST(0.0 as numeric(14,2)) END as Credit,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fydtluniq, SPACE(10) AS AtdUniq_Key,
		-- 12/15/16 VL added functional and presentation currency fields
		CASE WHEN UpdtStd.ChangeamtPR > 0.00 THEN CAST(ChangeAmtPR AS numeric(14,2)) ELSE CAST(0.0 as numeric(14,2)) END as DebitPR, 
		CASE WHEN UpdtStd.CHANGEAMTPR <0.00 THEN CAST(ABS(ChangeAmtPR) as Numeric(14,2)) ELSE CAST(0.0 as numeric(14,2)) END as CreditPR,
		FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq,
		Is_ERAdj
		FROM UpdtStd 
			INNER JOIN Fcused PF ON UpdtStd.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON UpdtStd.FuncFcused_uniq = FF.Fcused_uniq
		OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq  FROM @T as T 
		WHERE CAST(UPDTSTD.UpDtDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN GL_NBRS on Updtstd.WH_GL_NBR = gl_nbrs.gl_nbr
		WHERE UpDtStd.IS_rel_gl = 0
	),
	CostAdjCeridt
	AS
	(
	--10/07/13 YS wrong gl number need to use StdCostAdjGlNo, instead was using IADJ_GL_NO
	-- 05/11/17 VL If the records are from costroll (Is_ErAdj = 0), use InvSetup.StdCostAdjGlNo, if the records are from standard cost exchange rate adjustmnet (Is_ErAdj = 1), then use InvSetup,StdCostERAdjGlNo
	SELECT CostAdjDebit.Trans_Dt,CostAdjDebit.UNIQ_KEY,
		CostAdjDebit.UNIQ_UPDT,CostAdjDebit.UniqWh,CostAdjDebit.WH_GL_NBR,
		CAST('COSTADJ' as varchar(50)) as TransactionType, 
		CAST('UPDTSTD' as varchar(25)) as SourceTable,
		'UNIQ_UPDT' as cIdentifier,
		CostAdjDebit.UNIQ_UPDT as cDrill,
		CAST('INVENTOR' as varchar(25)) as SourceSubTable,
		'UNIQ_KEY' as cSubIdentifier,
		CostAdjDebit.UNIQ_KEY as cSubDrill,
		InvSetup.StdCostAdjGlNo  AS GL_NBR,
		gl_nbrs.GL_DESCR,
		CostAdjDebit.Credit as Debit, 
		CostAdjDebit.Debit as Credit,
		CostAdjDebit.FY,CostAdjDebit.Period ,CostAdjDebit.fk_fydtluniq, SPACE(10) AS AtdUniq_key,
		-- 12/15/16 VL added functional and presentation currency fields
		CostAdjDebit.CreditPR as DebitPR, 
		CostAdjDebit.DebitPR as CreditPR,
		Functional_Currency,Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq,
		Is_ERAdj
		FROM CostAdjDebit CROSS APPLY InvSetup
		INNER JOIN GL_NBRS on InvSetup.StdCostAdjGlNo = gl_nbrs.gl_nbr
		-- 05/11/17 VL added Is_ERAdj = 0
		WHERE Is_ERAdj = 0
	-- 05/11/17 VL added for standard cost exchange rate adjustment
	UNION ALL 
	SELECT CostAdjDebit.Trans_Dt,CostAdjDebit.UNIQ_KEY,
		CostAdjDebit.UNIQ_UPDT,CostAdjDebit.UniqWh,CostAdjDebit.WH_GL_NBR,
		CAST('COSTADJ' as varchar(50)) as TransactionType, 
		CAST('UPDTSTD' as varchar(25)) as SourceTable,
		'UNIQ_UPDT' as cIdentifier,
		CostAdjDebit.UNIQ_UPDT as cDrill,
		CAST('INVENTOR' as varchar(25)) as SourceSubTable,
		'UNIQ_KEY' as cSubIdentifier,
		CostAdjDebit.UNIQ_KEY as cSubDrill,
		InvSetup.StdCostERAdjGlNo AS Gl_NBR,
		gl_nbrs.GL_DESCR,
		CostAdjDebit.Credit as Debit, 
		CostAdjDebit.Debit as Credit,
		CostAdjDebit.FY,CostAdjDebit.Period ,CostAdjDebit.fk_fydtluniq, SPACE(10) AS AtdUniq_key,
		-- 12/15/16 VL added functional and presentation currency fields
		CostAdjDebit.CreditPR as DebitPR, 
		CostAdjDebit.DebitPR as CreditPR,
		Functional_Currency,Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq,
		IS_ERAdj 
		FROM CostAdjDebit CROSS APPLY InvSetup
		INNER JOIN GL_NBRS on InvSetup.StdCostERAdjGlNo = gl_nbrs.gl_nbr
		-- 05/11/17 VL added Is_ERAdj = 0
		WHERE Is_ERAdj = 1

	),FinalCostAdj as
	(	
	SELECT cast(0 as bit) as lSelect,CostAdjDebit.*,CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) as DisplayValue FROM CostAdjDebit INNER JOIN INVENTOR on CostAdjDebit.UNIQ_KEY =Inventor.UNIQ_KEY  
		UNION ALL
	SELECT cast(0 as bit) as lSelect,CostAdjCeridt.*,cast(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) as DisplayValue FROM CostAdjCeridt INNER JOIN INVENTOR on CostAdjCeridt.UNIQ_KEY = Inventor.UNIQ_KEY 	)
	SELECT FinalCostAdj.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalCostAdj ORDER BY cDrill
	END
END