-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 02/02/2014
-- Description:	Get all locations for list of given uniqmfgrhd
-- =============================================
CREATE PROCEDURE GetWhLocation4UniqMfgrhds 
	-- Add the parameters for the stored procedure here
	@ptUniqmfgrhd tUniqMfgrhd READONLY 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT distinct Invtmfgr.Uniqmfgrhd,Invtmfgr.Uniqwh,Warehous.WHNO,
		warehous.[default],warehous.warehouse,Invtmfgr.Location
		FROM Invtmfgr INNER JOIN Warehous ON INVTMFGR.UNIQWH=Warehous.Uniqwh 
		INNER JOIN @ptUniqmfgrhd H on Invtmfgr.UNIQMFGRHD=h.UniqMfgrHd
	WHERE Invtmfgr.Is_deleted=0
	AND Warehous.Warehouse<>'MRB' 
	AND Warehous.Warehouse<>'WIP' 
	AND Warehous.Warehouse<>'WO-WIP' 
	AND Invtmfgr.InStore=0 ;
	
	 
END