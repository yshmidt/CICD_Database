--============================
-- Modification:
-- 03/05/15 VL added CmpriceFC and CmExtendedFC
-- 10/31/16 VL added PR fields
--============================

CREATE PROCEDURE [dbo].[CmPricesView]
	-- Add the parameters for the stored procedure here
@gcCmUnique as Char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Cmemono, Packlistno, uniqueln, Descript, CmQuantity, CmPrice,
		CmExtended, Taxable, Flat, Inv_Link, RecordType,
		Is_Restock,RestockQty, ScrapQty, AmortFlag, SalesType, Pl_Gl_nbr,
		PlPricelnk,	pluniqlnk, Cog_Gl_nbr, cmPriceLnk, cmpruniq,
		Gl_Nbrs.Gl_Descr, CMUnique, CmPriceFC, CmExtendedFC, CmPricePR, CmExtendedPR
	FROM CmPrices, Gl_nbrs 
	WHERE cmPrices.CmUnique = @gcCmUnique
		and Gl_nbrs.Gl_nbr = CmPrices. Pl_Gl_nbr
END

select * from cmprices




