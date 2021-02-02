CREATE PROCEDURE [dbo].[ApMasterView3] 
	-- Add the parameters for the stored procedure here
@gcUniqApHead as char(10) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 06/30/15 VL added FC fields
	-- 11/30/16 VL added presentation currency fields
SELECT Apmaster.uniqaphead, 
  Apmaster.trans_dt, Apmaster.uniqsupno, Apmaster.invno,
  Apmaster.invdate, Apmaster.due_date, Apmaster.ponum, Apmaster.subtotal,
  Apmaster.terms, Apmaster.tax, Apmaster.freight, Apmaster.invamount,
  Apmaster.appmts, Apmaster.paypri, Apmaster.disc_perc, Apmaster.disc_amt,
  Apmaster.disc_tkn, Apmaster.aprpay, Apmaster.apnote, Apmaster.aptype,
  Apmaster.is_rel_gl, Apmaster.is_printed, Apmaster.linkadd,
  Apmaster.c_link, Apmaster.r_link, Apmaster.init, Apmaster.pmttype,
  Apmaster.paid, Apmaster.apgllink, Apmaster.editdate, Apmaster.apstatus,
  Apmaster.reason,lPrepay ,APMASTER.RecVer, 
  Apmaster.subtotalFC, Apmaster.taxFC, Apmaster.freightFC, Apmaster.invamountFC,
  Apmaster.appmtsFC, Apmaster.disc_amtFC, Apmaster.disc_tknFC, Apmaster.aprpayFC,
  Apmaster.Fcused_uniq, Apmaster.Fchist_key,
  -- 11/30/16 VL added presentation currency fields
  Apmaster.subtotalPR, Apmaster.taxPR, Apmaster.freightPR, Apmaster.invamountPR,
  Apmaster.appmtsPR, Apmaster.disc_amtPR, Apmaster.disc_tknPR, Apmaster.aprpayPR, 
  Apmaster.PRFcused_uniq, Apmaster.FuncFcused_uniq
FROM Apmaster

WHERE Apmaster.uniqaphead = @gcUniqApHead
END