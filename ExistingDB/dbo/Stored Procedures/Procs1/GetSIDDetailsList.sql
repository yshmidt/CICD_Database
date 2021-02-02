-- =============================================  
-- Author:Satish B  
-- Create date: 02/13/2018  
-- Description: Get SID detail based on unique key and warehouse  
-- 07/16/2020 : Rajendra K : Added isnull for the ExpDate 
-- exec GetSIDDetailsList 'OYU5NKB5DO','QIQ3UZ581F','',1,500  
-- =============================================  
CREATE PROCEDURE GetSIDDetailsList  
-- Add the parameters for the stored procedure here  
 @uniqKey AS char(10),  
 @wKey AS char(10),  
 @uniqLot char(10)='',  
 @startRecord int=0,  
 @endRecord int=50     
 --@sortExpression nvarchar(1000) = null  
AS  
BEGIN  
 SET NOCOUNT ON;  
 SELECT DISTINCT  
   ip.IpKeyUnique    
   ,(ip.pkgbalance-ip.qtyAllocatedTotal) As PkgBalance   
   ,0 As Issue  
   ,ip.UNIQ_KEY AS UniqKey  
   ,ip.W_KEY AS WKey  
      ,i.SERIALYES AS SerialYes  
   ,ip.LOTCODE AS LotCode  
   ,ip.REFERENCE AS Reference  
   ,ip.EXPDATE AS ExpDate  
   ,ip.PONUM AS PONum  
   ,lot.Uniq_lot AS UniqLot  
    
 FROM IPKEY ip      
   INNER JOIN inventor i ON i.UNIQ_KEY = ip.UNIQ_KEY  
   LEFT JOIN INVTLOT lot ON lot.LOTCODE=ip.LOTCODE AND lot.REFERENCE=ip.REFERENCE 
				AND ISNULL(lot.EXPDATE,'')=ISNULL(ip.EXPDATE ,'')-- 07/16/2020 : Rajendra K : Added isnull for the ExpDate 
				AND lot.PONUM=ip.PONUM AND lot.W_KEY= @wKey  
 WHERE ip.W_KEY=@wKey  
   AND ip.UNIQ_KEY=@uniqKey   
   AND (ip.pkgbalance - ip.qtyAllocatedTotal) >0  
   AND (@uniqLot IS NULL OR @uniqLot='' OR lot.Uniq_Lot= @uniqLot)  
   ORDER BY ip.IpKeyUnique DESC   
   OFFSET(@startRecord-1) ROWS  
   FETCH NEXT @EndRecord ROWS ONLY  
END  