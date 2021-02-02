-- =============================================
-- Author:		??
-- Create date: ??
-- Description:	ApRecDetailView
-- Modification:
-- 06/23/15 VL added FC fields:Price_eachFC, Item_totalFC
-- 12/06/16 VL added PR fields:Price_eachPR, Item_totalPR
-- =============================================
CREATE PROCEDURE [dbo].[ApRecDetailView]
	-- Add the parameters for the stored procedure here
@gcUniqRecur as Char(10)=" "
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT Aprecdet.uniqrecur, Aprecdet.uniqdetrec,
Aprecdet.item_no, Aprecdet.item_desc, Aprecdet.qty_each,
  Aprecdet.is_tax, Aprecdet.price_each, Aprecdet.tax_pct,
  Aprecdet.item_total, Aprecdet.gl_nbr, Aprecdet.item_note,
  Gl_Nbrs.Gl_Descr, Aprecdet.price_eachFC, Aprecdet.item_totalFC, 
  Aprecdet.price_eachPR, Aprecdet.item_totalPR
 FROM 
     aprecdet 
    LEFT OUTER JOIN Gl_Nbrs
   ON  Aprecdet.Gl_Nbr = Gl_Nbrs.Gl_Nbr
 WHERE  Aprecdet.uniqrecur = @gcUniqRecur
END