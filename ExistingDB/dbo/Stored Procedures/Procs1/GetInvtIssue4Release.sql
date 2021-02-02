-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/31/2011
-- Description:	Get Invt Issue information for release
--				10/16/2015 VL added AtdUniq_key
--				06/22/2016 VL added ROUND(,2) to the WHERE clause AND QtyIsu * Invt_isu.StdCost<>0, so the value < 0.01 won't show
--				12/21/16 VL added functional and presentation currency fields and separate FC and non-FC
-- =============================================
CREATE PROCEDURE [dbo].[GetInvtIssue4Release]
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
	WITH InvtIsuDebit as
	(
	SELECT Invt_isu.DAte as Trans_Dt, CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) as DisplayValue,
		QtyIsu ,Invt_isu.UNIQ_KEY,Invt_isu.W_KEY,
		ROUND(QtyIsu * Invt_isu.StdCost,2) AS nTransAmount, 
		CASE WHEN ROUND(QtyIsu * Invt_isu.StdCost,2)>0 THEN ROUND(QtyIsu * Invt_isu.StdCost,2) ELSE CAST(0.00 as numeric(14,2)) END as Debit,
		CASE WHEN ROUND(QtyIsu * Invt_isu.StdCost,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(QtyIsu * Invt_isu.StdCost,2)) END as Credit,
		CAST('INVTISU' as varchar(50)) as TransactionType, 
		CAST('Invt_isu' as varchar(25)) as SourceTable,
		'InvtIsu_No' as cIdentifier,
		Invt_isu.InvtIsu_No as cDrill,
		CAST('INVENTOR' as varchar(25)) as SourceSubTable,
		'UNIQ_KEY' as cSubIdentifier,
		Invt_isu.UNIQ_KEY as cSubDrill,
		Invt_isu.GL_NBR, Invt_isu.GL_NBR_INV ,gl_nbrs.GL_DESCR,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq
		FROM Invt_Isu INNER JOIN INVENTOR ON Invt_isu.UNIQ_KEY =Inventor.UNIQ_KEY 
		OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(Invt_isu.DAte as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		inner join GL_NBRS on invt_isu.GL_NBR = gl_nbrs.GL_NBR 
	WHERE Is_Rel_Gl =0
		AND Inventor.Part_Sourc <> 'CONSG' 
		AND Invt_Isu.Gl_Nbr<>' '
		AND CHARINDEX('REQ PKLST',IssuedTo)=0
		-- 06/22/16 VL added ROUND()
		AND ROUND(QtyIsu * Invt_isu.StdCost,2)<>0
	),
	InvtisuCredit as
	(
	SELECT Trans_Dt,QTYISU,UNIQ_KEY,W_KEY,nTransAmount,DisplayValue,
	Credit as Debit,
	Debit as Credit,
	GL_NBR_INV as gl_nbr,gl_nbrs.GL_DESCR ,
	TransactionType, 
	SourceTable,
	cIdentifier,
	cDrill,
	SourceSubTable,
	cSubIdentifier,
	cSubDrill,
	FY,Period,fk_fydtluniq  
	FROM InvtIsuDebit inner join GL_NBRS on InvtIsuDebit.GL_NBR_INV = gl_nbrs.GL_NBR 
	),FinalInvtIsu AS
	(
	SELECT cast(0 as bit) as lSelect,Trans_Dt,QTYISU,UNIQ_KEY,W_KEY,nTransAmount,DisplayValue, 
	Debit,Credit,GL_NBR,GL_DESCR,
	TransactionType, 
	SourceTable,
	cIdentifier,
	cDrill,
	SourceSubTable,
	cSubIdentifier,
	cSubDrill,
	FY,Period,fk_fydtluniq, SPACE(10) AS AtdUniq_key
	FROM InvtIsuDebit 
	UNION ALL
	SELECT cast(0 as bit) as lSelect,Trans_Dt,QTYISU,UNIQ_KEY,W_KEY,nTransAmount,DisplayValue, 
	Debit,Credit,GL_NBR,GL_DESCR,
	TransactionType, 
	SourceTable,
	cIdentifier,
	cDrill,
	SourceSubTable,
	cSubIdentifier,
	cSubDrill,
	FY,Period,fk_fydtluniq, SPACE(10) AS AtdUniq_key  
	FROM InvtisuCredit)
	
	SELECT FinalInvtIsu.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalInvtIsu ORDER BY cDrill
	
	END
ELSE
	BEGIN
	WITH InvtIsuDebit as
	(
	SELECT Invt_isu.DAte as Trans_Dt, CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) as DisplayValue,
		QtyIsu ,Invt_isu.UNIQ_KEY,Invt_isu.W_KEY,
		ROUND(QtyIsu * Invt_isu.StdCost,2) AS nTransAmount, 
		CASE WHEN ROUND(QtyIsu * Invt_isu.StdCost,2)>0 THEN ROUND(QtyIsu * Invt_isu.StdCost,2) ELSE CAST(0.00 as numeric(14,2)) END as Debit,
		CASE WHEN ROUND(QtyIsu * Invt_isu.StdCost,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(QtyIsu * Invt_isu.StdCost,2)) END as Credit,
		CAST('INVTISU' as varchar(50)) as TransactionType, 
		CAST('Invt_isu' as varchar(25)) as SourceTable,
		'InvtIsu_No' as cIdentifier,
		Invt_isu.InvtIsu_No as cDrill,
		CAST('INVENTOR' as varchar(25)) as SourceSubTable,
		'UNIQ_KEY' as cSubIdentifier,
		Invt_isu.UNIQ_KEY as cSubDrill,
		Invt_isu.GL_NBR, Invt_isu.GL_NBR_INV ,gl_nbrs.GL_DESCR,
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
		-- 12/21/16 VL added functional and presentation currency fields
		ROUND(QtyIsu * Invt_isu.StdCostPR,2) AS nTransAmountPR, 
		CASE WHEN ROUND(QtyIsu * Invt_isu.StdCostPR,2)>0 THEN ROUND(QtyIsu * Invt_isu.StdCostPR,2) ELSE CAST(0.00 as numeric(14,2)) END as DebitPR,
		CASE WHEN ROUND(QtyIsu * Invt_isu.StdCostPR,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(QtyIsu * Invt_isu.StdCostPR,2)) END as CreditPR,
		FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
		Invt_isu.FuncFcused_uniq, Invt_isu.PrFcused_uniq 
		FROM Invt_Isu 
			INNER JOIN Fcused PF ON Invt_Isu.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON Invt_Isu.FuncFcused_uniq = FF.Fcused_uniq
		INNER JOIN INVENTOR ON Invt_isu.UNIQ_KEY =Inventor.UNIQ_KEY 
		OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(Invt_isu.DAte as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		inner join GL_NBRS on invt_isu.GL_NBR = gl_nbrs.GL_NBR 
	WHERE Is_Rel_Gl =0
		AND Inventor.Part_Sourc <> 'CONSG' 
		AND Invt_Isu.Gl_Nbr<>' '
		AND CHARINDEX('REQ PKLST',IssuedTo)=0
		-- 06/22/16 VL added ROUND()
		AND ROUND(QtyIsu * Invt_isu.StdCost,2)<>0
	),
	InvtisuCredit as
	(
	SELECT Trans_Dt,QTYISU,UNIQ_KEY,W_KEY,nTransAmount,DisplayValue,
	Credit as Debit,
	Debit as Credit,
	GL_NBR_INV as gl_nbr,gl_nbrs.GL_DESCR ,
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
	FROM InvtIsuDebit inner join GL_NBRS on InvtIsuDebit.GL_NBR_INV = gl_nbrs.GL_NBR 
	),FinalInvtIsu AS
	(
	SELECT cast(0 as bit) as lSelect,Trans_Dt,QTYISU,UNIQ_KEY,W_KEY,nTransAmount,DisplayValue, 
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
	FROM InvtIsuDebit 
	UNION ALL
	SELECT cast(0 as bit) as lSelect,Trans_Dt,QTYISU,UNIQ_KEY,W_KEY,nTransAmount,DisplayValue, 
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
	FROM InvtisuCredit)
	
	SELECT FinalInvtIsu.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalInvtIsu ORDER BY cDrill

	END
	
END