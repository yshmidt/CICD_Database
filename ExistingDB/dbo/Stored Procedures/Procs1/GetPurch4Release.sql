-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/31/2011
-- Description:	Get AP transactions for release (exclude prepay and DM)
-- Modified:  04/30/14 YS when selecting invoices check for APTYPE<>'DM' to remove general Debit Memo
-- 10/16/15 VL Added FC currency and AtdUniq_key fields
-- 12/11/15 VL added ApdetailTax.UniqApdetl = PurchCredit.UniqApDetl
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 07/13/16 VL added AND ApdetailTax.UniqApdetl = PurchCredit.UniqApDetl in Tax SQL
-- 12/21/16 VL added functional and presentation currency fields
-- 05/09/17 VL Found an issue that the invamount calculated from apdetail (ApDetail.Qty_each*ApDetail.Price_each) sometimes won't match the apmaster.invAmount directly converted from invamount, it's due to extended has rounded to 2 decimal places,
-- need to get the rounding difference and add into GL records with Rouding GL numbers
-- 05/26/17 VL filter out if debit/credit<>0 in rounding cursor, also convert PR values 
-- 06/09/17 VL separate currency translation variance into two parts:functional currency and presentation currency and into two different GL accounts
-- =============================================
CREATE PROCEDURE [dbo].[GetPurch4Release]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @T as dbo.AllFYPeriods
INSERT INTO @T EXEC GlFyrstartEndView	;
-- 10/13/15 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
	BEGIN    

	;WITH PurchDebit as
	(
	SELECT Trans_dt, SupName , 
			PoNum , InvNo, InvAmount ,ApMaster.Tax,
			UniqApHead ,
			ApSetUp.Ap_Gl_no,ApSetup.Stax_Gl_No,
			ApSetUp.Ap_Gl_no as GL_nbr,Gl_nbrs.GL_DESCR ,
			CASE WHEN InvAmount>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(InvAmount) END AS Debit,
			CASE WHEN InvAmount>0 THEN InvAmount ELSE CAST(0.00 as numeric(14,2))  END AS Credit,
			CAST('PURCH' as varchar(50)) as TransactionType, 
			CAST('Apmaster' as varchar(25)) as SourceTable,
			'UniqApHead' as cIdentifier,
			apmaster.uniqaphead as cDrill,
			CAST('Apmaster' as varchar(25)) as SourceSubTable,
			'UniqApHead' as cSubIdentifier,
			apmaster.uniqaphead as cSubDrill,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fydtluniq, SPACE(10) AS AtdUniq_key
		FROM ApMaster INNER JOIN  SupInfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO 
		OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(Trans_dt as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		CROSS JOIN Apsetup
		INNER JOIN GL_NBRS ON Apsetup.Ap_Gl_no=gl_nbrs.GL_NBR 
		WHERE Is_Rel_Gl =0
			AND ApMaster.ApStatus <> 'Deleted' 
			---04/30/14 YS when selecting invoices check for APTYPE<>'DM' to remove general Debit Memo
			--AND LEFT(InvNo,2) <> 'DM' 
			AND Apmaster.Aptype<>'DM'
			AND lPrepay=0
		),
		PurchCredit as
		(
		-- 10/12/15 VL added Is_tax, Qty_each and Price_each to be used in PurchTaxTr for calculating tax
		-- 10/19/15 VL added Item_no
		SELECT PurchDebit.Trans_dt, PurchDebit.SupName , 
			PurchDebit.PoNum , PurchDebit.InvNo, PurchDebit.InvAmount ,PurchDebit.Tax,
			PurchDebit.UniqApHead ,ApDetail.UNIQAPDETL, 
			ApDetail.GL_nbr,Gl_nbrs.GL_DESCR,
			CASE WHEN ROUND(ApDetail.Qty_each*ApDetail.Price_each,2)>0 THEN ROUND(ApDetail.Qty_each*ApDetail.Price_each,2) ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
			CASE WHEN ROUND(ApDetail.Qty_each*ApDetail.Price_each,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(ApDetail.Qty_each*ApDetail.Price_each,2)) END AS Credit,
			PurchDebit.TransactionType, 
			SourceTable, 
			cIdentifier,
			cDrill,
			'APDETAIL' AS SourceSubTable,
			'UniqApDetl' as cSubIdentifier,
			apdetail.uniqapdetl as cSubDrill,
			PurchDebit.FY,PurchDebit.Period ,PurchDebit.fk_fyDtlUniq,
			Is_tax, Qty_each, Price_each, SPACE(10) AS AtdUniq_key, Item_no
			FROM PurchDebit inner join APDETAIL on PurchDebit.UNIQAPHEAD = APDETAIL.UNIQAPHEAD  
			INNER JOIN GL_NBRS on ApDetail.GL_nbr=Gl_nbrs.gl_nbr
		),
		-- 10/12/15 VL changed tax, now has tax detail tables will get data from ApdetailTax
		--PurchTaxTr as 
		--(
		--	SELECT PurchDebit.Trans_dt, PurchDebit.SupName , 
		--	PurchDebit.PoNum , PurchDebit.InvNo, PurchDebit.InvAmount ,PurchDebit.Tax,
		--	PurchDebit.UniqApHead  ,
		--	PurchDebit.Stax_Gl_No AS GL_nbr,gl_nbrs.GL_DESCR, 
		--	CASE WHEN PurchDebit.Tax>0 THEN PurchDebit.Tax ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
		--	CASE WHEN PurchDebit.Tax>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(PurchDebit.Tax) END AS Credit,
		--	PurchDebit.TransactionType, 
		--	SourceTable, 
		--	cIdentifier,
		--	cDrill,
		--	'APMASTER' AS SourceSubTable,
		--	'UniqAPHead' as cSubIdentifier,
		--	PurchDebit.uniqaphead as cSubDrill,
		--	PurchDebit.FY,PurchDebit.Period ,PurchDebit.fk_fyDtlUniq
		--	FROM PurchDebit INNER JOIN GL_NBRS ON PurchDebit.Stax_Gl_No =Gl_nbrs.GL_NBR   
		--	where TAX<>0.00
		--),
		PurchTaxTr as 
		(
			-- Calculate tax from ApdetailTax and use gl_nbr from tax_id linked to taxtabl and also include 0 tax
			-- 12/11/15 VL added AND ApdetailTax.UniqApdetl = PurchCredit.UniqApDetl criteria
			SELECT PurchCredit.Trans_dt, PurchCredit.SupName , 
			PurchCredit.PoNum , PurchCredit.InvNo, PurchCredit.InvAmount ,PurchCredit.Tax,
			PurchCredit.UniqApHead  ,
			Taxtabl.Gl_nbr_in as Gl_nbr,gl_nbrs.GL_DESCR, 
			CASE WHEN Is_tax = 1 THEN 
					CASE WHEN ROUND(Qty_each*Price_each*ApdetailTax.Tax_rate/100,2) > 0 THEN ROUND(Qty_each*Price_each*ApdetailTax.Tax_rate/100,2) ELSE CAST(0.00 as numeric(14,2)) END 
				ELSE
					CAST(0.00 as numeric(14,2)) END AS Debit,
			CASE WHEN Is_tax = 1 THEN
					CASE WHEN ROUND(Qty_each*Price_each*ApdetailTax.Tax_rate/100,2) > 0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Qty_each*Price_each*ApdetailTax.Tax_rate/100,2)) END
				ELSE
					CAST(0.00 as numeric(14,2)) END AS Credit,
			PurchCredit.TransactionType, 
			SourceTable, 
			cIdentifier,
			cDrill,
			'APDETAILTAX' AS SourceSubTable,
			'UniqApdetailTax' as cSubIdentifier,
			ApdetailTax.UniqApdetailTax as cSubDrill,
			PurchCredit.FY,PurchCredit.Period ,PurchCredit.fk_fyDtlUniq, 
			CASE WHEN ApdetailTax.Tax_rate = 0 THEN 'TAX0      ' ELSE SPACE(10) END AS AtdUniq_key
			FROM PurchCredit INNER JOIN ApdetailTax ON (ApdetailTax.UniqAphead = PurchCredit.UNIQAPHEAD
			AND ApdetailTax.UniqApdetl = PurchCredit.UniqApDetl)
			INNER JOIN Taxtabl ON Taxtabl.Tax_id = APDETAILTAX.Tax_id
			INNER JOIN Gl_nbrs ON Taxtabl.GL_NBR_in =gl_nbrs.gl_nbr 
			-- 10/19/15 VL filter out item_no = 99: freight amt and freight tax
			WHERE PurchCredit.Item_no<>99
		),

		FinalPurch AS
		(
		SELECT cast(0 as bit) as lSelect,Trans_dt, SupName , 
			PoNum , InvNo,
			CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(50)) as DisplayValue, 
			GL_NBR,Gl_descr,Debit,Credit,
			TransactionType, 
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			FY,Period ,fk_fyDtlUniq, AtdUniq_key
			FROM PurchDebit 
		UNION ALL
		SELECT cast(0 as bit) as lSelect, Trans_dt, SupName , 
			PoNum , InvNo,
			CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(50)) as DisplayValue, 
			GL_NBR,gl_descr,Debit,Credit,
			TransactionType, 
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			FY,Period ,fk_fyDtlUniq, AtdUniq_key
			FROM PurchCredit  
		UNION ALL
		SELECT cast(0 as bit) as lSelect,Trans_dt, SupName , 
			PoNum , InvNo,
			CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(50)) as DisplayValue, 
			GL_NBR,gl_descr,Debit,Credit,
			TransactionType, 
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			FY,Period ,fk_fyDtlUniq, AtdUniq_key
			FROM PurchTaxTr   )
	
		SELECT FinalPurch.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY PoNum,Trans_dt) as GroupIdNumber FROM FinalPurch ORDER BY PoNum,Trans_dt 
	 END
ELSE
	BEGIN
	;WITH PurchDebit as
	(
	SELECT Trans_dt, SupName , 
			PoNum , InvNo, InvAmount ,ApMaster.Tax,
			UniqApHead ,
			ApSetUp.Ap_Gl_no,ApSetup.Stax_Gl_No,
			ApSetUp.Ap_Gl_no as GL_nbr,Gl_nbrs.GL_DESCR ,
			CASE WHEN InvAmount>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(InvAmount) END AS Debit,
			CASE WHEN InvAmount>0 THEN InvAmount ELSE CAST(0.00 as numeric(14,2))  END AS Credit,
			CAST('PURCH' as varchar(50)) as TransactionType, 
			CAST('Apmaster' as varchar(25)) as SourceTable,
			'UniqApHead' as cIdentifier,
			apmaster.uniqaphead as cDrill,
			CAST('Apmaster' as varchar(25)) as SourceSubTable,
			'UniqApHead' as cSubIdentifier,
			apmaster.uniqaphead as cSubDrill,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fydtluniq, SPACE(10) AS AtdUniq_key,
			-- 12/21/16 VL added functional and presentation currency fields
			InvAmountPR ,ApMaster.TaxPR,
			CASE WHEN InvAmountPR>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(InvAmountPR) END AS DebitPR,
			CASE WHEN InvAmountPR>0 THEN InvAmountPR ELSE CAST(0.00 as numeric(14,2))  END AS CreditPR,
			FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency, TF.Symbol AS Transaction_Currency,
			Apmaster.FuncFcused_uniq, Apmaster.PrFcused_uniq,
			-- 05/09/17 VL added Fcused_uniq and Fchist_key and will be used to get rounding issue calculation later
			Apmaster.Fcused_Uniq, Fchist_key, InvAmountFC
  		FROM ApMaster
			INNER JOIN Fcused TF ON ApMaster.Fcused_uniq = TF.Fcused_uniq
	  		INNER JOIN Fcused PF ON ApMaster.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON ApMaster.FuncFcused_uniq = FF.Fcused_uniq
		INNER JOIN  SupInfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO 
		OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(Trans_dt as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		CROSS JOIN Apsetup
		INNER JOIN GL_NBRS ON Apsetup.Ap_Gl_no=gl_nbrs.GL_NBR 
		WHERE Is_Rel_Gl =0
			AND ApMaster.ApStatus <> 'Deleted' 
			---04/30/14 YS when selecting invoices check for APTYPE<>'DM' to remove general Debit Memo
			--AND LEFT(InvNo,2) <> 'DM' 
			AND Apmaster.Aptype<>'DM'
			AND lPrepay=0
		),
		PurchCredit as
		(
		-- 10/12/15 VL added Is_tax, Qty_each and Price_each to be used in PurchTaxTr for calculating tax
		-- 10/19/15 VL added item_no
		SELECT PurchDebit.Trans_dt, PurchDebit.SupName , 
			PurchDebit.PoNum , PurchDebit.InvNo, PurchDebit.InvAmount ,PurchDebit.Tax,
			PurchDebit.UniqApHead ,ApDetail.UNIQAPDETL, 
			ApDetail.GL_nbr,Gl_nbrs.GL_DESCR,
			CASE WHEN ROUND(ApDetail.Qty_each*ApDetail.Price_each,2)>0 THEN ROUND(ApDetail.Qty_each*ApDetail.Price_each,2) ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
			CASE WHEN ROUND(ApDetail.Qty_each*ApDetail.Price_each,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(ApDetail.Qty_each*ApDetail.Price_each,2)) END AS Credit,
			PurchDebit.TransactionType, 
			SourceTable, 
			cIdentifier,
			cDrill,
			'APDETAIL' AS SourceSubTable,
			'UniqApDetl' as cSubIdentifier,
			apdetail.uniqapdetl as cSubDrill,
			PurchDebit.FY,PurchDebit.Period ,PurchDebit.fk_fyDtlUniq,
			Is_tax, Qty_each, Price_each, SPACE(10) AS AtdUniq_key, Item_no,
			-- 12/21/16 VL added functional and presentation currency fields
			PurchDebit.InvAmountPR ,PurchDebit.TaxPR,
			CASE WHEN ROUND(ApDetail.Qty_each*ApDetail.Price_eachPR,2)>0 THEN ROUND(ApDetail.Qty_each*ApDetail.Price_eachPR,2) ELSE CAST(0.00 as numeric(14,2)) END AS DebitPR,
			CASE WHEN ROUND(ApDetail.Qty_each*ApDetail.Price_eachPR,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(ApDetail.Qty_each*ApDetail.Price_eachPR,2)) END AS CreditPR,
			Price_eachPR,
			Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq  
			FROM PurchDebit inner join APDETAIL on PurchDebit.UNIQAPHEAD = APDETAIL.UNIQAPHEAD  
			INNER JOIN GL_NBRS on ApDetail.GL_nbr=Gl_nbrs.gl_nbr
		),
		-- 10/12/15 VL changed tax, now has tax detail tables will get data from ApdetailTax
		--PurchTaxTr as 
		--(
		--	SELECT PurchDebit.Trans_dt, PurchDebit.SupName , 
		--	PurchDebit.PoNum , PurchDebit.InvNo, PurchDebit.InvAmount ,PurchDebit.Tax,
		--	PurchDebit.UniqApHead  ,
		--	PurchDebit.Stax_Gl_No AS GL_nbr,gl_nbrs.GL_DESCR, 
		--	CASE WHEN PurchDebit.Tax>0 THEN PurchDebit.Tax ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
		--	CASE WHEN PurchDebit.Tax>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(PurchDebit.Tax) END AS Credit,
		--	PurchDebit.TransactionType, 
		--	SourceTable, 
		--	cIdentifier,
		--	cDrill,
		--	'APMASTER' AS SourceSubTable,
		--	'UniqAPHead' as cSubIdentifier,
		--	PurchDebit.uniqaphead as cSubDrill,
		--	PurchDebit.FY,PurchDebit.Period ,PurchDebit.fk_fyDtlUniq
		--	FROM PurchDebit INNER JOIN GL_NBRS ON PurchDebit.Stax_Gl_No =Gl_nbrs.GL_NBR   
		--	where TAX<>0.00
		--),
		PurchTaxTr as 
		(
			-- Calculate tax from ApdetailTax and use gl_nbr from tax_id linked to taxtabl and also include 0 tax
			SELECT PurchCredit.Trans_dt, PurchCredit.SupName , 
			PurchCredit.PoNum , PurchCredit.InvNo, PurchCredit.InvAmount ,PurchCredit.Tax,
			PurchCredit.UniqApHead  ,
			Taxtabl.Gl_nbr_in as Gl_nbr,gl_nbrs.GL_DESCR, 
			CASE WHEN Is_tax = 1 THEN 
					CASE WHEN ROUND(Qty_each*Price_each*ApdetailTax.Tax_rate/100,2) > 0 THEN ROUND(Qty_each*Price_each*ApdetailTax.Tax_rate/100,2) ELSE CAST(0.00 as numeric(14,2)) END 
				ELSE
					CAST(0.00 as numeric(14,2)) END AS Debit,
			CASE WHEN Is_tax = 1 THEN
					CASE WHEN ROUND(Qty_each*Price_each*ApdetailTax.Tax_rate/100,2) > 0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Qty_each*Price_each*ApdetailTax.Tax_rate/100,2)) END
				ELSE
					CAST(0.00 as numeric(14,2)) END AS Credit,
			PurchCredit.TransactionType, 
			SourceTable, 
			cIdentifier,
			cDrill,
			'APDETAILTAX' AS SourceSubTable,
			'UniqApdetailTax' as cSubIdentifier,
			ApdetailTax.UniqApdetailTax as cSubDrill,
			PurchCredit.FY,PurchCredit.Period ,PurchCredit.fk_fyDtlUniq, 
			CASE WHEN ApdetailTax.Tax_rate = 0 THEN 'TAX0      ' ELSE SPACE(10) END AS AtdUniq_key,
			-- 12/21/16 VL added functional and presentation currency fields
			PurchCredit.InvAmountPR ,PurchCredit.TaxPR,
			CASE WHEN Is_tax = 1 THEN 
					CASE WHEN ROUND(Qty_each*Price_eachPR*ApdetailTax.Tax_rate/100,2) > 0 THEN ROUND(Qty_each*Price_eachPR*ApdetailTax.Tax_rate/100,2) ELSE CAST(0.00 as numeric(14,2)) END 
				ELSE
					CAST(0.00 as numeric(14,2)) END AS DebitPR,
			CASE WHEN Is_tax = 1 THEN
					CASE WHEN ROUND(Qty_each*Price_eachPR*ApdetailTax.Tax_rate/100,2) > 0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Qty_each*Price_eachPR*ApdetailTax.Tax_rate/100,2)) END
				ELSE
					CAST(0.00 as numeric(14,2)) END AS CreditPR,
			Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq  
			FROM PurchCredit INNER JOIN ApdetailTax ON (ApdetailTax.UniqAphead = PurchCredit.UNIQAPHEAD
			-- 07/13/16 VL added next line
			AND ApdetailTax.UniqApdetl = PurchCredit.UniqApDetl)
			INNER JOIN Taxtabl ON Taxtabl.Tax_id = APDETAILTAX.Tax_id
			INNER JOIN Gl_nbrs ON Taxtabl.GL_NBR_in =gl_nbrs.gl_nbr
			-- 10/19/15 VL filter out item_no = 99: freight amt and freight tax
			WHERE PurchCredit.Item_no<>99
		),
		-- 05/09/17 VL added to get the rounding difference caused by calculating HC values directly from FC total value (not from Apdetail)
		APFC2HC AS
		(
		SELECT PurchDebit.Trans_dt, PurchDebit.SupName , 
			PurchDebit.PoNum , PurchDebit.InvNo, PurchDebit.InvAmount ,PurchDebit.Tax,
			PurchDebit.UniqApHead, PurchDebit.Gl_nbr, PurchDebit.Gl_DESCR, 
			CASE WHEN ROUND(dbo.fn_Convert4FCHC('F',PurchDebit.Fcused_uniq, PurchDebit.InvAmountFC, dbo.fn_GetFunctionalCurrency(), PurchDebit.Fchist_key),2) - PurchDebit.InvAmount>0 THEN CAST(0.00 as numeric(14,2)) 
				ELSE ABS(ROUND(dbo.fn_Convert4FCHC('F',PurchDebit.Fcused_uniq, PurchDebit.InvAmountFC, dbo.fn_GetFunctionalCurrency(), PurchDebit.Fchist_key),2) - PurchDebit.InvAmount) END AS Debit,
			CASE WHEN ROUND(dbo.fn_Convert4FCHC('F',PurchDebit.Fcused_uniq, PurchDebit.InvAmountFC, dbo.fn_GetFunctionalCurrency(), PurchDebit.Fchist_key),2) - PurchDebit.InvAmount>0 THEN
				ROUND(dbo.fn_Convert4FCHC('F',PurchDebit.Fcused_uniq, PurchDebit.InvAmountFC, dbo.fn_GetFunctionalCurrency(), PurchDebit.Fchist_key),2) - PurchDebit.InvAmount ELSE CAST(0.00 as numeric(14,2)) END AS Credit,
			CAST('PURCH' as varchar(50)) as TransactionType, 
			CAST('Apmaster' as varchar(25)) as SourceTable,
			'UniqApHead' as cIdentifier,
			cDrill,
			CAST('Apmaster' as varchar(25)) as SourceSubTable,
			'UniqApHead' as cSubIdentifier,
			cSubDrill,
			FY, Period, fk_fydtluniq, SPACE(10) AS AtdUniq_key,
			InvAmountPR, TaxPR, 
			-- 05/26/17 VL changed from took DebitPR, CreditPR directly from PurchDebit to convert from FC values
			CASE WHEN ROUND(dbo.fn_Convert4FCHC('F',PurchDebit.Fcused_uniq, PurchDebit.InvAmountFC, dbo.fn_GetPresentationCurrency(), PurchDebit.Fchist_key),2) - PurchDebit.InvAmountPR>0 THEN CAST(0.00 as numeric(14,2)) 
				ELSE ABS(ROUND(dbo.fn_Convert4FCHC('F',PurchDebit.Fcused_uniq, PurchDebit.InvAmountFC, dbo.fn_GetPresentationCurrency(), PurchDebit.Fchist_key),2) - PurchDebit.InvAmountPR) END AS DebitPR,
			CASE WHEN ROUND(dbo.fn_Convert4FCHC('F',PurchDebit.Fcused_uniq, PurchDebit.InvAmountFC, dbo.fn_GetPresentationCurrency(), PurchDebit.Fchist_key),2) - PurchDebit.InvAmountPR>0 THEN
				ROUND(dbo.fn_Convert4FCHC('F',PurchDebit.Fcused_uniq, PurchDebit.InvAmountFC, dbo.fn_GetPresentationCurrency(), PurchDebit.Fchist_key),2) - PurchDebit.InvAmountPR ELSE CAST(0.00 as numeric(14,2)) END AS CreditPR,
			Functional_Currency, Presentation_Currency, Transaction_Currency, FuncFcused_uniq, PrFcused_uniq
			FROM PurchDebit
			-- 05/26/17 VL added to filter out if no rounding difference is created
			-- 06/09/17 VL added also consider if PR value <> 0
			WHERE (ROUND(dbo.fn_Convert4FCHC('F',PurchDebit.Fcused_uniq, PurchDebit.InvAmountFC, dbo.fn_GetFunctionalCurrency(), PurchDebit.Fchist_key),2) - PurchDebit.InvAmount<>0
			OR ROUND(dbo.fn_Convert4FCHC('F',PurchDebit.Fcused_uniq, PurchDebit.InvAmountFC, dbo.fn_GetPresentationCurrency(), PurchDebit.Fchist_key),2) - PurchDebit.InvAmountPR<>0)
			
		)
		,
		-- 06/09/17 VL separate currency translation variance into two parts:functional currency and presentation currency and into two different GL accounts
		--ROUNDING AS
		--(
		--SELECT Trans_dt, Supname, Ponum, Invno, InvAmount, Tax, UniqApHead, Rundvar_gl AS Gl_nbr, gl_nbrs.GL_DESCR,
		--	Credit AS Debit, Debit AS Credit, TransactionType, SourceTable, cIdentifier, cDrill, SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fydtluniq, AtdUniq_key,
		--	InvAmountPR, TaxPR, DebitPR, CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency, FuncFcused_uniq, PrFcused_uniq 
		--	FROM APFC2HC
		--	CROSS JOIN Invsetup
		--	INNER JOIN GL_NBRS ON Invsetup.Rundvar_gl=gl_nbrs.GL_NBR 
		--),
		RoundingFUNC AS
		(
		SELECT Trans_dt, Supname, Ponum, Invno, InvAmount, Tax, UniqApHead, CTVFUNC_GL_NO AS Gl_nbr, gl_nbrs.GL_DESCR,
			Credit AS Debit, Debit AS Credit, TransactionType, SourceTable, cIdentifier, cDrill, SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fydtluniq, AtdUniq_key,
			InvAmountPR, TaxPR, 0 AS DebitPR, 0 AS CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency, FuncFcused_uniq, PrFcused_uniq 
			FROM APFC2HC
			CROSS JOIN APSetup
			INNER JOIN GL_NBRS ON ApSetup.CTVFUNC_GL_NO=gl_nbrs.GL_NBR 
			WHERE (Credit<>0 OR Debit<>0)
		),
		RoundingPR AS
		(
		SELECT Trans_dt, Supname, Ponum, Invno, InvAmount, Tax, UniqApHead, CTVPR_GL_NO AS Gl_nbr, gl_nbrs.GL_DESCR,
			0 AS Debit, 0 AS Credit, TransactionType, SourceTable, cIdentifier, cDrill, SourceSubTable, cSubIdentifier, cSubDrill, FY, Period, fk_fydtluniq, AtdUniq_key,
			InvAmountPR, TaxPR, CreditPR AS DebitPR, DebitPR AS CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency, FuncFcused_uniq, PrFcused_uniq 
			FROM APFC2HC
			CROSS JOIN APSetup
			INNER JOIN GL_NBRS ON ApSetup.CTVPR_GL_NO=gl_nbrs.GL_NBR 
			WHERE (CreditPR<>0 OR DebitPR<>0)
		),
		-- 05/19/17 VL End}


		FinalPurch AS
		(
		SELECT cast(0 as bit) as lSelect,Trans_dt, SupName , 
			PoNum , InvNo,
			CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(50)) as DisplayValue, 
			GL_NBR,Gl_descr,Debit,Credit,
			TransactionType, 
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			FY,Period ,fk_fyDtlUniq, AtdUniq_key,
			-- 12/21/16 VL added functional and presentation currency fields
			DebitPR,CreditPR,Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq  
			FROM PurchDebit 
		UNION ALL
		SELECT cast(0 as bit) as lSelect, Trans_dt, SupName , 
			PoNum , InvNo,
			CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(50)) as DisplayValue, 
			GL_NBR,gl_descr,Debit,Credit,
			TransactionType, 
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			FY,Period ,fk_fyDtlUniq, AtdUniq_key,
			-- 12/21/16 VL added functional and presentation currency fields
			DebitPR,CreditPR,Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq  
			FROM PurchCredit  
		UNION ALL
		SELECT cast(0 as bit) as lSelect,Trans_dt, SupName , 
			PoNum , InvNo,
			CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(50)) as DisplayValue, 
			GL_NBR,gl_descr,Debit,Credit,
			TransactionType, 
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			FY,Period ,fk_fyDtlUniq, AtdUniq_key,
			-- 12/21/16 VL added functional and presentation currency fields
			DebitPR,CreditPR,Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq  
			FROM PurchTaxTr
		-- 05/09/17 VL added rounding GL records
		UNION ALL
		SELECT cast(0 as bit) as lSelect,Trans_dt, SupName , 
			PoNum , InvNo,
			CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(50)) as DisplayValue, 
			GL_NBR,Gl_descr,Debit,Credit,
			TransactionType, 
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			FY,Period ,fk_fyDtlUniq, AtdUniq_key,
			DebitPR,CreditPR,Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq  
			FROM APFC2HC
		UNION ALL
		-- 06/09/17 VL separate currency translation variance into two parts:functional currency and presentation currency and into two different GL accounts
		--SELECT cast(0 as bit) as lSelect,Trans_dt, SupName , 
		--	PoNum , InvNo,
		--	CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(50)) as DisplayValue, 
		--	GL_NBR,Gl_descr,Debit,Credit,
		--	TransactionType, 
		--	SourceTable,
		--	cIdentifier,
		--	cDrill,
		--	SourceSubTable,
		--	cSubIdentifier,
		--	cSubDrill,
		--	FY,Period ,fk_fyDtlUniq, AtdUniq_key,
		--	DebitPR,CreditPR,Functional_Currency, Presentation_Currency, Transaction_Currency,
		--	FuncFcused_uniq, PrFcused_uniq  
		--	FROM ROUNDING
		SELECT cast(0 as bit) as lSelect,Trans_dt, SupName , 
			PoNum , InvNo,
			CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(50)) as DisplayValue, 
			GL_NBR,Gl_descr,Debit,Credit,
			TransactionType, 
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			FY,Period ,fk_fyDtlUniq, AtdUniq_key,
			DebitPR,CreditPR,Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq  
			FROM RoundingFunc
		UNION ALL
		SELECT cast(0 as bit) as lSelect,Trans_dt, SupName , 
			PoNum , InvNo,
			CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(50)) as DisplayValue, 
			GL_NBR,Gl_descr,Debit,Credit,
			TransactionType, 
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			FY,Period ,fk_fyDtlUniq, AtdUniq_key,
			DebitPR,CreditPR,Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq  
			FROM RoundingPR
		-- 06/09/17 VL End}
		 )
	
		SELECT FinalPurch.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY PoNum,Trans_dt) as GroupIdNumber FROM FinalPurch ORDER BY PoNum,Trans_dt 
	END

END