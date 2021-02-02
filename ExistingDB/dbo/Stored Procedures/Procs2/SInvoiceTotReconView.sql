CREATE PROCEDURE [dbo].[SInvoiceTotReconView] 
	-- Add the parameters for the stored procedure here
	@gcPoNum as char(15) = ' ' , @gcSInv_uniq as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- 02/05/15 VL added FC field
    -- Insert statements for procedure here
	SELECT SUM(Sinvoice.InvAmount) as TotalRecon, SUM(Sinvoice.InvAmountFC) as TotalReconFC
		from SINVOICE, ApMaster
		where PoNum = @gcPoNum 
		and ApMaster.UNIQAPHEAD = SInvoice.fk_uniqaphead
		and SINV_UNIQ <> @gcSInv_uniq
END