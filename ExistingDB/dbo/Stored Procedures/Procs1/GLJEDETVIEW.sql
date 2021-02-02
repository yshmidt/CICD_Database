
-- =============================================
-- Author:		Yelena Shmidt	
-- Create date: <06/24/2011>
-- Description:	View used in General JE
--	10/21/15 VL added FC code which also has fields from CurrTrfr table
--  04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--	03/09/17 VL added functional currency and FC fields for user to enter FC(transactional currency) value
--	03/27/17 VL chagned to use Gljehdr.fcused_uniq rather Currtrfr.fcused_uniq, Gljehdr.fchist_key not Currtrfr.fchist_key
-- 06/19/17 VL added presentation currency symbol to show on list
-- 06/20/17 VL moved DebitPR, CreditPR and PRSymbol to after currency field, so can show in grid properly
-- 08/02/17 VL changed to show currency from currtrfr because currency might have different currency, if not from currtrfr, then still use Gljehdr.Fcused_uniq
-- 08/03/17 VL changed the column order bo Func Debit/credit, Trans Debit/credit, then PR debit/credit, removed currency label
-- =============================================
CREATE PROCEDURE [dbo].[GLJEDETVIEW] 
	-- Add the parameters for the stored procedure here
	@pcUniqJeHead as char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- 10/21/15 VL added to check if FC is installed or not, if yes, need to get the exchange rate variance calculated
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
	BEGIN    
		-- Insert statements for procedure here
		SELECT Gljedet.gl_nbr, Gl_nbrs.gl_descr, Gljedet.debit, Gljedet.credit,
	  Gljedet.uniqjehead, Gljedet.uniqjedet
	 FROM 
		 gljedet  LEFT OUTER JOIN gl_nbrs 
	   ON  Gljedet.gl_nbr = Gl_nbrs.gl_nbr
	 WHERE  Gljedet.uniqjehead = ( @pcUniqJeHead )
	 END
ELSE
	BEGIN
	-- 03/09/17 we used to not having FC fields (nor PR fields) in Gljedeto table, only left join with currtrfr to get creditfc/debitfc if the record is created from currency transfer, record created inside of
	-- JE module only had HC fields.  Now when adding functional currency, we also allow user to enter FC values in GL JE module, so I am not going to join with Currtrfr, just show the fields from Gljedeto itself
	-- When Currency transfer module created JE records, the values should be the same

		---- Insert statements for procedure here
		--SELECT Gljedet.gl_nbr, Gl_nbrs.gl_descr, Gljedet.debit, Gljedet.credit,
	 -- ISNULL(Currtrfr.debitfc,0) AS debitfc,
	 -- ISNULL(Currtrfr.creditfc,0) AS creditfc,
	 -- ISNULL(Currtrfr.ref_no,SPACE(10)) AS ref_no,
	 -- ISNULL(Currtrfr.tax_id,SPACE(8)) AS tax_id,
	 -- CASE WHEN Currtrfr.Tax_id IS NULL THEN SPACE(25) ELSE 
		--CASE WHEN Currtrfr.Tax_id<>'' THEN Taxtabl.TaxDesc ELSE SPACE(25) END END AS TaxDesc,
	 -- ISNULL(Currtrfr.tax_rate,0) AS tax_rate, 
	 -- CASE WHEN Currtrfr.Fcused_uniq IS NULL THEN SPACE(3) ELSE	
		--CASE WHEN Currtrfr.Fcused_uniq<>'' THEN Fcused.Symbol ELSE SPACE(10) END END AS Currency,
	 -- Gljedet.uniqjehead, Gljedet.uniqjedet,
	 -- Currtrfr.trfrkey, Currtrfr.chkmanual, Currtrfr.fchist_key,
	 -- Currtrfr.fcused_uniq
	 --FROM 
		-- gljedet  LEFT OUTER JOIN gl_nbrs 
	 --  ON  Gljedet.gl_nbr = Gl_nbrs.gl_nbr
		--LEFT OUTER JOIN Currtrfr 
	 --  ON  Gljedet.uniqjedet  = Currtrfr.jeodkey
	 --   LEFT OUTER JOIN Taxtabl 
	 --  ON Currtrfr.Tax_id = Taxtabl.Tax_id 
	 --   LEFT OUTER JOIN Fcused 
	 --  ON Currtrfr.Fcused_uniq = Fcused.Fcused_uniq
	 --WHERE  Gljedet.uniqjehead = ( @pcUniqJeHead )

		-- Insert statements for procedure here
	  -- 08/03/17 VL re-arrange the fields to show Func, Trans, PR currencies then the rest of fields
	SELECT Gljedet.gl_nbr, Gl_nbrs.gl_descr, Gljedet.debit, Gljedet.credit,
		Gljedet.debitfc, Gljedet.creditfc,Gljedet.DebitPR, Gljedet.CreditPR,
		ISNULL(Currtrfr.ref_no,SPACE(10)) AS ref_no,
		ISNULL(Currtrfr.tax_id,SPACE(8)) AS tax_id,
		CASE WHEN Currtrfr.Tax_id IS NULL THEN SPACE(25) ELSE 
		CASE WHEN Currtrfr.Tax_id<>'' THEN Taxtabl.TaxDesc ELSE SPACE(25) END END AS TaxDesc,
		ISNULL(Currtrfr.tax_rate,0) AS tax_rate, 
		-- 08/03/17 VL comment out Currency and PRSymbol because removed from screen
		--CASE WHEN Gljehdr.Fcused_uniq<>'' THEN Fcused.Symbol ELSE SPACE(3) END AS Currency,
		-- 06/19/17 VL added presentation currency symbol
		--PF.Symbol AS PRSymbol,
		Gljedet.uniqjehead, Gljedet.uniqjedet,
		Currtrfr.trfrkey, Currtrfr.chkmanual, Gljehdr.fchist_key,
		Gljehdr.fcused_uniq
	FROM 
		gljedet INNER JOIN Gljehdr
		ON Gljedet.UNIQJEHEAD = Gljehdr.UNIQJEHEAD
		LEFT OUTER JOIN gl_nbrs 
		ON  Gljedet.gl_nbr = Gl_nbrs.gl_nbr
		LEFT OUTER JOIN Currtrfr 
		ON  Gljedet.uniqjedet  = Currtrfr.jeodkey
	    LEFT OUTER JOIN Taxtabl 
		ON Currtrfr.Tax_id = Taxtabl.Tax_id 
	    LEFT OUTER JOIN Fcused 
		ON Gljehdr.Fcused_uniq = Fcused.Fcused_uniq
		-- 06/19/17 VL added presentation currency symbol to show on list
	    LEFT OUTER JOIN FcUsed PF
		ON PF.FcUsed_Uniq = dbo.fn_GetPresentationCurrency() 
	 WHERE  Gljedet.uniqjehead = ( @pcUniqJeHead )

	END
END