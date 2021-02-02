-- =============================================
-- Author:		<Bill Blake>
-- Create date: <??>
-- Description:	<Select Debit memo record>
-- Modification:
-- 06/25/15 VL added FC fields
-- 11/30/16 VL added PR fields
-- =============================================
CREATE PROCEDURE [dbo].[DebitMemoView]

@gcUniqDmHead as Char(10)='' 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT Dmemos.uniqdmhead, Dmemos.dmdate, Dmemos.dmemono, Dmemos.dmtotal,
  Dmemos.dmapplied, Dmemos.dmreason, Dmemos.saveinit, Dmemos.is_rel_gl,
  Dmemos.is_printed, Dmemos.uniqaphead, Dmemos.uniqsupno, Dmemos.dmstatus,
  Dmemos.dmtype, Supinfo.supname, Supinfo.acctno, Supinfo.status,
  Dmemos.r_link, Dmemos.editdt, Dmemos.reason, Dmemos.init, Dmemos.dmnote,
  Dmemos.invno, Dmemos.ponum, Dmemos.trans_no,
  Dmemos.dmrunique, Dmemos.ndiscamt, Dmemos.dmtotalFC, Dmemos.dmappliedFC, 
  Dmemos.ndiscamtFC, Dmemos.ntaxamt, Dmemos.ntaxamtFC, Dmemos.fcused_uniq, Dmemos.fchist_key,
  -- 11/30/16 VL added presentation currency fields
  Dmemos.dmtotalPR, Dmemos.dmappliedPR, Dmemos.ndiscamtPR, Dmemos.ntaxamtPR, PrFcused_uniq, FuncFcused_uniq
 FROM 
     dmemos 
    INNER JOIN supinfo 
 ON  Dmemos.UniqSupno = Supinfo.UniqSupno
 WHERE  Dmemos.UniqDmHead = @gcUniqDmHead 
END