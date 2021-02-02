-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <12/06/2010>
-- Description:	<INVTLOT records for items on the PO >
-- =============================================
CREATE PROCEDURE [dbo].[InvtLot4PoView] 
	-- Add the parameters for the stored procedure here
	@pcPonum char(15)=' '
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--03/28/12 YS added  and invtlot.PONUM=@pcPonum to get lot code created by this PO only
    -- Insert statements for procedure here
	SELECT INVTLOT.W_KEY,INVTLOT.LOTCODE,INVTLOT.EXPDATE,INVTLOT.REFERENCE,INVTLOT.PONUM,
	INVTLOT.LOTQTY,INVTLOT.LOTRESQTY,INVTLOT.COUNTFLAG,INVTLOT.UNIQ_LOT,INVTMFGR.UNIQMFGRHD,INVTMFGR.UNIQ_KEY   
	  FROM Invtlot,INVTMFGR,Poitems
 WHERE  Invtlot.w_key = INVTMFGR.W_KEY
 and invtmfgr.uniq_key=POITEMS.UNIQ_KEY 
 and INVTMFGR.UNIQMFGRHD = POITEMS.UNIQMFGRHD 
 and invtlot.PONUM=@pcPonum
 and POITEMS.PONUM =@pcPonum
 
END