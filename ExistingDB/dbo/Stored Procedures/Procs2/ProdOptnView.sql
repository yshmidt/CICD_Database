-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/05/2016
-- Description:	Product Type Option setup, used in Product Type setup
-- Modified
-- 05/06/16	VL	Try to add qty_oh and Extendqty that can be used in SO 'edit config' button, so no need to create 2nd similar view
-- 05/17/16	VL	Added Stdcost, used in order configuration
-- =============================================
CREATE PROCEDURE [dbo].[ProdOptnView]
	-- Add the parameters for the stored procedure here
	@ProdTpUniq as Char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	;WITH ZProdOptn AS 
	(
	-- 05/17/16 VL added stdcost
	SELECT Inventor.part_class, Inventor.part_type, Inventor.part_no, Inventor.revision, Inventor.descript, 
		Inventor.custno, Inventor.u_of_meas, Inventor.part_sourc, Inventor.serialyes, Inventor.make_buy, Inventor.saletypeid,
		Inventor.MinOrd, Inventor.OrdMult, Inventor.Taxable, Inventor.StdCost,
		Prodoptn.*, ProdOptn.ISREQUIRED AS Old_IsRequired
		FROM Prodoptn INNER JOIN Inventor
		ON Prodoptn.UNIQ_KEY = Inventor.Uniq_key
		WHERE Prodoptn.Prodtpuniq = @ProdTpUniq
	),
	ZQty_oh AS
	(
	SELECT Uniq_key, ISNULL(SUM(Invtmfgr.Qty_oh-Invtmfgr.Reserved),0.00) AS Qty_OH
		FROM Invtmfgr, Warehous 
		WHERE Invtmfgr.UniqWh = Warehous.UniqWh
		AND Warehous.Warehouse <> 'WIP'
		AND Warehous.Warehouse <> 'WO-WIP'
		AND Warehous.Warehouse <> 'MRB'
		AND Invtmfgr.Uniq_key IN (SELECT Uniq_key FROM ZProdOptn) 
		AND Invtmfgr.Qty_oh-Invtmfgr.Reserved >= 0 
		AND Invtmfgr.Is_Deleted = 0
		GROUP BY Uniq_key
	)
	SELECT ZProdOptn.*, ISNULL(ZQty_oh.Qty_OH,0.00) AS Qty_OH, 000000000.00 AS ExtendQty
		FROM ZProdOptn LEFT OUTER JOIN ZQty_oh
		ON ZProdOptn.Uniq_key = ZQty_oh.Uniq_key
		ORDER BY part_class, part_type, part_no
 	
END