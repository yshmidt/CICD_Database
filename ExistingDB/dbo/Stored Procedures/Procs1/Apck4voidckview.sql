
CREATE  PROCEDURE [dbo].[Apck4voidckview]
	-- Add the parameters for the stored procedure here
	@lcCheckNo as char(10) = ' ', @lcBk_uniq as char(10) = ' '
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- 09/04/12 YS added ReconcileStatus nad Reconciledate
	-- 07/09/15 VL added PmtType field 
	-- 07/17/15 VL added CheckAmtFC, Fcused_uniq, and Fchist_key
	-- 02/23/17 VL added functional currency code
		SELECT CheckNo, CheckAmt, ApChk_Uniq, Status, UniqSupNo, BK_ACCT_NO, CHECKNOTE, R_Link, 
			lApPrepay, BatchUniq,BK_UNIQ ,ApchkMst.ReconcileStatus ,Apchkmst.ReconcileStatus,Apchkmst.ReconcileDate, 
			Apchkmst.PmtType, ApChkMst.CheckAmtFC, ApChkMst.Fcused_uniq, ApChkMst.Fchist_key,
			-- 02/23/17 VL added functional currency code
			ApChkMst.CheckAmtPR, ApChkMst.PRFCUSED_UNIQ, ApChkMst.FUNCFCUSED_UNIQ
		FROM ApChkMst 
		WHERE CheckNo = @lcCheckNo 
			AND Bk_Uniq = @lcBk_Uniq 
		
END