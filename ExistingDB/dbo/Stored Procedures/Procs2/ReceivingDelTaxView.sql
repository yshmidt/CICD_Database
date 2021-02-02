
CREATE proc [dbo].[ReceivingDelTaxView]   
AS
 SELECT  TaxTabl.Tax_rate,TaxTabl.TaxDesc,TaxTabl.Tax_Id,
	ShipTax.LinkAdd ,SHIPTAX.UNQSHIPTAX,ShipTax.TaxType ,SHIPTAX.RECORDTYPE 
	 FROM TaxTabl, ShipTax 
	 WHERE ShipTax.TaxType = 'C' 
	 AND ShipTax.RecordType = 'I'  
	 AND TaxTabl.Tax_Id = ShipTax.Tax_id





