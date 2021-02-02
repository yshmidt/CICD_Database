

CREATE PROCEDURE [dbo].[ApdetailView] 
	@gcUniqApHead as Char(10)=''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- 02/06/15 VL added a empty Sdet_uniq field, that will be used in form to update ApDetailTaxView, also added FC fields, removed Apdetail.tax_pct field
	-- 11/16/16 VL added price_eachPR, item_totalPR
SELECT Apdetail.uniqapdetl, Apdetail.uniqaphead, 
  Apdetail.item_no, Apdetail.item_desc, Apdetail.qty_each,
  Apdetail.price_each, Apdetail.is_tax, Apdetail.item_total, Apdetail.gl_nbr, Apdetail.item_note,
  Apdetail.trans_no, Gl_nbrs.Gl_Descr, 
  Apdetail.price_eachFC, Apdetail.item_totalFC, SPACE(10) AS Sdet_uniq,
  Apdetail.price_eachPR, Apdetail.item_totalPR
 FROM 
     apdetail, Gl_Nbrs 
 WHERE ApDetail.uniqApHead = @gcUniqApHead
	AND Gl_Nbrs.Gl_Nbr = ApDetail.Gl_Nbr

END