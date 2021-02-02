-- =============================================
-- Author: Rajendra K
-- Create date: 07/10/2017
-- Description:	Get WareHouse list by UniqMfgrHd and UniqKey
-- =============================================
CREATE PROCEDURE [dbo].[GetWHAndLocByUniqMfgrHdAndUniqKey]
(	
	@UniqMfgrhd char(10)=' ',
	@UniqKey char(10)=''
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	WITH ZInvtMfgrWh AS
(
    SELECT DISTINCT Warehous.Warehouse
		   ,INVTMFgr.Location
		   ,'Y' AS InventorSet
		   ,Warehous.Whno
		   ,Wh_gl_nbr
		   ,Invtmfgr.UniqWh
		   ,Autolocation,warehous.[default] 
	FROM Warehous,Invtmfgr 
	WHERE WAREHOUS.UNIQWH =INVTMFGR.UNIQWH  
		  AND (@UniqMfgrhd IS NULL OR @UniqMfgrhd = '' OR UniqMfgrHd = @UniqMfgrhd) 
		  AND (@UniqKey IS NULL OR @UniqKey = '' OR UNIQ_KEY = @UniqKey) 
		  AND Invtmfgr.Is_deleted = 0  
		  AND invtmfgr.InStore=0
		  AND Warehouse<>'WO-WIP' 
		  AND Warehouse<>'WIP'
		  AND Warehouse<>'MRB'
	)
	
   	SELECT WAREHOUS.WAREHOUSE 
		   ,SPACE(256) AS Location
		   ,'N' AS InventorSet
		   ,WAREHOUS.WHNO
		   ,Wh_gl_nbr
		   ,WAREHOUS.uniqwh
		   ,Autolocation
		   ,[Default]
	FROM WAREHOUS
	WHERE WAREHOUS.IS_DELETED =0
		  AND Warehouse<>'WO-WIP' 
		  AND Warehouse<>'WIP'
		  AND Warehouse<>'MRB'
		  AND UNIQWH NOT IN (SELECT UNIQWH FROM ZInvtMfgrWh)
	UNION
	SELECT Warehouse
		   ,Location
		   ,InventorSet
		   ,Whno
		   ,Wh_gl_nbr
		   ,Uniqwh
		   ,Autolocation
		   ,[default]
	FROM ZInvtMfgrWh
	ORDER BY InventorSet DESC
	         ,[DEFAULT] DESC	
END