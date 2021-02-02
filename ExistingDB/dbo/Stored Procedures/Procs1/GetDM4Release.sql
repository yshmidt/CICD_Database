-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/30/2011
-- Description:	Get DM information for release
-- 10/05/15 VL Added for 0 amount tax from cmpricestax and cmfreighttax because 0 tax won't be saved in invstdtx, but Malaysia tax system needs 0% tax saved in records
--			   Also added AtdUniq_key to each CTE cursor
-- 10/16/15 VL added Currency field for FC
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 05/25/16 VL changed for both DMtype = 1 or 2 to have price_each*Qty_each, not just use item_total for Dmtype=2 because now the calculation on the form is price_each*Qty_each, before for manual type, user can just enter item_total without enter qty and price
--				because found a problem, if the item has tax, the item_total will include the tax, but actually tax has its own record, will just use qty*price
-- 12/19/16 VL added functional and presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[GetDM4Release]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @T as dbo.AllFYPeriods
	INSERT INTO @T EXEC GlFyrstartEndView	;

-- 10/09/15 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
	BEGIN

	;WITH DMHeader AS
	(
	SELECT DmDate as Trans_Dt, UniqSupno, DMTYPE,
		DMemoNo , DmTotal ,nDiscAmt,
		UniqDmHead , 
		CAST('DM' as varchar(50)) as TransactionType, 
		CAST('DMEMOS' as varchar(25)) as SourceTable,
		'UniqDmHead' as cIdentifier,
		Dmemos.UniqDmHead as cDrill,
		CASE WHEN Dmemos.DMTYPE=2 THEN CAST('APMASTER' as varchar(25)) --- if manual debit memo (type 2 ) will have to update apmaster
		ELSE CAST('DMEMOS' as varchar(25)) END as SourceSubTable,
		CASE WHEN Dmemos.DMTYPE=2 THEN 'UNIQAPHEAD' 
		ELSE 'UniqDmHead' END as cSubIdentifier,
		CASE WHEN Dmemos.DMTYPE=2 THEN DMEMOS.UNIQAPHEAD  
		ELSE Dmemos.UniqDmHead END as cSubDrill,
		ApSetup.Ap_Gl_no as GL_NBR,gl_nbrs.GL_DESCR,
		ApSetup.Disc_Gl_No,ApSetup.STAX_GL_NO ,
		CASE WHEN DmTotal>0 THEN DMTOTAL ELSE CAST(0.00 as numeric(14,2)) END as Debit,
		CASE WHEN DmTotal>0 THEN CAST(0.00 as numeric(14,2)) else  ABS(DMTOTAL) END as Credit, 
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
	FROM Dmemos OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(Dmemos.DmDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		CROSS APPLY ApSetup
		inner join GL_NBRS on apsetup.AP_GL_NO =gl_nbrs.GL_nbr
	WHERE Is_Rel_Gl=0
	AND Dmemos.DmStatus = 'Posted to AP'
	),
	DMDiscount AS
	(SELECT DmHeader.Trans_Dt, DmHeader.UniqSupno, 
		DmHeader.DMemoNo , DmHeader.DmTotal ,DmHeader.nDiscAmt,
		DmHeader.UniqDmHead , 
		CAST('DM' as varchar(50)) as TransactionType, 
		CAST('DMEMOS' as varchar(25)) as SourceTable,
		'UniqDmHead' as cIdentifier,
		DmHeader.UniqDmHead as cDrill,
		CAST('DMEMOS' as varchar(25)) as SourceSubTable,
		'UniqDmHead' as cSubIdentifier,
		DmHeader.UniqDmHead as cSubDrill,
		DmHeader.Disc_Gl_No as GL_NBR,gl_nbrs.GL_DESCR,
		CASE WHEN DmHeader.nDiscAmt>0 THEN DmHeader.nDiscAmt ELSE CAST(0.00 as numeric(14,2)) END as Debit,
		CASE WHEN DmHeader.nDiscAmt>0 THEN CAST(0.00 as numeric(14,2)) else  ABS(DmHeader.nDiscAmt) END as Credit, 
		DmHeader.FY,DmHeader.Period ,DmHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key   
		FROM DMHeader inner join GL_NBRS on dmHeader.DISC_GL_NO =gl_nbrs.gl_nbr
	WHERE DmHeader.nDiscAmt<>0.00
	),
	DMDetails AS
	(
	-- use >= when checking for debit, if amount is 0 result will be null if only check for >0 and <0
	SELECT DmHeader.Trans_dt,
		DmHeader.UniqSupno, 
		DmHeader.DMemoNo ,
		DmHeader.UniqDmHead,
		APDMDETL.UNIQDMDETL,
		ROUND(Price_Each * Qty_Each,2) as Extended,  
		-- 10/06/15 not calculate tax from this level, will get detail in DmTax from ApDmDetltax later
		--(ROUND(((Price_Each * Qty_Each) * Tax_Pct/100),2),0.00) as TAX, 
		-- 10/06/15 VL added to get price_each and Qty_each want to use in tax calculate then round() not just use extended to prevent get rounding issue
		Price_Each,
		Qty_Each,
		DMHeader.STAX_GL_NO , 
		ApDmDetl.Gl_nbr AS GL_NBR, GL_NBRS.Gl_Descr,
		CAST('DM' as varchar(50)) as TransactionType, 
		CAST('DMEMOS' as varchar(25)) as SourceTable,
		'UniqDmHead' as cIdentifier,
		DmHeader.UniqDmHead as cDrill,
		CAST('APDMDETL' as varchar(25)) as SourceSubTable,
		'UNIQDMDETL' as cSubIdentifier,
		ApDmDetl.UNIQDMDETL as cSubDrill, 
		-- 05/25/16 VL changed for both DMtype = 1 or 2 to have price_each*Qty_each, not just use item_total for Dmtype=2 because now the calculation on the form is price_each*Qty_each, before for manual type, user can just enter item_total without enter qty and price
		-- because found a problem, if the item has tax, the item_total will include the tax, but actually tax has its own record, will just use qty*price
		--CASE WHEN DMHEADER.Dmtype=1 AND ROUND(Price_Each * Qty_Each,2) >=0 THEN CAST(0.00 as numeric(14,2)) 
		--WHEN DMHEADER.Dmtype=2 AND ApdmDetl.ITEM_TOTAL >=0 THEN CAST(0.00 as numeric(14,2))
		--WHEN DMHEADER.Dmtype=1 AND ROUND(Price_Each * Qty_Each,2)<0 THEN ABS(ROUND(Price_Each * Qty_Each,2)) 
		--WHEN DMHEADER.Dmtype=2 AND ApdmDetl.ITEM_TOTAL<0 THEN ABS(Item_Total)END AS Debit,
		--CASE WHEN DMHEADER.Dmtype=1 AND ROUND(Price_Each * Qty_Each,2)>0 THEN ROUND(Price_Each * Qty_Each,2) 
		--WHEN DMHEADER.Dmtype=2 AND ApdmDetl.ITEM_TOTAL >0 THEN ApdmDetl.ITEM_TOTAL
		--ELSE  CAST(0.00 as numeric(14,2)) END as Credit, 
		CASE WHEN ROUND(Price_Each * Qty_Each,2) >=0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Price_Each * Qty_Each,2)) END AS Debit,
		CASE WHEN ROUND(Price_Each * Qty_Each,2) >0 THEN ROUND(Price_Each * Qty_Each,2) ELSE CAST(0.00 as numeric(14,2)) END as Credit, 
		DmHeader.FY,DmHeader.Period ,DmHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key  
	FROM DMHeader INNER JOIN ApDmDetl ON ApDmDetl.UniqDmHead = DMHeader.UNIQDMHEAD 
	---- 10/05/15 VL added next line, then comment out for now, create more detail tax records
	--LEFT OUTER JOIN DmTaxDetail ON DmTaxDetail.UNIQDMDETL = ApDmDetl.UNIQDMDETL
	INNER JOIN GL_NBRS on  ApDmDetl.Gl_nbr = gl_nbrs.gl_nbr
	),
	-- 10/06/15 VL changed not use ApSetup.STAX_GL_NO but use ApDmDetlTax.Tax_id linked to Taxtabl to get Gl_nbr
	--DmTax as
	--(
	--SELECT DMDetails.Trans_dt,
	--	DMDetails.UniqSupno, 
	--	DMDetails.DMemoNo ,
	--	DMDetails.UniqDmHead,
	--	DMDetails.UNIQDMDETL,
	--	DMDetails.TAX ,  
	--	DMDetails.STAX_GL_NO AS GL_NBR, 
	--	GL_NBRS.Gl_Descr,
	--	DMDetails.TransactionType, 
	--	DMDetails.SourceTable,
	--	DMDetails.cIdentifier,
	--	DMDetails.cDrill,
	--	DMDetails.SourceSubTable,
	--	DMDetails.cSubIdentifier,
	--	DMDetails.cSubDrill, 
	--	CASE WHEN DMDetails.TAX>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(DMDetails.TAX) END AS Debit,
	--	CASE WHEN DMDetails.TAX>0 THEN DMDetails.TAX ELSE CAST(0.00 as numeric(14,2)) END as Credit, 
	--	DMDetails.FY,DMDetails.Period ,DMDetails.fk_fyDtlUniq  
	--FROM DMDetails INNER JOIN GL_NBRS on  DMDetails.STAX_GL_NO = gl_nbrs.gl_nbr	
	--WHERE DMDetails.TAX<>0	
	--) 
	DmTax AS
	(
	SELECT DMDetails.Trans_Dt,
		DMDetails.UniqSupno, 
		DMDetails.DMemoNo ,
		DMDetails.UniqDmHead,
		DMDetails.UNIQDMDETL,
		ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) as TAX,
		Taxtabl.Gl_nbr_in AS Gl_nbr,
		GL_NBRS.Gl_Descr,
		DMDetails.TransactionType, 
		DMDetails.SourceTable,
		DMDetails.cIdentifier,
		DMDetails.cDrill,
		CAST('ApDmDetlTax' AS VARCHAR(25)) AS SourceSubTable,
		'UNIQAPDMDETLTAX' AS cSubIdentifier,
		ApDmDetlTax.UniqApDmDetlTax AS cSubDrill, 
		CASE WHEN ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) > 0 
			THEN CAST(0.00 as numeric(14,2)) 
			ELSE ABS(ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00)) END AS Debit,
		CASE WHEN ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) > 0 
			THEN ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00)
			ELSE CAST(0.00 as numeric(14,2)) END as Credit, 
		DMDetails.FY,DMDetails.Period ,DMDetails.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key   
	FROM DmDetails INNER JOIN ApDmDetlTax On DmDetails.UniqDmDetl = ApDmDetlTax.UniqDmDetl
		INNER JOIN Taxtabl ON ApDmDetlTax.Tax_id = Taxtabl.Tax_id 
		INNER JOIN Gl_nbrs ON Taxtabl.Gl_nbr_in = Gl_nbrs.Gl_nbr
	WHERE ApDmDetlTax.Tax_rate <> 0
	),
	DmTax0 AS
	(
	SELECT DMDetails.Trans_Dt,
		DMDetails.UniqSupno, 
		DMDetails.DMemoNo ,
		DMDetails.UniqDmHead,
		DMDetails.UNIQDMDETL,
		ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) as TAX,
		Taxtabl.Gl_nbr_in AS Gl_nbr,
		GL_NBRS.Gl_Descr,
		DMDetails.TransactionType, 
		DMDetails.SourceTable,
		DMDetails.cIdentifier,
		DMDetails.cDrill,
		CAST('ApDmDetlTax' AS VARCHAR(25)) AS SourceSubTable,
		'UNIQAPDMDETLTAX' AS cSubIdentifier,
		ApDmDetlTax.UniqApDmDetlTax AS cSubDrill, 
		CASE WHEN ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) > 0 
			THEN CAST(0.00 as numeric(14,2)) 
			ELSE ABS(ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00)) END AS Debit,
		CASE WHEN ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) > 0 
			THEN ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00)
			ELSE CAST(0.00 as numeric(14,2)) END as Credit, 
		DMDetails.FY,DMDetails.Period ,DMDetails.fk_fyDtlUniq, 'TAX0      ' AS AtdUniq_key   
	FROM DmDetails INNER JOIN ApDmDetlTax On DmDetails.UniqDmDetl = ApDmDetlTax.UniqDmDetl
		INNER JOIN Taxtabl ON ApDmDetlTax.Tax_id = Taxtabl.Tax_id 
		INNER JOIN Gl_nbrs ON Taxtabl.Gl_nbr_in = Gl_nbrs.Gl_nbr
	WHERE ApDmDetlTax.Tax_rate = 0
	)
	-- 10/06/15 VL End}
	, FinalDm as
	(
	SELECT cast(0 as bit) as lSelect,Trans_DT,GL_NBR,Gl_Descr,UniqSupNo,DMemoNo,DMemoNo as DisplayValue,
		TransactionType ,SourceTable,
		cIdentifier,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill, 
		Debit,Credit,
		FY,Period,fk_Fydtluniq, AtdUniq_key 
	 FROM DMHeader 
	 UNION ALl
	 SELECT cast(0 as bit) as lSelect,Trans_DT,GL_NBR,Gl_Descr,UniqSupNo,DMemoNo,DMemoNo as DisplayValue,
		TransactionType ,SourceTable,
		cIdentifier,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill, 
		Debit,Credit,
		FY,Period,fk_Fydtluniq, AtdUniq_key   
	 FROM DMDiscount 
	 UNION ALL
	 SELECT cast(0 as bit) as lSelect,Trans_DT,GL_NBR,Gl_Descr,UniqSupNo,DMemoNo,DMemoNo as DisplayValue,
		TransactionType ,SourceTable,
		cIdentifier,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill, 
		Debit,Credit,
		FY,Period,fk_Fydtluniq, AtdUniq_key   
	 FROM DMDetails   
	 UNION ALL
	 SELECT cast(0 as bit) as lSelect,Trans_DT,GL_NBR,Gl_Descr,UniqSupNo,DMemoNo,DMemoNo as DisplayValue,
		TransactionType ,SourceTable,
		cIdentifier,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill, 
		Debit,Credit,
		FY,Period,fk_Fydtluniq, AtdUniq_key   
	 FROM DmTax   
	 -- 10/06/15 VL added DmTax0 if any tax rate 0 records exist
	 UNION ALL
	 SELECT cast(0 as bit) as lSelect,Trans_DT,GL_NBR,Gl_Descr,UniqSupNo,DMemoNo,DMemoNo as DisplayValue,
		TransactionType ,SourceTable,
		cIdentifier,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill, 
		Debit,Credit,
		FY,Period,fk_Fydtluniq, AtdUniq_key   
	 FROM DmTax0 
	-- 10/06/15 VL End}
	 )
	 SELECT FinalDm.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY DMemoNo) as GroupIdNumber FROM FinalDm ORDER BY DMemoNo
	
	END
ELSE
	BEGIN

	;WITH DMHeader AS
	(
	SELECT DmDate as Trans_Dt, UniqSupno, DMTYPE,
		DMemoNo , DmTotal ,nDiscAmt,
		UniqDmHead , 
		CAST('DM' as varchar(50)) as TransactionType, 
		CAST('DMEMOS' as varchar(25)) as SourceTable,
		'UniqDmHead' as cIdentifier,
		Dmemos.UniqDmHead as cDrill,
		CASE WHEN Dmemos.DMTYPE=2 THEN CAST('APMASTER' as varchar(25)) --- if manual debit memo (type 2 ) will have to update apmaster
		ELSE CAST('DMEMOS' as varchar(25)) END as SourceSubTable,
		CASE WHEN Dmemos.DMTYPE=2 THEN 'UNIQAPHEAD' 
		ELSE 'UniqDmHead' END as cSubIdentifier,
		CASE WHEN Dmemos.DMTYPE=2 THEN DMEMOS.UNIQAPHEAD  
		ELSE Dmemos.UniqDmHead END as cSubDrill,
		ApSetup.Ap_Gl_no as GL_NBR,gl_nbrs.GL_DESCR,
		ApSetup.Disc_Gl_No,ApSetup.STAX_GL_NO ,
		CASE WHEN DmTotal>0 THEN DMTOTAL ELSE CAST(0.00 as numeric(14,2)) END as Debit,
		CASE WHEN DmTotal>0 THEN CAST(0.00 as numeric(14,2)) else  ABS(DMTOTAL) END as Credit, 
		fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, SPACE(10) AS AtdUniq_key ,
		-- 12/19/16 VL added functional and presentation currency fields
		DmTotalPR ,nDiscAmtPR,
		CASE WHEN DmTotalPR>0 THEN DMTOTALPR ELSE CAST(0.00 as numeric(14,2)) END as DebitPR,
		CASE WHEN DmTotalPR>0 THEN CAST(0.00 as numeric(14,2)) else  ABS(DMTOTALPR) END as CreditPR,
		FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq 
	FROM Dmemos
		INNER JOIN Fcused PF ON Dmemos.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON Dmemos.FuncFcused_uniq = FF.Fcused_uniq
	OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(Dmemos.DmDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		CROSS APPLY ApSetup
		inner join GL_NBRS on apsetup.AP_GL_NO =gl_nbrs.GL_nbr
	WHERE Is_Rel_Gl=0
	AND Dmemos.DmStatus = 'Posted to AP'
	),
	DMDiscount AS
	(SELECT DmHeader.Trans_Dt, DmHeader.UniqSupno, 
		DmHeader.DMemoNo , DmHeader.DmTotal ,DmHeader.nDiscAmt,
		DmHeader.UniqDmHead , 
		CAST('DM' as varchar(50)) as TransactionType, 
		CAST('DMEMOS' as varchar(25)) as SourceTable,
		'UniqDmHead' as cIdentifier,
		DmHeader.UniqDmHead as cDrill,
		CAST('DMEMOS' as varchar(25)) as SourceSubTable,
		'UniqDmHead' as cSubIdentifier,
		DmHeader.UniqDmHead as cSubDrill,
		DmHeader.Disc_Gl_No as GL_NBR,gl_nbrs.GL_DESCR,
		CASE WHEN DmHeader.nDiscAmt>0 THEN DmHeader.nDiscAmt ELSE CAST(0.00 as numeric(14,2)) END as Debit,
		CASE WHEN DmHeader.nDiscAmt>0 THEN CAST(0.00 as numeric(14,2)) else  ABS(DmHeader.nDiscAmt) END as Credit, 
		DmHeader.FY,DmHeader.Period ,DmHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/19/16 VL added functional and presentation currency fields   
		DmHeader.DmTotalPR ,DmHeader.nDiscAmtPR,
		CASE WHEN DmHeader.nDiscAmtPR>0 THEN DmHeader.nDiscAmtPR ELSE CAST(0.00 as numeric(14,2)) END as DebitPR,
		CASE WHEN DmHeader.nDiscAmtPR>0 THEN CAST(0.00 as numeric(14,2)) else  ABS(DmHeader.nDiscAmtPR) END as CreditPR,
		Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM DMHeader inner join GL_NBRS on dmHeader.DISC_GL_NO =gl_nbrs.gl_nbr
	WHERE DmHeader.nDiscAmt<>0.00
	),
	DMDetails AS
	(
	-- use >= when checking for debit, if amount is 0 result will be null if only check for >0 and <0
	SELECT DmHeader.Trans_dt,
		DmHeader.UniqSupno, 
		DmHeader.DMemoNo ,
		DmHeader.UniqDmHead,
		APDMDETL.UNIQDMDETL,
		ROUND(Price_Each * Qty_Each,2) as Extended,  
		-- 10/06/15 not calculate tax from this level, will get detail in DmTax from ApDmDetltax later
		--(ROUND(((Price_Each * Qty_Each) * Tax_Pct/100),2),0.00) as TAX, 
		-- 10/06/15 VL added to get price_each and Qty_each want to use in tax calculate then round() not just use extended to prevent get rounding issue
		Price_Each,
		Qty_Each,
		DMHeader.STAX_GL_NO , 
		ApDmDetl.Gl_nbr AS GL_NBR, GL_NBRS.Gl_Descr,
		CAST('DM' as varchar(50)) as TransactionType, 
		CAST('DMEMOS' as varchar(25)) as SourceTable,
		'UniqDmHead' as cIdentifier,
		DmHeader.UniqDmHead as cDrill,
		CAST('APDMDETL' as varchar(25)) as SourceSubTable,
		'UNIQDMDETL' as cSubIdentifier,
		ApDmDetl.UNIQDMDETL as cSubDrill, 
		-- 05/25/16 VL changed for both DMtype = 1 or 2 to have price_each*Qty_each, not just use item_total for Dmtype=2 because now the calculation on the form is price_each*Qty_each, before for manual type, user can just enter item_total without enter qty and price
		-- because found a problem, if the item has tax, the item_total will include the tax, but actually tax has its own record, will just use qty*price
		--CASE WHEN DMHEADER.Dmtype=1 AND ROUND(Price_Each * Qty_Each,2) >=0 THEN CAST(0.00 as numeric(14,2)) 
		--WHEN DMHEADER.Dmtype=2 AND ApdmDetl.ITEM_TOTAL >=0 THEN CAST(0.00 as numeric(14,2))
		--WHEN DMHEADER.Dmtype=1 AND ROUND(Price_Each * Qty_Each,2)<0 THEN ABS(ROUND(Price_Each * Qty_Each,2)) 
		--WHEN DMHEADER.Dmtype=2 AND ApdmDetl.ITEM_TOTAL<0 THEN ABS(Item_Total)END AS Debit,
		--CASE WHEN DMHEADER.Dmtype=1 AND ROUND(Price_Each * Qty_Each,2)>0 THEN ROUND(Price_Each * Qty_Each,2) 
		--WHEN DMHEADER.Dmtype=2 AND ApdmDetl.ITEM_TOTAL >0 THEN ApdmDetl.ITEM_TOTAL
		--ELSE  CAST(0.00 as numeric(14,2)) END as Credit, 
		CASE WHEN ROUND(Price_Each * Qty_Each,2) >=0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Price_Each * Qty_Each,2)) END AS Debit,
		CASE WHEN ROUND(Price_Each * Qty_Each,2) >0 THEN ROUND(Price_Each * Qty_Each,2) ELSE CAST(0.00 as numeric(14,2)) END as Credit, 
		DmHeader.FY,DmHeader.Period ,DmHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/19/16 VL added functional and presentation currency fields   
		ROUND(Price_EachPR * Qty_Each,2) as ExtendedPR,  
		Price_EachPR,
		CASE WHEN ROUND(Price_EachPR * Qty_Each,2) >=0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Price_EachPR * Qty_Each,2)) END AS DebitPR,
		CASE WHEN ROUND(Price_EachPR * Qty_Each,2) >0 THEN ROUND(Price_EachPR * Qty_Each,2) ELSE CAST(0.00 as numeric(14,2)) END as CreditPR,
		Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq  
	FROM DMHeader INNER JOIN ApDmDetl ON ApDmDetl.UniqDmHead = DMHeader.UNIQDMHEAD 
	---- 10/05/15 VL added next line, then comment out for now, create more detail tax records
	--LEFT OUTER JOIN DmTaxDetail ON DmTaxDetail.UNIQDMDETL = ApDmDetl.UNIQDMDETL
	INNER JOIN GL_NBRS on  ApDmDetl.Gl_nbr = gl_nbrs.gl_nbr
	),
	-- 10/06/15 VL changed not use ApSetup.STAX_GL_NO but use ApDmDetlTax.Tax_id linked to Taxtabl to get Gl_nbr
	--DmTax as
	--(
	--SELECT DMDetails.Trans_dt,
	--	DMDetails.UniqSupno, 
	--	DMDetails.DMemoNo ,
	--	DMDetails.UniqDmHead,
	--	DMDetails.UNIQDMDETL,
	--	DMDetails.TAX ,  
	--	DMDetails.STAX_GL_NO AS GL_NBR, 
	--	GL_NBRS.Gl_Descr,
	--	DMDetails.TransactionType, 
	--	DMDetails.SourceTable,
	--	DMDetails.cIdentifier,
	--	DMDetails.cDrill,
	--	DMDetails.SourceSubTable,
	--	DMDetails.cSubIdentifier,
	--	DMDetails.cSubDrill, 
	--	CASE WHEN DMDetails.TAX>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(DMDetails.TAX) END AS Debit,
	--	CASE WHEN DMDetails.TAX>0 THEN DMDetails.TAX ELSE CAST(0.00 as numeric(14,2)) END as Credit, 
	--	DMDetails.FY,DMDetails.Period ,DMDetails.fk_fyDtlUniq  
	--FROM DMDetails INNER JOIN GL_NBRS on  DMDetails.STAX_GL_NO = gl_nbrs.gl_nbr	
	--WHERE DMDetails.TAX<>0	
	--) 
	DmTax AS
	(
	SELECT DMDetails.Trans_Dt,
		DMDetails.UniqSupno, 
		DMDetails.DMemoNo ,
		DMDetails.UniqDmHead,
		DMDetails.UNIQDMDETL,
		ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) as TAX,
		Taxtabl.Gl_nbr_in AS Gl_nbr,
		GL_NBRS.Gl_Descr,
		DMDetails.TransactionType, 
		DMDetails.SourceTable,
		DMDetails.cIdentifier,
		DMDetails.cDrill,
		CAST('ApDmDetlTax' AS VARCHAR(25)) AS SourceSubTable,
		'UNIQAPDMDETLTAX' AS cSubIdentifier,
		ApDmDetlTax.UniqApDmDetlTax AS cSubDrill, 
		CASE WHEN ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) > 0 
			THEN CAST(0.00 as numeric(14,2)) 
			ELSE ABS(ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00)) END AS Debit,
		CASE WHEN ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) > 0 
			THEN ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00)
			ELSE CAST(0.00 as numeric(14,2)) END as Credit, 
		DMDetails.FY,DMDetails.Period ,DMDetails.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/19/16 VL added functional and presentation currency fields     
		ISNULL(ROUND(((DMDetails.Price_EachPR * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) as TAXPR,
		CASE WHEN ISNULL(ROUND(((DMDetails.Price_EachPR * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) > 0 
			THEN CAST(0.00 as numeric(14,2)) 
			ELSE ABS(ISNULL(ROUND(((DMDetails.Price_EachPR * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00)) END AS DebitPR,
		CASE WHEN ISNULL(ROUND(((DMDetails.Price_EachPR * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) > 0 
			THEN ISNULL(ROUND(((DMDetails.Price_EachPR * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00)
			ELSE CAST(0.00 as numeric(14,2)) END as CreditPR, 
		Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq  
	FROM DmDetails INNER JOIN ApDmDetlTax On DmDetails.UniqDmDetl = ApDmDetlTax.UniqDmDetl
		INNER JOIN Taxtabl ON ApDmDetlTax.Tax_id = Taxtabl.Tax_id 
		INNER JOIN Gl_nbrs ON Taxtabl.Gl_nbr_in = Gl_nbrs.Gl_nbr
	WHERE ApDmDetlTax.Tax_rate <> 0
	),
	DmTax0 AS
	(
	SELECT DMDetails.Trans_Dt,
		DMDetails.UniqSupno, 
		DMDetails.DMemoNo ,
		DMDetails.UniqDmHead,
		DMDetails.UNIQDMDETL,
		ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) as TAX,
		Taxtabl.Gl_nbr_in AS Gl_nbr,
		GL_NBRS.Gl_Descr,
		DMDetails.TransactionType, 
		DMDetails.SourceTable,
		DMDetails.cIdentifier,
		DMDetails.cDrill,
		CAST('ApDmDetlTax' AS VARCHAR(25)) AS SourceSubTable,
		'UNIQAPDMDETLTAX' AS cSubIdentifier,
		ApDmDetlTax.UniqApDmDetlTax AS cSubDrill, 
		CASE WHEN ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) > 0 
			THEN CAST(0.00 as numeric(14,2)) 
			ELSE ABS(ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00)) END AS Debit,
		CASE WHEN ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) > 0 
			THEN ISNULL(ROUND(((DMDetails.Price_Each * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00)
			ELSE CAST(0.00 as numeric(14,2)) END as Credit, 
		DMDetails.FY,DMDetails.Period ,DMDetails.fk_fyDtlUniq, 'TAX0      ' AS AtdUniq_key,
		-- 12/19/16 VL added functional and presentation currency fields     
		ISNULL(ROUND(((DMDetails.Price_EachPR * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) as TAXPR,
		CASE WHEN ISNULL(ROUND(((DMDetails.Price_EachPR * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) > 0 
			THEN CAST(0.00 as numeric(14,2)) 
			ELSE ABS(ISNULL(ROUND(((DMDetails.Price_EachPR * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00)) END AS DebitPR,
		CASE WHEN ISNULL(ROUND(((DMDetails.Price_EachPR * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00) > 0 
			THEN ISNULL(ROUND(((DMDetails.Price_EachPR * DMDetails.Qty_Each) * ApDmDetlTax.Tax_Rate/100),2),0.00)
			ELSE CAST(0.00 as numeric(14,2)) END as CreditPR, 
		Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq     
	FROM DmDetails INNER JOIN ApDmDetlTax On DmDetails.UniqDmDetl = ApDmDetlTax.UniqDmDetl
		INNER JOIN Taxtabl ON ApDmDetlTax.Tax_id = Taxtabl.Tax_id 
		INNER JOIN Gl_nbrs ON Taxtabl.Gl_nbr_in = Gl_nbrs.Gl_nbr
	WHERE ApDmDetlTax.Tax_rate = 0
	)
	-- 10/06/15 VL End}
	, FinalDm as
	(
	SELECT cast(0 as bit) as lSelect,Trans_DT,GL_NBR,Gl_Descr,UniqSupNo,DMemoNo,DMemoNo as DisplayValue,
		TransactionType ,SourceTable,
		cIdentifier,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill, 
		Debit,Credit,
		FY,Period,fk_Fydtluniq, AtdUniq_key,
		-- 12/19/16 VL added functional and presentation currency fields   
		DebitPR,CreditPR,Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq     
	 FROM DMHeader 
	 UNION ALl
	 SELECT cast(0 as bit) as lSelect,Trans_DT,GL_NBR,Gl_Descr,UniqSupNo,DMemoNo,DMemoNo as DisplayValue,
		TransactionType ,SourceTable,
		cIdentifier,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill, 
		Debit,Credit,
		FY,Period,fk_Fydtluniq, AtdUniq_key,
		-- 12/19/16 VL added functional and presentation currency fields   
		DebitPR,CreditPR,Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq     
	 FROM DMDiscount 
	 UNION ALL
	 SELECT cast(0 as bit) as lSelect,Trans_DT,GL_NBR,Gl_Descr,UniqSupNo,DMemoNo,DMemoNo as DisplayValue,
		TransactionType ,SourceTable,
		cIdentifier,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill, 
		Debit,Credit,
		FY,Period,fk_Fydtluniq, AtdUniq_key,
		-- 12/19/16 VL added functional and presentation currency fields   
		DebitPR,CreditPR,Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq     
	 FROM DMDetails   
	 UNION ALL
	 SELECT cast(0 as bit) as lSelect,Trans_DT,GL_NBR,Gl_Descr,UniqSupNo,DMemoNo,DMemoNo as DisplayValue,
		TransactionType ,SourceTable,
		cIdentifier,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill, 
		Debit,Credit,
		FY,Period,fk_Fydtluniq, AtdUniq_key,
		-- 12/19/16 VL added functional and presentation currency fields   
		DebitPR,CreditPR,Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq     
	 FROM DmTax   
	 -- 10/06/15 VL added DmTax0 if any tax rate 0 records exist
	 UNION ALL
	 SELECT cast(0 as bit) as lSelect,Trans_DT,GL_NBR,Gl_Descr,UniqSupNo,DMemoNo,DMemoNo as DisplayValue,
		TransactionType ,SourceTable,
		cIdentifier,cDrill ,
		SourceSubTable,cSubIdentifier,cSubDrill, 
		Debit,Credit,
		FY,Period,fk_Fydtluniq, AtdUniq_key,
		-- 12/19/16 VL added functional and presentation currency fields   
		DebitPR,CreditPR,Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq     
	 FROM DmTax0 
	-- 10/06/15 VL End}
	 )
	 SELECT FinalDm.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY DMemoNo) as GroupIdNumber FROM FinalDm ORDER BY DMemoNo

	 END
	
END