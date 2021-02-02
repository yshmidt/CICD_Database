-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <11/19/2010>
-- Description:	<All Invtmfgr records for a PO>
-- =============================================
CREATE PROCEDURE [dbo].[Invtmfgr4POView]
	-- Add the parameters for the stored procedure here
	@pcPoNum char(15)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT INVTMFGR.UNIQ_KEY,INVTMFGR.UNIQWH,WAREHOUS.WAREHOUSE,INVTMFGR.LOCATION,INVTMFGR.UNIQMFGRHD,INVTMFGR.W_KEY,
		INVTMFGR.IS_DELETED,INVTMFGR.INSTORE,INVTMFGR.uniqsupno ,INVTMFGR.NETABLE,INVTMFGR.QTY_OH,INVTMFGR.RESERVED,INVTMFGR.MARKING     	 
		FROM INVTMFGR,Warehous
		WHERE Exists (SELECT 1 from POITEMS WHere POITEMS.PONUM=@pcPoNum
					AND POITEMS.UNIQ_KEY = INVTMFGR.UNIQ_KEY)
		AND WAREHOUS.UNIQWH = INVTMFGR.UNIQWH 
		
END