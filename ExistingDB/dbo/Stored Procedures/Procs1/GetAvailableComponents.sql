-- =============================================        
-- Author:  Rajendra K         
-- Create date: <01/15/2018>        
-- Description: Get avaialbe Components        
-- [dbo].[GetAvailableComponents] '','00VE7GBEKX'        
-- Modification         
   -- 01/29/2018 Rajendra K : Added MM.AutoLocation and WH.AUTOLOCATION  in select query        
   -- 02/01/2018 Rajendra K : Change logic to get avaialable Qty        
   -- 02/06/2018 Rajendra K : Added new column WahrehouseLocation        
   -- 02/06/2018 Rajendra K : Added new parameter @uniqKey and Used it in where condition        
   -- 02/08/2018 Rajendra K : Added 2 columns Part_No and Description in select list        
   -- 02/12/2018 Rajendra K : Added new column UniqKey,SerialYes & UseIpKey in select list        
   -- 02/21/2018 Rajendra K : Added UniqLot in select list        
   -- 02/23/2018 Rajendra K : Added parameters @uniqMfgrHd,@uniqLot,@sid,@startRecord & @endRecord         
   -- 02/27/2018 Rajendra K : Changed datatype and size of input parameter @location        
   -- 03/01/2018 Rajendra K : Added parameter @isWHMap and used in where section for location comparision         
   -- 03/05/2018 Rajendra K : Changed order by condition        
   -- 03/06/2018 Rajendra K : Added new columns for IPKEYUnique,I.PART_NO,I.Revision,I.Part_Class,I.Part_Type  in select list Warehouse Map        
   -- 04/03/2018 Rajendra K : Removed unused variable @mfgrDefault         
   -- 03/12/2019  Rajendra K : Changed Column As Uniq_key        
   -- 03/13/2019  Rajendra K : Added Parameter @filter And @sortExpression        
   -- 03/13/2019  Rajendra K : Added Temp Table        
   -- 03/13/2019  Rajendra K : Remove ORDER BY          
   -- 03/13/2019  Rajendra K : Added Dynamic Query         
   -- 03/13/2019  Rajendra K : Added new column Ponum        
   -- 03/13/2019 Rajendra K : Added Condition For Location        
   -- 04/11/2019 Rajendra K : Added new column "Netable"        
   -- 04/11/2019 Rajendra K : Removed the setting         
   -- 04/11/2019 Rajendra K : Removed Netable condition        
   -- 05/15/2019 Rajendra K : Added case when ExpDate is null        
   -- 05/17/2019 Rajendra K :  Get the row count after the filter and removed the filter from query and used fn_GetDataBySortAndFilters function to get rows        
   -- 05/17/2019 Rajendra K : Added column "IsChecked" in select list        
   -- 05/20/2019 Rajendra K : Added two column "CustPartNo" and "CUSTNO" in select list        
   -- 05/20/2019 Rajendra K : Added two parameter @partNo and @rev        
   -- 05/20/2019 Rajendra K : Added two condition for @partNo and @rev        
   -- 06/11/2019 Rajendra K : Removed parameter @rev        
   -- 08/06/2019 Rajendra K : Changed location datatype from VARCHAR to NVARCHAR        
   -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition         
   -- 06/18/2020 Rajendra K : Added the @instore parameter and condition    
   -- 07/17/2020 Rajendra K : Added instore in selection list  
   -- 12/09/2020 Rajendra K : Added Transfer in selection list 
   -- GetAvailableComponents '','2','','',1,'','','',0,'','',1,100        
-- =============================================           
CREATE PROCEDURE GetAvailableComponents
(        
@uniqKey AS CHAR(10), -- 05/20/2019 Rajendra K : Added two parameter @partNo and @rev        
@partNo NVARCHAR(50),        
--@rev NVARCHAR(8),    -- 06/11/2019 Rajendra K : Removed parameter @rev        
@uniqWH AS CHAR(10)='', -- 02/06/2018 Rajendra K : Added new parameter @uniqKey and Used it in where condition        
@location AS NVARCHAR(100) = '', -- 02/27/2018 Rajendra K : Changed datatype and size        
@isLocation BIT, -- 08/06/2019 Rajendra K : Changed location datatype from VARCHAR to NVARCHAR        
@uniqMfgrHd CHAR(10), -- 02/23/2018 Rajendra K : Added parameter @uniqMfgrHd and used in where clause        
@uniqLot CHAR(10),        
@sid CHAR(10),        
@isWHMap BIT=0, -- 03/01/2018 Rajendra K : Added parameter @isWHMap and used in where section for location comparision         
@filter NVARCHAR(1000) = null,        
@sortExpression NVARCHAR(1000) = null ,   -- 03/13/2019  Rajendra K : Added Parameter @filter And @sortExpression        
@startRecord int =1,        
@endRecord int =10,      
@instore bit = 0-- 06/18/2020 Rajendra K : Added the @instore parameter and condition      
)        
AS         
BEGIN        
 SET NOCOUNT ON;         
         
 -- Declare variables        
    --DECLARE @mfgrDefault NVARCHAR(MAX) -- 04/03/2018 Rajendra K : Removed unused variable @mfgrDefault         
 DECLARE @nonNettable BIT,@sqlQuery NVARCHAR(MAX),@rowCount NVARCHAR(MAX)-- 03/12/2019  Rajendra K : Added @sqlQuery Variable        
        
 IF OBJECT_ID(N'tempdb..#TEMP') IS NOT NULL        
     DROP TABLE #TEMP ;  -- 03/13/2019  Rajendra K : Added Temp Table        
 IF OBJECT_ID(N'tempdb..#tempDate') IS NOT NULL        
     DROP TABLE #tempDate ;  -- 03/13/2019  Rajendra K : Added Temp Table        
        
 --  04/11/2019 Rajendra K : Removed the setting         
 -- Get Manufacturer default settings logic        
 --SELECT SettingName        
 --    ,LTRIM(WM.SettingValue) SettingValue        
 --INTO  #tempMfgrSettings        
 --FROM MnxSettingsManagement MS INNER JOIN WmSettingsManagement WM ON MS.settingId = WM.settingId          
 --WHERE SettingName IN('manufacturersDefault','allowUseOfNonNettableWarehouseLocation')         
        
 --   --Assign values to variables to hold values for Manufacturer  default settings        
 ----SET @mfgrDefault = ISNULL((SELECT SettingValue FROM #tempMfgrSettings WHERE SettingName = 'manufacturersDefault'),'All MFGRS') -- 04/03/2018 Rajendra K : Removed unused variable @mfgrDefault         
 --SET @nonNettable= ISNULL((SELECT CONVERT(BIT, SettingValue) FROM #tempMfgrSettings WHERE SettingName = 'allowUseOfNonNettableWarehouseLocation'),0)         
        
 -- 02/08/2018 Rajendra K : Added 2 columns Part_No and Description in select list        
 SELECT DISTINCT RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) AS PART_NO        
       ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE RTRIM(I.PART_CLASS) +' / ' END ) +         
     (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN I.PART_TYPE ELSE RTRIM(I.PART_TYPE) + ' / '+RTRIM(I.DESCRIPT) END) AS Descript          
       ,MM.PARTMFGR AS PartMfgr        
       ,MM.MFGR_PT_NO AS MfgrPtNo        
       ,WH.Warehouse         
       ,IM.Location        
       ,IP.IPKEYUNIQUE AS SID        
       ,IM.UniqWH         
       ,IM.W_KEY AS WKey        
       ,IL.UNIQ_LOT AS UniqLot -- 02/21/2018 Rajendra K : Added UniqLot        
       ,IL.LotCode        
       ,IL.ExpDate        
       ,IL.Reference        
       ,dbo.fRemoveLeadingZeros(IP.PONUM) AS Ponum  -- 03/13/2019  Rajendra K : Added new column  Ponum        
       ,COALESCE(IP.PkgBalance,IL.LotQty,IM.QTY_OH)-COALESCE(IP.qtyAllocatedTotal,IL.LotResQty,IM.Reserved) AS QtyOh  --02/01/2018 Rajendra K : Change logic to get avaialable Qty        
       ,ROW_NUMBER() OVER(ORDER BY MM.PARTMFGR ASC) AS RowNumber         
       ,IM.UniqMfgrhd          
       -- 01/29/2018 Rajendra K : Added MM.AutoLocation and WH.AUTOLOCATION  in select query        
       ,MM.AutoLocation AS MfgrAutoLocation        
       ,WH.AUTOLOCATION AS WHAutoLocation        
       -- 02/06/2018 Rajendra K : Added new column WahrehouseLocation        
       ,RTRIM(wh.Warehouse)+ (CASE WHEN IM.Location IS NULL OR IM.Location =''  THEN RTRIM(IM.Location) ELSE ' / '+RTRIM(IM.Location) END) AS WarehouseLocation        
       -- 02/12/2018 Rajendra K : Added new column UniqKey,SerialYes & UseIpKey in select list        
       ,I.UNIQ_KEY AS Uniq_key -- 03/12/2019  Rajendra K : Changed Column As Uniq_key        
       ,I.SERIALYES AS SerialYes        
       ,I.useipkey AS UseIpKey        
       -- 03/06/2018 Rajendra K : Added new columns for Warehouse Map        
       ,IP.IPKEYUNIQUE AS IPKEYUnique        
       ,I.PART_NO AS PartNo        
       ,I.Revision AS Revision        
       ,I.Part_Class AS PartClass        
       ,I.Part_Type AS PartType        
       ,IM.NETABLE AS Netable -- 04/11/2019 Rajendra K : Added new column "Netable"        
       ,0 AS IsChecked  -- 05/17/2019 Rajendra K : Added column "IsChecked" in select list        
       ,COALESCE(IP.qtyAllocatedTotal,IL.LotResQty,IM.Reserved) AS Reserved  -- 05/20/2019 Rajendra K : Added two column "CustPartNo" and "CUSTNO" in select list        
       ,RTRIM(I.CUSTPARTNO) + (CASE WHEN I.CUSTREV IS NULL OR I.CUSTREV = '' THEN I.CUSTREV ELSE '/'+ I.CUSTREV END) AS CustPartNo        
       ,I.CUSTNO   
    ,IM.INSTORE -- 07/17/2020 Rajendra K : Added instore in selection list      
	   ,0 AS Transfer  -- 12/09/2020 Rajendra K : Added Transfer in selection list   
 INTO #TEMP  -- 03/13/2019  Rajendra K : Added Temp Table        
 FROM INVENTOR I   INNER JOIN INVTMFGR IM ON I.UNIQ_KEY = IM.UNIQ_KEY -- AND (@nonNettable = 1 OR IM.NETABLE = 1)  -- 04/11/2019 Rajendra K : Removed Netable condition        
  AND ((@instore = 1 AND 1=1) OR (@instore= 0 AND IM.InStore = 0))-- 06/18/2020 Rajendra K : Added the @instore parameter and condition      
  AND IM.IS_DELETED = 0 AND im.SFBL = 0 -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition         
       INNER JOIN InvtMpnLink IML ON IM.UNIQMFGRHD = IML.uniqmfgrhd        
       INNER JOIN MfgrMaster MM ON IML.MfgrMasterId = MM.MfgrMasterId        
       INNER JOIN WAREHOUS WH ON IM.UNIQWH = WH.UNIQWH        
       LEFT JOIN INVTLOT IL ON IM.W_KEY = IL.W_KEY        
       LEFT JOIN IPKEY IP ON I.UNIQ_KEY = IP.UNIQ_KEY         
           AND IM.W_KEY = IP.W_KEY        
           AND COALESCE(IL.LOTCODE,IP.LOTCODE)= IP.LOTCODE        
           AND ISNULL(IL.REFERENCE,IP.REFERENCE)= IP.REFERENCE        
           AND ISNULL(IL.PONUM,IP.PONUM)= IP.PONUM        
           AND 1 =(CASE WHEN IL.LOTCODE IS NULL OR IL.LOTCODE= '' THEN 1         
               WHEN IL.EXPDATE IS NULL OR IL.EXPDATE= '' AND IP.EXPDATE IS NULL OR IP.EXPDATE = '' THEN 1 -- 05/15/2019 Rajendra K : Added case when ExpDate is null        
               WHEN IL.EXPDATE = IP.EXPDATE THEN 1 ELSE 0 END)        
 WHERE WH.WAREHOUSE NOT IN('WO-WIP','WIP') AND (@uniqKey IS NULL OR @uniqKey ='' OR I.UNIQ_KEY = @uniqKey)         
     AND (@partNo IS NULL OR @partNo ='' OR I.PART_NO LIKE '%'+@partNo+'%')  -- 05/20/2019 Rajendra K : Added two condition for @partNo and @rev        
     --AND (@rev IS NULL OR @rev ='' OR I.REVISION LIKE '%'+@rev+'%')         
     AND COALESCE(IP.PkgBalance,IL.LotQty,IM.QTY_OH)-COALESCE(IP.qtyAllocatedTotal,IL.LotResQty,IM.Reserved) > 0 -- 02/01/2018 Rajendra K : Change logic to get avaialable Qty                  
     AND (@uniqWH IS NULL OR @uniqWH= '' OR IM.UNIQWH = @uniqWH) -- 02/06/2018 Rajendra K : Added condition         
     AND ((@isLocation = 0) OR((@isWHMap=1 AND IM.LOCATION LIKE '%'+@location+'%') OR  (@isWHMap=0 AND IM.LOCATION = @location))) -- 03/01/2018 Rajendra K : Change logic for location comparision        
     AND IM.LOCATION NOT IN(SELECT inspHeaderId FROM inspectionHeader)  -- 03/13/2019 Rajendra K : Added Condition For Location        
     -- 02/23/2018 Rajendra K : Added parameters in @uniqMfgrHd,@uniqLot and @sid where clause        
     AND (@uniqMfgrHd IS NULL OR @uniqMfgrHd = '' OR IM.UNIQMFGRHD = @uniqMfgrHd)         
     AND (@uniqLot IS NULL OR @uniqLot ='' OR IL.UNIQ_LOT = @uniqLot)        
     AND (@sid IS NULL OR @sid ='' OR IP.IPKEYUNIQUE = @sid)        
 --ORDER BY  -- 03/13/2019  Rajendra K : Remove ORDER BY         
     -- MM.PARTMFGR        
     --,MM.MFGR_PT_NO        
  -- 03/05/2018 Rajendra K : Changed order by condition        
  -- 03/13/2019 Rajendra K : Remove order by condition        
     -- WH.Warehouse         
     --,IM.Location           
     --,MM.PARTMFGR        
     --,MM.MFGR_PT_NO          
  --OFFSET @startRecord -1 ROWS FETCH NEXT @endRecord ROWS ONLY;        
        
  -- 03/13/2019  Rajendra K : Added Dynamic Query         
  -- 05/17/2019 Rajendra K :  Get the row count after the filter and removed the filter from query and used fn_GetDataBySortAndFilters function to get rows        
  SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #TEMP',@filter,@sortExpression,'','Warehouse',@startRecord,@endRecord))               
        EXEC sp_executesql @rowCount            
        
  SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #TEMP',@filter,@sortExpression,N'Warehouse,Location,PartMfgr,MfgrPtNo','',@startRecord,@endRecord))          
     EXEC sp_executesql @sqlQuery        
   --Drop temp table        
  --DROP TABLE #tempMfgrSettings        
END 