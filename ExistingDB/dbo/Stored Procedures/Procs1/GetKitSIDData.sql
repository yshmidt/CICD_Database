-- =============================================
-- Author:Rajendra K
-- Create date: 09/06/2017
-- Description:	Get SID detail 
-- Modification 
   -- 09/13/2017 Rajendra K : Apply WO Reservation default settings
   -- 09/14/2017 Rajendra K : Added  OriginalIpkeyUnique & OriginalpkgBal for SID rejoin 
   -- 09/14/2017 Rajendra K : Get reserved quantity from IreserveIpey table
   -- 09/15/2017 Rajendra K : Removed condition @location = '' from where clause (Some location values are empty in table)
   -- 09/25/2017 Rajendra K : Added condition to check IpKeyUnique to get SID specific data			
   -- 10/04/2017 Rajendra K : Setting Name changed in where clause for #temoWOSettings to get ICM default settings
   -- 10/25/2017 Rajendra K : Removed condition INVTMF.QTY_OH > 0 to display all MFGR records 
   -- 10/25/2017 Rajendra K : Added INVENTOR table in join to get U_OF_MEAS    
   -- 10/25/2017 Rajendra K : Added U_OF_MEAS in select list
   -- 11/24/2017 Rajendra K : Replaced UNIQ_KEY with WONO to get BOMParent
   -- 11/24/2017 Rajendra K : Parameter name renamed as per naming conventions
   -- 01/10/2018 Rajendra K : Removed join with Kamin in second section of union
   -- 12/07/2017 Rajendra K : Added order by clause
   -- 11/27/2017 Rajenda K : Correction for parameter comparision(replaced @uniqWHKey by @uniqKey in where clause) 
   -- 06/02/2019 Rajendra K : Added @sortExpression parameter 
   -- 04/16/2019 Rajendra K : Added Input parameter @custNo
   -- 04/16/2019 Rajendra K : Added SET statement for @CosignUniqKey if part is CONSG 
   -- 04/17/2019 Rajendra K : Added "ManufactList" table to select consign's manufacture.
   -- 04/17/2019 Rajendra K : Added inner join with "ManufactList" table 
   -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.
   -- 04/18/2019 Rajendra K : Replaced @uniqKey by "@CosignUniqKey"
   -- 06/12/2019 Rajendra K : Changed QtyOh fn_GetCCQtyOH(IR.UNIQ_KEY,IP.W_Key,'',IRI.IPKEYUNIQUE) to pkgBalance
   -- 08/06/2019 Rajendra K : Changed location datatype from VARCHAR to NVARCHAR
   -- 08/08/19 YS Location is 200 characters  
   -- 11/06/2019 Rajendra K : Replaced @BomParent by K.BOMParent    
   -- 11/06/2019 Rajendra K : Added condition @kaSeqNum     
   -- 11/06/2019 Rajendra K : Added condition for antiavl records     
   -- 11/06/2019 Rajendra K : Added join with Kamin     
   -- 01/23/2020 Rajendra K : Removed the Instore condition to show instore locations
   -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition   
   -- 03/16/2020 Rajendra K : Added Instore,Supplier field in selection list and added left join with Supinfo table 
   -- 06/22/2020 Rajendra K : Added DoNotKit field in selection list  
   -- 08/31/2020 Rajendra K : Bring the correct pkgBalance  
   -- 12/01/2020 Rajendra K : Changed the selection of OriginalIpkeyUnique and OriginalpkgBal   
   -- GetKitSIDData 'B3UERG3BL4','','_14P0L5MHY','','W1SLUJW2AL','','0000001221','0000000002','QtyOh desc'
-- =============================================
CREATE PROCEDURE [dbo].[GetKitSIDData]
(
	@uniqKey AS CHAR(10)='',
	@uniqmfgrhd CHAR(10)='',
	@uniqWHKey VARCHAR(10)='',
 @location NVARCHAR (200)='',   -- 08/06/2019 Rajendra K : Changed location datatype from VARCHAR to NVARCHAR  
	@kaSeqNum  CHAR(10)='',
	@ipKeyUniq CHAR(10)='',
	@wONO CHAR(10)='', 
	@custNo CHAR(10) = '',   -- 04/16/2019 Rajendra K : Added Input parameter @custNo
	@sortExpression char(1000) = NULL  -- 06/02/2019 Rajendra K : Added @sortExpression parameter 
)
AS
BEGIN
SET NOCOUNT ON  
	-- 09/13/2017 Rajendra K : Added WO Reservation  default settings logic 
    --Declare variables
    --DECLARE @mfgrDefault NVARCHAR(MAX),
	DECLARE @nonNettable BIT,@bomParent CHAR(10),@CosignUniqKey CHAR(10);
	DECLARE @sqlQuery NVARCHAR(MAX); -- 06/02/2019 Rajendra K : Added @sqlQuery for dynamic Query

	IF OBJECT_ID(N'tempdb..#temp') IS NOT NULL
     DROP TABLE #temp ;  -- 06/02/2019 Rajendra K : Added temp table for @sortExpression 

	 -- 04/16/2019 Rajendra K : Added SET statement for @CosignUniqKey if part is CONSG    
	SET @CosignUniqKey = ISNULL((SELECT UNIQ_KEY FROM INVENTOR WHERE INT_UNIQ = @uniqKey AND CUSTNO = @custNo),@uniqKey);		

	SELECT SettingName
		   ,LTRIM(WM.SettingValue) SettingValue
	INTO #tempWOSettings
	FROM MnxSettingsManagement MS INNER JOIN WmSettingsManagement WM ON  MS.settingId = WM.settingId  
	WHERE SettingName  = 'allowUseOfNonNettableWarehouseLocation'--IN('manufacturersDefault','allowUseOfNonNettableWarehouseLocation')  -- 10/04/2017 Rajendra K : Setting Name changed in where clause

    --Assign values to variables to hold values for WO Reservation  default settings
	 -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.
	--SET @mfgrDefault = ISNULL((SELECT SettingValue FROM #tempWOSettings WHERE SettingName = 'manufacturersDefault'),'All MFGRS')	 -- 10/04/2017 Rajendra K : Setting Name changed in where clause
	SET @nonNettable= ISNULL((SELECT CONVERT(Bit, SettingValue) FROM #tempWOSettings WHERE SettingName = 'allowUseOfNonNettableWarehouseLocation'),0) -- 10/04/2017 Rajendra K : Setting Name changed in where clause
	SET @bomParent = (SELECT UNIQ_KEY FROM WOENTRY WHERE WONO = @wONO) -- 11/24/2017 Rajendra K : Replaced UNIQ_KEY with WONO
	SET @sortExpression = CASE WHEN @sortExpression IS NULL OR @sortExpression = '' THEN 'Mfgr,MfgrPartNo' ELSE @sortExpression END -- 06/02/2019 Rajendra K : Added @sortExpression 

	;WITH ManufactList AS(  -- 04/17/2019 Rajendra K : Added "ManufactList" table to select consign's manufacture.
	      SELECT DISTINCT mf.MfgrMasterId
		  FROM INVTMFGR im 
		     INNER JOIN InvtMPNLink m ON im.uniqmfgrhd = m.UNIQMFGRHD
		     INNER JOIN  MfgrMaster mf ON mf.MfgrMasterId = m.MfgrMasterId 
			WHERE im.UNIQ_KEY = @CosignUniqKey AND m.is_deleted = 0
   )    
	SELECT * INTO #temp 
	FROM(
		  SELECT DISTINCT IRI.IPKEYUNIQUE AS Sid
	-- 08/31/2020 Rajendra K : Bring the correct pkgBalance      
       ,PkgBal.pkgBalance AS pkgBalance --SUM(ip.pkgBalance) - SUM(ip.qtyAllocatedTotal) AS pkgBalance  
						 ,SUM(IRI.qtyAllocated) AS Allocated -- 09/14/2017 - Rajendra K : Get reserved quantity from IreserveIpey table
						 ,mfg.PartMfgr AS Mfgr
						 ,mfg.mfgr_pt_no AS MfgrPartNo  
						 ,IP.W_KEY
						 ,IP.UNIQMFGRHD
						  ,RTRIM(wh.Warehouse)+ (CASE WHEN IM.Location IS NULL OR IM.Location =''  THEN RTRIM(IM.Location) ELSE ' / '+RTRIM(IM.Location) END) AS ToWarehouse
						 ,IR.Uniq_Key -- 12/01/2020 Rajendra K : Changed the selection of OriginalIpkeyUnique and OriginalpkgBal   
						 ,CASE WHEN (SELECT COUNT(1) FROM  IPKEY WHERE ipkeyunique = IP.originalIpkeyUnique)>1 THEN '' 
						  ELSE ISNULL((SELECT IPKEYUNIQUE FROM  IPKEY WHERE ipkeyunique = IP.originalIpkeyUnique AND qtyAllocatedTotal = 0),'') END AS  OriginalIpkeyUnique
						  ,CASE WHEN (SELECT COUNT(1) FROM  IPKEY WHERE ipkeyunique = IP.originalIpkeyUnique)>1 THEN 0 
						  ELSE ISNULL((SELECT pkgBalance FROM  IPKEY WHERE ipkeyunique = IP.originalIpkeyUnique AND qtyAllocatedTotal = 0),0) END AS  OriginalpkgBal
						 --,CASE WHEN (SELECT COUNT(1) FROM  IPKEY WHERE originalIpkeyUnique = IRI.IPKEYUNIQUE)>1 THEN '' 
						 -- ELSE ISNULL((SELECT IPKEYUNIQUE FROM  IPKEY WHERE originalIpkeyUnique = IRI.IPKEYUNIQUE AND qtyAllocatedTotal = 0),'') END AS  OriginalIpkeyUnique
						 --  -- 09/14/2017 Rajendra K : Added  OriginalIpkeyUnique for SID rejoin 
						 -- ,CASE WHEN (SELECT COUNT(1) FROM  IPKEY WHERE originalIpkeyUnique = IRI.IPKEYUNIQUE)>1 THEN 0 
						 -- ELSE ISNULL((SELECT pkgBalance FROM  IPKEY WHERE originalIpkeyUnique = IRI.IPKEYUNIQUE AND qtyAllocatedTotal = 0),0) END AS  OriginalpkgBal
						  -- 09/14/2017 Rajendra K : Added  OriginalpkgBal for SID rejoin 
						  ,I.U_OF_MEAS AS Unit -- 10/25/2017 Rajendra K : Added U_OF_MEAS in select list
						  --,dbo.fn_GetCCQtyOH(IR.UNIQ_KEY,IP.W_Key,'',IRI.IPKEYUNIQUE) AS QtyOh -- 12/19/2017 Rajendra K : Added QtyOh in select list for CC
						 -- 06/12/2019 Rajendra K : Changed QtyOh fn_GetCCQtyOH(IR.UNIQ_KEY,IP.W_Key,'',IRI.IPKEYUNIQUE) to pkgBalance
				  -- 08/31/2020 Rajendra K : Bring the correct pkgBalance      
				  ,PkgBal.pkgBalance AS QtyOh--SUM(ip.pkgBalance) - SUM(ip.qtyAllocatedTotal) AS QtyOh  
		          ,IM.INSTORE      -- 03/16/2020 Rajendra K : Added Instore,Supplier field in selection list and added left join with Supinfo table  
		          ,sup.SUPNAME  AS Supplier     
			   	  ,mfg.LDISALLOWKIT AS DoNotKit-- 06/22/2020 Rajendra K : Added DoNotKit field in selection list       
    FROM iReserveIpKey IRI INNER JOIN INVT_RES IR ON  IRI.INVTRES_NO = IR.invtres_no  AND IR.UNIQ_KEY = @uniqKey AND IR.WONO = @wONO   
				INNER JOIN kamain K ON  IR.KaSeqnum = K.KASEQNUM 
				INNER JOIN INVTMFGR IM ON  IR.W_KEY = IM.W_KEY AND im.UNIQWH = @uniqWHKey
				INNER JOIN INVENTOR I ON IR.UNIQ_KEY = I.UNIQ_KEY -- 10/25/2017 Rajendra K : Added INVENTOR table in join to get U_OF_MEAS
		        INNER JOIN IPKEY IP ON  IP.IPKEYUNIQUE = IRI.Ipkeyunique AND IR.W_KEY = IP.W_KEY 
				INNER JOIN InvtMpnLink iml  ON  ip.UNIQMFGRHD = iml.uniqmfgrhd
				INNER JOIN MfgrMaster mfg  ON  iml.MfgrMasterId = mfg.MfgrMasterId								  
				INNER JOIN ManufactList ML ON mfg.MfgrMasterId = ML.MfgrMasterId  -- 04/17/2019 Rajendra K : Added inner join with "ManufactList" table 
				INNER JOIN WAREHOUS wh  ON  IM.Uniqwh = wh.UNIQWH
				LEFT JOIN SUPINFO sup ON IM.uniqsupno = sup.UNIQSUPNO    -- 03/16/2020 Rajendra K : Added Instore,Supplier field in selection list and added left join with Supinfo table       
	OUTER APPLY (-- 08/31/2020 Rajendra K : Bring the correct pkgBalance      
		SELECT (ip.pkgBalance - ip.qtyAllocatedTotal) AS pkgBalance FROM IPKEY WHERE IPKEYUNIQUE = IRI.Ipkeyunique
	) AS PkgBal
		  WHERE (@uniqmfgrhd IS NULL OR @uniqmfgrhd = '' OR  (IP.UNIQMFGRHD = @uniqmfgrhd))
			    AND (@uniqKey IS NULL OR @uniqKey = '' OR IP.UNIQ_KEY = @uniqKey)
				AND (@kaSeqNum IS NULL OR @kaSeqNum = '' OR k.KASEQNUM = @kaSeqNum)
				AND (@location IS NULL OR im.Location = @location)  -- 09/15/2017 Rajendra K : Removed condition @location = '' from where clause (Some location values are empty in table)
				AND (@uniqWHKey IS NULL OR @uniqWHKey ='' OR im.Uniqwh = @uniqWHKey)	
				AND (@ipKeyUniq IS NULL OR @ipKeyUniq ='' OR IP.IPKEYUNIQUE = @ipKeyUniq) -- 09/25/2017 Rajendra K : Added condition to check IpKeyUnique to get SID specific data			
    AND (NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A     
        WHERE A.BOMPARENT = K.BOMPARENT AND A.UNIQ_KEY = @CosignUniqKey AND A.PARTMFGR = mfg.PARTMFGR     
        and A.MFGR_PT_NO = mfg.MFGR_PT_NO)) -- 11/06/2019 Rajendra K : Added condition for antiavl records     
    GROUP BY IRI.IPKEYUNIQUE,mfg.PartMfgr,mfg.mfgr_pt_no,IP.UNIQMFGRHD,IP.W_KEY,wh.Warehouse,IM.Location,IR.UNIQ_KEY,I.U_OF_MEAS,IM.INSTORE 
           ,sup.SUPNAME ,mfg.LDISALLOWKIT,PkgBal.pkgBalance ,IP.originalIpkeyUnique ,IP.pkgBalance               
		HAVING SUM(ip.qtyAllocatedTotal) <>0					  		  		  
		UNION
		  SELECT DISTINCT ip.IPKEYUNIQUE AS Sid
					   ,ip.pkgBalance - ip.qtyAllocatedTotal AS pkgBalance
					   ,ip.qtyAllocatedTotal AS Allocated
					   ,mfg.PartMfgr AS Mfgr
					   ,mfg.mfgr_pt_no AS MfgrPartNo  
					   ,im.W_Key AS W_KEY 
					   ,ip.UNIQMFGRHD AS UNIQMFGRHD 
					   ,RTRIM(wh.Warehouse)+ (CASE WHEN IM.Location IS NULL OR IM.Location =''  THEN RTRIM(IM.Location) ELSE ' / '+RTRIM(IM.Location) END) AS ToWarehouse
					   ,i.Uniq_Key
					   ,'' AS OriginalIpkeyUnique  -- 09/14/2017 Rajendra K : Added  OriginalIpkeyUnique for SID rejoin 
					   ,0 AS OriginalpkgBal -- 09/14/2017 Rajendra K : Added  OriginalpkgBal for SID rejoin 
					   ,I.U_OF_MEAS AS Unit -- 10/25/2017 Rajendra K : Added U_OF_MEAS in select list
					  -- ,dbo.fn_GetCCQtyOH(i.UNIQ_KEY,im.W_Key,'',ip.IPKEYUNIQUE) AS QtyOh -- 12/19/2017 Rajendra K : Added QtyOh in select list for CC
					 -- 06/12/2019 Rajendra K : Changed QtyOh fn_GetCCQtyOH(IR.UNIQ_KEY,IP.W_Key,'',IRI.IPKEYUNIQUE) to pkgBalance 
					  ,ip.pkgBalance - ip.qtyAllocatedTotal AS QtyOh
					  ,IM.INSTORE    -- 03/16/2020 Rajendra K : Added Instore,Supplier field in selection list and added left join with Supinfo table 
					  ,sup.SUPNAME AS Supplier         
		   ,mfg.LDISALLOWKIT AS DoNotKit-- 06/22/2020 Rajendra K : Added DoNotKit field in selection list            
   FROM Ipkey ip INNER JOIN Inventor i  ON  ip.UNIQ_KEY = i.Uniq_Key  
              INNER JOIN KAMAIN k  ON  i.Uniq_Key = k.UNIQ_KEY --01/10/2018 Rajendra K : Removed join with Kamin --11/06/2019 Rajendra K : Added join with Kamin     
              INNER JOIN InvtMpnLink iml  ON  ip.UNIQMFGRHD = iml.uniqmfgrhd
              INNER JOIN Invtmfgr im  ON  ip.W_KEY = im.W_Key
			  LEFT JOIN SUPINFO sup ON IM.uniqsupno = sup.UNIQSUPNO   -- 03/16/2020 Rajendra K : Added Instore,Supplier field in selection list and added left join with Supinfo table        
				 -- 01/23/2020 Rajendra K : Removed the Instore condition to show instore locations
				 AND im.Is_deleted = 0  --AND im.InStore=0 -- 09/13/2017 Rajendra K : Excluding MFGR records with value Is_deleted & invtMf.InStore = 0
				  --AND im.QTY_OH > 0 -- 10/25/2017 Rajendra K : Removed condition INVTMF.QTY_OH > 0 to display all MFGR records 
				 -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition        
				 AND ((@nonNettable = 1 AND im.SFBL = 0) OR im.NETABLE = 1) -- 09/13/2017 Rajendra K : Apply WO Reservation default settings        
               INNER JOIN WAREHOUS wh  ON  im.Uniqwh = wh.UNIQWH
               INNER JOIN MfgrMaster mfg  ON  iml.MfgrMasterId = mfg.MfgrMasterId
			   INNER JOIN ManufactList ML ON mfg.MfgrMasterId = ML.MfgrMasterId 	  -- 04/17/2019 Rajendra K : Added inner join with "ManufactList" table 				  
		WHERE (@uniqKey IS NULL OR @uniqKey = '' OR ip.UNIQ_KEY = @uniqKey ) 
               AND (@uniqmfgrhd IS NULL OR @uniqmfgrhd = '' OR ip.UNIQMFGRHD = @uniqmfgrhd)
			   AND (@uniqWHKey IS NULL OR @uniqWHKey ='' OR im.Uniqwh = @uniqWHKey)
               AND (@location IS NULL OR im.Location = @location) -- 09/15/2017 Rajendra K : Removed condition @location = '' from where clause (Some location values are empty in table)
      AND (@kaSeqNum IS NULL OR @kaSeqNum = '' OR k.KASEQNUM = @kaSeqNum) -- 11/06/2019 Rajendra K : Added condition @kaSeqNum     
			   AND (@ipKeyUniq IS NULL OR @ipKeyUniq = '' OR ip.IPKEYUNIQUE = @ipKeyUniq)
			   AND ip.qtyAllocatedTotal = 0 AND (ip.pkgBalance - ip.qtyAllocatedTotal <> 0)
			   -- 09/13/2017 Rajendra K : Apply WO Reservation default settings
			   -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.
			   --AND (@mfgrDefault = 'All MFGRS' OR   
			   AND (NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A -- 04/18/2019 Rajendra K : Replaced @uniqKey by "@CosignUniqKey"
        WHERE A.BOMPARENT = k.BOMPARENT AND A.UNIQ_KEY = @CosignUniqKey AND A.PARTMFGR = mfg.PARTMFGR -- 11/27/2018 Rajendra K : Replace @uniqWHKey by @uniqKey    
        and A.MFGR_PT_NO = mfg.MFGR_PT_NO)) --)   -- 11/06/2019 Rajendra K : Replaced @BomParent by K.BOMParent    
		) t
		
		 SET @sqlQuery =  'SELECT * FROM #temp ORDER BY '+@sortExpression  -- 06/02/2019 Rajendra K : Added @sortExpression on #temp table 
		 EXEC sp_executesql @sqlQuery 
		--ORDER BY Mfgr,MfgrPartNo  -- 12/07/2017 Rajendra K : Added order by clause
END 