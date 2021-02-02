-- =============================================  
-- Author:  Satish B  
-- Create date: 2/19/2018  
-- Description: Get part details against scanned serial number 
--   : 07/16/2020 Rajendra K : Added join customer table and CustName,CustNo,CustpartRev in selection list
-- exec GetPartNumberDetailsBySerialNo '000000000000000001007591255102'       
-- =============================================  
CREATE PROCEDURE [dbo].[GetPartNumberDetailsBySerialNo]   
 -- Add the parameters for the stored procedure here  
 @serialNo char(30) =''  
AS  
BEGIN  
  SELECT DISTINCT   
    i.Uniq_Key AS UniqKey  
   ,imfgr.W_KEY AS WKey  
   ,ISNULL(lot.UNIQ_LOT,'') AS UniqLot  
   ,lot.LotCode  
   ,lot.ExpDate  
   ,lot.Reference  
   ,ip.IpKeyUnique  
   ,ser.SerialUniq  
   ,ser.SerialNo  
   ,SUM(imfgr.qty_oh) AS Available  
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
  ,i.PART_SOURC  --   : 07/16/2020 Rajendra K : Added join customer table and CustName,CustNo,CustpartRev in selection list 
  FROM INVENTOR i  
   INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY  
   INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId  
   INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY and mpn.uniqmfgrhd = imfgr.UNIQMFGRHD  
   INNER JOIN WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH     
   INNER JOIN INVTSER ser on ser.UNIQ_KEY = i.UNIQ_KEY and ser.ID_VALUE =imfgr.W_KEY  
   LEFT OUTER JOIN IPKEY ip ON ip.W_KEY =imfgr.W_KEY and imfgr.UNIQ_KEY = i.UNIQ_KEY and ip.IPKEYUNIQUE =ser.ipkeyunique and ip.pkgBalance > 0  
   LEFT OUTER JOIN INVTLOT lot ON lot.W_KEY =imfgr.W_KEY and lot.EXPDATE = ser.EXPDATE and lot.LOTCODE = ser.LOTCODE and lot.REFERENCE = ser.REFERENCE 
   LEFT join CUSTOMER C ON i.CUSTNO = c.CUSTNO --   : 07/16/2020 Rajendra K : Added join customer table and CustName,CustNo,CustpartRev in selection list
  WHERE   
   ser.SERIALNO = @serialNo   
   AND w.WAREHOUSE <> 'WIP'   
   AND w.WAREHOUSE <> 'WO-WIP'   
   AND w.Warehouse <> 'MRB   '  
   AND imfgr.IS_DELETED = 0   
   AND imfgr.Netable = 1  
   AND imfgr.INSTORE = 0  
   --AND ip.pkgBalance > 0  
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
    ,imfgr.W_KEY  
    ,lot.UNIQ_LOT  
    ,lot.LotCode  
    ,lot.ExpDate  
    ,lot.Reference  
    ,ip.IpKeyUnique  
    ,ser.SerialUniq  
    ,ser.SerialNo 
    ,c.CustName
    ,c.CUSTNO 
    ,i.CUSTPARTNO
    ,i.CUSTREV  --   : 07/16/2020 Rajendra K : Added join customer table and CustName,CustNo,CustpartRev in selection list
    ,i.PART_SOURC 
    HAVING SUM(imfgr.QTY_OH) > 0  
END