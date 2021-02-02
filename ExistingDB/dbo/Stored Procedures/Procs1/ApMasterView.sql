
CREATE PROCEDURE [dbo].[ApMasterView]
@gcUniqApHead as Char(10)=''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  -- Insert statements for procedure here 
  -- 02/06/15 VL added FC fields
  -- 11/16/16 VL added PR fields
SELECT Apmaster.uniqaphead,Apmaster.trans_dt, Apmaster.uniqsupno, Apmaster.invno,
  Apmaster.invdate, Apmaster.due_date, Apmaster.ponum, Apmaster.subtotal,
  Apmaster.terms, Apmaster.tax, Apmaster.freight, Apmaster.invamount,
  Apmaster.appmts, Apmaster.paypri, Apmaster.disc_perc, Apmaster.disc_amt,
  Apmaster.disc_tkn, Apmaster.aprpay, Apmaster.apnote, Apmaster.aptype,
  Apmaster.is_rel_gl, Apmaster.is_printed, Apmaster.linkadd,
  Apmaster.c_link, Apmaster.r_link, Supinfo.supname, Apmaster.init,
  Apmaster.pmttype, Apmaster.paid, Apmaster.apgllink, Apmaster.apstatus,
  Apmaster.editdate, Apmaster.reason, Apmaster.choldstatus,APMASTER.lPrepay,APMASTER.recver, 
  Apmaster.subtotalFC, Apmaster.taxFC, Apmaster.freightFC, Apmaster.invamountFC, Apmaster.appmtsFC,
  Apmaster.disc_amtFC, Apmaster.disc_tknFC, Apmaster.aprpayFC, APMASTER.Fcused_uniq, APMASTER.FcHist_key,
   Apmaster.subtotalPR, Apmaster.taxPR, Apmaster.freightPR, Apmaster.invamountPR, Apmaster.appmtsPR,
  Apmaster.disc_amtPR, Apmaster.disc_tknPR, Apmaster.aprpayPR, Apmaster.PRFcused_Uniq, Apmaster.FUNCFCUSED_UNIQ
   FROM 
     apmaster 
    INNER JOIN supinfo 
   ON  Apmaster.uniqsupno = Supinfo.uniqsupno  WHERE Apmaster.UniqApHead = @gcUniqApHead 
END