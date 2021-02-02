-- ==============================================================================
-- Author:  Satyawan H.
-- Create date: 06/03/2020  
-- Description: Get warehouse locations for schedule grid based on selected MFGR autolocation 
-- EXEC GetWarehouseLocations 'R9SI8F4Y0S' --YDS7WORTDP  
--- 06/12/20 YS removed  select @autoloc 
--- 06/23/2020 Rajendra K : Added GLNoWithDesc column in selection list
-- ==============================================================================
CREATE PROC [dbo].[GetWarehouseLocations]  
	@lcUniqMfgrhd CHAR(10) = ''
AS
BEGIN
	DECLARE @autoloc AS BIT;
	SET @autoloc = (SELECT Autolocation FROM InvtMPNLink mpn 
					JOIN MfgrMaster mstr ON  mstr.MfgrMasterId = mpn.MfgrMasterId 
					WHERE mpn.uniqmfgrhd =  @lcUniqMfgrhd)
   ---select @autoloc   
   SELECT * FROM (
		SELECT DISTINCT wa.Warehouse,mfgr.[Location], 'Y' AS InventorSet, wa.Whno,Wh_gl_nbr, 
				   mfgr.UniqWh,wa.Autolocation,wa.[default],WH_MAP,WH_DESCR
	   --- 06/23/2020 Rajendra K : Added GLNoWithDesc column in selection list
	   ,(SELECT (GL_NBR) + ' ( ' +(GL_DESCR)+ ' ) ' FROM GL_NBRS WHERE GL_NBR = Wh_gl_nbr) AS GLNoWithDesc  
		FROM INVENTOR i
			JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY
			JOIN INVTMFGR mfgr ON mpn.uniqmfgrhd = mfgr.UNIQMFGRHD AND i.uniq_key = mfgr.UNIQ_KEY
			JOIN MfgrMaster mstr ON  mstr.MfgrMasterId = mpn.MfgrMasterId 
			JOIN WAREHOUS wa ON wa.UNIQWH = mfgr.UNIQWH
		WHERE mpn.uniqmfgrhd =  @lcUniqMfgrhd 
			AND ((@autoloc = 1 AND wa.AUTOLOCATION = 1) OR (@autoloc = 0 AND 1=1)) 
			AND mfgr.Is_deleted = 0 
		UNION
		SELECT DISTINCT wa.Warehouse,'', 'Y' as InventorSet, wa.Whno,Wh_gl_nbr, 
			   wa.UniqWh,wa.Autolocation,wa.[default],WH_MAP,WH_DESCR
	  --- 06/23/2020 Rajendra K : Added GLNoWithDesc column in selection list
	  ,(SELECT (GL_NBR) + ' ( ' +(GL_DESCR)+ ' ) ' FROM GL_NBRS WHERE GL_NBR = Wh_gl_nbr) AS GLNoWithDesc 
		FROM WAREHOUS wa 
		WHERE (wa.Autolocation = 1 AND @autoloc = 1)
			  AND IS_DELETED =0 
	) result 
	WHERE 
		  Warehouse<>'WO-WIP'   
	  AND Warehouse<>'WIP'  
	  AND Warehouse<>'MRB'  
END