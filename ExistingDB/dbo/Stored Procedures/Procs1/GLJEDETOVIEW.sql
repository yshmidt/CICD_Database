
-- =============================================
-- Author:		Yelena Shmidt	
-- Create date: <06/24/2011>
-- Description:	View used in General JE
--	10/21/15 VL added FC code which also has fields from CurrTrfr table
--	11/09/15 VL found probably can use the same code for FC installed or not, will comment out code for now
--	11/18/15 VL found still need different code for FC installed, uncomment
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--	03/09/17 VL added functional currency and FC fields for user to enter FC(transactional currency) value
--	03/27/17 VL chagned to use Gljehdro.fcused_uniq rather Currtrfr.fcused_uniq, Gljehdro.fchist_key rather than currtrfr.fhist_key
-- 06/19/17 VL added presentation currency symbol to show on list
-- 06/20/17 VL moved DebitPR, CreditPR and PRSymbol to after currency field, so can show in grid properly
-- 08/02/17 VL changed to show currency from currtrfr because currency might have different currency, if not from currtrfr, then still use Gljehdr.Fcused_uniq
-- 08/03/17 VL changed the column order bo Func Debit/credit, Trans Debit/credit, then PR debit/credit, removed currency label
-- =============================================
CREATE PROCEDURE [dbo].[GLJEDETOVIEW] 
	-- Add the parameters for the stored procedure here
	@pcjeohkey as char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- 11/09/15 VL found probably can use the same code for FC installed or not, will comment out code for now
---- 10/21/15 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
	BEGIN    

		-- Insert statements for procedure here
		SELECT Gljedeto.gl_nbr, Gl_nbrs.gl_descr, Gljedeto.debit,
	  Gljedeto.credit, Gljedeto.jeodkey, Gljedeto.fkjeoh
	 FROM 
		 gljedeto 
		LEFT OUTER JOIN gl_nbrs 
	   ON  Gljedeto.gl_nbr = Gl_nbrs.gl_nbr
	 WHERE  Gljedeto.fkjeoh = ( @pcjeohkey )
	 END
ELSE
	BEGIN
	-- 03/09/17 we used to not having FC fields (nor PR fields) in Gljedeto table, only left join with currtrfr to get creditfc/debitfc if the record is created from currency transfer, record created inside of
	-- JE module only had HC fields.  Now when adding functional currency, we also allow user to enter FC values in GL JE module, so I am not going to join with Currtrfr, just show the fields from Gljedeto itself
	-- When Currency transfer module created JE records, the values should be the same

	--SELECT Gljedeto.gl_nbr, Gl_nbrs.gl_descr, Gljedeto.debit,
	--  Gljedeto.credit, ISNULL(Currtrfr.debitfc,0) AS debitfc,
	--  ISNULL(Currtrfr.creditfc,0) AS creditfc,
	--  ISNULL(Currtrfr.ref_no,SPACE(10)) AS ref_no,
	--  ISNULL(Currtrfr.tax_id,SPACE(8)) AS tax_id,
	--  CASE WHEN Currtrfr.Tax_id IS NULL THEN SPACE(25) ELSE 
	--	CASE WHEN Currtrfr.Tax_id<>'' THEN Taxtabl.TaxDesc ELSE SPACE(25) END END AS TaxDesc,
	--  ISNULL(Currtrfr.tax_rate,0) AS tax_rate, 
	--  CASE WHEN Currtrfr.Fcused_uniq IS NULL THEN SPACE(3) ELSE	
	--	CASE WHEN Currtrfr.Fcused_uniq<>'' THEN Fcused.Symbol ELSE SPACE(10) END END AS Currency,
	--  Gljedeto.jeodkey, Gljedeto.fkjeoh, 
	--  Gljedeto.credit AS credithold, Gljedeto.debit AS debithold,
	--  Currtrfr.trfrkey, Currtrfr.chkmanual, Currtrfr.fchist_key,
	--  Currtrfr.fcused_uniq
	-- FROM Gljedeto LEFT OUTER JOIN Gl_nbrs 
	--   ON  Gljedeto.gl_nbr = Gl_nbrs.gl_nbr 
	--	LEFT OUTER JOIN Currtrfr 
	--   ON  Gljedeto.jeodkey = Currtrfr.jeodkey
	--    LEFT OUTER JOIN Taxtabl 
	--   ON Currtrfr.Tax_id = Taxtabl.Tax_id 
	--    LEFT OUTER JOIN Fcused 
	--   ON Currtrfr.Fcused_uniq = Fcused.Fcused_uniq
	-- WHERE  Gljedeto.fkjeoh = ( @pcjeohkey )
	SELECT Gljedeto.gl_nbr, Gl_nbrs.gl_descr, Gljedeto.debit,
	  Gljedeto.credit, Gljedeto.debitfc, Gljedeto.creditfc,Gljedeto.DebitPR, Gljedeto.CreditPR,
	  ISNULL(Currtrfr.ref_no,SPACE(10)) AS ref_no,
	  ISNULL(Currtrfr.tax_id,SPACE(8)) AS tax_id,
	  CASE WHEN Currtrfr.Tax_id IS NULL THEN SPACE(25) ELSE 
		CASE WHEN Currtrfr.Tax_id<>'' THEN Taxtabl.TaxDesc ELSE SPACE(25) END END AS TaxDesc,
	  ISNULL(Currtrfr.tax_rate,0) AS tax_rate, 
	  -- 08/03/17 VL comment out Currency and PRSymbol because removed from screen
	  --CASE WHEN Gljehdro.Fcused_uniq<>'' THEN Fcused.Symbol ELSE SPACE(3) END AS Currency,
	  -- 06/19/17 VL added presentation currency symbol
	  --PF.Symbol AS PRSymbol,
	  Gljedeto.jeodkey, Gljedeto.fkjeoh, 
	  Gljedeto.credit AS credithold, Gljedeto.debit AS debithold,
	  Currtrfr.trfrkey, Currtrfr.chkmanual, Gljehdro.fchist_key,
	  Gljehdro.fcused_uniq
	 FROM Gljedeto INNER JOIN Gljehdro
		ON Gljedeto.FkJeoh = Gljehdro.Jeohkey
		LEFT OUTER JOIN Gl_nbrs 
	   ON  Gljedeto.gl_nbr = Gl_nbrs.gl_nbr 
		LEFT OUTER JOIN Currtrfr 
	   ON  Gljedeto.jeodkey = Currtrfr.jeodkey
	    LEFT OUTER JOIN Taxtabl 
	   ON Currtrfr.Tax_id = Taxtabl.Tax_id 
	    LEFT OUTER JOIN Fcused 
	   ON Gljehdro.Fcused_uniq = Fcused.Fcused_uniq
	   -- 06/19/17 VL added presentation currency symbol to show on list
	    LEFT OUTER JOIN FcUsed PF
	   ON PF.FcUsed_Uniq = dbo.fn_GetPresentationCurrency() 
	 WHERE  Gljedeto.fkjeoh = ( @pcjeohkey )

	END
END