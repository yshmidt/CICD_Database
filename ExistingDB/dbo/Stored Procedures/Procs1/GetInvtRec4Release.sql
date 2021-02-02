-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/31/2011
-- Description:	Get Invt Rec information for release
--				10/16/2015 VL added AtdUniq_key
--				06/22/2016 VL added ROUND(,2) to the WHERE clause AND QtyRec * Invt_rec.StdCost<>0, so the value < 0.01 won't show
--				12/21/16 VL added functional and presentation currency fields and separate FC and non-FC
-- =============================================
CREATE PROCEDURE [dbo].[GetInvtRec4Release]
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
	WITH InvtRecDebit as
	(
	SELECT Invt_rec.DAte as Trans_Dt, 
		QtyRec ,Invt_rec.UNIQ_KEY,Invt_rec.W_KEY,CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) as DisplayValue,
		ROUND(QtyRec * Invt_Rec.StdCost,2) AS nTransAmount, 
		CASE WHEN ROUND(QtyRec * Invt_rec.StdCost,2)>0 THEN ROUND(QtyRec * Invt_rec.StdCost,2) ELSE CAST(0.00 as numeric(14,2)) END as Debit,
		CASE WHEN ROUND(QtyRec * Invt_Rec.StdCost,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(QtyRec * Invt_Rec.StdCost,2)) END as Credit,
		CAST('INVTREC' as varchar(50)) as TransactionType, 
		CAST('Invt_rec' as varchar(25)) as SourceTable,
		'InvtRec_No' as cIdentifier,
		Invt_rec.InvtRec_No as cDrill,
		CAST('Inventor' as varchar(25)) as SourceSubTable,
		'UNIQ_KEY' as cSubIdentifier,
		Invt_rec.Uniq_key as cSubDrill,
		Invt_rec.GL_NBR as CR_GL_NBR, Invt_rec.GL_NBR_INV as GL_NBR ,gl_nbrs.GL_DESCR,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq
		FROM Invt_rec INNER JOIN INVENTOR ON Invt_rec.UNIQ_KEY =Inventor.UNIQ_KEY 
		OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(Invt_rec.DAte as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN GL_NBRS on Invt_rec.GL_NBR_INV=gl_nbrs.GL_NBR 
	WHERE Is_Rel_Gl =0
		AND Inventor.Part_Sourc <> 'CONSG' 
		AND Invt_Rec.Gl_Nbr<>' '
		-- 06/22/16 VL added ROUND()
		AND ROUND(QtyRec * Invt_rec.StdCost,2)<>0
	),
	InvtRecCredit as
	(
	SELECT Trans_Dt,QTYREC,UNIQ_KEY,W_KEY,nTransAmount,DisplayValue,
	Credit as Debit,
	Debit as Credit,
	CR_GL_NBR as gl_nbr,gl_nbrs.GL_DESCR,
	TransactionType, 
	SourceTable,
	cIdentifier,
	cDrill,
	SourceSubTable,
	cSubIdentifier,
	cSubDrill,
	FY,Period,fk_fydtluniq  
	FROM InvtRecDebit INNER JOIN GL_NBRS ON InvtRecDebit.CR_GL_NBR=gl_nbrs.gl_nbr
	),FinalInvtRec AS
	(
	SELECT cast(0 as bit) as lSelect,Trans_Dt,QTYREC,UNIQ_KEY,W_KEY,nTransAmount,DisplayValue, 
	Debit,Credit,GL_NBR,GL_DESCR,
	TransactionType, 
	SourceTable,
	cIdentifier,
	cDrill,
	SourceSubTable,
	cSubIdentifier,
	cSubDrill,
	FY,Period,fk_fydtluniq, SPACE(10) AS AtdUniq_key  
	FROM InvtRecDebit 
	UNION ALL
	SELECT cast(0 as bit) as lSelect,Trans_Dt,QTYREC,UNIQ_KEY,W_KEY,nTransAmount,DisplayValue, 
	Debit,Credit,GL_NBR,GL_DESCR,
	TransactionType, 
	SourceTable,
	cIdentifier,
	cDrill,
	SourceSubTable,
	cSubIdentifier,
	cSubDrill,
	FY,Period,fk_fydtluniq, SPACE(10) AS AtdUniq_key  
	FROM InvtRecCredit)
	
	SELECT FinalInvtRec.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalInvtRec ORDER BY cDrill 
	
	END
ELSE
	BEGIN
	WITH InvtRecDebit as
	(
	SELECT Invt_rec.DAte as Trans_Dt, 
		QtyRec ,Invt_rec.UNIQ_KEY,Invt_rec.W_KEY,CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) as DisplayValue,
		ROUND(QtyRec * Invt_Rec.StdCost,2) AS nTransAmount, 
		CASE WHEN ROUND(QtyRec * Invt_rec.StdCost,2)>0 THEN ROUND(QtyRec * Invt_rec.StdCost,2) ELSE CAST(0.00 as numeric(14,2)) END as Debit,
		CASE WHEN ROUND(QtyRec * Invt_Rec.StdCost,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(QtyRec * Invt_Rec.StdCost,2)) END as Credit,
		CAST('INVTREC' as varchar(50)) as TransactionType, 
		CAST('Invt_rec' as varchar(25)) as SourceTable,
		'InvtRec_No' as cIdentifier,
		Invt_rec.InvtRec_No as cDrill,
		CAST('Inventor' as varchar(25)) as SourceSubTable,
		'UNIQ_KEY' as cSubIdentifier,
		Invt_rec.Uniq_key as cSubDrill,
		Invt_rec.GL_NBR as CR_GL_NBR, Invt_rec.GL_NBR_INV as GL_NBR ,gl_nbrs.GL_DESCR,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
		-- 12/21/16 VL added functional and presentation currency fields
		ROUND(QtyRec * Invt_Rec.StdCostPR,2) AS nTransAmountPR, 
		CASE WHEN ROUND(QtyRec * Invt_rec.StdCostPR,2)>0 THEN ROUND(QtyRec * Invt_rec.StdCostPR,2) ELSE CAST(0.00 as numeric(14,2)) END as DebitPR,
		CASE WHEN ROUND(QtyRec * Invt_Rec.StdCostPR,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(QtyRec * Invt_Rec.StdCostPR,2)) END as CreditPR,
		FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
		Invt_rec.FuncFcused_uniq, Invt_rec.PrFcused_uniq 
		FROM Invt_rec 
			INNER JOIN Fcused PF ON Invt_rec.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON Invt_rec.FuncFcused_uniq = FF.Fcused_uniq
		INNER JOIN INVENTOR ON Invt_rec.UNIQ_KEY =Inventor.UNIQ_KEY 
		OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(Invt_rec.DAte as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN GL_NBRS on Invt_rec.GL_NBR_INV=gl_nbrs.GL_NBR 
	WHERE Is_Rel_Gl =0
		AND Inventor.Part_Sourc <> 'CONSG' 
		AND Invt_Rec.Gl_Nbr<>' '
		-- 06/22/16 VL added ROUND()
		AND ROUND(QtyRec * Invt_rec.StdCost,2)<>0
	),
	InvtRecCredit as
	(
	SELECT Trans_Dt,QTYREC,UNIQ_KEY,W_KEY,nTransAmount,DisplayValue,
	Credit as Debit,
	Debit as Credit,
	CR_GL_NBR as gl_nbr,gl_nbrs.GL_DESCR,
	TransactionType, 
	SourceTable,
	cIdentifier,
	cDrill,
	SourceSubTable,
	cSubIdentifier,
	cSubDrill,
	FY,Period,fk_fydtluniq,
	-- 12/21/16 VL added functional and presentation currency fields
	nTransAmountPR, CreditPR as DebitPR, DebitPR as CreditPR, Functional_Currency, Presentation_Currency,
	FuncFcused_uniq, PrFcused_uniq 
	FROM InvtRecDebit INNER JOIN GL_NBRS ON InvtRecDebit.CR_GL_NBR=gl_nbrs.gl_nbr
	),FinalInvtRec AS
	(
	SELECT cast(0 as bit) as lSelect,Trans_Dt,QTYREC,UNIQ_KEY,W_KEY,nTransAmount,DisplayValue, 
	Debit,Credit,GL_NBR,GL_DESCR,
	TransactionType, 
	SourceTable,
	cIdentifier,
	cDrill,
	SourceSubTable,
	cSubIdentifier,
	cSubDrill,
	FY,Period,fk_fydtluniq, SPACE(10) AS AtdUniq_key,
	-- 12/21/16 VL added functional and presentation currency fields
	nTransAmountPR, DebitPR, CreditPR, Functional_Currency, Presentation_Currency,
	FuncFcused_uniq, PrFcused_uniq   
	FROM InvtRecDebit 
	UNION ALL
	SELECT cast(0 as bit) as lSelect,Trans_Dt,QTYREC,UNIQ_KEY,W_KEY,nTransAmount,DisplayValue, 
	Debit,Credit,GL_NBR,GL_DESCR,
	TransactionType, 
	SourceTable,
	cIdentifier,
	cDrill,
	SourceSubTable,
	cSubIdentifier,
	cSubDrill,
	FY,Period,fk_fydtluniq, SPACE(10) AS AtdUniq_key,
	-- 12/21/16 VL added functional and presentation currency fields
	nTransAmountPR, DebitPR, CreditPR, Functional_Currency, Presentation_Currency,
	FuncFcused_uniq, PrFcused_uniq   
	FROM InvtRecCredit)
	
	SELECT FinalInvtRec.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalInvtRec ORDER BY cDrill 
	
	END
END