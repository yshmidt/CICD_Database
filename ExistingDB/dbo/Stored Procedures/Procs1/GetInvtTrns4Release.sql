-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/31/2011
-- Description:	Get Inventory Transactions info for release
--				10/16/2015 VL added AtdUniq_key
--				06/22/2016 VL added ROUND(,2) to the WHERE clause AND Qtyxfer * InvtTrns.StdCost<>0, so the value < 0.01 won't show
--				12/21/16 VL added functional and presentation currency fields and separate FC and non-FC
-- =============================================
CREATE PROCEDURE [dbo].[GetInvtTrns4Release]
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
	;WITH InvTrDebit AS
	(
	SELECT Date as Trans_dt, InvtTrns.FROMWKEY,InvtTrns.TOWKEY,InvtTrns.UNIQ_KEY,Invttrns.QTYXFER,    
			Gl_nbr, Gl_nbr_inv,InvtTrns.StdCost,
			ROUND(Qtyxfer * InvtTrns.StdCost,2) as nTransAmount ,CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) as DisplayValue,
			CASE WHEN ROUND(Qtyxfer * InvtTrns.StdCost,2) >0 THEN ROUND(Qtyxfer * InvtTrns.StdCost,2) ELSE CAST(0.00 as numeric(14,2)) END as Debit ,
			CASE WHEN ROUND(Qtyxfer * InvtTrns.StdCost,2) >0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Qtyxfer * InvtTrns.StdCost,2)) END as Credit ,
			CAST('INVTTRNS' as varchar(50)) as TransactionType, 
			CAST('InvtTrns' as varchar(25)) as SourceTable,
			'Invtxfer_N' as cIdentifier,
			InvtTrns.Invtxfer_N as cDrill,
			CAST('INVENTOR' as varchar(25)) as SourceSubTable,
			'UNIQ_KEY' as cSubIdentifier,
			InvtTrns.UNIQ_KEY as cSubDrill,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq
			FROM InvtTrns INNER JOIN INVENTOR on Invttrns.UNIQ_KEY =Inventor.UNIQ_KEY 
			OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(Invttrns.DAte as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		WHERE  Is_Rel_Gl =0
		AND GL_NBR<>' '
		and GL_NBR<>GL_NBR_INV
		AND Inventor.PART_SOURC<>'CONSG'
		-- 06/22/16 VL added ROUND()
		AND ROUND(Qtyxfer * InvtTrns.StdCost,2)<>0.00
		),
		InvTrCredit as
		(
		SELECT Trans_dt,FROMWKEY,TOWKEY,UNIQ_KEY ,QTYXFER,
			Gl_nbr_inv as gl_nbr,gl_nbrs.gl_descr,STDCOST,nTransAmount,DisplayValue,
			Credit as Debit,
			Debit as Credit,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			Fy,Period,fk_fyDtlUniq   
			FROM InvTrDebit inner join GL_NBRS on InvTrDebit.Gl_nbr_inv =gl_nbrs.gl_nbr
		),FinalInvtTrns AS
		(
		SELECT cast(0 as bit) as lSelect,Trans_dt,FROMWKEY,TOWKEY,UNIQ_KEY ,QTYXFER,
			InvTrDebit.gl_nbr,gl_nbrs.gl_descr,STDCOST,nTransAmount,DisplayValue ,
			Debit,
			Credit,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill ,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			Fy,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key     
			FROM InvTrDebit inner join GL_NBRS on InvTrDebit.Gl_nbr =gl_nbrs.gl_nbr
			UNION ALL
			SELECT cast(0 as bit) as lSelect, Trans_dt,FROMWKEY,TOWKEY,UNIQ_KEY ,QTYXFER,
			gl_nbr,gl_descr,STDCOST,nTransAmount,DisplayValue ,
			Debit,
			Credit,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill ,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			Fy,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key   
			FROM InvTrCredit)
	
		  SELECT FinalInvtTrns.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalInvtTrns ORDER BY cDrill 
	END
ELSE
	BEGIN
	;WITH InvTrDebit AS
	(
	SELECT Date as Trans_dt, InvtTrns.FROMWKEY,InvtTrns.TOWKEY,InvtTrns.UNIQ_KEY,Invttrns.QTYXFER,    
			Gl_nbr, Gl_nbr_inv,InvtTrns.StdCost,
			ROUND(Qtyxfer * InvtTrns.StdCost,2) as nTransAmount ,CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) as varchar(50)) as DisplayValue,
			CASE WHEN ROUND(Qtyxfer * InvtTrns.StdCost,2) >0 THEN ROUND(Qtyxfer * InvtTrns.StdCost,2) ELSE CAST(0.00 as numeric(14,2)) END as Debit ,
			CASE WHEN ROUND(Qtyxfer * InvtTrns.StdCost,2) >0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Qtyxfer * InvtTrns.StdCost,2)) END as Credit ,
			CAST('INVTTRNS' as varchar(50)) as TransactionType, 
			CAST('InvtTrns' as varchar(25)) as SourceTable,
			'Invtxfer_N' as cIdentifier,
			InvtTrns.Invtxfer_N as cDrill,
			CAST('INVENTOR' as varchar(25)) as SourceSubTable,
			'UNIQ_KEY' as cSubIdentifier,
			InvtTrns.UNIQ_KEY as cSubDrill,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
			-- 12/21/16 VL added functional and presentation currency fields
			InvtTrns.StdCostPR,
			ROUND(Qtyxfer * InvtTrns.StdCostPR,2) as nTransAmountPR ,
			CASE WHEN ROUND(Qtyxfer * InvtTrns.StdCostPR,2) >0 THEN ROUND(Qtyxfer * InvtTrns.StdCostPR,2) ELSE CAST(0.00 as numeric(14,2)) END as DebitPR ,
			CASE WHEN ROUND(Qtyxfer * InvtTrns.StdCostPR,2) >0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Qtyxfer * InvtTrns.StdCostPR,2)) END as CreditPR ,
			FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
			Invttrns.FuncFcused_uniq, Invttrns.PrFcused_uniq 
			FROM InvtTrns 
				INNER JOIN Fcused PF ON InvtTrns.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON InvtTrns.FuncFcused_uniq = FF.Fcused_uniq
			INNER JOIN INVENTOR on Invttrns.UNIQ_KEY =Inventor.UNIQ_KEY 
			OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(Invttrns.DAte as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		WHERE  Is_Rel_Gl =0
		AND GL_NBR<>' '
		and GL_NBR<>GL_NBR_INV
		AND Inventor.PART_SOURC<>'CONSG'
		-- 06/22/16 VL added ROUND()
		AND ROUND(Qtyxfer * InvtTrns.StdCost,2)<>0.00
		),
		InvTrCredit as
		(
		SELECT Trans_dt,FROMWKEY,TOWKEY,UNIQ_KEY ,QTYXFER,
			Gl_nbr_inv as gl_nbr,gl_nbrs.gl_descr,STDCOST,nTransAmount,DisplayValue,
			Credit as Debit,
			Debit as Credit,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			Fy,Period,fk_fyDtlUniq,
			-- 12/21/16 VL added functional and presentation currency fields
			STDCOSTPR, nTransAmountPR, CreditPR as DebitPR, DebitPR as CreditPR, Functional_Currency, Presentation_Currency,
			FuncFcused_uniq, PrFcused_uniq 
			FROM InvTrDebit inner join GL_NBRS on InvTrDebit.Gl_nbr_inv =gl_nbrs.gl_nbr
		),FinalInvtTrns AS
		(
		SELECT cast(0 as bit) as lSelect,Trans_dt,FROMWKEY,TOWKEY,UNIQ_KEY ,QTYXFER,
			InvTrDebit.gl_nbr,gl_nbrs.gl_descr,STDCOST,nTransAmount,DisplayValue ,
			Debit,
			Credit,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill ,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			Fy,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
			-- 12/21/16 VL added functional and presentation currency fields
			STDCOSTPR, nTransAmountPR, DebitPR, CreditPR, Functional_Currency, Presentation_Currency,
			FuncFcused_uniq, PrFcused_uniq      
			FROM InvTrDebit inner join GL_NBRS on InvTrDebit.Gl_nbr =gl_nbrs.gl_nbr
			UNION ALL
			SELECT cast(0 as bit) as lSelect, Trans_dt,FROMWKEY,TOWKEY,UNIQ_KEY ,QTYXFER,
			gl_nbr,gl_descr,STDCOST,nTransAmount,DisplayValue ,
			Debit,
			Credit,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill ,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			Fy,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key ,
			-- 12/21/16 VL added functional and presentation currency fields
			STDCOSTPR, nTransAmountPR, DebitPR, CreditPR, Functional_Currency, Presentation_Currency,
			FuncFcused_uniq, PrFcused_uniq      
			FROM InvTrCredit)
	
		  SELECT FinalInvtTrns.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalInvtTrns ORDER BY cDrill 
	END
	    
END    