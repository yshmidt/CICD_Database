-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 12/06/2013
-- Description:	get warehouse list for an MPN
-- This procedure will be used in the new WEB Purchase order 
-- it will list warehouse according with the setup for auto location in both warehouse table and invtmfhd table
-- needs @Uniqmfgrhd as parameter
-- 10/10/14 YS replaced invtmfhd table with 2 new tables
-- 04/14/15 YS Location length is changed to varchar(256)
-- =============================================
CREATE PROCEDURE [dbo].[WarehouseList4MPN] 
	-- Add the parameters for the stored procedure here
	@uniqmfgrhd char(10) = NULL 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @MfAutoLocationAllow bit =0
	-- find out if this mfgr allow auto location created upon receipt
	-- 10/10/14 YS replaced invtmfhd table with 2 new tables
	--SELECT @MfAutoLocationAllow = Invtmfhd.AUTOLOCATION from INVTMFHD where UNIQMFGRHD=@uniqmfgrhd 
	SELECT @MfAutoLocationAllow = M.AUTOLOCATION from Invtmpnlink L INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId 
		where L.UNIQMFGRHD=@uniqmfgrhd 

	if @MfAutoLocationAllow=0 -- no auto location, bring only warehouse/location assigned to this @uniqmfgrhd
		SELECT Warehous.Warehouse,INVTMFGR.LOCATION,cast(1 as bit) as InventorSet,Warehous.whno,warehous.Wh_gl_nbr,Invtmfgr.UniqWH,Warehous.AUTOLOCATION,Warehous.[DEFAULT] 
			 FROM Invtmfgr inner join warehous on invtmfgr.UNIQWH=warehous.UNIQWH 
			WHERE Uniqmfgrhd = @UniqMfgrHD
			AND Invtmfgr.IS_Deleted =0
			and INSTORE=0
	ELSE  --- if @MfAutoLocationAllow=0
	BEGIN
	-- bring all locations assigned to the @uniqmfgrhd + all warehouses fr which autolocation is activated
		;WITH InventoryAssignedLocation
		as(
		SELECT Warehous.Warehouse,INVTMFGR.LOCATION,cast(1 as bit) as InventorSet,Warehous.whno,warehous.Wh_gl_nbr,Invtmfgr.UniqWH,Warehous.AUTOLOCATION,Warehous.[DEFAULT] 
			 FROM Invtmfgr inner join warehous on invtmfgr.UNIQWH=warehous.UNIQWH 
			WHERE Uniqmfgrhd = @UniqMfgrHD
			AND Invtmfgr.IS_Deleted =0
			and INSTORE=0 
		)
		-- 04/14/15 YS Location length is changed to varchar(256)
		SELECT * from InventoryAssignedLocation		
		UNION
		SELECT Warehouse,SPACE(256) as Location,CAST(0 as bit) as Inventorset,Whno,Wh_gl_nbr,UniqWh,AutoLocation,[DEFAULT] 
			FROM Warehous 
			WHERE is_deleted=0 
			and Warehouse<>'WO-WIP' 
			AND Warehouse<>'WIP' 
			AND Warehouse<>'MRB'
			AND AUTOLOCATION =1	
			AND UNIQWH not IN (SELECT UNIQWH from InventoryAssignedLocation)
		ORDER BY InventorSet desc,[DEFAULT] desc,WAREHOUSE 
	END  -- if @MfAutoLocationAllow=0
		

END