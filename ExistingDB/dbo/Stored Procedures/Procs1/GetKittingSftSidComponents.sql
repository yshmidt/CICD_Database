-- =============================================  
-- Author:  Anuj  
-- Create date: 03/02/2016  
-- Description: Show Serial number and IpKey information related to a component in SFT  
-- GetKittingSftSidComponents '_1LR0NAL9Q','0000000524','_26U0XMZHL','' ,0,'44PT60QP7I',1,50,'IPKEYUNIQUE asc',''  
-- GetKittingSftSidComponents '_1EI0NK1ZM','0000000539','_37E0JLKTS','',0 ,'O1GNORCWO7',1,50,'IPKEYUNIQUE asc','',1  
-- 10/25/16 Sachin B Add three parameter U_OF_MEAS and RoHS,QtyUsed  
-- 06/09/2017 Sachin B Update SP for the Get SID info for Allocated Part  
-- 07/20/2017 Sachin B Add parameter @kaseqnum and check kaseqnum for the line items implementation  
-- 27/10/2017 Sachin B Sachin B Convert QtyUsed datatype from int to numeric(12,2) and Apply Coding Standard  
-- 11/27/2017 Sachin B Add @isReconciliation Parameter and get ReturnQty Conditionaliy  
-- 04/01/2019 Sachin B Get ReturnQty As Zero
--02/09/18 YS changed size of the lotcode column to 25 char  
-- 01/24/2020 Rajendra K : Added ISNULL condition for ExpDate if ExpDate is NULL
-- =============================================  
CREATE PROCEDURE [dbo].[GetKittingSftSidComponents]   
@uniqKey CHAR(10),  
@woNo CHAR(10),  
@wKey CHAR(10) ='',  
@uniqLot CHAR(10) ='',  
@isLotted BIT,  
@kaSeqNum CHAR(10),  
@startRecord INT,  
@endRecord INT,   
@sortExpression CHAR(1000) = NULL,  
@filter NVARCHAR(1000) = NULL,  
-- 11/27/2017 Sachin B Add @isReconciliation Parameter and get ReturnQty Conditionaliy  
@isReconciliation BIT =0  
AS  
  
SET NOCOUNT ON;   
IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL        
DROP TABLE dbo.#TEMP;  
  
DECLARE @sql NVARCHAR(max);  
  
-- 10/25/16 Sachin B Add three parameter U_OF_MEAS and RoHS,QtyUsed  
DECLARE @sftSidComponantList TABLE(  
IPKEYUNIQUE CHAR(10),  
QtyAllocated NUMERIC(12,2),  
-- 27/10/2017 Sachin B Convert QtyUsed datatype from int to numeric(12,2)  
ReturnQty NUMERIC(12,2),  
Unit CHAR(10),  
RoHS BIT,  
QtyUsed NUMERIC(12,2)  
);  
  
BEGIN  
  
     -- 06/09/2017 Sachin B Update SP for the Get SID info for Allocated Part  
     IF(@IsLotted = 0)  
    BEGIN  
   INSERT INTO @sftSidComponantList  
   SELECT ipReserve.IPKEYUNIQUE,SUM(ipReserve.qtyAllocated) AS QtyAllocated,  
   -- 11/27/2017 Sachin B Add @isReconciliation Parameter and get ReturnQty Conditionaliy  
   --   , CASE WHEN @isReconciliation =1 THEN (SUM(ipReserve.qtyAllocated)) ELSE 0 END AS ReturnQty,  
   -- 04/01/2019 Sachin B Get ReturnQty As Zero
   0.0 AS ReturnQty, 
   i.U_OF_MEAS AS Unit,CAST(1 AS BIT) RoHS,0 AS QtyUsed  
   FROM KAMAIN k   
   JOIN Inventor i ON k.Uniq_Key = i.Uniq_Key  
   JOIN INVT_RES res ON res.UNIQ_KEY = k.UNIQ_KEY AND res.WONO = k.WONO AND k.KASEQNUM = @kaSeqNum  
   JOIN iReserveIpKey ipReserve ON res.INVTRES_NO = ipReserve.invtres_no   
   -- 07/20/2017 Sachin B Add parameter @kaseqnum and check kaseqnum for the line items implementation  
   WHERE k.UNIQ_KEY=@uniqKey AND k.wono=@wono AND res.W_Key = @wKey AND res.KASEQNUM =@kaSeqNum  
   GROUP BY ipReserve.IPKEYUNIQUE,i.U_OF_MEAS  
   HAVING SUM(ipReserve.qtyAllocated)>0  
  END  
 ELSE  
  BEGIN  
  --02/09/18 YS changed size of the lotcode column to 25 char  
      DECLARE @lotcode nvarCHAR(25) = (SELECT lotcode FROM INVTLOT WHERE UNIQ_LOT = @uniqLot);  
   DECLARE @reference CHAR(12) = (SELECT REFERENCE FROM INVTLOT WHERE UNIQ_LOT = @uniqLot);  
   DECLARE @expDate SMALLDATETIME = (SELECT EXPDATE FROM INVTLOT WHERE UNIQ_LOT = @uniqLot);  
   DECLARE @ponum CHAR(15) = (SELECT ponum FROM INVTLOT WHERE UNIQ_LOT = @uniqLot);  
  
   INSERT INTO @sftSidComponantList  
   SELECT ipReserve.IPKEYUNIQUE,SUM(ipReserve.qtyAllocated) AS QtyAllocated,  
   -- 11/27/2017 Sachin B Add @isReconciliation Parameter and get ReturnQty Conditionaliy  
      CASE WHEN @isReconciliation =1 THEN (SUM(ipReserve.qtyAllocated)) ELSE 0 END AS ReturnQty,  
   i.U_OF_MEAS AS Unit,CAST(1 AS BIT) RoHS,0 AS QtyUsed  
   FROM KAMAIN k   
   JOIN Inventor i ON k.Uniq_Key = i.Uniq_Key  
   JOIN INVT_RES res ON res.UNIQ_KEY = k.UNIQ_KEY AND res.WONO = k.WONO AND k.KASEQNUM = @kaSeqNum  
   JOIN iReserveIpKey ipReserve ON res.INVTRES_NO = ipReserve.invtres_no   
   WHERE k.UNIQ_KEY=@uniqKey AND k.wono=@wono AND res.W_Key = @wKey   
   AND res.LOTCODE =ISNULL(@lotcode,'') AND res.REFERENCE =ISNULL(@reference,'')  
   -- 07/20/2017 Sachin B Add parameter @kaseqnum and check kaseqnum for the line items implementation  
   -- 01/24/2020 Rajendra K : Added ISNULL condition for ExpDate if ExpDate is NULL
   AND ISNULL(res.EXPDATE,1) = ISNULL(@expDate,1) AND res.PONUM =ISNULL(@ponum,'')    
   GROUP BY ipReserve.IPKEYUNIQUE,i.U_OF_MEAS  
   HAVING SUM(ipReserve.qtyAllocated)>0  
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