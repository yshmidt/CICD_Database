-- =============================================
-- Author:		??
-- Create date:
-- Modification:	
-- 09/18/13 YS change @gcInvNo parameter from char(10) to char(20), we had changed the length of the invoice number, but this procedure did not change.
-- 07/06/15 VL added FC fields 
-- 11/16/16 VL added PR fields
-- 01/27/17 VL separate FC and non FC, also added symbol for 3 currencies
-- 12/16/19 VL Added FC fields into not FC installed SQL statement but make the fields empty or 0
-- =============================================
CREATE PROCEDURE [dbo].[ApMaster4oneInvoiceView] 
	-- Add the parameters for the stored procedure here
	-- 09/18/13 YS change @gcInvNo parameter from char(10) to char(20), we had changed the length of the invoice number, but this procedure did not change.
	@lcUniqSupno as char(10) = ' ', @lcInvNo as char(20) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF dbo.fn_IsFCInstalled() = 0
	BEGIN
    -- Insert statements for procedure here
	SELECT ApMaster.InvNo,ApMaster.InvAmount, ApMaster.UniqApHead, 
	ApMaster.InvAmount - (ApMaster.ApPmts + ApMaster.Disc_Tkn) AS Balance, 
	ApMaster.Due_Date, ApMaster.PoNum, CASE WHEN ApMaster.Terms<>' ' THEN ApMaster.TERMS ELSE Supinfo.TERMS END AS Terms, 
	Supinfo.Supname, cHoldStatus ,apmaster.INVDATE ,APMASTER.RecVer,
	-- 12/16/19 VL Added FC fields into not FC installed SQL statement but make the fields empty or 0
	0 AS InvAmountFC, 0 AS BalanceFC,
	SPACE(10) AS FcUsed_uniq, SPACE(10) AS Fchist_key,
	0 AS InvAmountPR, 0 AS BalancePR,
	SPACE(10) AS PRFcused_Uniq, SPACE(10) AS FUNCFCUSED_UNIQ, SPACE(3) AS TSymbol, SPACE(3) AS PSymbol, SPACE(3) AS FSymbol
	FROM ApMaster INNER JOIN Supinfo  ON ApMaster.UniqSupNo = Supinfo.UNIQSUPNO
	WHERE UPPER(InvNo) = @lcInvNo 
	AND ApStatus <> 'Deleted'
	AND InvNo <> ' '
	AND Supinfo.UniqSupNo =CASE WHEN @lcUniqSupno=' ' THEN Supinfo.UniqSupNo ELSE @lcUniqSupno END
	AND ApMaster.Is_Printed = 0
	END
ELSE
	BEGIN
    -- Insert statements for procedure here
	SELECT ApMaster.InvNo,ApMaster.InvAmount, ApMaster.UniqApHead, 
	ApMaster.InvAmount - (ApMaster.ApPmts + ApMaster.Disc_Tkn) AS Balance, 
	ApMaster.Due_Date, ApMaster.PoNum, CASE WHEN ApMaster.Terms<>' ' THEN ApMaster.TERMS ELSE Supinfo.TERMS END AS Terms, 
	Supinfo.Supname, cHoldStatus ,apmaster.INVDATE ,APMASTER.RecVer,
	ApMaster.InvAmountFC, ApMaster.InvAmountFC - (ApMaster.ApPmtsFC + ApMaster.Disc_TknFC) AS BalanceFC,
	ApMaster.FcUsed_uniq, ApMaster.Fchist_key,
	ApMaster.InvAmountPR, ApMaster.InvAmountPR - (ApMaster.ApPmtsPR + ApMaster.Disc_TknPR) AS BalancePR,
	ApMaster.PRFcused_Uniq, ApMaster.FUNCFCUSED_UNIQ, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	FROM ApMaster 
	-- 01/27/17 VL changed criteria to get 3 currencies
	INNER JOIN Fcused PF ON ApMaster.PrFcused_uniq = PF.Fcused_uniq
	INNER JOIN Fcused FF ON ApMaster.FuncFcused_uniq = FF.Fcused_uniq			
	INNER JOIN Fcused TF ON ApMaster.Fcused_uniq = TF.Fcused_uniq
	INNER JOIN Supinfo  ON ApMaster.UniqSupNo = Supinfo.UNIQSUPNO
	WHERE UPPER(InvNo) = @lcInvNo 
	AND ApStatus <> 'Deleted'
	AND InvNo <> ' '
	AND Supinfo.UniqSupNo =CASE WHEN @lcUniqSupno=' ' THEN Supinfo.UniqSupNo ELSE @lcUniqSupno END
	AND ApMaster.Is_Printed = 0
	END
END