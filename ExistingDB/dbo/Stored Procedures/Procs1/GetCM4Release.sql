-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <08/24/2011>
-- Description:	Get CM information to release
-- 01/14/14 YS remove filter for cmTotal. Even if total is 0 there are trnasactions from cost of goods
-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
-- 09/28/15 VL Added for 0 amount tax from cmpricestax and cmfreighttax because 0 tax won't be saved in invstdtx, but Malaysia tax system needs 0% tax saved in records
--			   Also added AtdUniq_key to each CTE cursor
-- 10/15/15 VL added FC currency field
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 07/13/16 VL Comment out CmTax0 and FreightTax0 CTE cursor, now we have changed to save 0 amount tax in Invstdtx, so no need this duplicate records
-- 12/14/16 VL added functional and presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[GetCM4Release]
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

    WITH CMHeader AS  -- source table is CmMain, this is Header info
    (
	SELECT CmDate AS Trans_Dt,CustName,
	cmTotal ,cMemoNo,cmUnique,
	CmMain.PackListno,
	CmMain.IS_RMA ,
	CMMain.PTax,CMMain.STax,CmMain.TotTaxe,CmMain.Cm_frt,cmmain.Frt_Gl_no,cmmain.CM_FRT_TAX,
	CmMain.DsctAmt,CmMain.DISC_GL_NO,
	CAST('CM' as varchar(50)) as TransactionType, 
	CAST('CMMAIN' as varchar(25)) as SourceTable,
	'CMUnique' as cIdentifier,
	CMMAIN.CMUNIQUE as cDrill,
	CAST('CMMAIN' as varchar(25)) as SourceSubTable,
	'CMUnique' as cSubIdentifier,
	CMMAIN.CMUNIQUE as cSubDrill,
	CASE WHEN CmMain.cmTotal>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(CmMain.cmTotal) END AS Debit,
	CASE WHEN CmMain.CMTOTAL>0 THEN CmMain.cmTotal ELSE CAST(0.00 as numeric(14,2))END AS Credit,
	ArSetup.Ar_Gl_No as GL_NBR,gl_nbrs.GL_DESCR,
	fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
	 FROM cmmain OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(cmmain.CmDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN CUSTOMER on CMMAIN.CUSTNO =Customer.CUSTNO 
		CROSS JOIN ARSETUP  
		INNER JOIN GL_NBRS on arsetup.AR_GL_NO = gl_nbrs.gl_nbr
	 WHERE cmmain.Is_cmpost =1
	AND cmmain.is_rel_gl =0
	-- 01/14/14 YS remove filter for cmTotal. Even if total is 0 there are trnasactions from cost of goods
	--AND cmTotal<>0 
	and CSTATUS <>'CANCELLED'),
	--SELECT * from CMHeader order by CMEMONO 
	CmTax AS   -- source table is Invstdtx
	(
	SELECT CmHeader.Trans_Dt,CMHeader.CustName,
	CMHeader.cMemoNo,
	CMHeader.PackListno,
	CMHeader.TransactionType, 
	CmHeader.cmUnique,
	CmHeader.SourceTable,
	CmHeader.cIdentifier,
	CmHeader.cDrill,
	CAST('InvStdTx' AS VARCHAR(25)) AS SourceSubTable,
	'INVSTDTXUNIQ' as cSubIdentifier,
	Invstdtx.INVSTDTXUNIQ as cSubDrill,
	CASE WHEN Invstdtx.Tax_Amt>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(Invstdtx.Tax_Amt) END AS Debit,
	CASE WHEN Invstdtx.Tax_Amt>0 THEN Invstdtx.Tax_Amt ELSE CAST(0.00 as numeric(14,2)) END as Credit ,
	Invstdtx.Gl_nbr_out as Gl_nbr,gl_nbrs.GL_DESCR,
	CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
	FROM Invstdtx INNER JOIN CMHeader ON InvStdTx.INVOICENO = CMHeader.CMEMONO  
	INNER JOIN GL_NBRS on INVSTDTX.GL_NBR_OUT = gl_nbrs.GL_NBR 
	),
	--SELECT * FROM CmTax order by CMEMONO 
	-- 07/13/16 VL comment out CmTax0 and FreightTax0 CTE cursor, now we have changed to save 0 amount tax in Invstdtx, so no need this duplicate records
	-- 09/28/15 VL added tax records with 0% rate, Maylaysia tax might have 0 percent, but need to be saved, invstdtx didnt' save 0 amount tax, need to insert separately
	--CmTax0 AS
	--(
	--SELECT CmHeader.Trans_Dt,CmHeader.CustName,
	--CMHeader.cMemoNo,
	--CMHeader.PackListno,
	--CMHeader.TransactionType, 
	--CmHeader.cmUnique,
	--CmHeader.SourceTable,
	--CmHeader.cIdentifier,
	--CmHeader.cDrill,
	--CAST('CmPricesTax' AS VARCHAR(25)) AS SourceSubTable,
	--'UNIQCMPRICESTAX' as cSubIdentifier,
	--CmpricesTax.UniqCmpricesTax as cSubDrill,
	--0 AS Debit,
	--0 as Credit ,
	--Taxtabl.Gl_nbr_out as Gl_nbr,Gl_nbrs.GL_DESCR,
	--CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, 'TAX0      ' AS AtdUniq_key
	--FROM CMHeader INNER JOIN CmpricesTax ON CmpricesTax.CmUnique =CMHeader.CmUnique
	--INNER JOIN Taxtabl ON Taxtabl.Tax_id = CmpricesTax.Tax_id 
	--INNER JOIN GL_NBRS on Taxtabl.GL_NBR_OUT =gl_nbrs.gl_nbr 
	--WHERE CmpricesTax.Tax_Rate = 0
	--),
	--FreightTax0 AS
	--(
	--SELECT CmHeader.Trans_Dt,CmHeader.CustName,
	--CMHeader.cMemoNo,
	--CMHeader.PackListno,
	--CMHeader.TransactionType, 
	--CmHeader.cmUnique,
	--CmHeader.SourceTable,
	--CmHeader.cIdentifier,
	--CmHeader.cDrill,
	--CAST('CmFreightTax' AS VARCHAR(25)) AS SourceSubTable,
	--'UNIQCMFREIGHTTAX' as cSubIdentifier,
	--CmFreightTax.UniqCmFreightTax as cSubDrill,
	--0 AS Debit,
	--0 as Credit ,
	--Taxtabl.Gl_nbr_out as Gl_nbr,Gl_nbrs.GL_DESCR,
	--CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, 'TAX0      ' AS AtdUniq_key
	--FROM CMHeader INNER JOIN CmFreightTax ON CmFreightTax.CmUnique =CMHeader.CmUnique
	--INNER JOIN Taxtabl ON Taxtabl.Tax_id = CmFreightTax.Tax_id 
	--INNER JOIN GL_NBRS on Taxtabl.GL_NBR_OUT =gl_nbrs.gl_nbr 
	--WHERE CmFreightTax.Tax_Rate = 0
	--),
	---- 09/28/15 VL End
	-- 07/13/16 VL End}
	CmFrt AS  -- the source table hear is CMMAIN
	(
	SELECT CmHeader.Trans_Dt,CMHeader.CustName,
	CMHeader.cMemoNo,
	CMHeader.PackListno,
	CMHeader.Cm_frt,
	CMHeader.TransactionType, 
	CMHeader.SourceTable,
	CMHeader.cIdentifier,
	CMHeader.cDrill,
	CMHeader.SourceSubTable,
	CMHeader.cSubIdentifier,
	CMHeader.cSubDrill,
	CMHeader.cmunique, 
	CASE WHEN CMHeader.Cm_Frt>0 THEN CMHeader.Cm_Frt ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
	CASE WHEN CMHeader.Cm_Frt>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(CMHeader.Cm_Frt) END as Credit ,
	CMHeader.Frt_Gl_no as Gl_nbr,gl_nbrs.GL_DESCR,
	CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
	FROM CMHeader inner join GL_NBRS on CMHeader.FRT_GL_NO = gl_nbrs.gl_nbr  WHERE CMHeader.Cm_Frt<>0
	),
	--SELECT * FROM CmFrt order by CMEMONO 
	CmDiscount AS  -- Source Table CMMAIN
	(
	SELECT CmHeader.Trans_Dt,CMHeader.CustName,
	CMHeader.cMemoNo,
	CMHeader.PackListno,
	CMHeader.DsctAmt,
	CMHeader.TransactionType, 
	CMHeader.SourceTable,
	CMHeader.cIdentifier,
	CMHeader.cDrill,
	CMHeader.SourceSubTable,
	CMHeader.cSubIdentifier,
	CMHeader.cSubDrill,
	CMHeader.cmunique, 
	CASE WHEN CMHeader.DsctAmt>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(CMHeader.DsctAmt) END AS Debit,
	CASE WHEN CMHeader.DsctAmt>0 THEN CMHeader.DsctAmt ELSE CAST(0.00 as numeric(14,2)) END as Credit ,
	CMHeader.DISC_GL_NO as Gl_nbr,gl_nbrs.GL_DESCR,
	CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
	FROM CMHeader inner join GL_NBRS on CMHeader.DISC_GL_NO = gl_nbrs.gl_nbr WHERE CMHeader.DsctAmt<>0
	),
	--SELECT * FROM CmDiscount order by CMEMONO 
	PLCost AS   --- build for detail info
	(
	SELECT UNIQUELN
      ,CMQUANTITY
      ,CMPRICE
      ,CMEXTENDED
      ,TAXABLE
      ,FLAT
      ,INV_LINK
      ,RECORDTYPE
      ,SCRAPQTY
      ,SALESTYPE
      ,PL_GL_NBR
      ,PLPRICELNK
      ,PLUNIQLNK
      ,COG_GL_NBR
      ,CMPRICELNK
      ,CMPRUNIQ
      ,cmunique
	 FROM cmprices WHERE cmunique IN (SELECT cmunique FROM CMHeader) 
	),
	--SELECT * from PlCost where plcost.CMEXTENDED<>0 order by cmunique  
	DetailTrns AS --- get Detail information records with cmextended<>0  Source table is cmprices
	(
	SELECT CmHeader.Trans_Dt,CMHeader.CustName,
	CMHeader.cMemoNo,
	CMHeader.PackListno,
	CMHeader.TransactionType, 
	CMHeader.SourceTable,
	CMHeader.cIdentifier,
	CMHeader.cDrill,
	'CmPrices' AS SourceSubTable,
	'CMPrUniq' AS cSubIdentifier,
	PLCost.CmPrUniq as cSubDrill,
	CMHeader.CmUnique, 
	CASE WHEN PLCost.cmextended>0 THEN PLCost.cmextended ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
	CASE WHEN PLCost.cmextended>0 THEN CAST(0.00 as numeric(14,2)) ELSE abs(PLCost.cmextended) END as Credit ,
	PLCost.pl_gl_nbr as Gl_nbr,gl_nbrs.GL_DESCR,
	CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
	FROM PLCost  
	INNER JOIN CMHeader ON PLCost.cmunique  = CMHeader.CMUNIQUE   
	inner join GL_NBRS on plcost.PL_GL_NBR =gl_nbrs.gl_nbr
	-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
	--WHERE PLCost.cmextended<>0.00
	),
	--SELECT * from detailinfo order by cMemoNo
	StndCostInfo AS   --- Find standard cost for record <> 'O'
	(
	 SELECT DISTINCT Sodetail.uniqueln, Sodetail.uniq_key, PLCost.cmquantity, PLCost.cog_gl_nbr, 
		PLCost.scrapqty, PLCost.RecordType,PlCost.CMPRUNIQ,plcost.cmunique ,
		Inventor.stdcost,(plcost.cmquantity * Inventor.stdcost) AS nExtended
	FROM Sodetail INNER JOIN PLCost ON PLCost.uniqueln = Sodetail.uniqueln 
	INNER JOIN INVENTOR ON Sodetail.UNIQ_KEY =Inventor.UNIQ_KEY 
	WHERE PlCost.RECORDTYPE <>'O' 
	-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
	--AND plcost.cmquantity * Inventor.stdcost<>0.00
	)
	--SELECT * from StndCostInfo order by cmunique 
	,
	CostOfGoodsTr AS
	(
	SELECT CmHeader.Trans_Dt,CMHeader.CustName,
	CMHeader.cMemoNo,
	CMHeader.PackListno,
	CMHeader.TransactionType, 
	CMHeader.SourceTable,
	CMHeader.cIdentifier,
	CMHeader.cDrill,
	'CmPrices' AS SourceSubTable,
	'CMPrUniq' AS cSubIdentifier,
	CMHeader.CmUnique, 
	PLCost.CmPrUniq as cSubDrill,
	CASE WHEN StndCostInfo.nExtended>0 THEN  CAST(0.00 as numeric(14,2)) ELSE abs(StndCostInfo.nExtended) END AS Debit,
	CASE WHEN StndCostInfo.nExtended>0 THEN StndCostInfo.nExtended ELSE CAST(0.00 as numeric(14,2)) END as Credit ,
	StndCostInfo.cog_gl_nbr as Gl_nbr,gl_nbrs.GL_DESCR,
	CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
	FROM PLCost  
	INNER JOIN CMHeader ON PLCost.cmunique  = CMHeader.CMUNIQUE  
	INNER JOIN StndCostInfo ON PlCost.CMPRUNIQ = StndCostInfo.CMPRUNIQ
	inner join GL_NBRS on StndCostInfo.cog_gl_nbr =gl_nbrs.gl_nbr
	),
	--select * from CostOfGoodsTr order by CMEMONO
	RMA AS
	(
	SELECT cmHeader.Trans_Dt,
			CMHeader.CUSTNAME,
			CMHeader.PACKLISTNO,
			CMHeader.IS_RMA,        
			CMHeader.cMemoNo, 
			CmHeader.CMUNIQUE, 
			cmalloc.uniqueln, cmalloc.w_key, 
			cmalloc.allocqty, warehous.wh_gl_nbr,
			Inventor.STDCOST,
			cmalloc.UNIQ_ALLOC,cmalloc.allocqty*Inventor.STDCOST as nExtended,
			CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
			FROM cmdetail INNER JOIN CMHeader ON cmdetail.cmUnique=CMHeader.CMUNIQUE  
			INNER JOIN cmalloc ON CmAlloc.UNIQUELN = CMDETAIL.UNIQUELN  and CmAlloc.cmUnique = cmdetail.cmUnique 
			INNER JOIN invtmfgr ON cmAlloc.W_KEY = Invtmfgr.W_key
			INNER JOIN warehous ON Warehous.UNIQWH = Invtmfgr.UNIQWH 
			INNER JOIN Inventor ON Inventor.UNIQ_KEY=Invtmfgr.UNIQ_KEY 
			-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
			--WHERE cmalloc.allocqty*Inventor.STDCOST<>0.00
	)
	--SELECT * FROM CMALLOCINFO ORDER BY CMEMONO 
	,
	RMATR AS
	(
	SELECT RMA.Trans_dt,
			RMA.CUSTNAME, 
			RMA.PACKLISTNO,
			RMA.CMEMONO,
			RMA.CmUnique,
			RMA.wh_gl_nbr as gl_nbr,gl_nbrs.GL_DESCR,
			'CM' AS TransactionType,
			CAST('CMMAIN' as varchar(25)) as SourceTable,
			'CMUnique' as cIdentifier,
			RMA.CMUNIQUE as cDrill,
			'CMALLOC' as SourceSubTable,
			'UNIQ_ALLOC' AS cSubIdentifier,
			Rma.UNIQ_ALLOC as cSubDrill,
			CASE WHEN Rma.nExtended>0 THEN Rma.nExtended ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
			CASE WHEN Rma.nExtended>0 THEN CAST(0.00 as numeric(14,2)) ELSE abs(Rma.nExtended) END as Credit,
			RMA.FY,RMA.Period ,RMA.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
	FROM RMA INNER JOIN GL_NBRS on RMA.wh_gl_nbr=gl_nbrs.gl_nbr
	)
	--SELECT * FROM RMATR order by CMEMONO 
	,SCRAP AS 
	(
	SELECT PLCost.*,Inventor.STDCOST ,PlCost.SCRAPQTY *Inventor.STDCOST as nExtended,  
			cmHeader.Trans_Dt,
			CMHeader.CUSTNAME,
			CMHeader.PACKLISTNO,
			CMHeader.cMemoNo, 
			InvSetup.SHRI_GL_NO,
			CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
			FROM PLCost INNER JOIN CMHeader ON plCost.cmUnique=CMHeader.CMUNIQUE 
			INNER JOIN Sodetail ON PlCost.UNIQUELN = Sodetail.UNIQUELN  
			INNER JOIN Inventor ON Inventor.UNIQ_KEY=Sodetail.UNIQ_KEY 
			CROSS JOIN InvSetup
			WHERE PlCost.RECORDTYPE <>'O' AND PlCost.RECORDTYPE<>'M' 
			-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
			--AND PlCost.SCRAPQTY *Inventor.STDCOST <>0.00 
	)
	--SELECT * FROM SCRAP ORDER BY cmunique 
	,
	SCRAPTR AS
	(
	SELECT SCRAP.Trans_Dt,
			Scrap.CUSTNAME,
			Scrap.PACKLISTNO,
			Scrap.cMemoNo, 
			scrap.CMunique,
			scrap.SHRI_GL_NO as GL_NBR, gl_nbrs.GL_DESCR,
			'CM' AS TransactionType,
			CAST('CMMAIN' as varchar(25)) as SourceTable,
			'CMUnique' as cIdentifier,
			SCRAP.CMUNIQUE as cDrill,
			'CMPRICES' as SourceSubTable,
			'CMPrUniq' AS cSubIdentifier,
			Scrap.CMPrUniq as cSubDrill,
			CASE WHEN Scrap.nExtended>0 THEN Scrap.nExtended ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
			CASE WHEN Scrap.nExtended>0 THEN CAST(0.00 as numeric(14,2)) ELSE abs(Scrap.nExtended) END as Credit,
			Scrap.FY,Scrap.Period ,Scrap.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 
	 from SCRAP inner join GL_NBRS on scrap.SHRI_GL_NO = gl_nbrs.gl_nbr
	)
	,
	--SELECT * FROM SCRAPTR order by CMEMONO
	-- 09/28/15 VL added AtdUniq_key to save 'Tax0' if it's tax 0 record
	FinalCm AS
	(
	SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
			PackListno,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			GL_NBR,GL_DESCR,
			Debit,
			Credit,
			FY,Period,fk_fyDtlUniq,AtdUniq_key 
			FROM cmHeader
	UNION ALL
	SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
			PackListno,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			GL_NBR,GL_DESCR,
			Debit,
			Credit,
			FY,Period,fk_fyDtlUniq,AtdUniq_key 
			FROM CmTax	
	UNION ALL
	-- 07/13/16 VL comment out CmTax0 and FreightTax0 CTE cursor, now we have changed to save 0 amount tax in Invstdtx, so no need this duplicate records
	---- 10/05/15 VL added 
	--SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
	--		cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
	--		PackListno,
	--		TransactionType,
	--		SourceTable,
	--		cIdentifier,
	--		cDrill,
	--		SourceSubTable,
	--		cSubIdentifier,
	--		cSubDrill,
	--		GL_NBR,GL_DESCR,
	--		Debit,
	--		Credit,
	--		FY,Period,fk_fyDtlUniq,AtdUniq_key 
	--		FROM CmTax0	
	--UNION ALL
	--SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
	--		cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
	--		PackListno,
	--		TransactionType,
	--		SourceTable,
	--		cIdentifier,
	--		cDrill,
	--		SourceSubTable,
	--		cSubIdentifier,
	--		cSubDrill,
	--		GL_NBR,GL_DESCR,
	--		Debit,
	--		Credit,
	--		FY,Period,fk_fyDtlUniq,AtdUniq_key 
	--		FROM FreightTax0	
	---- 10/05/15 VL End}	
	--UNION ALL
	-- 07/13/16 VL End
	SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
			PackListno,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			GL_NBR,GL_DESCR,
			Debit,
			Credit,
			FY,Period,fk_fyDtlUniq,AtdUniq_key 
			FROM CmFrt 
	UNION ALL
	SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
			PackListno,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			GL_NBR,GL_DESCR,
			Debit,
			Credit,
			FY,Period,fk_fyDtlUniq,AtdUniq_key 
			FROM CmDiscount 
		UNION ALL	
		SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
			PackListno,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			GL_NBR,GL_DESCR,
			Debit,
			Credit,
			FY,Period,fk_fyDtlUniq,AtdUniq_key 
			FROM DetailTrns	
		UNION ALL	
		SELECT cast(0 as bit) as lSelect, Trans_Dt,CustName,
			cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
			PackListno,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			GL_NBR,GL_DESCR,
			Debit,
			Credit,
			FY,Period,fk_fyDtlUniq,AtdUniq_key 
			FROM CostOfGoodsTr 
		UNION ALL	
		SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
			PackListno,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			GL_NBR,GL_DESCR,
			Debit,
			Credit,
			FY,Period,fk_fyDtlUniq,AtdUniq_key 
			FROM RMATR 
		UNION ALL	
		SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
			PackListno,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			GL_NBR,GL_DESCR,
			Debit,
			Credit,
			FY,Period,fk_fyDtlUniq,AtdUniq_key 
			FROM SCRAPTR 
					
		)
		--select * from finalcm order by cdrill
		SELECT FinalCm.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cMemoNo) as GroupIdNumber FROM FinalCm ORDER BY CMEMONO 
	END
ELSE
	BEGIN
   WITH CMHeader AS  -- source table is CmMain, this is Header info
    (
	SELECT CmDate AS Trans_Dt,CustName,
	cmTotal ,cMemoNo,cmUnique,
	CmMain.PackListno,
	CmMain.IS_RMA ,
	CMMain.PTax,CMMain.STax,CmMain.TotTaxe,CmMain.Cm_frt,cmmain.Frt_Gl_no,cmmain.CM_FRT_TAX,
	CmMain.DsctAmt,CmMain.DISC_GL_NO,
	CAST('CM' as varchar(50)) as TransactionType, 
	CAST('CMMAIN' as varchar(25)) as SourceTable,
	'CMUnique' as cIdentifier,
	CMMAIN.CMUNIQUE as cDrill,
	CAST('CMMAIN' as varchar(25)) as SourceSubTable,
	'CMUnique' as cSubIdentifier,
	CMMAIN.CMUNIQUE as cSubDrill,
	CASE WHEN CmMain.cmTotal>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(CmMain.cmTotal) END AS Debit,
	CASE WHEN CmMain.CMTOTAL>0 THEN CmMain.cmTotal ELSE CAST(0.00 as numeric(14,2))END AS Credit,
	ArSetup.Ar_Gl_No as GL_NBR,gl_nbrs.GL_DESCR,
	fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
	-- 12/15/16 VL: added functional and presentation currency fields
	cmTotalPR, CMMain.PTaxPR,CMMain.STaxPR,CmMain.TotTaxePR,CmMain.Cm_frtPR,cmmain.CM_FRT_TAXPR,CmMain.DsctAmtPR,
	CASE WHEN CmMain.cmTotalPR>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(CmMain.cmTotalPR) END AS DebitPR,
	CASE WHEN CmMain.CMTOTALPR>0 THEN CmMain.cmTotalPR ELSE CAST(0.00 as numeric(14,2))END AS CreditPR,
	FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency, TF.Symbol AS Transaction_Currency,
	Cmmain.FuncFcused_uniq, Cmmain.PrFcused_uniq 
	 FROM Cmmain
		INNER JOIN Fcused TF ON Cmmain.Fcused_uniq = TF.Fcused_uniq
	  	INNER JOIN Fcused PF ON Cmmain.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON Cmmain.FuncFcused_uniq = FF.Fcused_uniq
	 OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
		WHERE CAST(cmmain.CmDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
		INNER JOIN CUSTOMER on CMMAIN.CUSTNO =Customer.CUSTNO 
		CROSS JOIN ARSETUP  
		INNER JOIN GL_NBRS on arsetup.AR_GL_NO = gl_nbrs.gl_nbr
	 WHERE cmmain.Is_cmpost =1
	AND cmmain.is_rel_gl =0
	-- 01/14/14 YS remove filter for cmTotal. Even if total is 0 there are trnasactions from cost of goods
	--AND cmTotal<>0 
	and CSTATUS <>'CANCELLED'),
	--SELECT * from CMHeader order by CMEMONO 
	CmTax AS   -- source table is Invstdtx
	(
	SELECT CmHeader.Trans_Dt,CMHeader.CustName,
	CMHeader.cMemoNo,
	CMHeader.PackListno,
	CMHeader.TransactionType, 
	CmHeader.cmUnique,
	CmHeader.SourceTable,
	CmHeader.cIdentifier,
	CmHeader.cDrill,
	CAST('InvStdTx' AS VARCHAR(25)) AS SourceSubTable,
	'INVSTDTXUNIQ' as cSubIdentifier,
	Invstdtx.INVSTDTXUNIQ as cSubDrill,
	CASE WHEN Invstdtx.Tax_Amt>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(Invstdtx.Tax_Amt) END AS Debit,
	CASE WHEN Invstdtx.Tax_Amt>0 THEN Invstdtx.Tax_Amt ELSE CAST(0.00 as numeric(14,2)) END as Credit ,
	Invstdtx.Gl_nbr_out as Gl_nbr,gl_nbrs.GL_DESCR,
	CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
	-- 12/15/16 VL: added functional and presentation currency fields
	CASE WHEN Invstdtx.Tax_AmtPR>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(Invstdtx.Tax_AmtPR) END AS DebitPR,
	CASE WHEN Invstdtx.Tax_AmtPR>0 THEN Invstdtx.Tax_AmtPR ELSE CAST(0.00 as numeric(14,2)) END as CreditPR ,	 
	Functional_Currency, Presentation_Currency, Transaction_Currency,
	FuncFcused_uniq, PrFcused_uniq 
	FROM Invstdtx INNER JOIN CMHeader ON InvStdTx.INVOICENO = CMHeader.CMEMONO  
	INNER JOIN GL_NBRS on INVSTDTX.GL_NBR_OUT = gl_nbrs.GL_NBR 
	),
	--SELECT * FROM CmTax order by CMEMONO 
	-- 07/13/16 VL comment out CmTax0 and FreightTax0 CTE cursor, now we have changed to save 0 amount tax in Invstdtx, so no need this duplicate records
	---- 09/28/15 VL added tax records with 0% rate, Maylaysia tax might have 0 percent, but need to be saved, invstdtx didnt' save 0 amount tax, need to insert separately
	--CmTax0 AS
	--(
	--SELECT CmHeader.Trans_Dt,CmHeader.CustName,
	--CMHeader.cMemoNo,
	--CMHeader.PackListno,
	--CMHeader.TransactionType, 
	--CmHeader.cmUnique,
	--CmHeader.SourceTable,
	--CmHeader.cIdentifier,
	--CmHeader.cDrill,
	--CAST('CmPricesTax' AS VARCHAR(25)) AS SourceSubTable,
	--'UNIQCMPRICESTAX' as cSubIdentifier,
	--CmpricesTax.UniqCmpricesTax as cSubDrill,
	--0 AS Debit,
	--0 as Credit ,
	--Taxtabl.Gl_nbr_out as Gl_nbr,Gl_nbrs.GL_DESCR,
	--CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, Currency, 'TAX0      ' AS AtdUniq_key
	--FROM CMHeader INNER JOIN CmpricesTax ON CmpricesTax.CmUnique =CMHeader.CmUnique
	--INNER JOIN Taxtabl ON Taxtabl.Tax_id = CmpricesTax.Tax_id 
	--INNER JOIN GL_NBRS on Taxtabl.GL_NBR_OUT =gl_nbrs.gl_nbr 
	--WHERE CmpricesTax.Tax_Rate = 0
	--),
	--FreightTax0 AS
	--(
	--SELECT CmHeader.Trans_Dt,CmHeader.CustName,
	--CMHeader.cMemoNo,
	--CMHeader.PackListno,
	--CMHeader.TransactionType, 
	--CmHeader.cmUnique,
	--CmHeader.SourceTable,
	--CmHeader.cIdentifier,
	--CmHeader.cDrill,
	--CAST('CmFreightTax' AS VARCHAR(25)) AS SourceSubTable,
	--'UNIQCMFREIGHTTAX' as cSubIdentifier,
	--CmFreightTax.UniqCmFreightTax as cSubDrill,
	--0 AS Debit,
	--0 as Credit ,
	--Taxtabl.Gl_nbr_out as Gl_nbr,Gl_nbrs.GL_DESCR,
	--CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, Currency, 'TAX0      ' AS AtdUniq_key
	--FROM CMHeader INNER JOIN CmFreightTax ON CmFreightTax.CmUnique =CMHeader.CmUnique
	--INNER JOIN Taxtabl ON Taxtabl.Tax_id = CmFreightTax.Tax_id 
	--INNER JOIN GL_NBRS on Taxtabl.GL_NBR_OUT =gl_nbrs.gl_nbr 
	--WHERE CmFreightTax.Tax_Rate = 0
	--),
	---- 09/28/15 VL End
	-- 07/13/16 VL End}
	CmFrt AS  -- the source table hear is CMMAIN
	(
	SELECT CmHeader.Trans_Dt,CMHeader.CustName,
	CMHeader.cMemoNo,
	CMHeader.PackListno,
	CMHeader.Cm_frt,
	CMHeader.TransactionType, 
	CMHeader.SourceTable,
	CMHeader.cIdentifier,
	CMHeader.cDrill,
	CMHeader.SourceSubTable,
	CMHeader.cSubIdentifier,
	CMHeader.cSubDrill,
	CMHeader.cmunique, 
	CASE WHEN CMHeader.Cm_Frt>0 THEN CMHeader.Cm_Frt ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
	CASE WHEN CMHeader.Cm_Frt>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(CMHeader.Cm_Frt) END as Credit ,
	CMHeader.Frt_Gl_no as Gl_nbr,gl_nbrs.GL_DESCR,
	CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
	-- 12/15/16 VL: added functional and presentation currency fields 
	CMHeader.Cm_frtPR,
	CASE WHEN CMHeader.Cm_FrtPR>0 THEN CMHeader.Cm_FrtPR ELSE CAST(0.00 as numeric(14,2)) END AS DebitPR,
	CASE WHEN CMHeader.Cm_FrtPR>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(CMHeader.Cm_FrtPR) END as CreditPR ,
	Functional_Currency, Presentation_Currency, Transaction_Currency,
	FuncFcused_uniq, PrFcused_uniq 
	FROM CMHeader inner join GL_NBRS on CMHeader.FRT_GL_NO = gl_nbrs.gl_nbr  WHERE CMHeader.Cm_Frt<>0
	),
	--SELECT * FROM CmFrt order by CMEMONO 
	CmDiscount AS  -- Source Table CMMAIN
	(
	SELECT CmHeader.Trans_Dt,CMHeader.CustName,
	CMHeader.cMemoNo,
	CMHeader.PackListno,
	CMHeader.DsctAmt,
	CMHeader.TransactionType, 
	CMHeader.SourceTable,
	CMHeader.cIdentifier,
	CMHeader.cDrill,
	CMHeader.SourceSubTable,
	CMHeader.cSubIdentifier,
	CMHeader.cSubDrill,
	CMHeader.cmunique, 
	CASE WHEN CMHeader.DsctAmt>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(CMHeader.DsctAmt) END AS Debit,
	CASE WHEN CMHeader.DsctAmt>0 THEN CMHeader.DsctAmt ELSE CAST(0.00 as numeric(14,2)) END as Credit ,
	CMHeader.DISC_GL_NO as Gl_nbr,gl_nbrs.GL_DESCR,
	CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
	-- 12/15/16 VL: added functional and presentation currency fields 
	CMHeader.DsctAmtPR, 
	CASE WHEN CMHeader.DsctAmtPR>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(CMHeader.DsctAmtPR) END AS DebitPR,
	CASE WHEN CMHeader.DsctAmtPR>0 THEN CMHeader.DsctAmtPR ELSE CAST(0.00 as numeric(14,2)) END as CreditPR ,
	Functional_Currency, Presentation_Currency, Transaction_Currency,
	FuncFcused_uniq, PrFcused_uniq 
	FROM CMHeader inner join GL_NBRS on CMHeader.DISC_GL_NO = gl_nbrs.gl_nbr WHERE CMHeader.DsctAmt<>0
	),
	--SELECT * FROM CmDiscount order by CMEMONO 
	PLCost AS   --- build for detail info
	(
	SELECT UNIQUELN
      ,CMQUANTITY
      ,CMPRICE
      ,CMEXTENDED
      ,TAXABLE
      ,FLAT
      ,INV_LINK
      ,RECORDTYPE
      ,SCRAPQTY
      ,SALESTYPE
      ,PL_GL_NBR
      ,PLPRICELNK
      ,PLUNIQLNK
      ,COG_GL_NBR
      ,CMPRICELNK
      ,CMPRUNIQ
      ,cmunique
	  -- 12/15/16 VL: added functional and presentation currency fields 
	  ,CMPRICEPR
      ,CMEXTENDEDPR
	 FROM cmprices WHERE cmunique IN (SELECT cmunique FROM CMHeader) 
	),
	--SELECT * from PlCost where plcost.CMEXTENDED<>0 order by cmunique  
	DetailTrns AS --- get Detail information records with cmextended<>0  Source table is cmprices
	(
	SELECT CmHeader.Trans_Dt,CMHeader.CustName,
	CMHeader.cMemoNo,
	CMHeader.PackListno,
	CMHeader.TransactionType, 
	CMHeader.SourceTable,
	CMHeader.cIdentifier,
	CMHeader.cDrill,
	'CmPrices' AS SourceSubTable,
	'CMPrUniq' AS cSubIdentifier,
	PLCost.CmPrUniq as cSubDrill,
	CMHeader.CmUnique, 
	CASE WHEN PLCost.cmextended>0 THEN PLCost.cmextended ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
	CASE WHEN PLCost.cmextended>0 THEN CAST(0.00 as numeric(14,2)) ELSE abs(PLCost.cmextended) END as Credit ,
	PLCost.pl_gl_nbr as Gl_nbr,gl_nbrs.GL_DESCR,
	CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
	-- 12/15/16 VL: added functional and presentation currency fields  
	CASE WHEN PLCost.cmextendedPR>0 THEN PLCost.cmextendedPR ELSE CAST(0.00 as numeric(14,2)) END AS DebitPR,
	CASE WHEN PLCost.cmextendedPR>0 THEN CAST(0.00 as numeric(14,2)) ELSE abs(PLCost.cmextendedPR) END as CreditPR ,
	Functional_Currency, Presentation_Currency, Transaction_Currency,
	FuncFcused_uniq, PrFcused_uniq 
	FROM PLCost  
	INNER JOIN CMHeader ON PLCost.cmunique  = CMHeader.CMUNIQUE   
	inner join GL_NBRS on plcost.PL_GL_NBR =gl_nbrs.gl_nbr
	-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
	--WHERE PLCost.cmextended<>0.00
	),
	--SELECT * from detailinfo order by cMemoNo
	StndCostInfo AS   --- Find standard cost for record <> 'O'
	(
	 SELECT DISTINCT Sodetail.uniqueln, Sodetail.uniq_key, PLCost.cmquantity, PLCost.cog_gl_nbr, 
		PLCost.scrapqty, PLCost.RecordType,PlCost.CMPRUNIQ,plcost.cmunique ,
		Inventor.stdcost,(plcost.cmquantity * Inventor.stdcost) AS nExtended,
		-- 12/15/16 VL: added functional and presentation currency fields  
		Inventor.stdcostPR,(plcost.cmquantity * Inventor.stdcostPR) AS nExtendedPR
	FROM Sodetail INNER JOIN PLCost ON PLCost.uniqueln = Sodetail.uniqueln 
	INNER JOIN INVENTOR ON Sodetail.UNIQ_KEY =Inventor.UNIQ_KEY 
	WHERE PlCost.RECORDTYPE <>'O' 
	-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
	--AND plcost.cmquantity * Inventor.stdcost<>0.00
	)
	--SELECT * from StndCostInfo order by cmunique 
	,
	CostOfGoodsTr AS
	(
	SELECT CmHeader.Trans_Dt,CMHeader.CustName,
	CMHeader.cMemoNo,
	CMHeader.PackListno,
	CMHeader.TransactionType, 
	CMHeader.SourceTable,
	CMHeader.cIdentifier,
	CMHeader.cDrill,
	'CmPrices' AS SourceSubTable,
	'CMPrUniq' AS cSubIdentifier,
	CMHeader.CmUnique, 
	PLCost.CmPrUniq as cSubDrill,
	CASE WHEN StndCostInfo.nExtended>0 THEN  CAST(0.00 as numeric(14,2)) ELSE abs(StndCostInfo.nExtended) END AS Debit,
	CASE WHEN StndCostInfo.nExtended>0 THEN StndCostInfo.nExtended ELSE CAST(0.00 as numeric(14,2)) END as Credit ,
	StndCostInfo.cog_gl_nbr as Gl_nbr,gl_nbrs.GL_DESCR,
	CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
	-- 12/15/16 VL: added functional and presentation currency fields  
	CASE WHEN StndCostInfo.nExtendedPR>0 THEN  CAST(0.00 as numeric(14,2)) ELSE abs(StndCostInfo.nExtendedPR) END AS DebitPR,
	CASE WHEN StndCostInfo.nExtendedPR>0 THEN StndCostInfo.nExtendedPR ELSE CAST(0.00 as numeric(14,2)) END as CreditPR ,
	Functional_Currency, Presentation_Currency, Transaction_Currency,
	FuncFcused_uniq, PrFcused_uniq 
	FROM PLCost  
	INNER JOIN CMHeader ON PLCost.cmunique  = CMHeader.CMUNIQUE  
	INNER JOIN StndCostInfo ON PlCost.CMPRUNIQ = StndCostInfo.CMPRUNIQ
	inner join GL_NBRS on StndCostInfo.cog_gl_nbr =gl_nbrs.gl_nbr
	),
	--select * from CostOfGoodsTr order by CMEMONO
	RMA AS
	(
	SELECT cmHeader.Trans_Dt,
			CMHeader.CUSTNAME,
			CMHeader.PACKLISTNO,
			CMHeader.IS_RMA,        
			CMHeader.cMemoNo, 
			CmHeader.CMUNIQUE, 
			cmalloc.uniqueln, cmalloc.w_key, 
			cmalloc.allocqty, warehous.wh_gl_nbr,
			Inventor.STDCOST,
			cmalloc.UNIQ_ALLOC,cmalloc.allocqty*Inventor.STDCOST as nExtended,
			CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
			-- 12/15/16 VL: added functional and presentation currency fields   
			Inventor.STDCOSTPR, cmalloc.allocqty*Inventor.STDCOSTPR as nExtendedPR,
			Functional_Currency, Presentation_Currency, Transaction_Currency,
			Cmheader.FuncFcused_uniq, Cmheader.PrFcused_uniq 
			FROM cmdetail INNER JOIN CMHeader ON cmdetail.cmUnique=CMHeader.CMUNIQUE  
			INNER JOIN cmalloc ON CmAlloc.UNIQUELN = CMDETAIL.UNIQUELN  and CmAlloc.cmUnique = cmdetail.cmUnique 
			INNER JOIN invtmfgr ON cmAlloc.W_KEY = Invtmfgr.W_key
			INNER JOIN warehous ON Warehous.UNIQWH = Invtmfgr.UNIQWH 
			INNER JOIN Inventor ON Inventor.UNIQ_KEY=Invtmfgr.UNIQ_KEY 
			-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
			--WHERE cmalloc.allocqty*Inventor.STDCOST<>0.00
	)
	--SELECT * FROM CMALLOCINFO ORDER BY CMEMONO 
	,
	RMATR AS
	(
	SELECT RMA.Trans_dt,
			RMA.CUSTNAME, 
			RMA.PACKLISTNO,
			RMA.CMEMONO,
			RMA.CmUnique,
			RMA.wh_gl_nbr as gl_nbr,gl_nbrs.GL_DESCR,
			'CM' AS TransactionType,
			CAST('CMMAIN' as varchar(25)) as SourceTable,
			'CMUnique' as cIdentifier,
			RMA.CMUNIQUE as cDrill,
			'CMALLOC' as SourceSubTable,
			'UNIQ_ALLOC' AS cSubIdentifier,
			Rma.UNIQ_ALLOC as cSubDrill,
			CASE WHEN Rma.nExtended>0 THEN Rma.nExtended ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
			CASE WHEN Rma.nExtended>0 THEN CAST(0.00 as numeric(14,2)) ELSE abs(Rma.nExtended) END as Credit,
			RMA.FY,RMA.Period ,RMA.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
			-- 12/15/16 VL: added functional and presentation currency fields   
			CASE WHEN Rma.nExtendedPR>0 THEN Rma.nExtendedPR ELSE CAST(0.00 as numeric(14,2)) END AS DebitPR,
			CASE WHEN Rma.nExtendedPR>0 THEN CAST(0.00 as numeric(14,2)) ELSE abs(Rma.nExtendedPR) END as CreditPR,
			Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq 
	FROM RMA INNER JOIN GL_NBRS on RMA.wh_gl_nbr=gl_nbrs.gl_nbr
	)
	--SELECT * FROM RMATR order by CMEMONO 
	,SCRAP AS 
	(
	SELECT PLCost.*,Inventor.STDCOST ,PlCost.SCRAPQTY *Inventor.STDCOST as nExtended,  
			cmHeader.Trans_Dt,
			CMHeader.CUSTNAME,
			CMHeader.PACKLISTNO,
			CMHeader.cMemoNo, 
			InvSetup.SHRI_GL_NO,
			CMHeader.FY,CMHeader.Period ,CMHeader.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
			-- 12/15/16 VL: added functional and presentation currency fields
			Inventor.STDCOSTPR ,PlCost.SCRAPQTY *Inventor.STDCOSTPR as nExtendedPR,
			Functional_Currency, Presentation_Currency, Transaction_Currency,
			CmHeader.FuncFcused_uniq, CmHeader.PrFcused_uniq   
			FROM PLCost INNER JOIN CMHeader ON plCost.cmUnique=CMHeader.CMUNIQUE 
			INNER JOIN Sodetail ON PlCost.UNIQUELN = Sodetail.UNIQUELN  
			INNER JOIN Inventor ON Inventor.UNIQ_KEY=Sodetail.UNIQ_KEY 
			CROSS JOIN InvSetup
			WHERE PlCost.RECORDTYPE <>'O' AND PlCost.RECORDTYPE<>'M' 
			-- 12/22/14 YS remove filter on the cost of goods and other levlels, for consistency
			--AND PlCost.SCRAPQTY *Inventor.STDCOST <>0.00 
	)
	--SELECT * FROM SCRAP ORDER BY cmunique 
	,
	SCRAPTR AS
	(
	SELECT SCRAP.Trans_Dt,
			Scrap.CUSTNAME,
			Scrap.PACKLISTNO,
			Scrap.cMemoNo, 
			scrap.CMunique,
			scrap.SHRI_GL_NO as GL_NBR, gl_nbrs.GL_DESCR,
			'CM' AS TransactionType,
			CAST('CMMAIN' as varchar(25)) as SourceTable,
			'CMUnique' as cIdentifier,
			SCRAP.CMUNIQUE as cDrill,
			'CMPRICES' as SourceSubTable,
			'CMPrUniq' AS cSubIdentifier,
			Scrap.CMPrUniq as cSubDrill,
			CASE WHEN Scrap.nExtended>0 THEN Scrap.nExtended ELSE CAST(0.00 as numeric(14,2)) END AS Debit,
			CASE WHEN Scrap.nExtended>0 THEN CAST(0.00 as numeric(14,2)) ELSE abs(Scrap.nExtended) END as Credit,
			Scrap.FY,Scrap.Period ,Scrap.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
			-- 12/15/16 VL: added functional and presentation currency fields 
			CASE WHEN Scrap.nExtendedPR>0 THEN Scrap.nExtendedPR ELSE CAST(0.00 as numeric(14,2)) END AS DebitPR,
			CASE WHEN Scrap.nExtendedPR>0 THEN CAST(0.00 as numeric(14,2)) ELSE abs(Scrap.nExtendedPR) END as CreditPR,
			Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq  
	 from SCRAP inner join GL_NBRS on scrap.SHRI_GL_NO = gl_nbrs.gl_nbr
	)
	,
	--SELECT * FROM SCRAPTR order by CMEMONO
	-- 09/28/15 VL added AtdUniq_key to save 'Tax0' if it's tax 0 record
	FinalCm AS
	(
	SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
			PackListno,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			GL_NBR,GL_DESCR,
			Debit,
			Credit,
			FY,Period,fk_fyDtlUniq, AtdUniq_key,
			-- 12/15/16 VL: added functional and presentation currency fields  
			DebitPR,
			CreditPR,
			Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq  
			FROM cmHeader
	UNION ALL
	SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
			PackListno,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			GL_NBR,GL_DESCR,
			Debit,
			Credit,
			FY,Period,fk_fyDtlUniq, AtdUniq_key,
			-- 12/15/16 VL: added functional and presentation currency fields  
			DebitPR,
			CreditPR,
			Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq  
			FROM CmTax	
	UNION ALL
	-- 07/13/16 VL comment out CmTax0 and FreightTax0 CTE cursor, now we have changed to save 0 amount tax in Invstdtx, so no need this duplicate records
	---- 10/05/15 VL added 
	--SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
	--		cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
	--		PackListno,
	--		TransactionType,
	--		SourceTable,
	--		cIdentifier,
	--		cDrill,
	--		SourceSubTable,
	--		cSubIdentifier,
	--		cSubDrill,
	--		GL_NBR,GL_DESCR,
	--		Debit,
	--		Credit,
	--		FY,Period,fk_fyDtlUniq, Currency, AtdUniq_key 
	--		FROM CmTax0	
	--UNION ALL
	--SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
	--		cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
	--		PackListno,
	--		TransactionType,
	--		SourceTable,
	--		cIdentifier,
	--		cDrill,
	--		SourceSubTable,
	--		cSubIdentifier,
	--		cSubDrill,
	--		GL_NBR,GL_DESCR,
	--		Debit,
	--		Credit,
	--		FY,Period,fk_fyDtlUniq, Currency, AtdUniq_key 
	--		FROM FreightTax0	
	---- 10/05/15 VL End}	
	--UNION ALL
	-- 07/13/16 VL End}
	SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
			cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
			PackListno,
			TransactionType,
			SourceTable,
			cIdentifier,
			cDrill,
			SourceSubTable,
			cSubIdentifier,
			cSubDrill,
			GL_NBR,GL_DESCR,
			Debit,
			Credit,
			FY,Period,fk_fyDtlUniq, AtdUniq_key, 
			-- 12/15/16 VL: added functional and presentation currency fields  
			DebitPR,
			CreditPR,
			Functional_Currency, Presentation_Currency, Transaction_Currency,
			FuncFcused_uniq, PrFcused_uniq  
			FROM CmFrt )
	--UNION ALL
	--SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
	--		cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
	--		PackListno,
	--		TransactionType,
	--		SourceTable,
	--		cIdentifier,
	--		cDrill,
	--		SourceSubTable,
	--		cSubIdentifier,
	--		cSubDrill,
	--		GL_NBR,GL_DESCR,
	--		Debit,
	--		Credit,
	--		FY,Period,fk_fyDtlUniq, AtdUniq_key,
	--		-- 12/15/16 VL: added functional and presentation currency fields  
	--		DebitPR,
	--		CreditPR,
	--		Functional_Currency, Presentation_Currency, Transaction_Currency 			 
	--		FROM CmDiscount 
	--	UNION ALL	
	--	SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
	--		cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
	--		PackListno,
	--		TransactionType,
	--		SourceTable,
	--		cIdentifier,
	--		cDrill,
	--		SourceSubTable,
	--		cSubIdentifier,
	--		cSubDrill,
	--		GL_NBR,GL_DESCR,
	--		Debit,
	--		Credit,
	--		FY,Period,fk_fyDtlUniq, AtdUniq_key,
	--		-- 12/15/16 VL: added functional and presentation currency fields  
	--		DebitPR,
	--		CreditPR,
	--		Functional_Currency, Presentation_Currency, Transaction_Currency 			 
	--		FROM DetailTrns	
	--	UNION ALL	
	--	SELECT cast(0 as bit) as lSelect, Trans_Dt,CustName,
	--		cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
	--		PackListno,
	--		TransactionType,
	--		SourceTable,
	--		cIdentifier,
	--		cDrill,
	--		SourceSubTable,
	--		cSubIdentifier,
	--		cSubDrill,
	--		GL_NBR,GL_DESCR,
	--		Debit,
	--		Credit,
	--		FY,Period,fk_fyDtlUniq, AtdUniq_key 
	--		-- 12/15/16 VL: added functional and presentation currency fields  
	--		DebitPR,
	--		CreditPR,
	--		Functional_Currency, Presentation_Currency, Transaction_Currency 
	--		FROM CostOfGoodsTr 
	--	UNION ALL	
	--	SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
	--		cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
	--		PackListno,
	--		TransactionType,
	--		SourceTable,
	--		cIdentifier,
	--		cDrill,
	--		SourceSubTable,
	--		cSubIdentifier,
	--		cSubDrill,
	--		GL_NBR,GL_DESCR,
	--		Debit,
	--		Credit,
	--		FY,Period,fk_fyDtlUniq, AtdUniq_key,
	--		-- 12/15/16 VL: added functional and presentation currency fields  
	--		DebitPR,
	--		CreditPR,
	--		Functional_Currency, Presentation_Currency, Transaction_Currency 
	--		FROM RMATR 
	--	UNION ALL	
	--	SELECT  cast(0 as bit) as lSelect,Trans_Dt,CustName,
	--		cMemoNo,cmUnique,cast(cMemoNo as varchar(50)) as DisplayValue,
	--		PackListno,
	--		TransactionType,
	--		SourceTable,
	--		cIdentifier,
	--		cDrill,
	--		SourceSubTable,
	--		cSubIdentifier,
	--		cSubDrill,
	--		GL_NBR,GL_DESCR,
	--		Debit,
	--		Credit,
	--		FY,Period,fk_fyDtlUniq, AtdUniq_key 
	--		-- 12/15/16 VL: added functional and presentation currency fields  
	--		DebitPR,
	--		CreditPR,
	--		Functional_Currency, Presentation_Currency, Transaction_Currency 
	--		FROM SCRAPTR 
					
	--	)
		--select * from finalcm order by cdrill
		SELECT FinalCm.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cMemoNo) as GroupIdNumber FROM FinalCm ORDER BY CMEMONO 
	END
	
END