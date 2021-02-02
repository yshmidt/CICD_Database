-- =============================================
-- Author:		Bill Blake
-- Create date: ??
-- Description:	ApMasterView4
-- Modification:
-- 09/19/13 YS added "Terms" column to the output
-- 06/17/15 VL added FC fields
--- 01/17/17 YS added APTYPE column to this view, need to know when the record is a debit memo aptype='DM'
-- 01/27/17 VL added PR fields
-- =============================================
CREATE PROCEDURE [dbo].[ApMasterView4] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--09/19/13 YS added "Terms" column to the output
    -- Insert statements for procedure here
	SELECT Apmaster.uniqaphead, Apmaster.invamount,
  Apmaster.appmts, Apmaster.disc_tkn, Apmaster.paid, Apmaster.apstatus,
  Apmaster.is_rel_gl, Apmaster.trans_dt, Apmaster.uniqsupno,
  Apmaster.ponum, Apmaster.init, Apmaster.editdate,InvDate,
  Apmaster.reason, Apmaster.lpaymentprocess, DUE_DATE, APRPAY,lPrepay,apmaster.TERMS, invno,Recver,
  --- 01/17/17 YS added APTYPE column to this view, need to know when the record is a debit memo aptype='DM'
  Apmaster.invamountFC, Apmaster.appmtsFC, Apmaster.disc_tknFC, APRPAYFC, Fcused_uniq, Fchist_key, Orig_Fchist_key,aptype,
  -- 01/27/17 VL added PR fields
  Apmaster.invamountPR, Apmaster.appmtsPR, Apmaster.disc_tknPR, APRPAYPR, PRFcused_uniq, FuncFcused_uniq
 FROM 
     apmaster
 WHERE  ( Apmaster.invamount-(Apmaster.appmts+Apmaster.disc_tkn) ) <> ( 0.00 )
   AND  ( Apmaster.invamount-Apmaster.appmts ) <> ( 0.00 )

END