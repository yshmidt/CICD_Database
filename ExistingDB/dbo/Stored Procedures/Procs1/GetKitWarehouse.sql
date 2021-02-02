-- =============================================
-- Author: Rajendra K
-- Create date: 07/10/2017
-- Description:	Get WareHouse list by UniqMfgrHd and UniqKey
-- Modification 
   -- 08/11/2017 Rajendra K : Renamed CTE ZInvtMfgrWh to InvtMfgrWh
   -- 09/01/2017 Rajendra K : Removed second select statement to get only records that matches with Input paramters
   -- 12/28/2017 : Satish B : Declare and set parameter @paramExists against @UniqMfgrhd and @UniqKey
   -- 12/28/2017 : Satish B : Select W_Key conditionally
   -- 01/23/2018 Rajendra K : Added parameter @isWH
   -- 02/13/2018 Rajendra K : Added column WH_MAP in select list
   -- 03/03/2018 Rajendra K : Added column WAREHOUS.Autolocation in select list
   -- 07/09/2018 Rajendra K : Added new parameter @inStore to get instore records and added condition WAREHOUS.Autolocation = 1 to get all WAREHOUSE having Autolocation = 1
   -- 10/03/2018 Rajendra K : added condition WAREHOUS.Autolocation = 1 With 'OR' clause in where condition
   -- 10/03/2018 Rajendra K : Moved ((WAREHOUS.UNIQWH =INVTMFGR.UNIQWH)) condition in Join Clause from where clause
   -- 04/11/2019 Nitesh B : Added column Invtmfgr.NETABLE in select list 
   -- 04/12/2019 Nitesh B : Added column Invtmfgr.IsLocal in select list 
   -- 08/08/2019 Nitesh B : Not bring the location which has the Location as Sodetail.uniqueln  
   -- exec GetKitWarehouse '_26U0T0Y23','_26U0T0Y0S'
-- =============================================
CREATE PROCEDURE [dbo].[GetKitWarehouse]
(	
	@uniqMfgrhd CHAR(10)='',
	@uniqKey CHAR(10)='',
	@isWH BIT = 0,
	@inStore BIT = 0 -- 07/09/2018 Rajendra K : Added new parameter @inStore to get instore records
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--12/28/2017 Satish B : Declare and set parameter @paramExists against @UniqMfgrhd and @UniqKey 
	--01/23/2018 Rajendra K : parameter @paramExists against@isWH
	DECLARE @paramExists BIT = 1
	IF(((@UniqKey = NULL OR @UniqKey = '')  AND (@UniqMfgrhd = NULL OR @UniqMfgrhd  ='')) OR @isWH = 1)
		BEGIN
			SET @paramExists = 0
		END

    -- Insert statements for procedure here
	-- 08/11/2017 Rajendra K : Renamed CTE ZInvtMfgrWh to InvtMfgrWh
	-- 09/01/2017 Rajendra K : Removed secnd select statement to get only records that matches with Input paramters
     SELECT DISTINCT Warehous.Warehouse
		   ,INVTMFgr.Location
		   ,'Y' AS InventorSet
		   ,Warehous.Whno
		   ,Wh_gl_nbr
		   ,Invtmfgr.UniqWh
		   --12/28/2017 : Satish B : Select W_Key conditionally
		   ,CASE WHEN @paramExists = 0 THEN '' ELSE INVTMFgr.W_Key END AS W_Key
		   --,INVTMFgr.W_Key
		   ,Autolocation,warehous.[default] 
		   ,WAREHOUS.WH_MAP -- 02/13/2018 Rajendra K : Added column WH_MAP in select list
		   ,WAREHOUS.Autolocation -- 03/03/2018 Rajendra K : Added column 
           ,Invtmfgr.NETABLE   -- 4/11/2019 Nitesh B : Added column Invtmfgr.NETABLE in select list
		   ,Invtmfgr.IsLocal   -- 4/12/2019 Nitesh B : Added column Invtmfgr.IsLocal in select list
	FROM Warehous--,Invtmfgr --10/03/2018 Rajendra K : Changed join condition
	INNER JOIN Invtmfgr ON Warehous.UNIQWH = INVTMFGR.UNIQWH 
	WHERE -- (WAREHOUS.UNIQWH =INVTMFGR.UNIQWH) --10/03/2018 Rajendra K : Moved this condition in Join Clause
		  --AND
		   (@UniqMfgrhd IS NULL OR @UniqMfgrhd = '' OR UniqMfgrHd = @UniqMfgrhd) 
		  AND (@UniqKey IS NULL OR @UniqKey = '' OR UNIQ_KEY = @UniqKey OR WAREHOUS.Autolocation = 1) --10/03/2018 Rajendra K : added condition WAREHOUS.Autolocation = 1 
		  AND Invtmfgr.Is_deleted = 0  
		   AND (invtmfgr.InStore = @inStore)
		   --OR WAREHOUS.Autolocation = 1 -- 07/09/2018 Rajendra K : used new parameter @inStore to get instore records 
		                                                                  -- and added condition WAREHOUS.Autolocation = 1 to get all WAREHOUSE having Autolocation = 1
																		  --10/03/2018 Rajendra K : Removed condition WAREHOUS.Autolocation = 1
		  AND Warehouse<>'WO-WIP' 
		  AND Warehouse<>'WIP'
		  AND Warehouse<>'MRB'
		  AND INVTMFgr.LOCATION NOT IN(SELECT UNIQUELN FROM SODETAIL) -- 08/08/2019 Nitesh B : Not bring the location which has the Location as Sodetail.uniqueln
END