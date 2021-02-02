-- =============================================  
-- Author:  Rajendra k  
-- Create date: 03/08/2019  
-- Description: To Get Lot Details by LotCode    
-- 03/13/2019 Rajendra K : Added Condition For Location  
-- 04/02/2019 Rajendra K : Added Condition to remove leading zero of @lotcode    
-- 05/17/2019 Rajendra K :  Get the row count after the filter and removed the filter from query and used fn_GetDataBySortAndFilters function to get rows  
-- 05/17/2019 Rajendra K : Added column "IsChecked" in select list  
-- 05/20/2019 Rajendra K : Added two column "CustPartNo" and "CUSTNO" in select list  
-- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition    
-- 12/09/2020 Rajendra K : Added Transfer in selection list 
-- Exec GetLotDetailsByLotCode '8335-6185A.03','',''  
-- =============================================  
CREATE PROCEDURE GetLotDetailsByLotCode 
(  
@lotcode AS NVARCHAR(50),  
@uniqWH NVARCHAR(50),  
@Location NVARCHAR(100) = null,  
@filter NVARCHAR(1000) = null,  
@sortExpression NVARCHAR(1000) = null ,  
@startRecord INT = 1,  
@endRecord INT = 150  
)  
AS   
BEGIN  
 SET NOCOUNT ON;  
  
  DECLARE @sqlQuery NVARCHAR(MAX),@rowCount NVARCHAR(MAX);  
  SET @sortExpression = CASE   
                           WHEN @sortExpression IS NULL OR @sortExpression = '' THEN 'WarehouseLocation,PartMfgr,MfgrPtNo'   
         ELSE @sortExpression   
         END   
  
IF OBJECT_ID(N'tempdb..#TEMP') IS NOT NULL  
     DROP TABLE #TEMP ;  
  
 SELECT DISTINCT   
   I.UNIQ_KEY AS Uniq_key  
   ,RTRIM(I.PART_NO )+ (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) AS PART_NO   
  ,REVISION  
  ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE RTRIM(I.PART_CLASS) +' / ' END ) +   
  (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN I.PART_TYPE ELSE RTRIM(I.PART_TYPE) + ' / '+RTRIM(I.DESCRIPT) END) AS Descript  
  ,PartMfgr AS PartMfgr  
  ,mfgr_pt_no AS MfgrPtNo  
  ,I.PART_NO AS PartNo  
  ,LOCATION  
  ,WH.UNIQWH  
  ,IM.W_KEY AS WKey  
  ,UNIQ_LOT AS UniqLot  
  ,IL.LOTCODE AS LotCode  
  ,IL.EXPDATE AS ExpDate  
  ,IL.REFERENCE AS Reference  
  ,dbo.fRemoveLeadingZeros(IL.PONUM) AS Ponum  
  ,COALESCE(IP.PkgBalance,IL.LotQty,IM.QTY_OH)-COALESCE(IP.qtyAllocatedTotal,IL.LotResQty,IM.Reserved) AS QtyOh   
  ,COALESCE(IP.qtyAllocatedTotal,IL.LotResQty,IM.Reserved) AS Reserved  
  ,RTRIM(wh.Warehouse)+ (CASE WHEN Location IS NULL OR IM.Location =''  THEN RTRIM(IM.Location) ELSE ' / '+RTRIM(IM.Location) END) AS WarehouseLocation   
  ,M.AutoLocation AS MfgrAutoLocation  
  ,WH.AUTOLOCATION AS WHAutoLocation   
  ,I.SERIALYES AS SerialYes  
  ,I.useipkey AS UseIpKey  
  ,IP.IPKEYUNIQUE AS SID  
  ,IP.IPKEYUNIQUE AS IPKEYUnique  
  ,IM.UniqMfgrhd   
  ,ROW_NUMBER() OVER(ORDER BY M.partmfgr ASC) AS RowNumber   
  ,IM.NETABLE AS Netable  
  ,0 AS IsChecked  -- 05/17/2019 Rajendra K : Added column "IsChecked" in select list  
  ,RTRIM(I.CUSTPARTNO) + (CASE WHEN I.CUSTREV IS NULL OR I.CUSTREV = '' THEN I.CUSTREV ELSE '/'+ I.CUSTREV END) AS CustPartNo  
  ,I.CUSTNO -- 05/20/2019 Rajendra K : Added two column "CustPartNo" and "CUSTNO" in select list  
    ,0 AS Transfer -- 12/09/2020 Rajendra K : Added Transfer in selection list 
 INTO #TEMP  
 FROM INVTLOT IL-- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition    
  JOIN INVTMFGR IM ON IM.W_KEY=IL.W_KEY  AND IM.is_deleted=0 AND IM.SFBL = 0  
     JOIN inventor I ON I.UNIQ_KEY=IM.UNIQ_KEY  
     JOIN InvtMPNLink L ON l.uniq_key=I.UNIQ_KEY AND L.is_deleted=0 AND IM.UNIQ_KEY=L.uniq_key AND L.uniqmfgrhd = IM.UNIQMFGRHD  
     JOIN MfgrMaster M on M.MfgrMasterId=L.MfgrMasterId  
     JOIN WAREHOUS WH on IM.UNIQWH = WH.UNIQWH AND (@uniqWH IS NULL OR @uniqWH= '' OR IM.UNIQWH = @uniqWH)  
  LEFT JOIN IPKEY IP ON I.UNIQ_KEY = IP.UNIQ_KEY   
      AND IM.W_KEY = IP.W_KEY  
   AND COALESCE(IL.LOTCODE,IP.LOTCODE)= IP.LOTCODE  
   AND ISNULL(IL.REFERENCE,IP.REFERENCE)= IP.REFERENCE  
   AND ISNULL(IL.PONUM,IP.PONUM)= IP.PONUM   
   AND 1 =(CASE WHEN IL.EXPDATE IS NULL OR IL.EXPDATE= '' AND IP.EXPDATE IS NULL OR IP.EXPDATE = '' THEN 1   
                WHEN IL.LOTCODE IS NULL OR IL.LOTCODE= '' THEN 1   
       WHEN IL.EXPDATE = IP.EXPDATE THEN 1 ELSE 0 END)   
   -- 04/02/2019 Rajendra K : Added Condition to remove leading zero of @lotcode    
  WHERE --dbo.fRemoveLeadingZeros(IL.LOTCODE) = dbo.fRemoveLeadingZeros(@lotcode)   
   (IL.LOTCODE LIKE '%'+@lotcode+'%')  
   AND (IM.LOCATION LIKE '%'+@Location+'%')  AND IM.LOCATION NOT IN(SELECT inspHeaderId FROM inspectionHeader)  -- 03/13/2019 Rajendra K : Added Condition For Location  
   AND COALESCE(IP.PkgBalance,IL.LotQty,IM.QTY_OH)-COALESCE(IP.qtyAllocatedTotal,IL.LotResQty,IM.Reserved) > 0  
  
  -- 05/17/2019 Rajendra K :  Get the row count after the filter and removed the filter from query and used fn_GetDataBySortAndFilters function to get rows  
  SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #TEMP',@filter,@sortExpression,'','WarehouseLocation',@startRecord,@endRecord))         
        EXEC sp_executesql @rowCount    
  
  SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #TEMP',@filter,@sortExpression,N'WarehouseLocation,PartMfgr,MfgrPtNo','',@startRecord,@endRecord))    
     EXEC sp_executesql @sqlQuery  
END  
    
  
    