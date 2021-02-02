-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <12/06/2010>
-- Description:	<INVTSER records for items on the PO >
-- =============================================
CREATE PROCEDURE [dbo].[InvtSer4PoView] 
	-- Add the parameters for the stored procedure here
	@pcPonum char(15)=' '
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT DISTINCT Invtser.serialuniq, Invtser.serialno, Invtser.uniq_key,
  Invtser.uniqmfgrhd, Invtser.uniq_lot, Invtser.id_key, Invtser.id_value,
  Invtser.savedttm, Invtser.saveinit, Invtser.lotcode, Invtser.expdate,
  Invtser.reference, Invtser.ponum, Invtser.isreserved, Invtser.actvkey,
  Invtser.oldwono, Invtser.wono, Invtser.reservedflag, Invtser.reservedno
 FROM invtser,poitems
 WHERE  Invtser.uniq_key = POITEMS.UNIQ_KEY 
 and INVTSER.UNIQMFGRHD = POITEMS.UNIQMFGRHD 
 and POITEMS.PONUM =@pcPonum
 ORDER BY InvtSer.Uniqmfgrhd,Invtser.serialno
END