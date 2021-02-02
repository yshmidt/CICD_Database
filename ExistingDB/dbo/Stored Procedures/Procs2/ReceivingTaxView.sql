
-- 01/14/15 VL added defaulttax

CREATE proc [dbo].[ReceivingTaxView]   
AS
 SELECT  TaxTabl.Tax_rate,TaxTabl.TaxDesc,TaxTabl.Tax_Id,
	ShipTax.LinkAdd ,SHIPTAX.UNQSHIPTAX ,ShipTax.TaxType,ShipTax.RecordType, Shiptax.DefaultTax
	 FROM TaxTabl, ShipTax 
	 WHERE ShipTax.TaxType = 'S' 
	 AND ShipTax.RecordType = 'I'  
	 AND TaxTabl.Tax_Id = ShipTax.Tax_id
