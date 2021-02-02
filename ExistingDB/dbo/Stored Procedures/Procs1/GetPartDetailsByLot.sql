-- =============================================    
-- Author:  Satish B    
-- Create date: 2/19/2018    
-- Description: Get part details using lot code    
--   : 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials  
--   : 02/26/2020 Rajendra K : Removed @lotCode condition and added "lotUniqKey" join to to get correct available Qty.  
--   : 07/15/2020 Rajendra K : Added join customer table and CustName,CustNo,CustpartRev in selection list
--   : 07/16/2020 Rajendra K : Changes available Qty calculation
-- exec GetPartDetailsByLot '1454154'      
-- =============================================    
CREATE PROCEDURE [dbo].[GetPartDetailsByLot]     
 -- Add the parameters for the stored procedure here    
 @lotCode char(35) =''    
AS    
BEGIN     
  SELECT DISTINCT     
    i.Uniq_Key AS UniqKey    
   --,SUM(imfgr.qty_oh-imfgr.Reserved) AS Available 
   ,SUM(lot.LOTQTY-lot.LOTRESQTY) AS Available  --   : 07/16/2020 Rajendra K : Changes available Qty calculation   
   ,RTRIM(i.PART_NO) + CASE WHEN i.REVISION IS NULL OR i.REVISION='' THEN '' ELSE '/' END + i.REVISION AS PartRev    
   ,RTRIM(i.PART_CLASS) + CASE WHEN i.PART_CLASS IS NULL OR i.PART_CLASS='' THEN '' ELSE '/' END +     
           RTRIM(i.PART_TYPE) + CASE WHEN i.PART_TYPE IS NULL OR i.PART_TYPE='' THEN '' ELSE '/' END +i.DESCRIPT AS Descript    
   ,i.U_Of_Meas AS SUom    
   ,i.UseIpKey     
   ,i.SerialYes    
   ,i.StdCost 
   ,c.CustName
   ,c.CUSTNO 
   ,RTRIM(LTRIM(i.CUSTPARTNO)) + CASE WHEN i.CUSTREV IS NULL OR i.CUSTREV='' THEN '' ELSE '/' END + i.CUSTREV AS CustPartRev   
   ,i.PART_SOURC --   : 07/15/2020 Rajendra K : Added join customer table and CustName,CustNo,CustpartRev in selection list
  FROM INVTLOT lot     
   INNER JOIN INVTMFGR imfgr ON imfgr.W_KEY =lot.W_KEY    
   INNER JOIN INVENTOR i ON i.UNIQ_KEY =imfgr.UNIQ_KEY     
   INNER JOIN WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH     
   INNER JOIN--   : 02/26/2020 Rajendra K : Removed @lotCode condition and added "lotUniqKey" join to to get correct available Qty.  
   (  
  SELECT TOP 1 i.UNIQ_KEY   
  FROM inventor i   
  JOIN INVTMFGR m ON i.UNIQ_KEY = m.UNIQ_KEY   
  JOIN INVTLOT l ON m.W_KEY = l.W_KEY AND l.LotCode = @lotCode 
   ) lotUniqKey ON i.UNIQ_KEY = lotUniqKey.UNIQ_KEY 
   LEFT JOIN customer c ON c.custno = i.custno --   : 07/15/2020 Rajendra K : Added join customer table and CustName,CustNo,CustpartRev in selection list
  WHERE     
   --lot.LotCode = @lotCode  AND --   : 02/26/2020 Rajendra K : Removed @lotCode condition and added "lotUniqKey" join to to get correct available Qty.  
   w.WAREHOUSE <> 'WIP'     
   AND w.WAREHOUSE <> 'WO-WIP'     
   AND w.Warehouse <> 'MRB'    
   AND imfgr.IS_DELETED = 0     
   AND imfgr.Netable = 1    
   --AND imfgr.INSTORE = 0  --   : 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials  
   AND lot.LotQty>0 
   AND i.status='active' 
 GROUP BY i.UNIQ_KEY    
    ,i.PART_NO    
    ,i.REVISION     
    ,i.PART_CLASS    
    ,i.PART_TYPE    
    ,i.U_Of_Meas    
    ,i.DESCRIPT    
    ,i.UseIpKey     
    ,i.SerialYes    
    ,i.StdCost 
	,c.CustName
	,c.CUSTNO 
	,i.CUSTPARTNO
	,i.CUSTREV --   : 07/15/2020 Rajendra K : Added join customer table and CustName,CustNo,CustpartRev in selection list
	,i.PART_SOURC     
    HAVING SUM(lot.LOTQTY-lot.LOTRESQTY) > 0 --   : 07/16/2020 Rajendra K : Changes available Qty calculation      
END