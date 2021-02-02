-- =============================================
-- Author:		Bill Blake
-- Create date: ??
-- Description:	get AP batch details
-- 07/06/15 VL added FC fields 
-- 07/24/15 VL added fcused_uniq and fchist_key
-- 10/09/15 VL rename Orig_Fchkey to Orig_Fchist_key
-- 02/07/17 VL added functional currency codes
-- 10/14/20 VL added acctno, Zendesk# 6643 request by customer
-- =============================================
CREATE PROCEDURE [dbo].[ApBatchDetailView]
	-- Add the parameters for the stored procedure here
	@gcBatchUniq as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT Apbatdet.disc_amt, Apbatdet.disc_tkn, Apbatdet.aprpay,
  Apbatdet.is_printed, Apbatdet.batchuniq, Apbatdet.batdetuniq,
  Apbatdet.fk_uniqaphead, Supinfo.supname,
  Apmaster.invamount-(Apmaster.appmts+Apmaster.disc_tkn) AS balance,
  Apmaster.invamount, Apmaster.due_date, 1 AS yesno, Apmaster.invno,
  CAST (null as smalldatetime) AS discdate, Apmaster.r_link, Apmaster.ponum, Apmaster.invdate,
  Apmaster.uniqsupno, Apmaster.choldstatus, APMASTER.RecVer,
  Apbatdet.disc_amtFC, Apbatdet.disc_tknFC, Apbatdet.aprpayFC, 
  Apmaster.invamountFC-(Apmaster.appmtsFC+Apmaster.disc_tknFC) AS balanceFC, Apmaster.invamountFC,
  Apmaster.FcUsed_uniq, Apmaster.Fchist_key, ApbatDet.Orig_Fchist_key,
  -- 02/07/17 VL added functional currency codes
  Apbatdet.disc_amtPR, Apbatdet.disc_tknPR, Apbatdet.aprpayPR, 
  Apmaster.invamountPR-(Apmaster.appmtsPR+Apmaster.disc_tknPR) AS balancePR, Apmaster.invamountPR,
  Apmaster.PrFcused_uniq, Apmaster.FuncFcused_uniq
  -- 10/14/20 VL added acctno, Zendesk# 6643 request by customer
  ,Supinfo.ACCTNO
 FROM
     apbatdet 
    INNER JOIN  apmaster 
    INNER JOIN supinfo
   ON  Apmaster.uniqsupno = Supinfo.uniqsupno 
   ON  Apbatdet.fk_uniqaphead = Apmaster.uniqaphead
 WHERE  Apbatdet.batchuniq = @gcBatchUniq
END