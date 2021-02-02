-- =============================================
-- Author:		Vicky Lu
-- Create date: 11/30/15
-- Description:	Get Currency Transfer detail in Cashbook
-- Modification: 
-- 03/23/16 VL: Minor change to change AND CurrTrfr.JEOEHKEY = GlTransDetails.cSubDrill to AND CurrTrfr.JEOHKEY = GlTransDetails.cSubDrill, also added order by
-- 05/25/16 VL: Change the link between CurrTrfr and GlTransDetails
-- 06/29/16 VL: Added missing criteria to ZAllCurrTrfr 'AND GLJEDET.GL_NBR=@Bk_Gl_Nbr'
-- 04/26/17 VL: Added functional currency code
-- 07/31/17 VL: Found a situation that a sundry record that is created for another bank (CurrTrfr.Bk_uniq is not @Bk_uniq) but the GL number is for the bank @Bk_uniq, the record is filtered out in ZAllCurrTrfr
--				So I tried to change CurrTrfr.Bk_uniq = @Bk_uniq to (CurrTrfr.Bk_uniq = @Bk_uniq OR CurrTrfr.Gl_nbr = @Bk_Gl_nbr) to include the situation, but it's slow, and the code is very confusing
--				with Yelena's help, we re-create the code
-- =============================================
CREATE PROCEDURE [dbo].[CashbookCurrencyTransfer4BankView] 
	-- Add the parameters for the stored procedure here
	@Bk_Uniq char(10), @FiscalYr char(4), @Period numeric(2,0)
AS
BEGIN
	-- 03/23/16 VL: Minor change to change AND CurrTrfr.JEOEHKEY = GlTransDetails.cSubDrill to AND CurrTrfr.JEOHKEY = GlTransDetails.cSubDrill, also added order by
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @Bk_Gl_Nbr char(13) 
	SELECT @Bk_Gl_Nbr = Gl_nbr FROM Banks WHERE Bk_Uniq = @Bk_Uniq

-- 07/31/17 VL comment out the old code and modified the code Yelena helped to create
---- Get all currency transfer in this FY/Period
--;WITH ZAllCurrTrfr AS 
--(
--SELECT post_date, currtrfr.debitfc, currtrfr.creditfc, gljedet.debit, gljedet.credit, gljedet.uniqjedet,
--		currtrfr.jeohkey, ref_no, notes, trans_no, je_no, Sundry, Currtrfr.JEODKEY,
--		-- 04/26/17 VL: Added functional currency code
--		gljedet.debitPR, gljedet.creditPR, GLTRANSHEADER.PRFCUsed_Uniq, GLTRANSHEADER.FuncFCUsed_uniq
--	FROM Banks, CurrTrfr, GlTransDetails, GlTrans, GLTRANSHEADER, Gljedet
--	WHERE Banks.Bk_Uniq = CurrTrfr.Bk_Uniq
--	-- 05/25/16 VL changed next line
--	--AND CurrTrfr.JEOHKEY = GlTransDetails.cSubDrill
--	AND CurrTrfr.JEOHKEY = GlTransDetails.cDrill
--	--AND CurrTrfr.JEODKEY = GlTransDetails.cSubDrill
--	AND GlTransDetails.fk_gluniq_key = GlTrans.GLUNIQ_KEY
--	AND GlTrans.Fk_GlTransUnique = GLTRANSHEADER.GltransUnique
--	AND GLTRANS.GL_NBR = Banks.GL_NBR
--	AND GLTRANSHEADER.TransactionType = 'JE'
--	AND CurrTrfr.JEOHKEY = Gljedet.UNIQJEHEAD
--	AND CurrTrfr.JEODKEY = GLJEDET.UNIQJEDET
--	--AND CurrTrfr.Sundry = ''
--	AND CurrTrfr.Bk_Uniq = @Bk_Uniq
--	AND FY = @FiscalYr
--	AND Period = @Period
--	AND Banks.InternalUse = 1
--	-- 06/29/16 VL Added next line
--	AND GLJEDET.GL_NBR=@Bk_Gl_Nbr
--),
--ZEndBank AS
--(
---- Get bank transfer made TO for actual transfers
--SELECT Bank AS Endbank, Gljedet.Uniqjehead AS Jeohkey 
--   FROM Gljedet, ZAllCurrTrfr, Banks 
--   WHERE Gljedet.uniqjehead = ZAllCurrTrfr.jeohkey 
--   AND Gljedet.gl_nbr <> @Bk_Gl_Nbr
--   AND Gljedet.gl_nbr = banks.gl_nbr 
--   AND ZAllCurrTrfr.Sundry = ''
--),
--ZTrfr AS
--(
---- 04/26/17 VL: Added functional currency code
--SELECT DISTINCT Post_date, Debitfc, Creditfc, Debit, Credit, Ref_no, Je_no, Endbank, Notes, DebitPR, CreditPR
--   FROM ZAllCurrTrfr, ZEndBank
--   WHERE ZAllCurrTrfr.Jeohkey = ZEndBank.Jeohkey 
 
--),
--ZSundry AS
--(
---- 04/26/17 VL: Added functional currency code
--SELECT Post_date, ZAllCurrTrfr.Debitfc, ZAllCurrTrfr.CreditFC, Gljedet.Debit, Gljedet.Credit, Ref_no, Je_no, SPACE(50) AS Endbank, Notes,
--	Gljedet.DebitPR, Gljedet.CreditPR
--	FROM ZAllCurrTrfr, Gljedet
--	WHERE Gljedet.uniqjehead = ZAllCurrTrfr.jeohkey 
--	AND Gljedet.uniqjedet = ZAllCurrTrfr.JEODKEY
--	AND Sundry<>''
--	AND GLJEDET.GL_NBR = @Bk_Gl_Nbr
--	AND (ZAllCurrTrfr.debit+ZAllCurrTrfr.credit) <> 0 
--)
---- 04/26/17 VL: Added functional currency code
--SELECT Post_date, Debitfc, CreditFC, Debit, Credit, Ref_no, Je_no, Endbank, Notes, DebitPR, CreditPR
--	FROM ZTrfr
--UNION ALL
--SELECT Post_date, Debitfc, CreditFC, Debit, Credit, Ref_no, Je_no, Endbank, Notes, DebitPR, CreditPR
--	FROM ZSundry
--ORDER BY Post_date, Ref_no

---- 07/31/17 VL add new code
SELECT GL.POST_DATE, t.DEBITFC, t.CREDITFC, jd.DEBIT, jd.CREDIT,t.REF_NO,t.JE_NO,ISNULL(B.BANK,SPACE(50)) AS EndBank, t.NOTES, jd.DEBITPR, jd.CREDITPR
	FROM Currtrfr T INNER JOIN GLJEDET jd ON t.JEODKEY=jd.UNIQJEDET
	INNER JOIN GlJehdr jh ON jd.UNIQJEHEAD=jh.UNIQJEHEAD
	CROSS APPLY (SELECT h.TRANS_no,h.POST_DATE
				from GLTRANSHEADER h INNER JOIN gltrans T1 on h.GLTRANSUNIQUE=t1.Fk_GLTRansUnique
				inner join GlTransDetails d ON d.fk_gluniq_key=t1.GLUNIQ_KEY
				WHERE h.TransactionType='JE' AND h.FY=@FiscalYr and h.period=@Period 
				and d.cDrill=jd.UNIQJEHEAD AND t1.GL_NBR=@Bk_Gl_Nbr) GL
	CROSS APPLY (SELECT Bank FROM Banks INNER JOIN Gljedet ON banks.gl_nbr = Gljedet.gl_nbr AND Gljedet.GL_NBR<>@Bk_Gl_Nbr AND GLJEDET.UNIQJEHEAD = jd.UNIQJEHEAD) B
	WHERE jd.GL_NBR=@Bk_Gl_Nbr and SUNDRY=''
UNION ALL
SELECT GL.POST_DATE, t.DEBITFC, t.CREDITFC, jd.DEBIT, jd.CREDIT,t.REF_NO,t.JE_NO, SPACE(50) AS EndBank, t.NOTES, jd.DEBITPR, jd.CREDITPR
	FROM Currtrfr T INNER JOIN GLJEDET jd ON t.JEODKEY=jd.UNIQJEDET AND t.JEOHKEY = jd.UNIQJEHEAD
	INNER JOIN GlJehdr jh ON jd.UNIQJEHEAD=jh.UNIQJEHEAD
	CROSS APPLY (SELECT h.TRANS_no,h.POST_DATE
				from GLTRANSHEADER h INNER JOIN gltrans T1 on h.GLTRANSUNIQUE=t1.Fk_GLTRansUnique
				inner join GlTransDetails d ON d.fk_gluniq_key=t1.GLUNIQ_KEY
				where h.TransactionType='JE' AND h.FY=@FiscalYr and h.period=@Period 
				and d.cDrill=jd.UNIQJEHEAD AND t1.GL_NBR=@Bk_Gl_Nbr) GL
	WHERE jd.GL_NBR=@Bk_Gl_Nbr and SUNDRY<>''
	AND jd.DEBIT+jd.CREDIT <> 0
	    
END