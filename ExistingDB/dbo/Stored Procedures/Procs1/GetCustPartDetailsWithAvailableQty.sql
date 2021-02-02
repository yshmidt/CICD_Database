-- =============================================    
-- Author:Rajendra K    
-- Create date: 07/08/2020    
-- Description : Get the customer part details with its available quantity    
-- exec GetCustPartDetailsWithAvailableQty '0000000002'   
-- =============================================    
CREATE PROCEDURE GetCustPartDetailsWithAvailableQty 
@custNo VARCHAR(10) = ''
 AS    
 BEGIN    
  SET NOCOUNT ON      
  SELECT SUM(m.qty_oh-m.Reserved) AS Available       
   ,RTRIM(LTRIM(i.PART_NO)) + CASE WHEN i.REVISION IS NULL OR i.REVISION='' THEN '' ELSE '/' END + i.REVISION AS PartRev    
   ,RTRIM(LTRIM(i.CUSTPARTNO)) + CASE WHEN i.CUSTREV IS NULL OR i.CUSTREV='' THEN '' ELSE '/' END + i.CUSTREV AS CustPartRev
   ,RTRIM(i.PART_CLASS) + CASE WHEN i.PART_CLASS IS NULL OR i.PART_CLASS='' THEN '' ELSE '/' END +     
        RTRIM(i.PART_TYPE) + CASE WHEN i.PART_TYPE IS NULL OR i.PART_TYPE='' THEN '' ELSE '/' END +i.DESCRIPT AS Descript    
   ,i.U_Of_Meas AS SUom    
   ,i.Uniq_Key AS UniqKey    
   ,i.UseIpKey     
   ,i.SerialYes    
   ,i.StdCost
   ,i.CUSTPARTNO
   ,i.CUSTREV
   ,i.CUSTNO 
   ,C.CUSTNAME    
  FROM INVENTOR i     
   INNER JOIN INVTMFGR m on m.UNIQ_KEY =i.UNIQ_KEY   
   INNER join CUSTOMER C ON i.CUSTNO = c.CUSTNO
  WHERE i.status='active'     
   AND i.Part_Sourc='CONSG'     
   AND m.Netable=1   
   AND ((IsNULL(@custNo ,'') <> '' AND i.CUSTNO = @custNo) OR (IsNULL(@custNo ,'') = '' AND 1=1))
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
   ,i.CUSTPARTNO
   ,i.CUSTREV
   ,i.CUSTNO
   ,C.CUSTNAME    
  HAVING SUM(m.QTY_OH-m.Reserved) > 0  
  ORDER BY i.PART_NO ,i.REVISION
 END    