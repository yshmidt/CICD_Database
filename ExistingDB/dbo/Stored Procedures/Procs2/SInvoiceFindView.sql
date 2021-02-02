CREATE PROCEDURE [dbo].[SInvoiceFindView]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
 Select Distinct SupName, supInfo.UniqSupNo 
 FROM SInvoice, SupInfo, PORECDTL, PoItems, PoMain 
 WHERE PORECDTL.RECEIVERNO = SINVOICE.Receiverno
	and POITems.UNIQLNNO =  PORECDTL.UNIQLNNO 
	and POMAIN.PoNum = POITEMS.PoNum
	and Supinfo.UniqSupNo  = PoMain.UniqSupNo 
	
 
END