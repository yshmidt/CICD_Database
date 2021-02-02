-- =============================================      
-- Author:  Sachin B      
-- Create date: 09/09/2016      
-- Description: this procedure will be called from the SF module and get all the ipkey data which are associated with this warehouse      
-- [dbo].[GetWareHouseIpKeyData] '_1EP0LM58C','_1EP0LML8M','',false,1,3000,'',''       
-- [dbo].[GetWareHouseIpKeyData] '_2N20N2DPF','REVH5CV74T','',0,1,3000,'',''      
--- 09/13/16 Sachin b Gettting IpKey if part is lotted      
-- 10/25/16 Sachin B Add three parameter U_OF_MEAS and RoHS and QtyUsed      
-- 12/05/16 Sachin B Add Ponum      
-- 27/10/2017 Sachin B Convert QtyUsed datatype from int to numeric(12,2) and Apply Coding Standard      
-- 02/09/18 YS changed size of the lotcode column to 25 char      
-- 08/09/18 Sachin B Cooment the IpKey Condition for SID Breaking Fixes    
-- 12/05/18 Sachin B Fix the Issue the SID Scan is not working becuase it also getting Reserved SID Add and Condition ip.qtyAllocatedTotal = 0     
-- 01/24/2020 Rajendra K : Added ISNULL condition for ExpDate if ExpDate is NULL  
-- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials
-- GetWareHouseIpKeyData '_1EI0NK1ZM','_25T0QWHVI','',0,1,150  
-- =============================================      
      
CREATE PROCEDURE [dbo].[GetWareHouseIpKeyData]       
 -- Add the parameters for the stored procedure here      
 @uniqKey CHAR(10)=' ',      
 @wKey CHAR(10) ='',      
 @uniqLot CHAR(10) ='',      
 @isLotted BIT,      
 @startRecord INT,      
 @endRecord INT,       
 @sortExpression CHAR(1000) = NULL,      
 @filter NVARCHAR(1000) = NULL      
AS      
BEGIN      
      
-- SET NOCOUNT ON added to prevent extra result sets from      
-- interfering with SELECT statements.      
SET NOCOUNT ON;      
      
IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL            
DROP TABLE dbo.#TEMP;      
      
DECLARE @sql NVARCHAR(MAX);      
      
-- 10/25/16 Sachin B Add three parameter U_OF_MEAS and RoHS and QtyUsed      
DECLARE @sftSidComponantList TABLE(      
IPKEYUNIQUE CHAR(10),      
QtyAllocated NUMERIC(12,2),      
Unit CHAR(10),      
RoHS BIT,      
-- 27/10/2017 Sachin B Sachin B Convert QtyUsed datatype from int to numeric(12,2)      
QtyUsed NUMERIC(12,2)      
);      
      
if(@IsLotted = 0)      
 BEGIN      
     INSERT INTO @sftSidComponantList      
  -- 10/25/16 Sachin B Add three parameter U_OF_MEAS and RoHS and QtyUsed      
  SELECT DISTINCT ip.IPKEYUNIQUE,ip.pkgBalance,i.U_OF_MEAS AS Unit,CAST(1 AS BIT) RoHS,0 as QtyUsed      
  FROM INVENTOR i      
  INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY      
  INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId      
  INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND mpn.uniqmfgrhd = imfgr.UNIQMFGRHD      
  INNER JOIN WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH      
  INNER JOIN IPKEY ip ON ip.W_KEY =imfgr.W_KEY AND imfgr.UNIQ_KEY =i.UNIQ_KEY      
  WHERE       
  i.UNIQ_KEY = @uniqKey      
  AND WAREHOUSE <> 'WIP   '       
  AND WAREHOUSE <> 'WO-WIP'       
  AND Warehouse <> 'MRB   '      
  AND ip.pkgBalance > 0       
  AND imfgr.W_KEY = @wKey      
  AND imfgr.IS_DELETED = 0   
  -- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials    
  --AND imfgr.INSTORE = 0   
  -- 12/05/18 Sachin B Fix the Issue the SID Scan is not working becuase it also getting Reserved SID Add and Condition ip.qtyAllocatedTotal = 0     
  AND ip.qtyAllocatedTotal = 0      
  -- 08/09/18 Sachin B Cooment the IpKey Condition for SID Breaking Fixes    
  --AND ip.IPKEYUNIQUE NOT IN (SELECT IPKEYUNIQUE FROM iReserveIpKey)      
 END      
ELSE      
    BEGIN      
  -- 09/13/16 Sachin b Gettting IpKey if part is lotted    
  --02/09/18 YS changed size of the lotcode column to 25 char      
  DECLARE @lotcode nvarCHAR(25) = (SELECT lotcode FROM INVTLOT WHERE UNIQ_LOT = @uniqLot);      
  DECLARE @reference CHAR(12) = (SELECT REFERENCE FROM INVTLOT WHERE UNIQ_LOT = @uniqLot);      
  DECLARE @expDate SMALLDATETIME = (SELECT EXPDATE FROM INVTLOT WHERE UNIQ_LOT = @uniqLot);      
  DECLARE @ponum CHAR(15) = (SELECT ponum FROM INVTLOT WHERE UNIQ_LOT = @uniqLot);      
      
  INSERT INTO @sftSidComponantList      
  -- 10/25/16 Sachin B Add three parameter U_OF_MEAS and RoHS and QtyUsed      
        SELECT DISTINCT ip.IPKEYUNIQUE,ip.pkgBalance,i.U_OF_MEAS as Unit,CAST(1 AS BIT) RoHS,0 AS QtyUsed      
  FROM INVENTOR i      
  INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY      
  INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId      
  INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND mpn.uniqmfgrhd = imfgr.UNIQMFGRHD      
  INNER JOIN WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH      
  INNER JOIN IPKEY ip ON ip.W_KEY =imfgr.W_KEY AND imfgr.UNIQ_KEY =i.UNIQ_KEY      
  WHERE       
  i.UNIQ_KEY = @uniqKey      
  AND WAREHOUSE <> 'WIP   '       
  AND WAREHOUSE <> 'WO-WIP'       
  AND Warehouse <> 'MRB   '      
  AND ip.pkgBalance > 0       
  AND imfgr.W_KEY = @wKey      
  AND imfgr.IS_DELETED = 0  
  -- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials     
  --AND imfgr.INSTORE = 0   
  -- 12/05/18 Sachin B Fix the Issue the SID Scan is not working becuase it also getting Reserved SID Add and Condition ip.qtyAllocatedTotal = 0       
  AND ip.qtyAllocatedTotal = 0       
  --AND ip.IPKEYUNIQUE NOT IN (SELECT IPKEYUNIQUE FROM iReserveIpKey)      
  AND ip.LOTCODE = @lotcode      
  AND ip.REFERENCE = @reference      
  -- 01/24/2020 Rajendra K : Added ISNULL condition for ExpDate if ExpDate is NULL  
  AND ISNULL(ip.EXPDATE,1) = ISNULL(@expDate,1)       
  AND ip.PONUM = @ponum      
 END      
SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @sftSidComponantList      
      
 IF @filter <> '' AND @sortExpression <> ''      
  BEGIN      
   SET @sql=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE '+@filter+' and      
   RowNumber BETWEEN '+CONVERT(VARCHAR,@startRecord)+' AND '+CONVERT(VARCHAR,@endRecord)+' ORDER BY '+ @sortExpression+''      
   END      
  ELSE IF @filter = '' AND @sortExpression <> ''      
  BEGIN      
    SET @sql=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP ) AS TotalCount from #TEMP  t  WHERE       
    RowNumber BETWEEN '+CONVERT(VARCHAR,@startRecord)+' AND '+CONVERT(VARCHAR,@endRecord)+' ORDER BY '+ @sortExpression+''      
 END      
  ELSE IF @filter <> '' AND @sortExpression = ''      
  BEGIN      
      SET @sql=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE  '+@filter+' and      
      RowNumber BETWEEN '+CONVERT(VARCHAR,@startRecord)+' AND '+CONVERT(VARCHAR,@endRecord)+''      
   END      
   ELSE      
     BEGIN      
      SET @sql=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE       
      RowNumber BETWEEN '+CONVERT(VARCHAR,@startRecord)+' AND '+CONVERT(VARCHAR,@endRecord)+''      
   END      
   EXEC SP_EXECUTESQL @sql      
END