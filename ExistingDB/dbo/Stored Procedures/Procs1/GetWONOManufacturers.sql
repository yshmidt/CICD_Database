-- =============================================
-- Author:		Rajendra K	
-- Create date: <05/36/2017>
-- Description:Get Manufacturers data
-- Modification 
   -- 07/28/2017 Rajendra K : Excluding MFGR records with value Is_deleted & invtMf.InStore
   -- 07/28/2017 Rajendra K : Excluding MFGR records where Available quanityt is zero
   -- 08/02/2017 Rajendra K : Added to get MFGR records by location
   -- 10/04/2017 Rajendra K : Setting Name changed in where clause for #temoWOSettings to get ICM default settings
   -- 10/25/2017 Rajendra K : Removed condition to check INVTMF.QTY_OH to display all MFGR records 
   -- 10/25/2017 Rajendra K : Added INVENTOR table in join to get U_OF_MEAS
   -- 10/25/2017 Rajendra K : Added U_OF_MEAS in select list
   -- 11/02/2017 Rajendra K : Removed white spaces from  @location in Set parameter section 
   -- 11/02/2017 Rajendra K : Added DISTINCT in select list
   -- 11/02/2017 Rajendra K : Added @isAutoComplete,UniqKey in select list,KaMain table in join condition and @woNumber in where condition to get Manufacturer data for Autocomplete
   -- 11/17/2017 Rajendra K : Changed condition in where clause for Location
   -- 11/24/2017 Rajendra K : Replaced UNIQ_KEY with WONO to get BOMParent
   -- 11/27/2017 Rajendra K : Added QtyOh in select list for CC
   -- 11/28/2017 Rajendra K : Added condition INVT.Is_Deleted = 0 
   -- 12/07/2017 Rajendra K : Added order by Clause
   -- 04/16/2019 Rajendra K : Added Input parameter @custNo
   -- 05/02/2019 Rajendra K : Added @sortExpression parameter 
   -- 04/16/2019 Rajendra K : Added SET statement for @CosignUniqKey if part is CONSG 
   -- 04/17/2019 Rajendra K : Added "ManufactList" table to select consign's manufacture.
   -- 04/17/2019 Rajendra K : Added inner join with "ManufactList" table 
   -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.  
   -- 04/18/2019 Rajendra K : Replaced @uniqKey by "@CosignUniqKey"
   -- 06/12/2019 Rajendra K : Changed QtyOh dbo.fn_GetCCQtyOH(I.UNIQ_KEY,invtMf.W_Key,'','') to Available Quantity
   -- 08/06/2019 Rajendra K : Changed location datatype from VARCHAR to NVARCHAR
   -- 09/27/2019 Rajendra K : Added new paramrter @KaSeqNumber and condition
   -- 11/06/2019 Rajendra K : Replaced @BomParent by K.BOMParent  
   -- 11/06/2019 Rajendra K : where Qty_oh  > 0 condition 
   -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations
   -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition   
   -- 03/16/2020 Rajendra K : Added Instore,Supplier field in selection list and added left join with Supinfo table 
   -- 05/07/2020 Rajendra K : Added condition if location is blank
   -- 06/22/2020 Rajendra K : Added DoNotKit field in selection list 
-- EXEC GetWONOManufacturers '0000001225','8VDCMKO8T6','','','',0,'0000000002','MfgrPtNo asc'
-- =============================================
CREATE PROCEDURE GetWONOManufacturers
(
@woNumber AS CHAR(10),
@uniqKey AS CHAR(10)='', 
@uniqWHKey AS CHAR(10)='',
@wKey AS CHAR(10)='',
@location AS NVARCHAR(256)='',-- 08/06/2019 Rajendra K : Changed location datatype from VARCHAR to NVARCHAR
@KaSeqNumber CHAR(10)='',   --  09/27/2019 Rajendra K : Added new paramrter @KaSeqNumber and condition
@isAutoComplete BIT = 0, -- 11/02/2017 Rajendra K : Added parameter
@custNo CHAR(10) = '',  -- 04/16/2019 Rajendra K : Added Input parameter @custNo
@sortExpression char(1000) = NULL  -- 05/02/2019 Rajendra K : Added @sortExpression parameter 
)
AS  
BEGIN
	SET NOCOUNT ON;
	-- 11/02/2017 Rajendra K : Remove white spaces from  @location
    SET @location = LTRIM(RTRIM(@location))
	
	--09/13/2017 - Rajendra K : Added WO Reservation  default settings logic
	--Declare variables
    --DECLARE @MfgrDefault NVARCHAR(MAX);
	DECLARE @NonNettable BIT,@BomParent CHAR(10),@CosignUniqKey CHAR(10);
	DECLARE @sqlQuery NVARCHAR(MAX); 

	IF OBJECT_ID(N'tempdb..#TempData') IS NOT NULL
     DROP TABLE #TempData ;  -- 05/02/2019 Rajendra K : Added temp table for @sortExpression 
	
	-- 04/16/2019 Rajendra K : Added SET statement for @CosignUniqKey if part is CONSG    
	SET @CosignUniqKey = ISNULL((SELECT UNIQ_KEY FROM INVENTOR WHERE INT_UNIQ = @uniqKey AND CUSTNO = @custNo),@uniqKey);	

	SELECT SettingName
		   ,LTRIM(WM.SettingValue) SettingValue
	INTO #TempWOSettings
	FROM MnxSettingsManagement MS INNER JOIN WmSettingsManagement WM ON MS.settingId = WM.settingId  
	WHERE SettingName = 'allowUseOfNonNettableWarehouseLocation'--IN('manufacturersDefault','allowUseOfNonNettableWarehouseLocation') -- 10/04/2017 Rajendra K : Setting Name changed in where clause

    --Assign values to variables to hold values for WO Reservation  default settings
	-- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.
	--SET @MfgrDefault = ISNULL((SELECT SettingValue FROM #TempWOSettings WHERE SettingName = 'manufacturersDefault'),'All MFGRS')	 -- 10/04/2017 Rajendra K : Setting Name changed in where clause
	SET @NonNettable= ISNULL((SELECT CONVERT(Bit, SettingValue) FROM #TempWOSettings WHERE SettingName = 'allowUseOfNonNettableWarehouseLocation'),0) -- 10/04/2017 Rajendra K : Setting Name changed in where clause
	SET @BomParent = (SELECT UNIQ_KEY FROM WOENTRY WHERE WONO = @woNumber) -- 11/24/2017 Rajendra K : Replaced UNIQ_KEY with WONO
	SET @sortExpression = CASE WHEN @sortExpression IS NULL OR @sortExpression = '' THEN 'PartMfgr,MfgrPtNo' ELSE @sortExpression END -- 05/02/2019 Rajendra K : Added @sortExpression 

	 SET NOCOUNT ON;
	 ;WITH ManufactList AS(  -- 04/17/2019 Rajendra K : Added "ManufactList" table to select consign's manufacture.
	      SELECT DISTINCT mf.MfgrMasterId
		  FROM INVTMFGR im 
		     INNER JOIN InvtMPNLink m ON im.uniqmfgrhd = m.UNIQMFGRHD
		     INNER JOIN  MfgrMaster mf ON mf.MfgrMasterId = m.MfgrMasterId 
			WHERE im.UNIQ_KEY = @CosignUniqKey AND m.is_deleted = 0
    ),
	 InvtResCte AS 
		(
		  SELECT SUM(QTYALLOC) AS Allocated,W_KEY
		  FROM 
		  INVT_RES IR 
    WHERE IR.WONO = @woNumber  AND IR.KaSeqNum = @KaSeqNumber 
		  GROUP BY W_KEY
		) 
	SELECT DISTINCT INVT.uniqmfgrhd AS UniqMfgrHd -- 11/02/2017 Rajendra K : Added DISTINCT
		  ,MFG.MfgrMasterId AS MfgrMasterId 
		  ,MFG.mfgr_pt_no AS MfgrPtNo
		  ,MFG.PartMfgr AS PartMfgr
		  ,INVTMF.W_Key AS WKey
		  ,ISNULL(IR.Allocated,0) AS Reserved
		  ,(INVTMF.Qty_Oh- INVTMF.Reserved) AS Quantity
		  ,ISNULL(IR.Allocated,0) AS OriginalReserved-- 05/07/2020 Rajendra K : Added condition if location is blank
		  ,CASE WHEN ISNULL(RTRIM(invtMf.Location),'') = '' THEN RTRIM(W.Warehouse) ELSE RTRIM(W.Warehouse)+' / '+RTRIM(invtMf.Location) END AS ToWarehouse
		  ,I.U_OF_MEAS AS Unit -- 10/25/2017 Rajendra K : Added U_OF_MEAS in select list
		  ,I.UNIQ_KEY AS UniqKey-- 11/02/2017 Rajendra K : Added to get Manufacturer data for Autocomplete
		  --,(CASE WHEN @uniqKey IS NULL OR @uniqKey = '' THEN 0 ELSE  dbo.fn_GetCCQtyOH(I.UNIQ_KEY,invtMf.W_Key,'','') END ) AS QtyOh  -- 11/27/2017 Rajendra K : Added QtyOh in select list for CC
		  -- 06/12/2019 Rajendra K : Changed QtyOh dbo.fn_GetCCQtyOH(I.UNIQ_KEY,invtMf.W_Key,'','') to Available Quantity
		,(INVTMF.Qty_Oh- INVTMF.Reserved) AS QtyOh 
  	,INVTMF.INSTORE    -- 03/16/2020 Rajendra K : Added Instore,Supplier field in selection list and added left join with Supinfo table 
  	,sup.SUPNAME AS Supplier   
   ,mfg.LDISALLOWKIT AS DoNotKit-- 06/22/2020 Rajendra K : Added DoNotKit field in selection list  
    INTO #TempData -- 05/02/2019 Rajendra K : Added temp table for @sortExpression 
    FROM MfgrMaster mfg 
         INNER JOIN InvtMpnLink INVT  ON MFG.MfgrMasterId = INVT.MfgrMasterId
		 INNER JOIN ManufactList ML ON mfg.MfgrMasterId = ML.MfgrMasterId  -- 04/17/2019 Rajendra K : Added inner join with "ManufactList" table 
         INNER JOIN Invtmfgr invtMf ON INVT.uniqmfgrhd = INVTMF.Uniqmfgrhd 
		 INNER JOIN INVENTOR I ON invtMf.UNIQ_KEY = I.UNIQ_KEY -- 10/25/2017 Rajendra K : Added INVENTOR table in join to get U_OF_MEAS
   AND invtMf.Is_deleted = 0   -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations
   --AND invtMf.InStore=0 -- 07/28/2017 Rajendra K : Excluding MFGR records with value Is_deleted & invtMf.InStore  
      -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations
		 AND INVT.Is_Deleted = 0 -- 11/28/2017 Rajendra K : Added condition INVT.Is_Deleted = 0 
		 --AND invtMf.QTY_OH > 0  -- 10/25/2017 Rajendra K : Removed condition INVTMF.QTY_OH > 0 to display all MFGR records 
  -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition  
   AND ((@NonNettable = 1 AND invtMf.SFBL = 0) OR invtMf.NETABLE = 1) -- 09/13/2017 Rajendra K : Apply WO Reservation default settings    
		 INNER JOIN WAREHOUS W  ON invtMf.Uniqwh = W.UNIQWH
		 LEFT JOIN InvtResCte IR ON invtMf.W_KEY = IR.W_KEY
		 LEFT JOIN KAMAIN K ON K.UNIQ_KEY = invtMf.UNIQ_KEY -- 11/02/2017 Rajendra K : Added Kamain table in join condition to get Manufacturer data for Autocomplete
	LEFT JOIN SUPINFO sup ON invtMf.uniqsupno = sup.UNIQSUPNO -- 03/16/2020 Rajendra K : Added Instore,Supplier field in selection list and added left join with Supinfo table 
	WHERE (@uniqKey IS NULL OR @uniqKey = '' OR INVTMF.UNIQ_KEY = @uniqKey)
	      AND (@uniqWHKey IS NULL OR @uniqWHKey = '' OR INVTMF.UNIQWH = @uniqWHKey)
		    AND (@wKey IS NULL OR @wKey = '' OR INVTMF.W_KEY = @wKey)
	      AND (@KaSeqNumber = NULL OR @KaSeqNumber ='' OR K.KaSeqNum = @KaSeqNumber)   --  09/27/2019 Rajendra K : Added new paramrter @KaSeqNumber and condition
		  -- 10/25/2017 Rajendra K : Removed condition AND ((INVTMF.Qty_Oh- INVTMF.Reserved) - ISNULL(IR.Allocated,0)) <> 0 to display all MFGR records 
		  --AND ((INVTMF.Qty_Oh- INVTMF.Reserved) - ISNULL(IR.Allocated,0)) <> 0 -- 07/28/2017 Rajendra K : Excluding MFGR records where Available quanityt is zero
		  AND (@isAutoComplete = 1 OR @location IS NULL OR RTRIM(INVTMF.LOCATION) = @location) -- 08/02/2017 Rajendra K : Added to get MFGR records by location --  --11/17/2017 Rajendra K : Added @isAutoComplete 
		  --11/02/2017 Rajendra K : Removed white spaces from  @location on script start
		  -- 09/13/2017 Rajendra K : Apply WO Reservation default settings
		  -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.
		AND ((INVTMF.Qty_Oh- INVTMF.Reserved) > 0 OR INVTMF.Reserved > 0)-- 11/06/2019 Rajendra K : where Qty_oh  > 0 condition   
		   -- AND (@MfgrDefault = 'All MFGRS' OR 
		   AND (NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A -- 04/18/2019 Rajendra K : Replaced @uniqKey by "@CosignUniqKey"
        WHERE A.BOMPARENT = k.BOMPARENT AND A.UNIQ_KEY = @CosignUniqKey AND A.PARTMFGR = mfg.PARTMFGR and A.MFGR_PT_NO = mfg.MFGR_PT_NO)) --)    
     AND (@isAutoComplete = 0 OR (@woNumber IS NULL OR @woNumber= '' OR K.WONO =  @woNumber))     -- 11/06/2019 Rajendra K : Replaced @BomParent by K.BOMParent  
		   -- 11/02/2017 Rajendra K : Added condition to get Manufacturer data for Autocomplete
   ORDER BY MfgrPtNo,PartMfgr -- 12/07/2017 Rajendra K : Added order by Clause
   
   SET @sqlQuery =  'SELECT * FROM #TempData ORDER BY '+@sortExpression  -- 05/02/2019 Rajendra K : Added @sortExpression parameter 
   EXEC sp_executesql @sqlQuery 
   DROP TABLE #TempWOSettings
END