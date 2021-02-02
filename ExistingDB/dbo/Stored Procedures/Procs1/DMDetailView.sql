-- =============================================
-- Author:		<Bill Blake>
-- Create date: <??>
-- Description:	<Select Debit memo detail records>
-- Modification:
-- 06/25/15 VL added FC fields
-- 01/06/16 VL removed Tax_pct field
-- 11/30/16 VL added presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[DMDetailView] 
@gcUniqDmHead as Char(10)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT Apdmdetl.uniqdmdetl, Apdmdetl.uniqdmhead, Apdmdetl.item_no,
  Apdmdetl.item_desc, Apdmdetl.is_tax, Apdmdetl.qty_each,
  Apdmdetl.price_each, Apdmdetl.item_total, Apdmdetl.gl_nbr,
  Apdmdetl.item_note, Apdmdetl.uniqaphead, Apdmdetl.UNIQAPDETL,Gl_Nbrs.Gl_Descr,
  Apdmdetl.price_eachFC, Apdmdetl.item_totalFC, Apdmdetl.price_eachPR, Apdmdetl.item_totalPR
 FROM
     Apdmdetl
    LEFT OUTER JOIN Gl_Nbrs
   ON  Apdmdetl.Gl_Nbr = Gl_Nbrs.Gl_Nbr
 WHERE  Apdmdetl.uniqdmhead = @gcUniqDmHead
END