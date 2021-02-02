-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/26/2011>
-- Description:	<get drill down information for the AP Cheks>
-- Modification:
-- 09/15/15 VL Added FC fields
-- 05/27/16 VL: added if FC installed or not to separate the SQL because FC requires to join with Fcused to get currency
-- 12/13/16 VL: added presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownChecks]
	-- Add the parameters for the stored procedure here
	@ApChk_Uniq as char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- 05/27/16 VL added to check if FC is installed or not, if yes, need to get the currency 
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
    -- Insert statements for procedure here
	select apchkmst.checkno,apchkmst.checkdate,apchkmst.Status,apchkmst.CHECKNOTE,apchkmst.uniqsupno,Supinfo.SupName,apmaster.PONUM, 
	apmaster.INVDATE,apmaster.INVAMOUNT ,apmaster.INVNO as Invoiceno,apmaster.DUE_DATE,apmaster.lPrepay,
	apchkdet.UNIQAPHEAD ,apchkdet.ITEM_DESC 
	APCKD_UNIQ,apchkdet.APCHK_UNIQ,
    apchkdet.APRPAY as ChkItemAmnt,
    apchkdet.DISC_TKN,
	apmaster.INVAMOUNTFC, apchkdet.APRPAYFC as ChkItemAmntFC, apchkdet.DISC_TKNFC
	from APCHKDET inner join apchkmst on apchkdet.APCHK_UNIQ=apchkmst.APCHK_UNIQ
     left outer join APMASTER on apchkdet.UNIQAPHEAD =apmaster.UNIQAPHEAD 
     inner join SUPINFO on apchkmst.uniqsupno=supinfo.UNIQSUPNO 
     where apchkdet.apchk_uniq=@ApChk_Uniq     
ELSE
    -- Insert statements for procedure here
	select apchkmst.checkno,apchkmst.checkdate,apchkmst.Status,apchkmst.CHECKNOTE,apchkmst.uniqsupno,Supinfo.SupName,apmaster.PONUM, 
	apmaster.INVDATE,apmaster.INVAMOUNT ,apmaster.INVNO as Invoiceno,apmaster.DUE_DATE,apmaster.lPrepay,
	apchkdet.UNIQAPHEAD ,apchkdet.ITEM_DESC 
	APCKD_UNIQ,apchkdet.APCHK_UNIQ,
    apchkdet.APRPAY as ChkItemAmnt,
    apchkdet.DISC_TKN, FF.Symbol AS Functional_Currency,
	apmaster.INVAMOUNTFC, apchkdet.APRPAYFC as ChkItemAmntFC, apchkdet.DISC_TKNFC, TF.Symbol AS Transaction_Currency,
	apmaster.INVAMOUNTPR, apchkdet.APRPAYPR as ChkItemAmntPR, apchkdet.DISC_TKNPR, PF.Symbol AS Presentation_Currency
	from APCHKDET inner join apchkmst on apchkdet.APCHK_UNIQ=apchkmst.APCHK_UNIQ 
				INNER JOIN Fcused TF ON Apchkmst.Fcused_uniq = TF.Fcused_uniq
				INNER JOIN Fcused PF ON Apchkmst.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON Apchkmst.FuncFcused_uniq = FF.Fcused_uniq
	 left outer join APMASTER on apchkdet.UNIQAPHEAD =apmaster.UNIQAPHEAD 
     inner join SUPINFO on apchkmst.uniqsupno=supinfo.UNIQSUPNO 
     where apchkdet.apchk_uniq=@ApChk_Uniq     
END