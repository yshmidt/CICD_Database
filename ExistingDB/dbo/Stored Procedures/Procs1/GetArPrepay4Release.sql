-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/24/2011>
-- Description:	<get ar prepay information>
-- 10/02/15 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
-- 10/16/15 VL added AtdUniq_key, Currency
-- 10/19/15 VL Change Credit <> 0 AND Debit <> 0 to 'OR', also change ERVariance curror to only create one record for ER variance
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 05/18/16 VL Change the way to show prepaid release records as pairs, so two prepaid records and two ER records credit/debit to different GL numbers
-- 05/19/16 VL Added to include manual CM used in aroffset for FC, need to consider the ER variance, don't need to add for CM itself because they are crediting and debiting the same GL account with same amount
--			   Will only insert pair for ER variance for CM, Jira ticket MHD-282
-- 06/08/16 YS cannot check if the invoice has 'cm' in the the 2 left charcaters, becuase we allow the user to enter anything they want. 
-- added isManualCm column to acctsrec, will use this column. 
-- 07/01/16 YS reversed exchange rate
-- 07/25/16 VL In ER Variance SQL, added ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0 in criteria because sometimes the credit/debit has number after decimal point 3 digits (eg 0.001), although it <> 0, 
-- but in GL release/post, it only allows 2 digits, so user would only see 0.00 on screen, so here if ROUND()=0, then don't bother to get the records
-- 12/14/16 VL: added functional and presentation currency fields
-- 06/29/17 VL YS found when created ER variance, have to check for any variance functional or presentation, it is possible to have only one type of variance
-- 07/21/17 VL YS fixed exchange rate variance 
--07/25/17 YS missing one more place 
-- ============================================

CREATE PROCEDURE [dbo].[GetArPrepay4Release] 
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--declare @T TABLE (FiscalYr char(4),fk_fy_uniq char(10),Period Numeric(2,0),StartDate smalldatetime,EndDate smallDateTime,fyDtlUniq uniqueidentifier)
declare @T as [dbo].[AllFYPeriods]
insert into @T EXEC GlFyrstartEndView	;

-- 10/02/15 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
IF @lFCInstalled = 0
	BEGIN
	;WITH C as
	(		
	SELECT [DATE] as Trans_dt,
		UNIQ_AROFF,cTransaction,Aroffset.Amount as nTransAmount,CAST(AROFFSET.Invno as varchar(50)) as DisplayValue,
		CASE WHEN Aroffset.Amount>0 THEN cast(Aroffset.Amount as numeric(14,2)) 
			WHEN Aroffset.Amount<0 THEN CAST(0.00 as numeric(14,2)) END AS Credit,
		CASE WHEN Aroffset.Amount>0 THEN CAST(0.00 as numeric(14,2))
			WHEN Aroffset.Amount<0 THEN  cast(ABS(Aroffset.Amount) AS numeric(14,2)) END AS Debit,	
			CAST(' ' as CHAR(8)) as Saveinit,
			CAST('ARPREPAY' as varchar(50)) as TransactionType,    -- assign the same value as in glpostdef.PostType
			CAST('AROFFSET' as varchar(25)) as SourceTable,
			'ctransaction' as cIdentifier,
			cTransaction as cDrill,
			CAST('ACTSREC' as varchar(25)) as SourceSubTable,
			'UNIQUEAR' as cSubIdentifier,
			AROFFSET.UNIQUEAR as cSubDrill,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
			Arsetup.AR_GL_NO as GL_NBR 
	  from AROFFSET CROSS JOIN ARSETUP
	  INNER JOIN ACCTSREC ON Acctsrec.UNIQUEAR = AROFFSET.UNIQUEAR
	  OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
	  WHERE CAST(AROFFSET.DATE as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
	   where Acctsrec.lPrepay=1 
	   AND Aroffset.is_rel_gl =0),
	  D AS
	  (
	  SELECT [DATE] as Trans_dt,
		UNIQ_AROFF,cTransaction,Aroffset.Amount as nTransAmount,CAST(AROFFSET.Invno as varchar(50)) as DisplayValue,
		CASE WHEN Aroffset.Amount>0 THEN cast(Aroffset.Amount as numeric(14,2)) 
			WHEN Aroffset.Amount<0 THEN CAST(0.00 as numeric(14,2)) END AS Credit,
		CASE WHEN Aroffset.Amount>0 THEN CAST(0.00 as numeric(14,2))
			WHEN Aroffset.Amount<0 THEN  cast(ABS(Aroffset.Amount) AS numeric(14,2)) END AS Debit,	
			CAST(' ' as CHAR(8)) as Saveinit,
			CAST('ARPREPAY' as varchar(50)) as TransactionType,    -- assign the same value as in glpostdef.PostType
			CAST('AROFFSET' as varchar(25)) as SourceTable,
			'ctransaction' as cIdentifier,
			cTransaction as cDrill,
			CAST('ACTSREC' as varchar(25)) as SourceSubTable,
			'UNIQUEAR' as cSubIdentifier,
			AROFFSET.UNIQUEAR as cSubDrill,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
			ArSetup.CuDepGl_no  as GL_NBR 
	  from AROFFSET CROSS JOIN ARSETUP
	  INNER JOIN ACCTSREC ON Acctsrec.UNIQUEAR = AROFFSET .UNIQUEAR
	  OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
	  WHERE CAST(AROFFSET.DATE as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
	   where AROFFSET.CTRANSACTION IN (SELECT CTRANSACTION from C)
	   and Acctsrec.lPrepay=0  
	   ),
	   FinalArOff as
	   (
	   SELECT cast(0 as bit) as lSelect,Trans_dt,Debit,Credit,Saveinit,TransactionType ,DisplayValue,
	   SourceTable ,cIdentifier ,cDrill ,
		SourceSubTable ,cSubIdentifier ,cSubDrill ,
	   FY,Period,fk_fyDtlUniq,C.gl_nbr, Gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key 
	   FROM C inner join GL_NBRS on C.GL_NBR = gl_nbrs.gl_nbr
	   UNION ALL
	   SELECT cast(0 as bit) as lSelect,Trans_dt,Debit,Credit,Saveinit,TransactionType ,DisplayValue,
	   SourceTable ,cIdentifier ,cDrill ,
	   SourceSubTable ,cSubIdentifier ,cSubDrill ,
	   FY,Period,fk_fyDtlUniq,
	   D.GL_NBR , Gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key 
	   FROM D inner join GL_NBRS on D.Gl_nbr = gl_nbrs.gl_nbr)
	   SELECT FinalArOff.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalArOff ORDER BY cDrill
	END
ELSE 
BEGIN
-- IF FC is installed, need to include exchange rage variance  
-- 05/18/16 VL found the FC is using different way in showing the record
-- it's like
--						Debit	Credit
-- prepay	Deposit GL		0	105
-- invoice	Deposit GL	  105	  0
--			Deposit GL		3	  0
--			ER GL			0	  3
-- 
--- 06/16/16 YS rewrote the code in [GetArPrepay4Release] for FC 
;WITH C as
	(		
	SELECT [DATE] as Trans_dt,
		UNIQ_AROFF,cTransaction,Aroffset.Amount as nTransAmount,CAST(AROFFSET.Invno as varchar(50)) as DisplayValue,
		CASE WHEN Aroffset.Amount>0 THEN cast(Aroffset.Amount as numeric(14,2)) 
			WHEN Aroffset.Amount<0 THEN CAST(0.00 as numeric(14,2)) END AS Credit,
		CASE WHEN Aroffset.Amount>0 THEN CAST(0.00 as numeric(14,2))
			WHEN Aroffset.Amount<0 THEN  cast(ABS(Aroffset.Amount) AS numeric(14,2)) END AS Debit,	
			CAST(' ' as CHAR(8)) as Saveinit,
			CAST('ARPREPAY' as varchar(50)) as TransactionType,    -- assign the same value as in glpostdef.PostType
			CAST('AROFFSET' as varchar(25)) as SourceTable,
			'ctransaction' as cIdentifier,
			cTransaction as cDrill,
			CAST('ACTSREC' as varchar(25)) as SourceSubTable,
			'UNIQUEAR' as cSubIdentifier,
			AROFFSET.UNIQUEAR as cSubDrill,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
			Arsetup.AR_GL_NO as GL_NBR ,
			---06/16/16 YS  added FC columns and fcUsed table to get Symbol
			Aroffset.AmountFC as nTransAmountFC, ArOffset.Fcused_uniq, ArOffset.FCHIST_KEY, Orig_Fchist_key, aroffset.CFCGROUP,
			-- 12/14/16 VL added presentation currency fields
			Aroffset.AmountPR as nTransAmountPR, 
			CASE WHEN Aroffset.AmountPR>0 THEN cast(Aroffset.AmountPR as numeric(14,2)) 
			WHEN Aroffset.AmountPR<0 THEN CAST(0.00 as numeric(14,2)) END AS CreditPR,
			CASE WHEN Aroffset.AmountPR>0 THEN CAST(0.00 as numeric(14,2))
			WHEN Aroffset.AmountPR<0 THEN  cast(ABS(Aroffset.AmountPR) AS numeric(14,2)) END AS DebitPR,
			FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency, TF.Symbol AS Transaction_Currency,
			AROFFSET.FuncFcused_uniq, AROFFSET.PrFcused_uniq 
	  from AROFFSET 
		INNER JOIN Fcused TF ON AROFFSET.Fcused_uniq = TF.Fcused_uniq
	  	INNER JOIN Fcused PF ON AROFFSET.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON AROFFSET.FuncFcused_uniq = FF.Fcused_uniq
	  CROSS JOIN ARSETUP
	  INNER JOIN ACCTSREC ON Acctsrec.UNIQUEAR = AROFFSET.UNIQUEAR
	  OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
	  WHERE CAST(AROFFSET.DATE as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
	  --- 06/16/16 YS added code form manual CM . Added new column to acctsrec table isManualCM
	   where (Acctsrec.lPrepay=1 or Acctsrec.isManualCM=1)
	   AND Aroffset.is_rel_gl =0),
	  D AS
	  (
	  SELECT [DATE] as Trans_dt,
		aroffset.UNIQ_AROFF,aroffset.cTransaction,Aroffset.Amount as nTransAmount,CAST(AROFFSET.Invno as varchar(50)) as DisplayValue,
		-- 06/20/16 YS use c.nTransAmount
		CASE WHEN C.nTransAmount>0 THEN cast(c.nTransAmount as numeric(14,2)) 
			WHEN C.nTransAmount<0 THEN CAST(0.00 as numeric(14,2)) END AS Debit,
		CASE WHEN C.nTransAmount>0 THEN CAST(0.00 as numeric(14,2))
			WHEN C.nTransAmount<0 THEN  cast(ABS(Aroffset.Amount) AS numeric(14,2)) END AS Credit,	
			CAST(' ' as CHAR(8)) as Saveinit,
			CAST('ARPREPAY' as varchar(50)) as TransactionType,    -- assign the same value as in glpostdef.PostType
			CAST('AROFFSET' as varchar(25)) as SourceTable,
			'ctransaction' as cIdentifier,
			aroffset.cTransaction as cDrill,
			CAST('ACTSREC' as varchar(25)) as SourceSubTable,
			'UNIQUEAR' as cSubIdentifier,
			AROFFSET.UNIQUEAR as cSubDrill,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
			ArSetup.CuDepGl_no  as GL_NBR ,
		---06/16/16 YS  added FC columns and fcUsed table to get Symbol
			 Aroffset.AmountFC as nTransAmountFC, ArOffset.Fcused_uniq, ArOffset.FCHIST_KEY, AROFFSET.Orig_Fchist_key, aroffset.CFCGROUP,
			 -- 12/14/16 VL added presentation currency fields
			 Aroffset.AmountPR as nTransAmountPR,
			 CASE WHEN C.nTransAmountPR>0 THEN cast(c.nTransAmountPR as numeric(14,2)) 
			WHEN C.nTransAmountPR<0 THEN CAST(0.00 as numeric(14,2)) END AS DebitPR,
			CASE WHEN C.nTransAmountPR>0 THEN CAST(0.00 as numeric(14,2))
			WHEN C.nTransAmountPR<0 THEN  cast(ABS(Aroffset.AmountPR) AS numeric(14,2)) END AS CreditPR,
			FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency, TF.Symbol AS Transaction_Currency,
			AROFFSET.FuncFcused_uniq, AROFFSET.PrFcused_uniq 
	  from AROFFSET 
		INNER JOIN Fcused TF ON AROFFSET.Fcused_uniq = TF.Fcused_uniq
	  	INNER JOIN Fcused PF ON AROFFSET.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON AROFFSET.FuncFcused_uniq = FF.Fcused_uniq
	  CROSS JOIN ARSETUP 
	  INNER JOIN C on AROFFSET.CFCGROUP=c.CFCGROUP
	  INNER JOIN ACCTSREC ON Acctsrec.UNIQUEAR = AROFFSET .UNIQUEAR
	  OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
	  WHERE CAST(AROFFSET.DATE as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
	   --where AROFFSET.CTRANSACTION IN (SELECT CTRANSACTION from C)
	   --- 06/16/16 YS added code for manual CM . Added new column to acctsrec table isManualCM
	   where Acctsrec.lPrepay=0  and Acctsrec.isManualCM=0
	   )
	   ,
	   --07/01/16 YS reversed exchange rate
	   -- if difference between invoice original amount and current prepay is negative difference is credited , if positive - debited to the er account
	   exchageVarSite
	   as
	   (
	   -- 12/14/16 VL added presentation currency fields and change for fn_Convert4FCHC()
	   select c.Trans_dt, c.UNIQ_AROFF, c.cTransaction,
	   c.Saveinit, c.TransactionType, c.SourceTable,c.cIdentifier,c.cDrill, c.DisplayValue,c.SourceSubTable,c.cSubIdentifier,c.cSubDrill,c.fy,c.Period,c.fk_fyDtlUniq,
	   abs(c.nTransAmount) as PayAmount,
	   dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetFunctionalCurrency(),Orig_Fchist_key) as invAmount,
		case when dbo.fn_Convert4FCHC('F',Fcused_uniq, abs(nTransAmountFC), dbo.fn_GetFunctionalCurrency(),Orig_Fchist_key)>abs(c.nTransAmount) THEN 0.00 else abs(c.nTransAmount)-dbo.fn_Convert4FCHC('F',Fcused_uniq, abs(nTransAmountFC), dbo.fn_GetFunctionalCurrency(),Orig_Fchist_key) END as credit,
		CASE WHEN dbo.fn_Convert4FCHC('F',Fcused_uniq, abs(nTransAmountFC), dbo.fn_GetFunctionalCurrency(),Orig_Fchist_key)>abs(c.nTransAmount) THEN dbo.fn_Convert4FCHC('F',Fcused_uniq, abs(nTransAmountFC), dbo.fn_GetFunctionalCurrency(),Orig_Fchist_key)-abs(c.nTransAmount) else 0.00 END as debit,
		arsetup.CEV_GL_NO as gl_nbr,
		abs(c.nTransAmountPR) as PayAmountPR,
			--07/25/17 YS one more place used fn_GetFunctionalCurrency instead of  fn_GetPresentationCurrency
	   dbo.fn_Convert4FCHC('F',Fcused_uniq, nTransAmountFC, dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) as invAmountPR,
		case when dbo.fn_Convert4FCHC('F',Fcused_uniq, abs(nTransAmountFC), dbo.fn_GetPresentationCurrency(),Orig_Fchist_key)>abs(c.nTransAmountPR) THEN 0.00 else abs(c.nTransAmountPR)-dbo.fn_Convert4FCHC('F',Fcused_uniq, abs(nTransAmountFC), dbo.fn_GetPresentationCurrency(),Orig_Fchist_key) END as creditPR,
		CASE WHEN dbo.fn_Convert4FCHC('F',Fcused_uniq, abs(nTransAmountFC), dbo.fn_GetPresentationCurrency(),Orig_Fchist_key)>abs(c.nTransAmountPR) THEN dbo.fn_Convert4FCHC('F',Fcused_uniq, abs(nTransAmountFC), dbo.fn_GetPresentationCurrency(),Orig_Fchist_key)-abs(c.nTransAmountPR) else 0.00 END as debitPR,
		Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
	   From c cross join arsetup
	   ),
	  
	   
	 --   --- 06/16/16 YS added code for exchange rate Orig_Fchist_key is different from invoice Orig_Fchist_key
		---- find if CM/Prepay 
		----- positive erVar debit exchange rate account
		--select c.CFCGROUP,sum(abs(c.nTransAmount)) as PayAmount, inv.invAmount, 
		--case when inv.invAmount>sum(c.nTransAmount) THEN inv.invAmount-sum(abs(c.nTransAmount)) 
		--ELSE 0.00 END as credit,
		--CASE WHEN inv.invAmount>sum(c.nTransAmount) THEN 0 
		--ELSE sum(c.nTransAmount)-inv.invAmount END as debit
		--from c
		--CROSS APPLY 
		--(select D.CFCGROUP,sum(abs(d.nTransAmount)) as invAmount from D where d.CFCGROUP=c.CFCGROUP group by d.CFCGROUP) Inv
		----GROUP BY c.CFCGROUP,inv.invAmount
		--HAVING inv.invAmount<>sum(abs(c.nTransAmount)) 
		--),
		--exchageVarSite
		--as
		--(select c.Trans_dt, c.UNIQ_AROFF, cTransaction, case when ervar.Credit>0 then ervar.credit else ervar.debit end as nTransAmount, c.DisplayValue,
		--ervar.Debit,ervar.credit,c.Saveinit, c.TransactionType, c.SourceTable,c.cIdentifier,c.cDrill,  
		--'AROFFSET' as SourceSubTable, 'CFCGROUP' as cSubIdentifier, c.CFCGROUP as cSubDrill, c.FY, c.Period, 
		--	c.fk_fyDtlUniq, arsetup.Cev_gl_no AS GL_NBR, Currency
		--from ervar inner join c on ervar.CFCGROUP=c.CFCGROUP
		--cross join arsetup),
		exchangeARSite
		as
		(
		-- 12/14/16 VL added presentation currency fields 
		select v.Trans_dt,v.UNIQ_AROFF, v.cTransaction, v.DisplayValue,
		v. debit as credit,v.credit as Debit,v.Saveinit, v.TransactionType, v.SourceTable,v.cIdentifier,v.cDrill,  
		v.SourceSubTable, v.cSubIdentifier, v.cSubDrill, v.FY, v.Period, 
		v.fk_fyDtlUniq, arsetup.AR_GL_NO AS GL_NBR, 
		v.debitPR as creditPR,v.creditPR as DebitPR,Functional_Currency, Presentation_Currency, Transaction_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		from exchageVarSite V cross join arsetup
		),
	
		FinalArOff as
	   (
	   -- 12/14/16 VL added presentation currency fields 
	   SELECT cast(0 as bit) as lSelect,Trans_dt,Debit,Credit,Saveinit,TransactionType ,DisplayValue,
	   SourceTable ,cIdentifier ,cDrill ,
		SourceSubTable ,cSubIdentifier ,cSubDrill ,
	   FY,Period,fk_fyDtlUniq,C.gl_nbr, Gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key,
	   DebitPR,CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
	   FuncFcused_uniq, PrFcused_uniq 
	   FROM C inner join GL_NBRS on C.GL_NBR = gl_nbrs.gl_nbr
	   UNION ALL
	   SELECT cast(0 as bit) as lSelect,Trans_dt,Debit,Credit,Saveinit,TransactionType ,DisplayValue,
	   SourceTable ,cIdentifier ,cDrill ,
	   SourceSubTable ,cSubIdentifier ,cSubDrill ,
	   FY,Period,fk_fyDtlUniq,
	   D.GL_NBR , Gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key,
	   DebitPR,CreditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
	   FuncFcused_uniq, PrFcused_uniq  
	   FROM D inner join GL_NBRS on D.Gl_nbr = gl_nbrs.gl_nbr
	   --select * from FinalArOff order by cSubDrill
	   UNION ALL
	   -- 07/25/16 VL In ER Variance SQL, added ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0 in criteria because sometimes the credit/debit has number after decimal point 3 digits (eg 0.001), although it <> 0, 
	   -- but in GL release/post, it only allows 2 digits, so user would only see 0.00 on screen, so here if ROUND()=0, then don't bother to get the records
	   SELECT cast(0 as bit) as lSelect,Trans_dt,round(Debit,2) as debit,round(Credit,2) as credit,Saveinit,TransactionType ,DisplayValue,
	   SourceTable ,cIdentifier ,cDrill ,
	   SourceSubTable ,cSubIdentifier ,cSubDrill ,
	   FY,Period,fk_fyDtlUniq,
	   erVar.GL_NBR , Gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key,
	   round(DebitPR,2) as debitPR,round(CreditPR,2) as creditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
	   FuncFcused_uniq, PrFcused_uniq 
	   FROM exchageVarSite erVar inner join GL_NBRS on erVar.Gl_nbr = gl_nbrs.gl_nbr 
	   WHERE (ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0)
	   -- 07/21/17 VL YS found when created ER variance, have to check for any variance functional or presentation, it is possible to have only one type of variance
	   OR (ROUND(CreditPR,2)<>0 OR ROUND(DebitPR,2)<>0) 
	   UNION ALL
	   SELECT cast(0 as bit) as lSelect,Trans_dt,round(Debit,2) as debit,round(Credit,2) as credit ,Saveinit,TransactionType ,DisplayValue,
	   SourceTable ,cIdentifier ,cDrill ,
	   SourceSubTable ,cSubIdentifier ,cSubDrill ,
	   FY,Period,fk_fyDtlUniq,
	   ArerVar.GL_NBR , Gl_nbrs.GL_DESCR, SPACE(10) AS AtdUniq_key,
	   round(DebitPR,2) as debitPR,round(CreditPR,2) as creditPR, Functional_Currency, Presentation_Currency, Transaction_Currency,
	   FuncFcused_uniq, PrFcused_uniq 
	   FROM exchangeARSite arerVar inner join GL_NBRS on arerVar.Gl_nbr = gl_nbrs.gl_nbr
	   WHERE (ROUND(Credit,2)<>0 OR ROUND(Debit,2)<>0) 
	   -- 06/29/17 VL YS found when created ER variance, have to check for any variance functional or presentation, it is possible to have only one type of variance
		OR (ROUND(CreditPR,2)<>0 OR ROUND(DebitPR,2)<>0) 
	   )
	      
	   SELECT FinalArOff.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY cDrill) as GroupIdNumber FROM FinalArOff ORDER BY cDrill
	
END --- 	ELSE FOR IF FC is installed
END -- end for the SP