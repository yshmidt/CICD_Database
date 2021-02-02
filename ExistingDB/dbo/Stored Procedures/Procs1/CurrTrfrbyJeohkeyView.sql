
-- =============================================
-- Author:		Vicky Lu	
-- Create date: <10/23/15>
-- Description:	View used in General JE, after Glejdeto got updated, need to update FC values saved in CurrTrfr table
-- Modification:
--	03/15/17 VL Added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[CurrTrfrbyJeohkeyView] 
	-- Add the parameters for the stored procedure here
	@pcjeohkey as char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT TrfrKey, Jeohkey, Jeodkey, Je_no, Ct_no, Bk_Uniq, Transdate, Ref_no, Debit, Credit, DebitFC, CreditFC, Orig_bk_bal,
		Orig_bk_balFC, Final_bk_bal, Final_bk_balFC, Gl_nbr, Chkmanual, Notes, Sundry, Tax_id, Tax_rate, Fchist_key, Fcused_uniq,
		DebitPR, CreditPR, Orig_bk_balPR, Final_bk_balPR, PRFCUSED_UNIQ, FUNCFCUSED_UNIQ
		FROM CurrTrfr
		WHERE Jeohkey = @pcjeohkey
END