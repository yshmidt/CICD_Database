-- Author:  Rajendra K       
-- Create date: <02/18/2018>      
-- Description:Kit details data      
-- 12/20/2018 Rajendra : Get Reserve qty from KAMAIN table      
-- 03/1/2019 Rajendra : For getting the currect Available Qty Modified the SP      
-- 02/13/2019 Rajendra : Get Reserve qty from INVT_RES table      
-- 02/13/2019 Rajendra : Added Condition For location and warehouse      
-- 05/06/2019 Rajendra : Added GetTotalStock table exp. to get sum available Qty of approved MPN    
-- 05/06/2019 Rajendra : Changed AvailableQty as "TotalStock" sum available Qty of approved MPN    
-- 05/06/2019 Rajendra : Added AvailableQty in selection list as sum of all MPN    
-- 08/06/2019 Rajendra : Changed location datatype from VARCHAR to NVARCHAR      
-- 08/08/19 YS Location is 200 characters      
-- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations    
-- 03/25/2020 Rajendra K : Added @custNo and outer join to get consign uniq_key to calculate available Qty except AntiAvls    
-- 06/24/2020 Rajendra K : Added Outer join to get OtherAvailable Qty and added into selection list  
-- 12/02/2020 Rajendra K : Changed inner to left join  with invt_res table
-- 12/17/2020 Rajendra K : Added condition to skip issued Qty
-- 01/18/2021 Rajendra K : Added condition for approved available Qty
-- EXEC GetWOQuantities '_1EI0NK1ZN','_0DM120YNM','A17:R2:S1:B8','KX8Y5N2Z46','0000000850'      
--==============================================================================================      
 CREATE PROCEDURE [dbo].[GetWOQuantities]    
(      
 @uniqKey AS CHAR(10)='',      
 @uniqWHKey VARCHAR(10)='',      
 @location NVARCHAR (200)='',  -- 08/06/2019 Rajendra K : Changed location datatype from VARCHAR to NVARCHAR      
 @kaSeqNum  CHAR(10)='',      
 @wONO CHAR(10)=''       
)      
AS      
BEGIN      
 SET NOCOUNT ON -- 03/1/2019 Rajendra : For getting the currect Available Qty Modified the SP      
 DECLARE @bomParent CHAR(10)  ,@custNo CHAR(10)      
 SET @bomParent = (SELECT UNIQ_KEY FROM WOENTRY WHERE WONO = @wONO)    
 SET @custNo = (SELECT BOMCUSTNO FROM INVENTOR WHERE UNIQ_KEY = @bomParent)-- 03/25/2020 Rajendra K : Added @custNo and outer join to get consign uniq_key to calculate available Qty except AntiAvls    
 ;with GetAvailable AS (    
          SELECT DISTINCT  (SUM(IM.QTY_OH) - SUM(IM.RESERVED)) AS  TotalStock    
           FROM InvtMfgr IM       
           WHERE IM.uniq_Key = @uniqKey AND UNIQWH = @uniqWHKey and location = @location --and INSTORE= 0-- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations    
   ),      
   GetTotalStock AS (   -- 05/06/2019 Rajendra : Added GetTotalStock table exp. to get available Qty of approved MPN    
         SELECT DISTINCT  (SUM(IM.QTY_OH) - SUM(IM.RESERVED)) AS AvailableQty    
         FROM InvtMfgr IM     
     INNER JOIN InvtMPNLink mpn on im.UNIQMFGRHD = mpn.uniqmfgrhd     
     INNER JOIN MfgrMaster mm ON mpn.MfgrMasterId = mm.MfgrMasterId    
          WHERE IM.uniq_Key = @uniqKey AND UNIQWH = @uniqWHKey AND location = @location --AND INSTORE= 0 -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations    
        AND (NOT EXISTS (SELECT bomParent,ConsgUniq.UNIQ_KEY       
        FROM ANTIAVL A -- 03/25/2020 Rajendra K : Added @custNo and outer join to get consign uniq_key to calculate available Qty except AntiAvls    
        OUTER APPLY(    
           SELECT ISNULL(UNIQ_KEY,Im.UNIQ_KEY)AS UNIQ_KEY FROM INVENTOR WHERE INT_UNIQ = Im.UNIQ_KEY AND CUSTNO = @custNo    
          )AS ConsgUniq       
        WHERE A.BOMPARENT = @bomParent   -- 01/18/2021 Rajendra K : Added condition for approved available Qty   
        AND A.UNIQ_KEY = CASE WHEN ISNULL(ConsgUniq.UNIQ_KEY, '') = '' THEN Im.UNIQ_KEY ELSE ConsgUniq.UNIQ_KEY END
        AND A.PARTMFGR = mm.PARTMFGR     
        and A.MFGR_PT_NO = mm.MFGR_PT_NO)    
       )      
   ),    
  GetAll AS     
  (      
  SELECT GetAvailable.TotalStock     
     ,ISNULL(sum(IR.QTYALLOC),0) AS Reserve      
    ,K.SHORTQTY AS Shortage      
    ,(K.SHORTQTY+(K.ACT_QTY+K.AllocatedQty)) AS Required      
     ,ACT_QTY AS Used    
     ,GetTotalStock.AvailableQty  
  -- 06/24/2020 Rajendra K : Added Outer join to get OtherAvailable Qty and added into selection list  
  ,ExtraQty.OtherAvailable AS OtherAvailable    
  FROM GetTotalStock,GetAvailable,InvtMfgr IM  -- 12/02/2020 Rajendra K : Changed inner to left join  with invt_res table     
   LEFT JOIN Invt_Res IR ON IM.W_KEY = IR.W_KEY AND IR.KaSeqnum = @kaSeqNum AND IR.WONO = @wONO AND IM.LOCATION = @location AND IM.UNIQWH = @uniqWHKey    
   INNER JOIN KAMAIN K ON K.KaSeqnum = @kaSeqNum AND K.WONO = @wONO    
     OUTER APPLY (-- 06/24/2020 Rajendra K : Added Outer join to get OtherAvailable Qty and added into selection list 
	 -- 12/17/2020 Rajendra K : Added condition to skip issued Qty 
   SELECT CASE WHEN ABS(SUM(shortqty)) > SUM(ACT_QTY) THEN ABS(SUM(shortqty)) - SUM(ACT_QTY) ELSE 0.00 END AS OtherAvailable     
   FROM kamain WHERE kamain.UNIQ_KEY = @uniqKey AND  SHORTQTY<0 AND EXISTS  
   (SELECT 1 FROM woentry WHERE OPENCLOS NOT LIKE 'C%' and woentry.wono=kamain.wono AND kamain.WONO != @wONO)   
 ) ExtraQty    
  GROUP BY K.SHORTQTY,K.ACT_QTY,K.AllocatedQty,GetAvailable.TotalStock,GetTotalStock.AvailableQty,ExtraQty.OtherAvailable    
  )      
      
 SELECT  ISNULL(SUM(TotalStock),0) AS TotalStock-- 05/06/2019 Rajendra : Changed AvailableQty as "TotalStock" sum available Qty of approved MPN    
    ,ISNULL(AvailableQty,0) AS AvailableQty -- 05/06/2019 Rajendra : Added AvailableQty in selection list as sum of all MPN    
    ,ISNULL((Reserve),0) AS Reserve    
 ,ISNULL(OtherAvailable,0) AS OtherAvailable  -- 06/24/2020 Rajendra K : Added Outer join to get OtherAvailable Qty and added into selection list  
    ,Shortage      
    ,Required      
    ,Used       
 FROM GetAll      
 GROUP BY Shortage,Required,Used,Reserve,AvailableQty,OtherAvailable    
END 