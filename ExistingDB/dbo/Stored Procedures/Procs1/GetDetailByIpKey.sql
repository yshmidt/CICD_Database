
-- =============================================    
-- Author:  Satish B    
-- Create date: 09/27/2016    
-- Description: this procedure will be used to get part detail by ipkey    
-- Modified : 02/20/2018 Satish B : Added the selection of part details :START    
--   : 02/20/2018 Satish B : Added the join of Inventor,InvtMPNLink,INVTMFGR,MfgrMaster table    
--   : 02/20/2018 Satish B : Added gropu by clause    
--   : 02/20/2018 Satish B :Check null for uniq_lot    
--   : 02/28/2018 Satish B : Added filter of (ip.pkgBalance  - ip.qtyAllocatedTotal)> 0    
--   : 04/03/2018 Satish B : Add filter of INSTORE : Check INSTORE=0    
--   : 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials  
--   : 02/26/2020 Rajendra K : Changed the AvailableQty calculation from QTY_OH to (imfgr.QTY_OH - imfgr.Reserved)  
--   : 07/15/2020 Rajendra K : Added join customer table and CustName,CustNo,CustpartRev in selection list
-- [dbo].[GetDetailByIpKey] 'OBGB6A3KW5'    
-- =============================================    
CREATE PROCEDURE [dbo].[GetDetailByIpKey]     
 -- Add the parameters for the stored procedure here    
 @ipKey char(10) =''    
AS    
BEGIN    
    
-- SET NOCOUNT ON added to prevent extra result sets from    
-- interfering with SELECT statements.    
SET NOCOUNT ON;    
 SELECT DISTINCT    
         ip.UNIQ_KEY    
  ,ip.W_KEY     
  --02/20/2018 Satish B :Check null for uniq_lot    
  ,ISNULL(lot.UNIQ_LOT,'') AS UNIQ_LOT    
  ,lot.LOTCODE    
  ,lot.EXPDATE    
  ,lot.REFERENCE    
  ,ip.IPKEYUNIQUE    
  ,ip.PONUM    
  --02/20/2018 Satish B : Added the selection of part details :START    
  ,SUM(imfgr.QTY_OH-imfgr.Reserved) AS Available  --   : 02/26/2020 Rajendra K : Changed the AvailableQty calculation from QTY_OH to (imfgr.QTY_OH - imfgr.Reserved)  
  ,RTRIM(i.PART_NO) + CASE WHEN i.REVISION IS NULL OR i.REVISION='' THEN '' ELSE '/' END + i.REVISION AS PartRev    
  ,RTRIM(i.PART_CLASS) + CASE WHEN i.PART_CLASS IS NULL OR i.PART_CLASS='' THEN '' ELSE '/' END +     
          RTRIM(i.PART_TYPE) + CASE WHEN i.PART_TYPE IS NULL OR i.PART_TYPE='' THEN '' ELSE '/' END +i.DESCRIPT AS Descript    
  ,i.U_Of_Meas AS SUom    
  ,i.UseIpKey     
  ,i.SerialYes    
  ,i.StdCost 
  ,c.CustName
  ,c.CUSTNO --   : 07/15/2020 Rajendra K : Added join customer table and CustName,CustNo,CustpartRev in selection list
  ,RTRIM(LTRIM(i.CUSTPARTNO)) + CASE WHEN i.CUSTREV IS NULL OR i.CUSTREV='' THEN '' ELSE '/' END + i.CUSTREV AS CustPartRev  
  ,i.PART_SOURC 
  --02/20/2018 Satish B : Added the selection of part details :END    
 FROM IPKEY ip    
  --02/20/2018 Satish B : Added the join of Inventor,InvtMPNLink,INVTMFGR,MfgrMaster table    
  INNER JOIN INVENTOR i on i.UNIQ_KEY=ip.UNIQ_KEY    
  INNER JOIN InvtMPNLink mpn ON mpn.UNIQ_KEY = i.UNIQ_KEY    
  INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY and mpn.uniqmfgrhd = imfgr.UNIQMFGRHD    
  INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
  LEFT OUTER JOIN INVTLOT lot ON lot.W_KEY =ip.W_KEY and ISNULL(lot.EXPDATE,1) = ISNULL(ip.EXPDATE,1) AND lot.LOTCODE = ip.LOTCODE AND lot.REFERENCE = ip.REFERENCE AND lot.PONUM = ip.PONUM    
  LEFT JOIN customer c ON c.custno = i.custno--   : 07/15/2020 Rajendra K : Added join customer table and CustName,CustNo,CustpartRev in selection list
 WHERE     
 ip.IPKEYUNIQUE = @ipKey    
 --02/28/2018 Satish B : Added filter of (ip.pkgBalance  - ip.qtyAllocatedTotal)> 0    
 AND (ip.pkgBalance  - ip.qtyAllocatedTotal)> 0     
 --04/03/2018 Satish B : Add filter of INSTORE : Check INSTORE=0    
 --AND imfgr.INSTORE= 0   --   : 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials  
 --02/20/2018 Satish B : Added gropu by clause    
 GROUP BY ip.UNIQ_KEY    
  ,i.PART_NO    
  ,i.REVISION     
  ,i.PART_CLASS    
  ,i.PART_TYPE    
  ,i.U_Of_Meas    
  ,i.DESCRIPT    
  ,i.UseIpKey     
  ,i.SerialYes    
  ,i.StdCost     
  ,ip.W_KEY    
  ,lot.UNIQ_LOT    
  ,lot.LotCode    
  ,lot.ExpDate    
  ,lot.Reference    
  ,ip.IpKeyUnique    
  ,ip.PONUM 
  ,c.CustName
  ,c.CUSTNO 
  ,i.CUSTPARTNO--   : 07/15/2020 Rajendra K : Added join customer table and CustName,CustNo,CustpartRev in selection list
  ,i.CUSTREV  
  ,i.PART_SOURC 
  --   : 02/26/2020 Rajendra K : Changed the AvailableQty calculation from QTY_OH to (imfgr.QTY_OH - imfgr.Reserved)  
  HAVING SUM(imfgr.QTY_OH-imfgr.Reserved) > 0   
END