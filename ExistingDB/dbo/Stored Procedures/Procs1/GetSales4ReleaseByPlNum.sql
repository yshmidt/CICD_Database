-- =============================================
-- Author:		Anuj Kumar
-- Create date: <11/30/2015>
-- Description:	GetItemByCreditMemo
-- =============================================
Create PROCEDURE [dbo].[GetSales4ReleaseByPlNum]
	@plNum char(10) = NULL
AS
BEGIN
  -- Insert statements for procedure here
	DECLARE @T as dbo.AllFYPeriods
INSERT INTO @T EXEC GlFyrstartEndView	;
with SalesInfo AS
(
 
SELECT InvDate as Trans_Dt, CustName ,
		InvoiceNo , InvTotal , Sono,
		PacklistNo,FreightAmt, 
		CAST('Customer: '+RTRIM(CustName)+', Invoice: '+InvoiceNo as varchar(50)) as DisplayValue,
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
	FY,Period,fk_fyDtlUniq 
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
	SalesInfo.FY,SalesInfo.Period ,SalesInfo.fk_fyDtlUniq
	FROM SalesInfo INNER JOIN InvStdTx ON InvStdTx.Packlistno =SalesInfo.Packlistno 
	INNER JOIN GL_NBRS on INVSTDTX.GL_NBR_OUT =gl_nbrs.gl_nbr 
	WHERE InvStdTx.INVOICENO = ' '
),
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
	FY,Period,fk_fyDtlUniq 
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
	FY,Period,fk_fyDtlUniq 
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
	FY,Period,fk_fyDtlUniq
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
	FY,Period,fk_fyDtlUniq 
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
	FY,Period,fk_fyDtlUniq 
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
			FY,Period,fk_fyDtlUniq 
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
			FY,Period,fk_fyDtlUniq 
			FROM SalesTax 
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
			FY,Period,fk_fyDtlUniq
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
			FY,Period,fk_fyDtlUniq
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
			FY,Period,fk_fyDtlUniq
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
			FY,Period,fk_fyDtlUniq
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
			FY,Period,fk_fyDtlUniq
			FROM FGIStndCOst 	)	
						
	SELECT FinalSales.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY Invoiceno) as GroupIdNumber FROM FinalSales 
	WHERE PACKLISTNO = @plNum
	ORDER BY Invoiceno

END