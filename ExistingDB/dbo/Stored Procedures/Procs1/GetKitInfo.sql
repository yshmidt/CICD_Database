  -- =============================================    
-- Author: Rajendra K   
-- Create date: 12/31/2019 
-- Description: Get kamain data for BOM to KIT Module      
-- Exec GetKitInfo '0009856123'
-- =============================================    
CREATE PROCEDURE GetKitInfo     
 @woNumber AS CHAR(10)   
AS    
BEGIN    
    
  SET NOCOUNT ON;    
    
  SELECT I.uniq_key AS UniqKey,    
         K.KASEQNUM,     
            k.WONO AS WorkOrder,     
      I.useipkey AS UseIpKey,      
            I.SERIALYES AS Serialyes,     
   ISNULL(PT.LOTDETAIL,0) AS IsLotted,     
   K.ShortQty    
  FROM  KAMAIN K     
  INNER JOIN INVENTOR I ON K.UNIQ_KEY=I.UNIQ_KEY AND K.WONO= @woNumber AND K.IGNOREKIT = 0  
  INNER JOIN PartClass pc on i.PART_CLASS = pc.part_class     
  LEFT JOIN PARTTYPE PT ON I.PART_CLASS = PT.PART_CLASS AND I.PART_TYPE = PT.PART_TYPE        
END    
    
    
    