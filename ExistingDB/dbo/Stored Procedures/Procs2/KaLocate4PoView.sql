-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <12/06/2010>
-- Description:	<Shortages for items on the given PO. using in PO receiving module >
-- =============================================
CREATE PROCEDURE [dbo].[KaLocate4PoView]
	-- Add the parameters for the stored procedure here
	@pcPonum char(15)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT KALOCATE.KASEQNUM,KALOCATE.LOTCODE,KALOCATE.OVERISSQTY,
	KALOCATE.OVERW_KEY,KALOCATE.PICK_QTY,KALOCATE.EXPDATE,
	KALOCATE.REFERENCE,KALOCATE.PONUM,KALOCATE.UNIQMFGRHD,
	KALOCATE.W_KEY,KALOCATE.Wono,KALOCATE.UNIQKALOCATE 
	FROM KALOCATE 
	WHERE EXISTS
	(SELECT 1 FROM KAMAIN WHERE Kamain.KaSeqNum=Kalocate.KaSeqnum
		AND Kamain.shortqty > 0.00
		AND Kamain.ignorekit =0
		AND Kamain.uniq_key IN (SELECT Uniq_key FROM POITEMS WHERE PONUM=@pcPonum) )        
	
		        
END