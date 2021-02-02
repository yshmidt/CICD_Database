-- =============================================
-- Author:		??
-- Create date: ??
-- Description:	ApOffsetView
-- Modification:
-- 06/18/15 VL added FC fields
-- 02/07/17 VL added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[ApOffsetView]
      -- Add the parameters for the stored procedure here
      @gcUniq_apoff as char(10) = ' '
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
 
    -- Insert statements for procedure here
SELECT Apoffset.uniq_apoff, Apoffset.uniqaphead, Apoffset.UniqApHead,
  Apoffset.uniqsupno, Apoffset.UniqSupNo, Apoffset.ref_no, Apoffset.invno,
  Apoffset.amount, Apoffset.date, Apoffset.initials, Apoffset.offnote,
  Apoffset.cgroup, Apoffset.dcurdate, Apoffset.uniq_save,
  Apoffset.is_rel_gl, Apoffset.amountFC, Apoffset.Fcused_uniq, 
  Apoffset.Fchist_key, Apoffset.Orig_Fchist_key,
  -- 02/07/17 VL added functional currency code
  Apoffset.amountPR, PrFcused_uniq, FuncFcused_uniq 
FROM
     apoffset
WHERE  Apoffset.uniq_apoff = @gcUniq_apoff
 
END