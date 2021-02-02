-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/01/2011
-- Description:	Get Sales info to release
-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
-- 09/25/15 VL Added for 0 amount tax from plpricestax and plfreighttax because 0 tax won't be saved in invstdtx, but Malaysia tax system needs 0% tax saved in records
--			   Also added AtdUniq_key to each CTE cursor
-- 10/14/15 VL Added Currency field
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 07/13/16 VL Comment out SalesTax0 and FreightTax0 CTE cursor, now we have changed to save 0 amount tax in Invstdtx, so no need this duplicate records
-- 12/09/16 VL Added presentation currency fields
-- 03/07/17 YS remove leading zero in displayvalye for the invoices
-- 06/09/17 VL Found an issue that the invtotal calculated from plprices sometimes won't match the plmain.invtotal directly converted from invtotalfc, it's due to extended has rounded to 2 decimal places,
-- need to get the rounding difference and add into GL records with Rouding GL numbers, separate currency translation variance into two parts:functional currency and presentation currency and into two different GL accounts
-- 06/22/17 VL Found in the last FinalSales cursor, forgot to add ARFC2HC, also added ABS() in ARFC2HC
-- =============================================
CREATE PROCEDURE [dbo].[GetSales4Release]
	
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
	with SalesInfo AS
	(
 
	SELECT InvDate as Trans_Dt, CustName ,
			InvoiceNo , InvTotal , Sono,
			PacklistNo,FreightAmt, 
			-- 03/07/17 YS remove leading zero in displayvalye for the invoices
			--CAST('Customer: '+RTRIM(CustName)+', Invoice: '+InvoiceNo as varchar(50)) as DisplayValue,
			CAST(' Inv #: '+dbo.fRemoveLeadingZeros(InvoiceNo)+ ', Cust: '+RTRIM(CustName) as varchar(50)) as DisplayValue,
			TotTaxe,  TotTaxf, DsctAmt,
			Frt_Gl_No, Fc_Gl_No, Disc_gl_no, Ar_Gl_no, 
			PTax, STax ,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq
		FROM  PlMain INNER JOIN Customer ON PlMain.CustNo = Customer.CustNo 
		OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
				WHERE CAST(InvDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
			WHERE PlMain.Is_InvPost =1
			AND  PlMain.Is_Rel_Gl =0
	),
	AR as
	(
		SELECT Trans_dt,CUSTNAME,INVOICENO ,packlistno,
		DisplayValue,
		CASE WHEN InvTotal>0 THEN INVTOTAL ELSE CAST(0.0 as numeric(14,2)) END as Debit,
		CASE WHEN InvTotal>0 THEN CAST(0.0 as numeric(14,2))  ELSE INVTOTAL END as Credit,
		Ar_Gl_no as GL_nbr,gl_nbrs.GL_DESCR,
		CAST('SALES' as varchar(50)) as TransactionType, 
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('PlMain' as varchar(25)) as SourceSubTable,
		'PackListno' as cSubIdentifier,
		SalesInfo.PACKLISTNO as cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
		FROM SalesInfo inner join gl_nbrs on SalesInfo.AR_GL_NO = gl_nbrs.GL_NBR 
		-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
		--where  INVTOTAL<>0.00
	),
	SalesTax as 
	(
	SELECT SalesInfo.Trans_Dt,SalesInfo.CustName,
		SalesInfo.INVOICENO ,
		SalesInfo.PackListno,
		SalesInfo.DisplayValue,
		CAST('SALES' as varchar(50)) as TransactionType,
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('InvStdTx' AS VARCHAR(25)) AS SourceSubTable,
		'INVSTDTXUNIQ' as cSubIdentifier,
		Invstdtx.INVSTDTXUNIQ as cSubDrill,
		CASE WHEN Invstdtx.Tax_Amt>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(Invstdtx.Tax_Amt) END AS Debit,
		CASE WHEN Invstdtx.Tax_Amt>0 THEN Invstdtx.Tax_Amt ELSE CAST(0.00 as numeric(14,2)) END as Credit ,
		Invstdtx.Gl_nbr_out as Gl_nbr,Gl_nbrs.GL_DESCR,
		SalesInfo.FY,SalesInfo.Period ,SalesInfo.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
		FROM SalesInfo INNER JOIN InvStdTx ON InvStdTx.Packlistno =SalesInfo.Packlistno 
		INNER JOIN GL_NBRS on INVSTDTX.GL_NBR_OUT =gl_nbrs.gl_nbr 
		WHERE InvStdTx.INVOICENO = ' '
	),
	-- 07/13/16 VL Comment out SalesTax0 and FreightTax0 CTE cursor, now we have changed to save 0 amount tax in Invstdtx, so no need this duplicate records
	---- 09/25/15 VL added tax records with 0% rate, Maylaysia tax might have 0 percent, but need to be saved, invstdtx didnt' save 0 amount tax, need to insert separately
	--SalesTax0 AS
	--(
	--	SELECT SalesInfo.Trans_Dt,SalesInfo.CustName,
	--	SalesInfo.INVOICENO ,
	--	SalesInfo.PackListno,
	--	SalesInfo.DisplayValue,
	--	CAST('SALES' as varchar(50)) as TransactionType,
	--	CAST('PlMain' as varchar(25)) as SourceTable,
	--	'PackListno' as cIdentifier,
	--	SalesInfo.PACKLISTNO as cDrill,
	--	CAST('PlPricesTax' AS VARCHAR(25)) AS SourceSubTable,
	--	'UNIQPLPRICESTAX' as cSubIdentifier,
	--	PlpricesTax.UniqPlpricesTax as cSubDrill,
	--	0 AS Debit,
	--	0 as Credit ,
	--	Taxtabl.Gl_nbr_out as Gl_nbr,Gl_nbrs.GL_DESCR,
	--	SalesInfo.FY,SalesInfo.Period ,SalesInfo.fk_fyDtlUniq, 'TAX0      ' AS AtdUniq_key
	--	FROM SalesInfo INNER JOIN PlpricesTax ON PlpricesTax.Packlistno =SalesInfo.Packlistno 
	--	INNER JOIN Taxtabl ON Taxtabl.Tax_id = PlpricesTax.Tax_id 
	--	INNER JOIN GL_NBRS on Taxtabl.GL_NBR_OUT =gl_nbrs.gl_nbr 
	--	WHERE PlpricesTax.Tax_Rate = 0
	--),
	--FreightTax0 AS
	--(
	--	SELECT SalesInfo.Trans_Dt,SalesInfo.CustName,
	--	SalesInfo.INVOICENO ,
	--	SalesInfo.PackListno,
	--	SalesInfo.DisplayValue,
	--	CAST('SALES' as varchar(50)) as TransactionType,
	--	CAST('PlMain' as varchar(25)) as SourceTable,
	--	'PackListno' as cIdentifier,
	--	SalesInfo.PACKLISTNO as cDrill,
	--	CAST('PlFreightTax' AS VARCHAR(25)) AS SourceSubTable,
	--	'UNIQPLFREIGHTTAX' as cSubIdentifier,
	--	PlFreightTax.UniqPlFreightTax as cSubDrill,
	--	0 AS Debit,
	--	0 as Credit ,
	--	Taxtabl.Gl_nbr_out as Gl_nbr,Gl_nbrs.GL_DESCR,
	--	SalesInfo.FY,SalesInfo.Period ,SalesInfo.fk_fyDtlUniq, 'TAX0      ' AS AtdUniq_key
	--	FROM SalesInfo INNER JOIN PlFreightTax ON PlFreightTax.Packlistno =SalesInfo.Packlistno 
	--	INNER JOIN Taxtabl ON Taxtabl.Tax_id = PlFreightTax.Tax_id 
	--	INNER JOIN GL_NBRS on Taxtabl.GL_NBR_OUT =gl_nbrs.gl_nbr 
	--	WHERE PlFreightTax.Tax_Rate = 0
	--),
	---- 09/25/15 VL End
	-- 07/13/16 VL End}
	SalesFreight AS
	(
		SELECT Trans_dt,CUSTNAME,INVOICENO ,packlistno,
		SalesInfo.DisplayValue,
		CASE WHEN FreightAmt>0 THEN CAST(0.0 as numeric(14,2)) ELSE ABS(FreightAmt) END as Debit,
		CASE WHEN FreightAmt>0 THEN FreightAmt ELSE CAST(0.0 as numeric(14,2)) END as Credit,
		Frt_Gl_No as GL_nbr,gl_nbrs.GL_DESCR,
		CAST('SALES' as varchar(50)) as TransactionType, 
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('PlMain' as varchar(25)) as SourceSubTable,
		'PackListno' as cSubIdentifier,
		SalesInfo.PACKLISTNO as cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
		FROM SalesInfo inner join gl_nbrs on salesinfo.FRT_GL_NO = gl_nbrs.gl_nbr  WHERE FreightAmt<>0.00
	),
	SalesDiscount AS
	(
		SELECT Trans_dt,CUSTNAME,INVOICENO ,packlistno,
		SalesInfo.DisplayValue,
		CASE WHEN DsctAmt>0 THEN DsctAmt ELSE CAST(0.0 as numeric(14,2)) END as Debit,
		CASE WHEN DsctAmt>0 THEN CAST(0.0 as numeric(14,2)) ELSE ABS(DsctAmt) END as Credit,
		Disc_gl_no as GL_nbr,gl_nbrs.GL_DESCR,
		CAST('SALES' as varchar(50)) as TransactionType, 
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('PlMain' as varchar(25)) as SourceSubTable,
		'PackListno' as cSubIdentifier,
		SalesInfo.PACKLISTNO as cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
		FROM SalesInfo inner join gl_nbrs on SalesInfo.DISC_GL_NO = gl_nbrs.gl_nbr WHERE DsctAmt<>0.00
	),
	SalesDetail as
	(
	SELECT SalesInfo.Trans_dt,SalesInfo.CUSTNAME,SalesInfo.INVOICENO ,
		SalesInfo.packlistno,SalesInfo.DisplayValue,
		Plprices.EXTENDED,PLPRICES.PLUNIQLNK ,
		CASE WHEN PlPrices.EXTENDED >0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(Plprices.EXTENDED) END AS Debit,
		CASE WHEN PlPrices.EXTENDED >0 THEN Plprices.EXTENDED ELSE CAST(0.00 as numeric(14,2)) END AS Credit,
		PlPrices.Pl_gl_nbr as Gl_nbr,gl_nbrs.GL_DESCR,
		CAST('SALES' as varchar(50)) as TransactionType, 
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('PlPrices' as varchar(25)) as SourceSubTable,
		'PLUNIQLNK'  as cSubIdentifier,
		PlPrices.PLUNIQLNK as cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
		FROM SalesInfo INNER JOIN PlPrices ON SalesInfo.Packlistno = PlPrices.Packlistno 
		inner join GL_NBRS on plprices.PL_GL_NBR = gl_nbrs.GL_NBR
			
	),
	CostOfGoods as
	(
	SELECT SalesInfo.Trans_dt,SalesInfo.CUSTNAME,SalesInfo.INVOICENO ,
		SalesInfo.packlistno,SalesInfo.DisplayValue,
		PP.uniqueln, PP.Cog_gl_nbr AS Gl_nbr, gl_nbrs.GL_DESCR,
		Invt_isu.StdCost, Invt_isu.Qtyisu , 
		CASE WHEN ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2)>0 THEN ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2) ELSE CAST(0.00 as numeric(14,2)) END  as Debit,
		CASE WHEN ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2))  END  as Credit,
		CAST('SALES' as varchar(50)) as TransactionType, 
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('Invt_isu' as varchar(25)) as SourceSubTable,
		'Invtisu_no'  as cSubIdentifier,
		Invt_isu.Invtisu_no as cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
		FROM SalesInfo INNER JOIN ( SELECT DISTINCT Packlistno,UniqueLn,Cog_Gl_nbr FROM PLPRICES where Plprices.RecordType <> 'O') PP ON SalesInfo.Packlistno = PP.Packlistno 
		INNER JOIN Invt_Isu ON Invt_isu.Uniqueln = PP.Uniqueln
		inner join GL_NBRS on PP.Cog_gl_nbr = gl_nbrs.GL_NBR
		WHERE  SUBSTRING(Invt_isu.ISSUEDTO,11,10) = SalesInfo.Packlistno
		-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
		--AND  Invt_isu.StdCost * Invt_Isu.QtyIsu<>0.00
				
	), FGIStndCOst AS
	(
	SELECT SalesInfo.Trans_dt,SalesInfo.CUSTNAME,SalesInfo.INVOICENO ,
		SalesInfo.packlistno,SalesInfo.DisplayValue,
		pldetail.uniqueln,
		PLDETAIL.INV_LINK, 
		Invt_Isu.QtyIsu ,
		invt_isu.Gl_nbr_inv  as Gl_nbr,gl_nbrs.GL_DESCR,
		Invt_isu.StdCost, 
		CASE WHEN ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2))  END  as Debit,
		CASE WHEN ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2)>0 THEN ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2) ELSE CAST(0.00 as numeric(14,2)) END  as Credit,
		CAST('SALES' as varchar(50)) as TransactionType, 
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('Invt_isu' as varchar(25)) as SourceSubTable,
		'Invtisu_no'  as cSubIdentifier,
		Invt_isu.Invtisu_no as cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
		FROM SalesInfo INNER JOIN PlDetail ON SalesInfo.Packlistno = PlDetail.Packlistno 
		INNER JOIN Invt_Isu ON Invt_isu.Uniqueln = PlDetail.Uniqueln
		inner join GL_NBRS on Invt_isu.GL_NBR_INV = gl_nbrs.gl_nbr
		WHERE  SUBSTRING(Invt_isu.ISSUEDTO,11,10) = SalesInfo.Packlistno
		-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
		--AND  Invt_isu.StdCost * Invt_Isu.QtyIsu<>0.00
	
	),FinalSales as (
	
		SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key 
				FROM AR
			UNION ALL
			SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key 
				FROM SalesTax 
			-- 07/13/16 VL Comment out SalesTax0 and FreightTax0 CTE cursor, now we have changed to save 0 amount tax in Invstdtx, so no need this duplicate records
			---- 09/25/15 VL added for 0 amount tax from plpricestax and plfreighttax because 0 tax won't be saved in invstdtx, but Malaysia tax system needs 0% tax saved in records
			--UNION ALL
			--SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			--	Invoiceno,Packlistno,DisplayValue,
			--	TransactionType,
			--	SourceTable,
			--	cIdentifier,
			--	cDrill,
			--	SourceSubTable,
			--	cSubIdentifier,
			--	cSubDrill,
			--	GL_NBR,
			--	GL_DESCR,
			--	Debit,
			--	Credit,
			--	FY,Period,fk_fyDtlUniq, AtdUniq_key 
			--	FROM SalesTax0 
			--UNION ALL
			--SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			--	Invoiceno,Packlistno,DisplayValue,
			--	TransactionType,
			--	SourceTable,
			--	cIdentifier,
			--	cDrill,
			--	SourceSubTable,
			--	cSubIdentifier,
			--	cSubDrill,
			--	GL_NBR,
			--	GL_DESCR,
			--	Debit,
			--	Credit,
			--	FY,Period,fk_fyDtlUniq, AtdUniq_key 
			--	FROM FreightTax0
			---- 09/25/15 VL End}
			-- 07/13/16 VL End}
			UNION ALL
			SELECT cast(0 as bit) as lSelect, Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key
				FROM SalesDetail 
			UNION ALL
			SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key
				FROM SalesFreight
			UNION ALL
			SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key
				FROM SalesDiscount 
			UNION ALL
			SELECT cast(0 as bit) as lSelect, Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key
				FROM CostOfGoods 
			UNION ALL
			SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key
				FROM FGIStndCOst 	)			
		SELECT FinalSales.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY Invoiceno) as GroupIdNumber FROM FinalSales ORDER BY Invoiceno
	
		--SELECT SUM(DEBIT) as sum_debit, SUM(credit) as sum_credit from finalsales
	END
ELSE
	BEGIN
	with SalesInfo AS
	(
	SELECT InvDate as Trans_Dt, CustName ,
			InvoiceNo , InvTotal , Sono,
			PacklistNo,FreightAmt, 
			-- 03/07/17 YS remove leading zero in displayvalye for the invoices
			--CAST('Customer: '+RTRIM(CustName)+', Invoice: '+InvoiceNo as varchar(50)) as DisplayValue,
			CAST(' Inv #: '+dbo.fRemoveLeadingZeros(InvoiceNo)+ ', Cust: '+RTRIM(CustName) as varchar(50)) as DisplayValue,
			TotTaxe,  TotTaxf, DsctAmt,
			Frt_Gl_No, Fc_Gl_No, Disc_gl_no, Ar_Gl_no, 
			PTax, STax ,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, 
			-- 12/09/16 VL added presentation currency fields
			InvTotalPR, FreightAmtPR, TotTaxePR,  TotTaxfPR, DsctAmtPR, PTaxPR, STaxPR, 
			FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency, TF.Symbol AS Transaction_Currency,
			Plmain.FuncFcused_uniq, Plmain.PrFcused_uniq,
			-- 06/09/17 VL added Fcused_uniq and Fchist_key and will be used to get rounding issue calculation later
			Plmain.Fcused_Uniq, Fchist_key, InvTotalFC
 		FROM Plmain 
			INNER JOIN Fcused TF ON Plmain.Fcused_uniq = TF.Fcused_uniq
	  		INNER JOIN Fcused PF ON Plmain.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON Plmain.FuncFcused_uniq = FF.Fcused_uniq
		INNER JOIN Customer ON PlMain.CustNo = Customer.CustNo 
		OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
				WHERE CAST(InvDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
			WHERE PlMain.Is_InvPost =1
			AND  PlMain.Is_Rel_Gl =0
	),
	AR as
	(
		SELECT Trans_dt,CUSTNAME,INVOICENO ,packlistno,
		DisplayValue,
		CASE WHEN InvTotal>0 THEN INVTOTAL ELSE CAST(0.0 as numeric(14,2)) END as Debit,
		CASE WHEN InvTotal>0 THEN CAST(0.0 as numeric(14,2))  ELSE INVTOTAL END as Credit,
		Ar_Gl_no as GL_nbr,gl_nbrs.GL_DESCR,
		CAST('SALES' as varchar(50)) as TransactionType, 
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('PlMain' as varchar(25)) as SourceSubTable,
		'PackListno' as cSubIdentifier,
		SalesInfo.PACKLISTNO as cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/09/16 VL added presentation currency fields
		CASE WHEN InvTotalPR>0 THEN INVTOTALPR ELSE CAST(0.0 as numeric(14,2)) END as DebitPR,
		CASE WHEN InvTotalPR>0 THEN CAST(0.0 as numeric(14,2))  ELSE INVTOTALPR END as CreditPR, 
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq,
		-- 06/09/17 VL added Fcused_uniq and Fchist_key and will be used to get rounding issue calculation later
		Fcused_Uniq, Fchist_key, InvTotalFC, InvTotal, InvTotalPR 
		FROM SalesInfo inner join gl_nbrs on SalesInfo.AR_GL_NO = gl_nbrs.GL_NBR 
		-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
		--where  INVTOTAL<>0.00
	),
	SalesTax as 
	(
	SELECT SalesInfo.Trans_Dt,SalesInfo.CustName,
		SalesInfo.INVOICENO ,
		SalesInfo.PackListno,
		SalesInfo.DisplayValue,
		CAST('SALES' as varchar(50)) as TransactionType,
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('InvStdTx' AS VARCHAR(25)) AS SourceSubTable,
		'INVSTDTXUNIQ' as cSubIdentifier,
		Invstdtx.INVSTDTXUNIQ as cSubDrill,
		CASE WHEN Invstdtx.Tax_Amt>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(Invstdtx.Tax_Amt) END AS Debit,
		CASE WHEN Invstdtx.Tax_Amt>0 THEN Invstdtx.Tax_Amt ELSE CAST(0.00 as numeric(14,2)) END as Credit ,
		Invstdtx.Gl_nbr_out as Gl_nbr,Gl_nbrs.GL_DESCR,
		SalesInfo.FY,SalesInfo.Period ,SalesInfo.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/09/16 VL added presentation currency fields
		CASE WHEN Invstdtx.Tax_AmtPR>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(Invstdtx.Tax_AmtPR) END AS DebitPR,
		CASE WHEN Invstdtx.Tax_AmtPR>0 THEN Invstdtx.Tax_AmtPR ELSE CAST(0.00 as numeric(14,2)) END as CreditPR , 
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM SalesInfo INNER JOIN InvStdTx ON InvStdTx.Packlistno =SalesInfo.Packlistno 
		INNER JOIN GL_NBRS on INVSTDTX.GL_NBR_OUT =gl_nbrs.gl_nbr 
		WHERE InvStdTx.INVOICENO = ' '
	),
	-- 07/13/16 VL Comment out SalesTax0 and FreightTax0 CTE cursor, now we have changed to save 0 amount tax in Invstdtx, so no need this duplicate records
	---- 09/25/15 VL added tax records with 0% rate, Maylaysia tax might have 0 percent, but need to be saved, invstdtx didnt' save 0 amount tax, need to insert separately
	--SalesTax0 AS
	--(
	--	SELECT SalesInfo.Trans_Dt,SalesInfo.CustName,
	--	SalesInfo.INVOICENO ,
	--	SalesInfo.PackListno,
	--	SalesInfo.DisplayValue,
	--	CAST('SALES' as varchar(50)) as TransactionType,
	--	CAST('PlMain' as varchar(25)) as SourceTable,
	--	'PackListno' as cIdentifier,
	--	SalesInfo.PACKLISTNO as cDrill,
	--	CAST('PlPricesTax' AS VARCHAR(25)) AS SourceSubTable,
	--	'UNIQPLPRICESTAX' as cSubIdentifier,
	--	PlpricesTax.UniqPlpricesTax as cSubDrill,
	--	0 AS Debit,
	--	0 as Credit ,
	--	Taxtabl.Gl_nbr_out as Gl_nbr,Gl_nbrs.GL_DESCR,
	--	SalesInfo.FY,SalesInfo.Period ,SalesInfo.fk_fyDtlUniq, Currency, 'TAX0      ' AS AtdUniq_key
	--	FROM SalesInfo INNER JOIN PlpricesTax ON PlpricesTax.Packlistno =SalesInfo.Packlistno 
	--	INNER JOIN Taxtabl ON Taxtabl.Tax_id = PlpricesTax.Tax_id 
	--	INNER JOIN GL_NBRS on Taxtabl.GL_NBR_OUT =gl_nbrs.gl_nbr 
	--	WHERE PlpricesTax.Tax_Rate = 0
	--),
	--FreightTax0 AS
	--(
	--	SELECT SalesInfo.Trans_Dt,SalesInfo.CustName,
	--	SalesInfo.INVOICENO ,
	--	SalesInfo.PackListno,
	--	SalesInfo.DisplayValue,
	--	CAST('SALES' as varchar(50)) as TransactionType,
	--	CAST('PlMain' as varchar(25)) as SourceTable,
	--	'PackListno' as cIdentifier,
	--	SalesInfo.PACKLISTNO as cDrill,
	--	CAST('PlFreightTax' AS VARCHAR(25)) AS SourceSubTable,
	--	'UNIQPLFREIGHTTAX' as cSubIdentifier,
	--	PlFreightTax.UniqPlFreightTax as cSubDrill,
	--	0 AS Debit,
	--	0 as Credit ,
	--	Taxtabl.Gl_nbr_out as Gl_nbr,Gl_nbrs.GL_DESCR,
	--	SalesInfo.FY,SalesInfo.Period ,SalesInfo.fk_fyDtlUniq, Currency, 'TAX0      ' AS AtdUniq_key
	--	FROM SalesInfo INNER JOIN PlFreightTax ON PlFreightTax.Packlistno =SalesInfo.Packlistno 
	--	INNER JOIN Taxtabl ON Taxtabl.Tax_id = PlFreightTax.Tax_id 
	--	INNER JOIN GL_NBRS on Taxtabl.GL_NBR_OUT =gl_nbrs.gl_nbr 
	--	WHERE PlFreightTax.Tax_Rate = 0
	--),
	---- 09/25/15 VL End
	-- 07/13/16 VL End
	SalesFreight AS
	(
		SELECT Trans_dt,CUSTNAME,INVOICENO ,packlistno,
		SalesInfo.DisplayValue,
		CASE WHEN FreightAmt>0 THEN CAST(0.0 as numeric(14,2)) ELSE ABS(FreightAmt) END as Debit,
		CASE WHEN FreightAmt>0 THEN FreightAmt ELSE CAST(0.0 as numeric(14,2)) END as Credit,
		Frt_Gl_No as GL_nbr,gl_nbrs.GL_DESCR,
		CAST('SALES' as varchar(50)) as TransactionType, 
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('PlMain' as varchar(25)) as SourceSubTable,
		'PackListno' as cSubIdentifier,
		SalesInfo.PACKLISTNO as cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/09/16 VL added presentation currency fields 
		CASE WHEN FreightAmtPR>0 THEN CAST(0.0 as numeric(14,2)) ELSE ABS(FreightAmtPR) END as DebitPR,
		CASE WHEN FreightAmtPR>0 THEN FreightAmtPR ELSE CAST(0.0 as numeric(14,2)) END as CreditPR, 
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM SalesInfo inner join gl_nbrs on salesinfo.FRT_GL_NO = gl_nbrs.gl_nbr  WHERE FreightAmt<>0.00
	),
	SalesDiscount AS
	(
		SELECT Trans_dt,CUSTNAME,INVOICENO ,packlistno,
		SalesInfo.DisplayValue,
		CASE WHEN DsctAmt>0 THEN DsctAmt ELSE CAST(0.0 as numeric(14,2)) END as Debit,
		CASE WHEN DsctAmt>0 THEN CAST(0.0 as numeric(14,2)) ELSE ABS(DsctAmt) END as Credit,
		Disc_gl_no as GL_nbr,gl_nbrs.GL_DESCR,
		CAST('SALES' as varchar(50)) as TransactionType, 
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('PlMain' as varchar(25)) as SourceSubTable,
		'PackListno' as cSubIdentifier,
		SalesInfo.PACKLISTNO as cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/09/16 VL added presentation currency fields  
		CASE WHEN DsctAmtPR>0 THEN DsctAmtPR ELSE CAST(0.0 as numeric(14,2)) END as DebitPR,
		CASE WHEN DsctAmtPR>0 THEN CAST(0.0 as numeric(14,2)) ELSE ABS(DsctAmtPR) END as CreditPR, 
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM SalesInfo inner join gl_nbrs on SalesInfo.DISC_GL_NO = gl_nbrs.gl_nbr WHERE DsctAmt<>0.00
	),
	SalesDetail as
	(
	SELECT SalesInfo.Trans_dt,SalesInfo.CUSTNAME,SalesInfo.INVOICENO ,
		SalesInfo.packlistno,SalesInfo.DisplayValue,
		Plprices.EXTENDED,PLPRICES.PLUNIQLNK ,
		CASE WHEN PlPrices.EXTENDED >0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(Plprices.EXTENDED) END AS Debit,
		CASE WHEN PlPrices.EXTENDED >0 THEN Plprices.EXTENDED ELSE CAST(0.00 as numeric(14,2)) END AS Credit,
		PlPrices.Pl_gl_nbr as Gl_nbr,gl_nbrs.GL_DESCR,
		CAST('SALES' as varchar(50)) as TransactionType, 
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('PlPrices' as varchar(25)) as SourceSubTable,
		'PLUNIQLNK'  as cSubIdentifier,
		PlPrices.PLUNIQLNK as cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/09/16 VL added presentation currency fields  
		CASE WHEN PlPrices.EXTENDEDPR >0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(Plprices.EXTENDEDPR) END AS DebitPR,
		CASE WHEN PlPrices.EXTENDEDPR >0 THEN Plprices.EXTENDEDPR ELSE CAST(0.00 as numeric(14,2)) END AS CreditPR, 
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM SalesInfo INNER JOIN PlPrices ON SalesInfo.Packlistno = PlPrices.Packlistno 
		inner join GL_NBRS on plprices.PL_GL_NBR = gl_nbrs.GL_NBR
			
	),
	CostOfGoods as
	(
	SELECT SalesInfo.Trans_dt,SalesInfo.CUSTNAME,SalesInfo.INVOICENO ,
		SalesInfo.packlistno,SalesInfo.DisplayValue,
		PP.uniqueln, PP.Cog_gl_nbr AS Gl_nbr, gl_nbrs.GL_DESCR,
		Invt_isu.StdCost, Invt_isu.Qtyisu , 
		CASE WHEN ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2)>0 THEN ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2) ELSE CAST(0.00 as numeric(14,2)) END  as Debit,
		CASE WHEN ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2))  END  as Credit,
		CAST('SALES' as varchar(50)) as TransactionType, 
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('Invt_isu' as varchar(25)) as SourceSubTable,
		'Invtisu_no'  as cSubIdentifier,
		Invt_isu.Invtisu_no as cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/09/16 VL added presentation currency fields   
		CASE WHEN ROUND(Invt_isu.StdCostPR * Invt_Isu.QtyIsu,2)>0 THEN ROUND(Invt_isu.StdCostPR * Invt_Isu.QtyIsu,2) ELSE CAST(0.00 as numeric(14,2)) END  as DebitPR,
		CASE WHEN ROUND(Invt_isu.StdCostPR * Invt_Isu.QtyIsu,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Invt_isu.StdCostPR * Invt_Isu.QtyIsu,2))  END  as CreditPR, 
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		SalesInfo.FuncFcused_uniq, SalesInfo.PrFcused_uniq 
		FROM SalesInfo INNER JOIN ( SELECT DISTINCT Packlistno,UniqueLn,Cog_Gl_nbr FROM PLPRICES where Plprices.RecordType <> 'O') PP ON SalesInfo.Packlistno = PP.Packlistno 
		INNER JOIN Invt_Isu ON Invt_isu.Uniqueln = PP.Uniqueln
		inner join GL_NBRS on PP.Cog_gl_nbr = gl_nbrs.GL_NBR
		WHERE  SUBSTRING(Invt_isu.ISSUEDTO,11,10) = SalesInfo.Packlistno
		-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
		--AND  Invt_isu.StdCost * Invt_Isu.QtyIsu<>0.00
				
	), FGIStndCOst AS
	(
	SELECT SalesInfo.Trans_dt,SalesInfo.CUSTNAME,SalesInfo.INVOICENO ,
		SalesInfo.packlistno,SalesInfo.DisplayValue,
		pldetail.uniqueln,
		PLDETAIL.INV_LINK, 
		Invt_Isu.QtyIsu ,
		invt_isu.Gl_nbr_inv  as Gl_nbr,gl_nbrs.GL_DESCR,
		Invt_isu.StdCost, 
		CASE WHEN ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2))  END  as Debit,
		CASE WHEN ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2)>0 THEN ROUND(Invt_isu.StdCost * Invt_Isu.QtyIsu,2) ELSE CAST(0.00 as numeric(14,2)) END  as Credit,
		CAST('SALES' as varchar(50)) as TransactionType, 
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		SalesInfo.PACKLISTNO as cDrill,
		CAST('Invt_isu' as varchar(25)) as SourceSubTable,
		'Invtisu_no'  as cSubIdentifier,
		Invt_isu.Invtisu_no as cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/09/16 VL added presentation currency fields    
		CASE WHEN ROUND(Invt_isu.StdCostPR * Invt_Isu.QtyIsu,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(Invt_isu.StdCostPR * Invt_Isu.QtyIsu,2))  END  as DebitPR,
		CASE WHEN ROUND(Invt_isu.StdCostPR * Invt_Isu.QtyIsu,2)>0 THEN ROUND(Invt_isu.StdCostPR * Invt_Isu.QtyIsu,2) ELSE CAST(0.00 as numeric(14,2)) END  as CreditPR, 
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		SalesInfo.FuncFcused_uniq, SalesInfo.PrFcused_uniq 
		FROM SalesInfo INNER JOIN PlDetail ON SalesInfo.Packlistno = PlDetail.Packlistno 
		INNER JOIN Invt_Isu ON Invt_isu.Uniqueln = PlDetail.Uniqueln
		inner join GL_NBRS on Invt_isu.GL_NBR_INV = gl_nbrs.gl_nbr
		WHERE  SUBSTRING(Invt_isu.ISSUEDTO,11,10) = SalesInfo.Packlistno
		-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
		--AND  Invt_isu.StdCost * Invt_Isu.QtyIsu<>0.00
	
	),

	-- 06/09/17 VL added to get the rounding difference caused by calculating HC values directly from FC total value (not from plprices)
	ARFC2HC AS
		(
		SELECT Trans_dt,CUSTNAME,INVOICENO ,packlistno,
		DisplayValue,
		CASE WHEN ROUND(dbo.fn_Convert4FCHC('F',AR.Fcused_uniq, AR.InvTotalFC, dbo.fn_GetFunctionalCurrency(), AR.Fchist_key),2) - AR.InvTotal>0 THEN 
			ABS(ROUND(dbo.fn_Convert4FCHC('F',AR.Fcused_uniq, AR.InvTotalFC, dbo.fn_GetFunctionalCurrency(), AR.Fchist_key),2) - AR.InvTotal) ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
		CASE WHEN ROUND(dbo.fn_Convert4FCHC('F',AR.Fcused_uniq, AR.InvTotalFC, dbo.fn_GetFunctionalCurrency(), AR.Fchist_key),2) - AR.InvTotal>0 THEN CAST(0.00 as numeric(14,2))
		-- 06/22/17 VL added ABS()
			ELSE ABS(ROUND(dbo.fn_Convert4FCHC('F',AR.Fcused_uniq, AR.InvTotalFC, dbo.fn_GetFunctionalCurrency(), AR.Fchist_key),2) - AR.InvTotal) END AS Credit,
		AR.GL_nbr,GL_DESCR,
		CAST('SALES' as varchar(50)) as TransactionType, 
		CAST('PlMain' as varchar(25)) as SourceTable,
		'PackListno' as cIdentifier,
		cDrill,
		CAST('PlMain' as varchar(25)) as SourceSubTable,
		'PackListno' as cSubIdentifier,
		cSubDrill,
		FY,Period,fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/09/16 VL added presentation currency fields
		-- 06/09/17 VL changed to convert from FC
		-- 06/22/17 VL added ABS()
		CASE WHEN ROUND(dbo.fn_Convert4FCHC('F',AR.Fcused_uniq, AR.InvTotalFC, dbo.fn_GetPresentationCurrency(), AR.Fchist_key),2) - AR.InvTotalPR>0 THEN 
			ABS(ROUND(dbo.fn_Convert4FCHC('F',AR.Fcused_uniq, AR.InvTotalFC, dbo.fn_GetPresentationCurrency(), AR.Fchist_key),2) - AR.InvTotalPR) ELSE CAST(0.00 as numeric(14,2)) END AS DebitPR,
		CASE WHEN ROUND(dbo.fn_Convert4FCHC('F',AR.Fcused_uniq, AR.InvTotalFC, dbo.fn_GetPresentationCurrency(), AR.Fchist_key),2) - AR.InvTotalPR>0 THEN CAST(0.00 as numeric(14,2))
			ELSE ABS(ROUND(dbo.fn_Convert4FCHC('F',AR.Fcused_uniq, AR.InvTotalFC, dbo.fn_GetPresentationCurrency(), AR.Fchist_key),2) - AR.InvTotalPR) END AS CreditPR,
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM AR 
		WHERE (ROUND(dbo.fn_Convert4FCHC('F',AR.Fcused_uniq, AR.InvTotalFC, dbo.fn_GetFunctionalCurrency(), AR.Fchist_key),2) - AR.InvTotal <> 0
		OR ROUND(dbo.fn_Convert4FCHC('F',AR.Fcused_uniq, AR.InvTotalFC, dbo.fn_GetPresentationCurrency(), AR.Fchist_key),2) - AR.InvTotalPR <> 0)
	),
	RoundingFUNC AS
		(
		SELECT Trans_dt,CUSTNAME,INVOICENO ,packlistno,	DisplayValue, Credit AS Debit, Debit AS Credit, CTVFUNC_GL_NO AS Gl_nbr, gl_nbrs.GL_DESCR, TransactionType, SourceTable, cIdentifier,
				cDrill, SourceSubTable, cSubIdentifier, cSubDrill, FY,Period,fk_fyDtlUniq, AtdUniq_key, 0 AS DebitPR, 0 AS CreditPR, Functional_Currency, 
				Presentation_Currency, Transaction_Currency, FuncFcused_uniq, PrFcused_uniq  
			FROM ARFC2HC
			CROSS JOIN ARSetup
			INNER JOIN GL_NBRS ON ARSetup.CTVFUNC_GL_NO=gl_nbrs.GL_NBR 
			WHERE (Credit<>0 OR Debit<>0)
		),
	RoundingPR AS
		(
		SELECT Trans_dt,CUSTNAME,INVOICENO ,packlistno,	DisplayValue, 0 AS Debit, 0 AS Credit, CTVPR_GL_NO AS Gl_nbr, gl_nbrs.GL_DESCR, TransactionType, SourceTable, cIdentifier,
				cDrill, SourceSubTable, cSubIdentifier, cSubDrill, FY,Period,fk_fyDtlUniq, AtdUniq_key, CreditPR AS DebitPR, DebitPR AS CreditPR, Functional_Currency, 
				Presentation_Currency, Transaction_Currency, FuncFcused_uniq, PrFcused_uniq  
			FROM ARFC2HC
			CROSS JOIN ARSetup
			INNER JOIN GL_NBRS ON ARSetup.CTVPR_GL_NO=gl_nbrs.GL_NBR 
			WHERE (CreditPR<>0 OR DebitPR<>0)
		),
	-- 06/09/17 VL End
	FinalSales as (
		SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key, 
				-- 12/09/16 VL added presentation currency fields    
				DebitPR, CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
				FuncFcused_uniq, PrFcused_uniq 
				FROM AR
			UNION ALL
			SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key, 
				-- 12/09/16 VL added presentation currency fields    
				DebitPR, CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
				FuncFcused_uniq, PrFcused_uniq 
				FROM SalesTax 
			-- 07/13/16 VL Comment out SalesTax0 and FreightTax0 CTE cursor, now we have changed to save 0 amount tax in Invstdtx, so no need this duplicate records
			---- 09/25/15 VL added for 0 amount tax from plpricestax and plfreighttax because 0 tax won't be saved in invstdtx, but Malaysia tax system needs 0% tax saved in records
			--UNION ALL
			--SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			--	Invoiceno,Packlistno,DisplayValue,
			--	TransactionType,
			--	SourceTable,
			--	cIdentifier,
			--	cDrill,
			--	SourceSubTable,
			--	cSubIdentifier,
			--	cSubDrill,
			--	GL_NBR,
			--	GL_DESCR,
			--	Debit,
			--	Credit,
			--	FY,Period,fk_fyDtlUniq, Currency, AtdUniq_key 
			--	FROM SalesTax0 
			--UNION ALL
			--SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			--	Invoiceno,Packlistno,DisplayValue,
			--	TransactionType,
			--	SourceTable,
			--	cIdentifier,
			--	cDrill,
			--	SourceSubTable,
			--	cSubIdentifier,
			--	cSubDrill,
			--	GL_NBR,
			--	GL_DESCR,
			--	Debit,
			--	Credit,
			--	FY,Period,fk_fyDtlUniq, Currency, AtdUniq_key 
			--	FROM FreightTax0
			---- 09/25/15 VL End}
			-- 07/13/16 VL End}
			UNION ALL
			SELECT cast(0 as bit) as lSelect, Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key, 
				-- 12/09/16 VL added presentation currency fields    
				DebitPR, CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
				FuncFcused_uniq, PrFcused_uniq 
				FROM SalesDetail 
			UNION ALL
			SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key, 
				-- 12/09/16 VL added presentation currency fields    
				DebitPR, CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
				FuncFcused_uniq, PrFcused_uniq 
				FROM SalesFreight
			UNION ALL
			SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key, 
				-- 12/09/16 VL added presentation currency fields    
				DebitPR, CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
				FuncFcused_uniq, PrFcused_uniq 
				FROM SalesDiscount 
			UNION ALL
			SELECT cast(0 as bit) as lSelect, Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key, 
				-- 12/09/16 VL added presentation currency fields    
				DebitPR, CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
				FuncFcused_uniq, PrFcused_uniq 
				FROM CostOfGoods 
			UNION ALL
			SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key, 
				-- 12/09/16 VL added presentation currency fields    
				DebitPR, CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
				FuncFcused_uniq, PrFcused_uniq 
				FROM FGIStndCOst
			-- 06/22/17 VL added ARFC2HC
			UNION ALL
			SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key, 
				DebitPR, CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
				FuncFcused_uniq, PrFcused_uniq 
				FROM ARFC2HC
			-- 06/09/17 VL added currency translation variance into two parts:functional currency and presentation currency and into two different GL accounts
			UNION ALL
			SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key, 
				DebitPR, CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
				FuncFcused_uniq, PrFcused_uniq 
				FROM RoundingFUNC
			UNION ALL		
			SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
				Invoiceno,Packlistno,DisplayValue,
				TransactionType,
				SourceTable,
				cIdentifier,
				cDrill,
				SourceSubTable,
				cSubIdentifier,
				cSubDrill,
				GL_NBR,
				GL_DESCR,
				Debit,
				Credit,
				FY,Period,fk_fyDtlUniq, AtdUniq_key, 
				DebitPR, CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
				FuncFcused_uniq, PrFcused_uniq 
				FROM RoundingPR)			
			-- 06/09/17 VL End
		SELECT FinalSales.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY Invoiceno) as GroupIdNumber FROM FinalSales ORDER BY Invoiceno
	
		--SELECT SUM(DEBIT) as sum_debit, SUM(credit) as sum_credit from finalsales
	END
END