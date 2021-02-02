-- =============================================
-- Author:		
-- Create date: 
-- Description:	AP Check Master view
-- Modified:	
-- 03/15/12 YS added shipbill address
-- 07/16/15 VL added FC fields
-- 02/14/17 VL added functional currency code
-- 10/14/20 VL added acctno, Zendesk# 6643 request by customer
-- =============================================
CREATE PROCEDURE [dbo].[ApChkMstView] 
	-- Add the parameters for the stored procedure here
	@gcApChk_Uniq as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --03/15/12 YS added shipbill address
	-- 07/16/15 VL added FC fields
	SELECT Banks.bank, Apchkmst.apchk_uniq, Apchkmst.batch_date,
  Apchkmst.checkno, Apchkmst.checkdate,
  Apchkmst.checkamt, Apchkmst.bk_acct_no,
  Apchkmst.pmt_type, Apchkmst.status, Apchkmst.ReconcileDate ,
  Apchkmst.checknote, Apchkmst.voiddate, Apchkmst.amt1099,
  Apchkmst.is_rel_gl, Apchkmst.is_printed, Apchkmst.saveinit,
  Apchkmst.trans_no, Apchkmst.bklastsave, Apchkmst.uniqsupno,
  Apchkmst.bk_uniq, Supinfo.supname as Supname, Apchkmst.r_link, Apchkmst.batchuniq,Apchkmst.ReconcileStatus, 
  Apchkmst.lapprepay,APCHKMST.RecVer, ISNULL(ShipBill.ShipTo,Supinfo.SUPNAME) as ShipTo,
  ISNULL(ShipBill.ADDRESS1,SPACE(35)) as Address1, ISNULL(ShipBill.ADDRESS2,SPACE(35)) as Address2,
  ISNULL(ShipBill.City,SPACE(20)) as City,ISNULL(ShipBill.State,SPACE(3)) as State,
  ISNULL(ShipBill.Zip,SPACE(10)) as Zip,ISNULL(ShipBill.Country,SPACE(20)) as Country,
  Apchkmst.CheckamtFC, Apchkmst.amt1099FC, Apchkmst.PmtType, Apchkmst.FCUSED_UNIQ, Apchkmst.FCHIST_KEY,
  -- 02/14/17 VL added functional currency code
  Apchkmst.CheckamtPR, Apchkmst.amt1099PR, Apchkmst.PRFCUSED_UNIQ, APCHKMST.FUNCFCUSED_UNIQ 
  -- 10/14/20 VL added acctno, Zendesk# 6643 request by customer
  , Supinfo.ACCTNO
 FROM apchkmst INNER JOIN banks ON  Apchkmst.bk_uniq=Banks.BK_UNIQ 
 INNER JOIN supinfo ON  Apchkmst.uniqsupno = Supinfo.uniqsupno 
 LEFT OUTER JOIN SHIPBILL ON APCHKMST.R_LINK =ShipBill.LINKADD   
  WHERE  Apchkmst.apchk_uniq = @gcApChk_Uniq
END