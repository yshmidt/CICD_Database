-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/31/2011
-- Description:	Get JE information for release
-- 10/12/15: added AtdUniq_key and insert 'Tax0' for FC, because in some case the user does have 0% rate but still need to be recorded in accounting
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 07/28/16 YS found that when Parmit Malaysia is using JE upload Fcused_Uniq is not populated, will fix their upload later, for now will find homecurrency and use the key to display the symbol
-- 12/21/16 VL added functional and presentation currency fields and separate FC and non-FC
-- 06/20/17 VL changed fn_GetHomeCurrency to use fn_GetFunctionalCurrency
-- 07/05/17 ys CAN BE in functional or a trabsaction or both currencies. Have to check for both amounts not being zero
-- =============================================
CREATE PROCEDURE [dbo].[GetJE4Release]
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
--07/28/16 YS found that when Paramit Malaysia is using JE upload Fcused_Uniq is not populated, will fix their upload later, for now will find homecurrency and use the key to display the symbol
DECLARE @lFCInstalled bit,@hcurrencySymbol char(10)
-- 04/08/16 VL changed to get FC installed from function

SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

--07/28/16 YS found that when Paramit Malaysia is using JE upload Fcused_Uniq is not populated, will fix their upload later, for now will find homecurrency and use the key to display the symbol
-- 06/20/17 VL changed fn_GetHomeCurrency to use fn_GetFunctionalCurrency
select @hcurrencySymbol=Fcused.Symbol
from Fcused where FcUsed.FcUsed_Uniq=dbo.fn_GetFunctionalCurrency()

IF @lFCInstalled = 0
	BEGIN

	;WITH JeDebit as
	(
	SELECT TransDate as Trans_dt,JeType,GLJEHDRO.JEOHKEY, 
		CAST('JE' as varchar(50)) as TransactionType, gljehdro.JE_NO ,'JE #: '+cast(gljehdro.JE_NO as varchar(50)) as DisplayValue,
			CAST('GLJEHDR' as varchar(25)) as SourceTable,
			'UNIQJEHEAD' as cIdentifier,
			GLJEHDRO.JEOHKEY as cDrill,
			CAST('GLJEDET' as varchar(25)) as SourceSubTable,
			'UNIQJEDET' as cSubIdentifier,
			GLJEDETO.JEODKEY as cSubDrill,
			GLJEDETO.DEBIT,
			GLJEDETO.Credit,
			GLJEDETO.GL_NBR ,Gl_nbrs.gl_Descr,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, SPACE(10) AS AtdUniq_key 	
	FROM GLJEHDRO INNER JOIN GLJEDETO ON GLJEHDRO.JEOHKEY = GLJEDETO.FKJEOH   
	OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(TransDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
	INNER JOIN GL_NBRS ON Gl_nbrs.GL_NBR=GLJEDETO.GL_NBR
	WHERE GLJEHDRO.STATUS ='APPROVED' and GLJEDETO.DEBIT <>0.00 and  GLJEHDRO.Is_Rel_Gl=0
	),
	JeCredit AS
	(
	SELECT Trans_dt,JeType,
		CAST('JE' as varchar(50)) as TransactionType,je_no, displayvalue,
		CAST('GLJEHDR' as varchar(25)) as SourceTable,
		'UNIQJEHEAD' as cIdentifier,
		JeDebit.JEOHKEY as cDrill,
		CAST('GLJEDET' as varchar(25)) as SourceSubTable,
		'UNIQJEDET' as cSubIdentifier,
		GLJEDETO.JEODKEY as cSubDrill,
		GLJEDETO.Debit,
		GLJEDETO.Credit,
		GLJEDETO.GL_NBR  ,Gl_nbrs.gl_Descr,
		JeDebit.Fy,JeDebit.Period,JeDebit.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key
		FROM JeDebit INNER JOIN GLJEDETO ON JeDebit.JEOHKEY=GLJEDETO.FKJEOH	
		INNER JOIN GL_NBRS ON GLJEDETO.GL_NBR = gl_nbrs.gl_nbr
		WHERE  GLJEDETO.Credit <>0.00 
	),
	-- 10/12/15 VL create 0% tax rate CTE and used in AllCRDB0 to get those 0% tax record from JE tables because first 2 cursors filtr out 0 value credit and debit records
	TaxRate0 AS
	(
	SELECT gl_nbr_in AS Gl_nbr 
		FROM TAXTABL 
		WHERE TAX_RATE = 0 
	UNION ALL 
	SELECT gl_nbr_out AS Gl_nbr 
		FROM Taxtabl 
		WHERE Tax_rate = 0
	),
	AllCRDB0 AS
	(
	SELECT TransDate as Trans_dt,JeType,GLJEHDRO.JEOHKEY, 
		CAST('JE' as varchar(50)) as TransactionType, gljehdro.JE_NO ,'JE #: '+cast(gljehdro.JE_NO as varchar(50)) as DisplayValue,
			CAST('GLJEHDR' as varchar(25)) as SourceTable,
			'UNIQJEHEAD' as cIdentifier,
			GLJEHDRO.JEOHKEY as cDrill,
			CAST('GLJEDET' as varchar(25)) as SourceSubTable,
			'UNIQJEDET' as cSubIdentifier,
			GLJEDETO.JEODKEY as cSubDrill,
			GLJEDETO.DEBIT,
			GLJEDETO.Credit,
			GLJEDETO.GL_NBR ,Gl_nbrs.gl_Descr,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, 
			CASE WHEN TaxRate0.Gl_nbr IS NOT NULL THEN 'TAX0      ' ELSE SPACE(10) END AS AtdUniq_key
	FROM GLJEHDRO INNER JOIN GLJEDETO ON GLJEHDRO.JEOHKEY = GLJEDETO.FKJEOH 
	LEFT OUTER JOIN TaxRate0 ON TaxRate0.Gl_nbr = GlJedeto.GL_NBR
	OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(TransDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
	INNER JOIN GL_NBRS ON Gl_nbrs.GL_NBR=GLJEDETO.GL_NBR
	WHERE GLJEHDRO.STATUS ='APPROVED' and (GLJEDETO.DEBIT = 0.00 AND GLJEDETO.CREDIT = 0.00) and  GLJEHDRO.Is_Rel_Gl=0
	),
	FinalJe as
	(
	SELECT cast(0 as bit) as lSelect,Trans_dt,JeType,JE_NO,DisplayValue ,
		TransactionType,SourceTable,cIdentifier,cDrill,
		SourceSubTable,cSubIdentifier,cSubDrill,
		Debit,Credit,GL_NBR,GL_DESCR,
		Fy,Period,fk_fyDtlUniq, AtdUniq_key
		FROM JeDebit 
	UNION 
		SELECT cast(0 as bit) as lSelect,Trans_dt,JeType,JE_NO,DisplayValue, 
		TransactionType,SourceTable,cIdentifier,cDrill,
		SourceSubTable,cSubIdentifier,cSubDrill,
		Debit,Credit,GL_NBR,GL_DESCR,
		Fy,Period,fk_fyDtlUniq, AtdUniq_key
		FROM JeCredit
	UNION
	SELECT cast(0 as bit) as lSelect,Trans_dt,JeType,JE_NO,DisplayValue, 
		TransactionType,SourceTable,cIdentifier,cDrill,
		SourceSubTable,cSubIdentifier,cSubDrill,
		Debit,Credit,GL_NBR,GL_DESCR,
		Fy,Period,fk_fyDtlUniq, AtdUniq_key
		FROM AllCRDB0
	)

	
	 SELECT FinalJe.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY Je_no) as GroupIdNumber FROM FinalJe ORDER BY Je_no 
	END
ELSE -- IF @lFCInstalled = 0
	--07/28/16 YS found that when Paramit Malaysia is using JE upload Fcused_Uniq is not populated, will fix their upload later, for now will find homecurrency and use the key to display the symbol
	BEGIN
	;WITH JeDebit as
	(
	SELECT TransDate as Trans_dt,JeType,GLJEHDRO.JEOHKEY, 
		CAST('JE' as varchar(50)) as TransactionType, gljehdro.JE_NO ,'JE #: '+cast(gljehdro.JE_NO as varchar(50)) as DisplayValue,
			CAST('GLJEHDR' as varchar(25)) as SourceTable,
			'UNIQJEHEAD' as cIdentifier,
			GLJEHDRO.JEOHKEY as cDrill,
			CAST('GLJEDET' as varchar(25)) as SourceSubTable,
			'UNIQJEDET' as cSubIdentifier,
			GLJEDETO.JEODKEY as cSubDrill,
			GLJEDETO.DEBIT,
			GLJEDETO.Credit,
			GLJEDETO.GL_NBR ,Gl_nbrs.gl_Descr,
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, 
			-- 12/21/16 VL, comment out the code that get home currency that YS added in 07/28/16, we should already fix it in Function version, will just link by FuncFcuse_uniq and PRFcused_uniq
			-- @hcurrencySymbol AS Currency, 
			SPACE(10) AS AtdUniq_key,
			-- 12/21/16 VL added functional and presentation currency fields
			GLJEDETO.DEBITPR,
			GLJEDETO.CreditPR,
			FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
			Gljehdro.FuncFcused_uniq, Gljehdro.PrFcused_uniq  	
	FROM 
	--07/28/16 YS found that when Paramit Malaysia is using JE upload Fcused_Uniq is not populated, will fix their upload later, for now will find homecurrency and use the key to display the symbol
	--Fcused INNER JOIN GLJEHDRO ON GlJehdro.Fcused_Uniq = Fcused.Fcused_Uniq
	GLJEHDRO 
		INNER JOIN Fcused PF ON GLJEHDRO.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON GLJEHDRO.FuncFcused_uniq = FF.Fcused_uniq
	INNER JOIN GLJEDETO ON GLJEHDRO.JEOHKEY = GLJEDETO.FKJEOH   
	OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(TransDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
	INNER JOIN GL_NBRS ON Gl_nbrs.GL_NBR=GLJEDETO.GL_NBR
	-- 07/05/17 ys CAN BE in functional or a trabsaction or both currencies. Have to check for both amounts not being zero
	WHERE GLJEHDRO.STATUS ='APPROVED' and 
	(GLJEDETO.DEBIT <>0.00 or GLJEDETO.DEBITPR <>0.00)
	and  GLJEHDRO.Is_Rel_Gl=0
	),
	JeCredit AS
	(
	SELECT Trans_dt,JeType,
		CAST('JE' as varchar(50)) as TransactionType,je_no, displayvalue,
		CAST('GLJEHDR' as varchar(25)) as SourceTable,
		'UNIQJEHEAD' as cIdentifier,
		JeDebit.JEOHKEY as cDrill,
		CAST('GLJEDET' as varchar(25)) as SourceSubTable,
		'UNIQJEDET' as cSubIdentifier,
		GLJEDETO.JEODKEY as cSubDrill,
		GLJEDETO.Debit,
		GLJEDETO.Credit,
		GLJEDETO.GL_NBR  ,Gl_nbrs.gl_Descr,
		JeDebit.Fy,JeDebit.Period,JeDebit.fk_fyDtlUniq, SPACE(10) AS AtdUniq_key,
		-- 12/21/16 VL added functional and presentation currency fields
		GLJEDETO.DebitPR,
		GLJEDETO.CreditPR,
		Functional_Currency, Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM JeDebit INNER JOIN GLJEDETO ON JeDebit.JEOHKEY=GLJEDETO.FKJEOH	
		INNER JOIN GL_NBRS ON GLJEDETO.GL_NBR = gl_nbrs.gl_nbr
		-- 07/05/17 ys CAN BE in functional or a trabsaction or both currencies. Have to check for both amounts not being zero
		WHERE  (GLJEDETO.Credit <>0.00 OR GLJEDETO.CreditPR <>0.00)
	),
	-- 10/12/15 VL create 0% tax rate CTE and used in AllCRDB0 to get those 0% tax record from JE tables because first 2 cursors filtr out 0 value credit and debit records
	TaxRate0 AS
	(
	SELECT gl_nbr_in AS Gl_nbr 
		FROM TAXTABL 
		WHERE TAX_RATE = 0 
	UNION ALL 
	SELECT gl_nbr_out AS Gl_nbr 
		FROM Taxtabl 
		WHERE Tax_rate = 0
	),
	AllCRDB0 AS
	(
	--07/28/16 YS found that when Paramit Malaysia is using JE upload Fcused_Uniq is not populated, will fix their upload later, for now will find homecurrency and use the key to display the symbol
	SELECT TransDate as Trans_dt,JeType,GLJEHDRO.JEOHKEY, 
		CAST('JE' as varchar(50)) as TransactionType, gljehdro.JE_NO ,'JE #: '+cast(gljehdro.JE_NO as varchar(50)) as DisplayValue,
			CAST('GLJEHDR' as varchar(25)) as SourceTable,
			'UNIQJEHEAD' as cIdentifier,
			GLJEHDRO.JEOHKEY as cDrill,
			CAST('GLJEDET' as varchar(25)) as SourceSubTable,
			'UNIQJEDET' as cSubIdentifier,
			GLJEDETO.JEODKEY as cSubDrill,
			GLJEDETO.DEBIT,
			GLJEDETO.Credit,
			GLJEDETO.GL_NBR ,Gl_nbrs.gl_Descr,
			--07/28/16 YS found that when Paramit Malaysia is using JE upload Fcused_Uniq is not populated, will fix their upload later, for now will find homecurrency and use the key to display the symbol
			-- 12/21/16 VL comment out @hcurrencySymbol as currency code, now use FuncFcused_uniq to get functional currency 
			fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq, --@hcurrencySymbol AS Currency,
			CASE WHEN TaxRate0.Gl_nbr IS NOT NULL THEN 'TAX0      ' ELSE SPACE(10) END AS AtdUniq_key,
			-- 12/21/16 VL added functional and presentation currency fields
			GLJEDETO.DebitPR,
			GLJEDETO.CreditPR,
			FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency,
			FuncFcused_uniq, PrFcused_uniq  	
	FROM 
	--07/28/16 YS found that when Paramit Malaysia is using JE upload Fcused_Uniq is not populated, will fix their upload later, for now will find homecurrency and use the key to display the symbol
	--Fcused INNER JOIN GLJEHDRO ON GLJEHDRO.Fcused_Uniq = Fcused.Fcused_Uniq 
	GLJEHDRO
			INNER JOIN Fcused PF ON GLJEHDRO.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON GLJEHDRO.FuncFcused_uniq = FF.Fcused_uniq
	INNER JOIN GLJEDETO ON GLJEHDRO.JEOHKEY = GLJEDETO.FKJEOH 
	LEFT OUTER JOIN TaxRate0 ON TaxRate0.Gl_nbr = GlJedeto.GL_NBR
	OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(TransDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
	INNER JOIN GL_NBRS ON Gl_nbrs.GL_NBR=GLJEDETO.GL_NBR
	WHERE GLJEHDRO.STATUS ='APPROVED'
	 -- 07/05/17 ys CAN BE in functional or a trabsaction or both currencies. Have to check for both amounts not being zero
	 and (GLJEDETO.DEBIT = 0.00 AND GLJEDETO.CREDIT = 0.00 and GLJEDETO.DEBITPR = 0.00 AND GLJEDETO.CREDITPR = 0.00  ) 
	 and  GLJEHDRO.Is_Rel_Gl=0
	),
	FinalJe as
	(
	SELECT cast(0 as bit) as lSelect,Trans_dt,JeType,JE_NO,DisplayValue ,
		TransactionType,SourceTable,cIdentifier,cDrill,
		SourceSubTable,cSubIdentifier,cSubDrill,
		Debit,Credit,GL_NBR,GL_DESCR,
		Fy,Period,fk_fyDtlUniq, AtdUniq_key,
		-- 12/21/16 VL added functional and presentation currency fields,
		DebitPR,CreditPR,Functional_Currency,Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM JeDebit 
	UNION 
		SELECT cast(0 as bit) as lSelect,Trans_dt,JeType,JE_NO,DisplayValue, 
		TransactionType,SourceTable,cIdentifier,cDrill,
		SourceSubTable,cSubIdentifier,cSubDrill,
		Debit,Credit,GL_NBR,GL_DESCR,
		Fy,Period,fk_fyDtlUniq, AtdUniq_key,
		-- 12/21/16 VL added functional and presentation currency fields,
		DebitPR,CreditPR,Functional_Currency,Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM JeCredit
	UNION
	SELECT cast(0 as bit) as lSelect,Trans_dt,JeType,JE_NO,DisplayValue, 
		TransactionType,SourceTable,cIdentifier,cDrill,
		SourceSubTable,cSubIdentifier,cSubDrill,
		Debit,Credit,GL_NBR,GL_DESCR,
		Fy,Period,fk_fyDtlUniq, AtdUniq_key,
		-- 12/21/16 VL added functional and presentation currency fields,
		DebitPR,CreditPR,Functional_Currency,Presentation_Currency,
		FuncFcused_uniq, PrFcused_uniq 
		FROM AllCRDB0
	)

	
	 SELECT FinalJe.*,ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY Je_no) as GroupIdNumber FROM FinalJe ORDER BY Je_no 
	END	

END