-- =============================================  
-- Author:  Mahesh B  
-- Create date: 1/241/2019  
-- Description: Get Auto kit SID Information  
-- 12/26/2019 Rajendra k  : changed expdate condition 
-- Exec GetAutoKitSIDInfo '0000000500','_25P0KUM80','HXS02L6GBT', 'CO726MLCQ0'    
-- =============================================  
CREATE PROCEDURE GetAutoKitSIDInfo  
 -- Add the parameters for the stored procedure here  
 @woNumber AS CHAR(10),  
 @uniqKey AS CHAR(10),  
 @wKey AS CHAR(10)='',  
 @isUniqLot AS CHAR(10)=''  
  
AS  
BEGIN  
  -- SET NOCOUNT ON added to prevent extra result sets from  
  -- interfering with SELECT statements.  
  SET NOCOUNT ON;  
  IF @isUniqLot = ''-- for the SID only    
  BEGIN   
  SELECT  ip.IPKEYUNIQUE AS Sid,  
       ip.pkgBalance - ip.qtyAllocatedTotal AS AvailableQty,  
    ip.recordCreated  
    FROM  IPKEY ip  
    INNER JOIN Inventor i on i.UNIQ_KEY =ip.uniq_key  AND ip.uniq_key = @uniqKey AND ip.W_KEY = @wKey AND (ip.pkgBalance - ip.qtyAllocatedTotal > 0)  
    ORDER BY recordCreated  ASC  
  
 END  
  ELSE   
   BEGIN  --- SID with lot    
   SELECT  IL.UNIQ_LOT AS UniqLot,    
     IL.LOTCODE AS LotCode,   
     IL.REFERENCE AS Reference,  
     IL.EXPDATE AS ExpDate,  
     IL.PONUM AS PONumber ,  
     ip.IPKEYUNIQUE AS Sid,  
     ip.pkgBalance - ip.qtyAllocatedTotal AS AvailableQty,  
     ip.recordCreated  
					FROM INVTLOT IL -- 12/26/2019 Rajendra k  : changed expdate condition 
           INNER JOIN Ipkey IP ON 1 =(CASE WHEN IL.LOTCODE IS NULL OR IL.LOTCODE= '' THEN 1 --IL.EXPDATE = IP.EXPDATE 
	       							 WHEN IL.EXPDATE IS NULL OR IL.EXPDATE= '' AND IP.EXPDATE IS NULL OR IP.EXPDATE = '' THEN 1 
	       							 WHEN IL.EXPDATE = IP.EXPDATE THEN 1 ELSE 0 END)
                                   AND IL.REFERENCE = IP.REFERENCE
                   AND IL.PONUM = IP.PONUM  
                    AND IL.LOTCODE = IP.LOTCODE   
     WHERE  (ip.pkgBalance - ip.qtyAllocatedTotal > 0) AND  IP.W_KEY = @wKey AND IP.UNIQ_KEY = @uniqKey AND IL.UNIQ_LOT= @isUniqLot  
     ORDER BY recordCreated  ASC  
     
      END  
END  