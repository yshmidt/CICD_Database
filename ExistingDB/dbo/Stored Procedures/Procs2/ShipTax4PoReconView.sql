CREATE PROCEDURE dbo.ShipTax4PoReconView
	-- Add the parameters for the stored procedure here
	@lcI_link as char(10) = ' '
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT SUM(TaxTabl.Tax_rate) AS Totrate 
	FROM TaxTabl, ShipTax 
	WHERE ShipTax.TaxType = 'S' 
		AND ShipTax.RecordType = 'I' 
		AND TaxTabl.Tax_Id = ShipTax.Tax_id 
		AND ShipTax.LinkAdd = @lcI_Link 
END