
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <02/24/2010>
-- Description:	<Invt_lot_view>
-- =============================================
CREATE PROCEDURE [dbo].[invt_lot_view] 
	-- Add the parameters for the stored procedure here
@gcW_key as char(10)=' '	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Invtlot.w_key, Invtlot.lotcode, Invtlot.lotqty, Invtlot.expdate,
  Invtlot.reference, Invtlot.lotresqty, Invtlot.ponum, Invtlot.countflag,
  Invtlot.uniq_lot, Invtlot.lotqty-Invtlot.lotqty AS retlotqty
	FROM invtlot
	WHERE  Invtlot.w_key = @gcW_key
END
