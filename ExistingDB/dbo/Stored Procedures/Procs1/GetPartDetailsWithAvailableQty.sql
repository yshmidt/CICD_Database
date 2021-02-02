-- =============================================  
-- Author:Satish B  
-- Create date: 02/12/2018  
-- Description : Get the part details with its available quantity  
-- Modified : 05/10/2018 : Satish B : Removed extra trailing space from PartRev  
--   : 07/20/2018 : Satish B : Remove space from PART_NO  
-- Nitesh B : 12/11/2018 Added sort order  
-- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials
-- exec GetPartDetailsWithAvailableQty  
-- =============================================  
CREATE PROCEDURE GetPartDetailsWithAvailableQty    
 AS  
 BEGIN  
  SET NOCOUNT ON    
  SELECT SUM(m.qty_oh-m.Reserved) AS Available  
   --05/10/2018 : Satish B : Removed extra trailing space from PartRev  
   --07/20/2018 : Satish B : Remove space from PART_NO  
   ,RTRIM(LTRIM(i.PART_NO)) + CASE WHEN i.REVISION IS NULL OR i.REVISION='' THEN '' ELSE '/' END + i.REVISION AS PartRev  
   ,RTRIM(i.PART_CLASS) + CASE WHEN i.PART_CLASS IS NULL OR i.PART_CLASS='' THEN '' ELSE '/' END +   
        RTRIM(i.PART_TYPE) + CASE WHEN i.PART_TYPE IS NULL OR i.PART_TYPE='' THEN '' ELSE '/' END +i.DESCRIPT AS Descript  
   ,i.U_Of_Meas AS SUom  
   ,i.Uniq_Key AS UniqKey  
   ,i.UseIpKey   
   ,i.SerialYes  
   ,i.StdCost   
  FROM INVENTOR i   
   INNER JOIN INVTMFGR m on m.UNIQ_KEY =i.UNIQ_KEY  
  WHERE i.status='active'   
   AND i.Part_Sourc<>'CONSG'   
   --AND m.Instore=0 -- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials
   AND m.Netable=1  
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
  HAVING SUM(m.QTY_OH-m.Reserved) > 0  
  ORDER BY i.PART_NO ,i.REVISION -- Nitesh B : 12/11/2018 Added sort order  
 END  
  