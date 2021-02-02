-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/28/2010
-- Description:	Create a union between qualified Wh/localtions for specific Uniqmfgrhd and extra warehouses from the warehouse setup
-- This will allow for the users to add wh/location at the PO receipt
--- 04/14/15 YS change "location" column length to 256
--- 09/13/15 Shivshankar P  : Added 'WH_MAP' column 
--- 27/09/17 Shivshankar P : Get NETABLE =1 
--- 06/25/18 Rajendra K : Added 2 new parameters @lcInStore & @lcUniqSup and Used these parameters in where conditions(To get InStore and Non-InStore records)
---02/20/2018 Satish B :Added 'WH_DESCR' column    
-- 4/11/2019 Nitesh B : Add parameter @isIngnoreNetable and Change condition (@isIngnoreNetable =1 AND 1=1) OR (@isIngnoreNetable =0 AND Invtmfgr.NETABLE = 1)  
-- GetWhListANdLocations4UniqMfgrhd '_01F15TF7G',false,'',true  
-- =============================================
CREATE PROCEDURE [dbo].[GetWhListANdLocations4UniqMfgrhd] 
	-- Add the parameters for the stored procedure here
   	@lcUniqMfgrhd CHAR(10)='',
   	@lcInStore BIT = 0,
    @lcUniqSup CHAR(10)='',  
    @isIngnoreNetable BIT = 0  -- 4/11/2019 Nitesh B : Add parameter @isIngnoreNetable  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	WITH ZInvtMfgrWh AS
(

 SELECT DISTINCT Warehous.Warehouse,INVTMFgr.Location, 'Y' as InventorSet, Warehous.Whno,Wh_gl_nbr, Invtmfgr.UniqWh,Autolocation,warehous.[default] ,WH_MAP,WH_DESCR --- 09/13/15 Shivshankar P  : Added 'WH_MAP' column,02/20/2018 Satish B :Added 'WH_DESCR' column    
		FROM Warehous,Invtmfgr 
	WHERE WAREHOUS.UNIQWH =INVTMFGR.UNIQWH  
	AND UniqMfgrHd=@lcUniqmfgrhd
	AND Invtmfgr.Is_deleted = 0 
	AND invtmfgr.InStore=@lcInStore -- 06/25/2018 Rajendra K : Replace 0 by parameter @lcInStore
 AND ((@isIngnoreNetable =1 AND 1=1) OR (@isIngnoreNetable =0 AND Invtmfgr.NETABLE = 1))   --  27/09/17 Shivshankar P : Get NETABLE =1  4/11/2019 Nitesh B : Change condition (@isIngnoreNetable =1 AND 1=1) OR (@isIngnoreNetable =0 AND Invtmfgr.NETABLE = 1)  
	AND Warehouse<>'WO-WIP' 
	AND Warehouse<>'WIP'
	AND Warehouse<>'MRB'
	AND (@lcInStore = 0 OR Invtmfgr.uniqsupno = @lcUniqSup) -- 06/25/2018 Rajendra K : Added condition Invtmfgr.uniqsupno = @lcUniqSup for Instore parts 
	--AND INVTMFGR.autolocation=1
	)
	--- 04/14/15 YS change "location" column length to 256
 SELECT WAREHOUS.WAREHOUSE ,space(256) as Location,'N' as InventorSet,WAREHOUS.WHNO,Wh_gl_nbr,WAREHOUS.uniqwh,Autolocation,[Default],WH_MAP,WH_DESCR --- 09/13/15 Shivshankar P  : Added 'WH_MAP' column,02/20/2018 Satish B :Added 'WH_DESCR' column    
		from WAREHOUS
	WHERE WAREHOUS.IS_DELETED =0
	AND Warehouse<>'WO-WIP' 
	AND Warehouse<>'WIP'
	AND Warehouse<>'MRB'
	AND UNIQWH NOT IN (SELECT UNIQWH FROM ZInvtMfgrWh)
	UNION
	--- 04/14/15 YS change "location" column length to 256
 SELECT WAREHOUS.WAREHOUSE ,space(256) as Location,'N' as InventorSet,WAREHOUS.WHNO,Wh_gl_nbr,WAREHOUS.uniqwh,Autolocation,[Default],WH_MAP,WH_DESCR --- 09/13/15 Shivshankar P  : Added 'WH_MAP' column,02/20/2018 Satish B :Added 'WH_DESCR' column    
		from WAREHOUS
	WHERE WAREHOUS.IS_DELETED =0
	AND Warehouse<>'WO-WIP' 
	AND Warehouse<>'WIP'
	AND Warehouse<>'MRB'
	AND AUTOLOCATION = 1
	UNION
 SELECT Warehouse,Location,InventorSet,Whno,Wh_gl_nbr,Uniqwh,Autolocation,[default],WH_MAP,WH_DESCR --- 09/13/15 Shivshankar P  : Added 'WH_MAP' column,02/20/2018 Satish B :Added 'WH_DESCR' column    
	FROM ZInvtMfgrWh
	ORDER BY InventorSet desc,[DEFAULT] desc
	
END