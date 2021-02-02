
-- =============================================
-- Author:		Rajendra K	
-- Create date: <05/36/2017>
-- Description:Get LotDetails and SID Data
-- Modification
   -- 06/20/2017 Rajendra K : Added Input parameter @UniqWH to get records from same WorkCener 
   -- 06/20/2017 Rajendra K : Removed condition IL.LOTQTY - IL.LOTRESQTY > 0 to reserved parts 
   -- 06/20/2017 Rajendra K : Added parameter @Location to get records from same Location
   -- 06/20/2017 Rajendra K : Added parameter @KaSeqNumber to get records from same KaSeqNumber
   -- 06/30/2017 Rajendra K : Removed condition '(IP.pkgBalance - IP.qtyAllocatedTotal)>0' to get Reserved parts 
   -- 06/30/2017 Rajendra K : Removed condition '(IP.pkgBalance - IP.qtyAllocatedTotal)>0' to get Reserved parts 
   -- 07/25/2017 Rajendra K : Set Available quantity as (Available - Reserve) qty 
   -- 07/25/2017 Rajendra K : Divided query on UseIpKey column from Inventor table
   -- 07/25/2017 Rajendra K : Added Input parameter @WoNumber
   -- 07/25/2017 Rajendra K : Added CTE InvtResCte to get Reserved Quantity from Invt_Res table
   -- 08/02/2017 Rajendra K : Check and Exclude records with zero quantity added
   -- 08/02/2017 Rajendra K : Added CTE IReserveIpkeyCte to get records from  ireserveipkey
   -- 08/11/2017 Rajendra K : Added condition in join
   -- 08/11/2017 Rajendra K : Added condition to get valid records from InvtMfgr table
   -- 09/13/2017 Rajendra K : Added WO Reservation  default settings logic
   -- 09/14/2017 Rajendra K : Added  OriginalIpkeyUnique and OriginalpkgBal for SID rejoin 
   -- 09/26/2017 Rajendra K : Added join condition in CTE IReserveIpkeyCte to get WONO specific data
   -- 10/04/2017 Rajendra K : Setting Name changed in where clause for #temoWOSettings to get ICM default settings
   -- 10/0/92017 Rajendra K : Change value '' to 0 as default value for OriginalPackageBal
   -- 10/25/2017 Rajendra K : Removed condition INVTMF.QTY_OH > 0 to display all MFGR records 
   -- 10/25/2017 Rajendra K : Added INVENTOR table in join to get U_OF_MEAS
   -- 10/25/2017 Rajendra K : Added U_OF_MEAS in select list
   -- 11/24/2017 Rajendra K : Replaced UNIQ_KEY with WONO to get BOMParent
   -- 11/27/2017 Rajendra K : Added QtyOh in select list for CC 
   -- 12/07/2017 Rajendra K : Added order by clause
   -- 12/08/2017 Rajendra K : Replaced * by 1 in IF EXISTS condition
   -- 12/22/2017 Rajendra K : Added '/' for WarehouseLocation
   -- 01/23/2017 Rajendra K : Added Input parameter @sortExpression
   -- 04/16/2019 Rajendra K : Added Input parameter @CustNo
   -- 04/16/2019 Rajendra K : Added SET statement for @CosignUniqKey if part is CONSG
   -- 04/17/2019 Rajendra K : Added "ManufactList" table to select consign's manufacture.
   -- 04/18/2019 Rajendra K : Added inner join with "ManufactList" table    
   -- 04/18/2019 Rajendra K : Replaced K.UNIQ_KEY by "@CosignUniqKey" 
   -- 06/12/2019 Rajendra K : Changed QtyOh dbo.fn_GetCCQtyOH(K.UNIQ_KEY,IM.W_Key,IL.UNIQ_LOT,'') to Lot QtyOh 
   -- 08/02/2019 Rajendra K : Added ISNULL on condition
   -- 08/06/2019 Rajendra K : Changed location datatype from VARCHAR to NVARCHAR
   -- 08/08/19 YS location is 200 characters in all the tables  
   -- 11/06/2019 Rajendra K : Replaced @BomParent by K.BOMParent  
   -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations    
   -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition   
   -- 03/16/2020 Rajendra K : Added Instore,Supplier field in selection list and added left join with Supinfo table  
   -- 06/22/2020 Rajendra K : Added DoNotKit field in selection list     
   -- GetLotDetailsData '9PYOKX3J4S','','_0DM120YNM','','0K233I4N2W','0000001334','',''        
-- =============================================      
CREATE PROCEDURE [dbo].[GetLotDetailsData]      
(      
@UniqKey  CHAR(10)='',      
@MfgrMasterhd  CHAR(10)='',      
@UniqWH CHAR(10)='',      
@Location NVARCHAR(200)='',-- 08/06/2019 Rajendra K : Changed location datatype from VARCHAR to NVARCHAR      
@KaSeqNumber CHAR(10)='',      
@WoNumber CHAR(10)='',      
@CustNo CHAR(10) = '',  -- 04/16/2019 Rajendra K : Added Input parameter @CustNo      
@SortExpression NVARCHAR(200)= ''        
)      
AS      
BEGIN      
 SET NOCOUNT ON;      
 -- 01/23/2017 Rajendra K : Added table for sorting      
 IF OBJECT_ID(N'tempdb..#TempData') IS NOT NULL      
    DROP TABLE #TempData;      
 IF OBJECT_ID(N'tempdb..#TempDataEl') IS NOT NULL      
    DROP TABLE #TempDataEl;      
    -- 09/13/2017 Rajendra K : Added WO Reservation  default settings logic      
    --Declare variables      
    -- DECLARE @MfgrDefault NVARCHAR(MAX);      
 DECLARE  @NonNettable BIT,@BomParent CHAR(10), @qryMain  NVARCHAR(MAX),@CosignUniqKey CHAR(10);      
      
 -- 04/16/2019 Rajendra K : Added SET statement for @CosignUniqKey if part is CONSG          
 SET @CosignUniqKey = ISNULL((SELECT UNIQ_KEY FROM INVENTOR WHERE INT_UNIQ = @UniqKey AND CUSTNO = @CustNo),@UniqKey);           
      
 SELECT SettingName      
     ,LTRIM(WM.SettingValue) SettingValue      
 INTO  #TempWOSettings      
 FROM MnxSettingsManagement MS INNER JOIN WmSettingsManagement WM ON MS.settingId = WM.settingId        
 WHERE SettingName  = 'allowUseOfNonNettableWarehouseLocation'--IN('manufacturersDefault','allowUseOfNonNettableWarehouseLocation') -- 10/04/2017 Rajendra K : Setting Name changed in where clause      
      
    --Assign values to variables to hold values for WO Reservation  default settings      
 -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.      
 --SET @MfgrDefault = ISNULL((SELECT SettingValue FROM #TempWOSettings WHERE SettingName = 'manufacturersDefault'),'All MFGRS')  -- 10/04/2017 Rajendra K : Setting Name changed in where clause      
 SET @NonNettable= ISNULL((SELECT CONVERT(Bit, SettingValue) FROM #TempWOSettings WHERE SettingName = 'allowUseOfNonNettableWarehouseLocation'),0) -- 10/04/2017 Rajendra K : Setting Name changed in where clause      
 SET @BomParent = (SELECT UNIQ_KEY FROM WOENTRY WHERE WONO = @WoNumber) -- 11/24/2017 Rajendra K : Replaced UNIQ_KEY with WONO      
 SET @sortExpression = CASE WHEN @sortExpression IS NULL OR @sortExpression = '' THEN 'ExpDate,LOTCODE' ELSE @SortExpression END       
      
    IF NOT EXISTS(SELECT 1 FROM INVENTOR WHERE UNIQ_KEY = @UniqKey AND USEIPKEY = 1 ) -- 12/08/2017 Rajendra K : Replaced * by 1       
 BEGIN      
 -- GetLotDetailsData '_1EP0Q018H','','_0DM120YNN','','UIKKVDYDFB','0000000515'      
  ;WITH  ManufactList AS(  -- 04/17/2019 Rajendra K : Added "ManufactList" table to select consign's manufacture.      
       SELECT DISTINCT mf.MfgrMasterId      
    FROM INVTMFGR im       
       INNER JOIN InvtMPNLink m ON im.uniqmfgrhd = m.UNIQMFGRHD      
       INNER JOIN  MfgrMaster mf ON mf.MfgrMasterId = m.MfgrMasterId       
   WHERE im.UNIQ_KEY = @CosignUniqKey AND m.is_deleted = 0      
    ),      
  InvtResCte AS       
  (      
    SELECT SUM(QTYALLOC) AS Allocated      
    ,W_KEY      
    ,LOTCODE      
    ,Reference      
    ,ExpDate      
    ,PONUM      
    ,KaSeqNum          
    FROM       
    INVT_RES IR       
    WHERE IR.WONO = @WoNumber AND KaSeqNum = @KaSeqNumber      
    GROUP BY W_KEY      
      ,LOTCODE      
      ,Reference      
      ,ExpDate      
      ,PONUM      
      ,KaSeqNum      
  )      
 SELECT DISTINCT IL.UNIQ_LOT AS UniqLot               
           ,IL.LOTCODE AS LotCode       
           ,IM.W_Key AS WKey        
           ,IL.REFERENCE AS Reference       
           ,IL.EXPDATE AS ExpDate      
           ,IL.PONUM AS PONumber      
           ,IM.Uniqmfgrhd AS UniqMfgrhd        
           ,MM.PartMfgr AS PartMfgr        
           ,MM.mfgr_pt_no AS MfgrPtNo       
     ,'' AS SID      
     ,COALESCE(IL.LOTQTY,0)-COALESCE(IL.LOTRESQTY,0) AS LotQty --07/25/2017 Rajendra K :  Set Available quantity as (Available - Reserve) qty      
     ,COALESCE(IR.Allocated,0) AS LotResQty      
     ,RTRIM(W.Warehouse)+ (CASE WHEN IM.Location IS NULL OR IM.Location =''  THEN RTRIM(IM.Location) ELSE ' / '+RTRIM(IM.Location) END) AS ToWarehouse -- 12/22/2017 Rajendra : Added '/' for WarehouseLocation      
     ,I.U_OF_MEAS -- 10/25/2017 Rajendra K : Added U_OF_MEAS in select list      
    --,dbo.fn_GetCCQtyOH(K.UNIQ_KEY,IM.W_Key,IL.UNIQ_LOT,'') AS QtyOh -- 11/27/2017 Rajendra K : Added QtyOh in select list for CC      
    -- 06/12/2019 Rajendra K : Changed QtyOh dbo.fn_GetCCQtyOH(K.UNIQ_KEY,IM.W_Key,IL.UNIQ_LOT,'') to Lot QtyOh       
     ,COALESCE(IL.LOTQTY,0)-COALESCE(IL.LOTRESQTY,0)  AS QtyOh
	,IM.INSTORE    -- 03/16/2020 Rajendra K : Added Instore,Supplier field in selection list and added left join with Supinfo table 
	,sup.SUPNAME AS Supplier    
	,MM.LDISALLOWKIT AS DoNotKit-- 06/22/2020 Rajendra K : Added DoNotKit field in selection list      
 INTO #TempData -- 01/23/2017 Rajendra K : Added table for sorting      
 FROM InvtMpnLink IML       
 INNER JOIN KAMAIN K ON IML.Uniq_Key =  K.UNIQ_KEY -- 06/20/2017 Rajendra K : Added join condition with table  KaMain to get records from same KaSeqNumber      
 INNER JOIN INVENTOR I ON K.UNIQ_KEY = I.UNIQ_KEY -- 10/25/2017 Rajendra K : Added INVENTOR table in join to get U_OF_MEAS      
 INNER JOIN INVTMFGR IM ON IML.uniqmfgrhd = IM.Uniqmfgrhd       
   --AND IM.QTY_OH > 0  -- 10/25/2017 Rajendra K : Removed condition INVTMF.QTY_OH > 0 to display all MFGR records       
      -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition    
   AND ((@NonNettable = 1  AND IM.SFBL = 0) OR IM.NETABLE = 1) -- 09/13/2017 Rajendra K : Apply WO Reservation default settings         
  -- AND IM.InStore = 0    -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations    
   AND IM.IS_DELETED = 0 -- 08/11/2017 Rajendra K : Added this condition to get valid records from InvtMfgr table      
 INNER JOIN  WAREHOUS W ON IM.Uniqwh = W.UNIQWH      
 INNER JOIN INVTLOT IL ON IM.W_Key = IL.W_KEY -- 06/20/2017 Rajendra K : Removed condition IL.LOTQTY - IL.LOTRESQTY > 0 to reserved parts      
 INNER JOIN MfgrMaster MM  ON IML.MfgrMasterId = MM.MfgrMasterId      
 INNER JOIN ManufactList ML ON MM.MfgrMasterId = ML.MfgrMasterId  -- 04/17/2019 Rajendra K : Added inner join with "ManufactList" table       
 LEFT JOIN InvtResCte IR ON IL.W_KEY = IR.W_KEY AND IM.W_KEY= IR.W_KEY AND  K.KASEQNUM = IR.KaSeqNum -- 07/25/2017 Rajendra K : Added Cte InvtResCte in Join condition to get Reserved qty from Invt_Res table      
       AND IL.LOTCODE = IR.LOTCODE      
       AND IL.REFERENCE = IR.REFERENCE      
       AND COALESCE(IL.EXPDATE,GETDATE()) = COALESCE(IR.EXPDATE,GETDATE())      
       AND IL.PONUM = IR.PONUM  
 LEFT JOIN SUPINFO sup ON IM.uniqsupno = sup.UNIQSUPNO  -- 03/16/2020 Rajendra K : Added Instore,Supplier field in selection list and added left join with Supinfo table      
 WHERE (@UniqKey = NULL OR @UniqKey= '' OR IML.uniq_key = @UniqKey)      
           AND (@MfgrMasterhd = NULL OR @MfgrMasterhd = '' OR IM.Uniqmfgrhd = @MfgrMasterhd)      
     AND (@UniqWH = NULL OR @UniqWH = '' OR IM.UNIQWH = @UniqWH) -- 06/20/2017 Rajendra K :  Added Input parameter @UniqWH to get records from same WorkCener      
     AND (@Location = NULL OR IM.LOCATION = @Location) -- 06/20/2017 Rajendra K : Added parameter @Location to get records from same Location      
     AND (@KaSeqNumber = NULL OR @KaSeqNumber ='' OR K.KaSeqNum = @KaSeqNumber) -- 06/20/2017 Rajendra K : Added parameter @KaSeqNumber to get records from same KaSeqNumber      
     AND ((COALESCE(IL.LOTQTY,0)-COALESCE(IL.LOTRESQTY,0))+COALESCE(IR.Allocated,0)) <> 0 -- 08/02/2017 - Rajendra K : Check and Exclude records with zero quantity added      
          -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.      
       --AND (@MfgrDefault = 'All MFGRS' OR       
   AND (NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A -- 04/18/2019 Rajendra K : Replaced K.UNIQ_KEY by "@CosignUniqKey"      
        WHERE A.BOMPARENT = K.BOMPARENT AND A.UNIQ_KEY = @CosignUniqKey AND A.PARTMFGR = MM.PARTMFGR and A.MFGR_PT_NO = MM.MFGR_PT_NO)) --)  
   SET @qryMain ='select * from #TempData'  +' ORDER BY ' + @SortExpression +';'      
   EXEC sp_executesql @qryMain -- 01/23/2017 Rajendra K : for sorting on @sortExpression      
 END      
 ELSE      
 BEGIN      
 --08/02/2017 Rajendra K : Added CTE IReserveIpkeyCte to get records from  ireserveipkey       
  ;WITH ManufactList AS(  -- 04/17/2019 Rajendra K : Added "ManufactList" table to select consign's manufacture.      
       SELECT mf.MfgrMasterId      
    FROM INVTMFGR im       
       INNER JOIN InvtMPNLink m ON im.uniqmfgrhd = m.UNIQMFGRHD      
       INNER JOIN  MfgrMaster mf ON mf.MfgrMasterId = m.MfgrMasterId       
   WHERE im.UNIQ_KEY = @CosignUniqKey AND m.is_deleted = 0      
    ),      
  IReserveIpkeyCte AS        
  (      
    SELECT SUM(QtyAllocated) AS Allocated        
    ,IR.KaSeqNum       
    ,ipkeyunique         
    FROM       
    ireserveipkey IR INNER JOIN INVT_RES IRS ON IR.invtres_no = IRS.INVTRES_NO AND IRS.WONO = @WoNumber -- 09/26/2017 Rajendra K : Added join condition to get WONO specific data      
    WHERE  IR.KaSeqNum = @KaSeqNumber      
    GROUP BY IR.KaSeqNum,ipkeyunique      
  )      
 SELECT DISTINCT IL.UNIQ_LOT AS UniqLot               
           ,IL.LOTCODE AS LotCode       
           ,IM.W_Key AS WKey        
           ,IL.REFERENCE AS Reference       
           ,IL.EXPDATE AS ExpDate      
           ,IL.PONUM AS PONumber      
           ,IM.Uniqmfgrhd AS UniqMfgrhd        
           ,MM.PartMfgr AS PartMfgr        
   ,MM.mfgr_pt_no AS MfgrPtNo       
     ,IP.IPKEYUNIQUE AS SID      
     ,COALESCE(IP.pkgBalance,0)-COALESCE(IP.qtyAllocatedTotal,0) AS LotQty --07/25/2017 Rajendra K : Set Available quantity as (Available - Reserve) qty      
     ,COALESCE(IR.Allocated,0) AS LotResQty      
     ,RTRIM(W.Warehouse)+ (CASE WHEN IM.Location IS NULL OR IM.Location =''  THEN RTRIM(IM.Location) ELSE ' / '+RTRIM(IM.Location) END) AS ToWarehouse -- 12/22/2017 Rajendra : Added '/' for WarehouseLocation      
     ,CASE WHEN (SELECT COUNT(1) FROM  IPKEY WHERE originalIpkeyUnique = IP.IPKEYUNIQUE)>1 THEN ''       
        ELSE ISNULL((SELECT IPKEYUNIQUE FROM  IPKEY WHERE originalIpkeyUnique = IP.IPKEYUNIQUE AND qtyAllocatedTotal = 0),'') END AS  OriginalIpkeyUnique      
        -- 09/14/2017 Rajendra K : Added  OriginalIpkeyUnique for SID rejoin      
     ,CASE WHEN (SELECT COUNT(1) FROM  IPKEY WHERE originalIpkeyUnique = IP.IPKEYUNIQUE)>1 THEN 0 -- 10/0/92017 Rajendra K : Change value '' to 0       
        ELSE ISNULL((SELECT pkgBalance FROM  IPKEY WHERE originalIpkeyUnique = IP.IPKEYUNIQUE AND qtyAllocatedTotal = 0),0) END AS  OriginalpkgBal      
        -- 09/14/2017 Rajendra K : Added  OriginalpkgBal for SID rejoin       
     ,I.U_OF_MEAS -- 10/25/2017 Rajendra K : Added U_OF_MEAS in select list      
     --,dbo.fn_GetCCQtyOH(K.UNIQ_KEY,IM.W_Key,'',IP.IPKEYUNIQUE) AS QtyOh -- 11/27/2017 Rajendra K : Added QtyOh in select list for CC      
     -- 06/12/2019 Rajendra K : Changed QtyOh dbo.fn_GetCCQtyOH(K.UNIQ_KEY,IM.W_Key,IL.UNIQ_LOT,'') to Lot QtyOh       
     ,COALESCE(IP.pkgBalance,0)-COALESCE(IP.qtyAllocatedTotal,0) AS QtyOh  
	 ,IM.INSTORE    -- 03/16/2020 Rajendra K : Added Instore,Supplier field in selection list and added left join with Supinfo table  
	 ,sup.SUPNAME AS Supplier         
	,MM.LDISALLOWKIT AS DoNotKit-- 06/22/2020 Rajendra K : Added DoNotKit field in selection list           
 INTO #TempDataEl -- 01/23/2017 Rajendra K : Added table for sorting      
 FROM InvtMpnLink IML       
 INNER JOIN KAMAIN K ON IML.Uniq_Key =  K.UNIQ_KEY -- 06/20/2017 Rajendra K : Added join condition with table  KaMain to get records from same KaSeqNumber      
 INNER JOIN INVENTOR I ON K.UNIQ_KEY = I.UNIQ_KEY -- 10/25/2017 Rajendra : Added INVENTOR table in join to get U_OF_MEAS      
 INNER JOIN INVTMFGR IM ON IML.uniqmfgrhd = IM.Uniqmfgrhd       
   --AND IM.QTY_OH > 0 -- 10/25/2017 Rajendra K : Removed condition INVTMF.QTY_OH > 0 to display all MFGR records    
   -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition       
   AND ((@NonNettable = 1 AND IM.SFBL = 0) OR IM.NETABLE = 1) -- 09/13/2017 Rajendra K : Apply WO Reservation default settings      
  -- AND IM.InStore = 0    -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations    
   AND IM.IS_DELETED = 0 -- 08/11/2017 Rajendra K : Added this condition to get valid records from InvtMfgr table      
 INNER JOIN  WAREHOUS W ON IM.Uniqwh = W.UNIQWH      
 INNER JOIN INVTLOT IL ON IM.W_Key = IL.W_KEY -- 06/20/2017 Rajendra K : Removed condition IL.LOTQTY - IL.LOTRESQTY > 0 to reserved parts On date      
 INNER JOIN MfgrMaster MM  ON IML.MfgrMasterId = MM.MfgrMasterId -- 09/13/2017 Rajendra K : Apply WO Reservation default settings      
 INNER JOIN ManufactList ML ON MM.MfgrMasterId = ML.MfgrMasterId  -- 04/17/2019 Rajendra K : Added inner join with "ManufactList" table       
 INNER JOIN Ipkey IP ON ISNULL(IL.EXPDATE,'') = ISNULL(IP.EXPDATE,'') AND ISNULL(IL.REFERENCE,'') = ISNULL(IP.REFERENCE,'')       
         AND ISNULL(IL.PONUM,'')  = ISNULL(IP.PONUM,'')  AND IL.LOTCODE = IP.LOTCODE     -- 08/02/2019 Rajendra K : Added ISNULL on condition         
         AND IM.W_Key = IP.W_KEY -- 08/11/2017 - Rajendra K : Added condition in  join      
 LEFT JOIN IReserveIpkeyCte IR ON IP.IPKEYUNIQUE = IR.ipkeyunique 
 LEFT JOIN SUPINFO sup ON IM.uniqsupno = sup.UNIQSUPNO   -- 03/16/2020 Rajendra K : Added Instore,Supplier field in selection list and added left join with Supinfo table              
 WHERE (@UniqKey = NULL OR @UniqKey= '' OR IML.uniq_key = @UniqKey)      
           AND (@MfgrMasterhd = NULL OR @MfgrMasterhd = '' OR IM.Uniqmfgrhd = @MfgrMasterhd)      
     AND (@UniqWH = NULL OR @UniqWH = '' OR IM.UNIQWH = @UniqWH) -- 06/20/2017 Rajendra K : Added Input parameter @UniqWH to get records from same WorkCener On date      
     AND (@Location = NULL OR IM.LOCATION = @Location) -- 06/20/2017 Rajendra K : Added parameter @Location to get records from same Location      
     AND (@KaSeqNumber = NULL OR @KaSeqNumber ='' OR K.KaSeqNum = @KaSeqNumber) -- 06/20/2017 Rajendra K Added parameter @KaSeqNumber to get records from same KaSeqNumber      
     AND IP.pkgBalance<> 0  -- 08/02/2017 Rajendra K : Check and Exclude records with zero quantity added      
     AND (COALESCE(IP.pkgBalance,0)-COALESCE(IP.qtyAllocatedTotal,0)) + COALESCE(IR.Allocated,0) <>0 -- 08/02/2017 Rajendra K : Check and get where quantity available for Reserve/UnReserve      
     -- 09/13/2017 Rajendra K : Apply WO Reservation default settings      
         -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.      
       --AND (@MfgrDefault = 'All MFGRS' OR       
   AND (NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A -- 04/18/2019 Rajendra K : Replaced K.UNIQ_KEY by "@CosignUniqKey"      
        WHERE A.BOMPARENT = K.BOMParent AND A.UNIQ_KEY = @CosignUniqKey AND A.PARTMFGR = MM.PARTMFGR and A.MFGR_PT_NO = MM.MFGR_PT_NO)) --)  
           -- 11/06/2019 Rajendra K : Replaced @BomParent by K.BOMParent  
   ORDER BY PartMfgr,MfgrPtNo --12/07/2017 Rajendra K : Added order by Clause      
    SET @qryMain ='select * from #TempDataEl'  +' ORDER BY ' + @SortExpression +';'      
   EXEC sp_executesql @qryMain   -- 01/23/2017 Rajendra K : for sorting on @sortExpression      
 END      
END 