-- =============================================
-- Author:		
-- Create date: 
-- Description:	AP Check Master view 2
-- Modified:	
-- 02/14/17 VL added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[ApChkMstView2]
	-- Add the parameters for the stored procedure here
	@gcApChk_Uniq as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT  Apchkmst.apchk_uniq, Apchkmst.batch_date,
  Apchkmst.checkno, Apchkmst.checkdate,
  Apchkmst.checkamt, Apchkmst.bk_acct_no,
  Apchkmst.pmt_type, Apchkmst.status, Apchkmst.ReconcileDate ,Apchkmst.ReconcileStatus, 
  Apchkmst.checknote, Apchkmst.voiddate, Apchkmst.amt1099,
  Apchkmst.is_rel_gl, Apchkmst.is_printed, Apchkmst.saveinit,
  Apchkmst.trans_no, Apchkmst.bklastsave, Apchkmst.uniqsupno,
  Apchkmst.bk_uniq, Apchkmst.r_link, Apchkmst.batchuniq,
  Apchkmst.lapprepay,APCHKMST.RecVer,
  -- 02/14/17 VL added functional currency code
  Apchkmst.checkamtFC, Apchkmst.AMT1099FC, Apchkmst.Fcused_uniq, Apchkmst.FCHIST_KEY,
  Apchkmst.checkamtPR, Apchkmst.amt1099PR, Apchkmst.PRFCUSED_UNIQ, APCHKMST.FUNCFCUSED_UNIQ
 FROM  apchkmst 
  WHERE  Apchkmst.apchk_uniq = @gcApChk_Uniq
END