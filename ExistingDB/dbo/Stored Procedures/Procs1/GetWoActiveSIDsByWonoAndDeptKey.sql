-- =============================================    
-- Author:  Sachin B    
-- Create date: 02/22/2017    
-- Description: This procedure will be called from the SF module and get work orders Active SIDs    
-- [GetWoActiveSIDsByWonoAndDeptKey] '0000000516', '_33P0RF9SI'    
-- Reserve SID [GetWoActiveSIDsByWonoAndDeptKey] '0000000427','3700211MHK'    
-- [GetWoActiveSIDsByWonoAndDeptKey] '0000013508',_40X0Y6NQI    
-- 03/20/2017 Sachin B Add SID Done condition    
-- 07/22/2017 Sachin B Add Join With kamain for the current used kamain Data and Remove UnUsed parameter @DeptId and Add column in temp table @SIDQtyAllocated    
-- 06/01/2018 Sachin B Add POCount Count Info     
-- 08/20/2020 Sachin B Change the Logic for the getting PartNoWithRev if source is consg then get custPartNo/rev otherwise get PartNo/rev   
-- 01/25/2021 Add CurrentReqQty in the select
-- =============================================    
    
CREATE PROCEDURE [dbo].[GetWoActiveSIDsByWonoAndDeptKey]     
 -- Add the parameters for the stored procedure here    
 @wono CHAR(10) ='',    
 @deptKey CHAR(10) =''    
AS    
BEGIN    
    
-- SET NOCOUNT ON added to prevent extra result sets from    
SET NOCOUNT ON;    
    
-- 07/22/2017 Sachin B Add Join With kamain for the current used kamain Data and Remove UnUsed parameter @DeptId and Add column in temp table @SIDQtyAllocated    
--Temp table for get SID qtyAllocated(if reserved)/warehouse qty (pkgBalance-qtyAllocatedTotal If SID Not reserved)  
-- 01/25/2021 Add CurrentReqQty in the select  
DECLARE @SIDQtyAllocated TABLE(W_Key CHAR(10),IPKEYUNIQUE CHAR(10),qty NUMERIC(12,2),ReserveQty NUMERIC(12,2),IsReserve BIT,KaSeqNum CHAR(10),DeptID char(4),CurrentReqQty NUMERIC(12,2))    
    
-- 07/22/2017 Sachin B Add Join With kamain for the current used kamain Data and Remove UnUsed parameter @DeptId and Add column in temp table @SIDQtyAllocated    
--get Reserved SID Avilable Qty    
INSERT INTO @SIDQtyAllocated (W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID,CurrentReqQty)    
SELECT ip.W_KEY,ip.IPKEYUNIQUE,SUM(resIp.qtyAllocated),SUM(resIp.qtyAllocated),CAST(1 AS BIT),resIp.KaSeqNum,ActSID.DeptID,ka.allocatedQty+ka.SHORTQTY     
FROM WOActiveSID ActSID    
INNER JOIN IPKEY ip ON ActSID.IPKEYUNIQUE = ip.IPKEYUNIQUE    
INNER JOIN INVT_RES res ON res.UNIQ_KEY = ip.UNIQ_KEY and res.WONO = @wono    
INNER JOIN KAMAIN ka ON ActSID.KaSeqnum = ka.KaSeqnum    
INNER JOIN iReserveIpKey resIp ON res.INVTRES_NO = resIp.INVTRES_NO and resIp.IPKEYUNIQUE = ActSID.IPKEYUNIQUE    
WHERE ActSID.wono = @wono and ActSID.DeptKey = @deptKey    
GROUP BY ip.W_KEY,ip.IPKEYUNIQUE,resIp.KaSeqNum,ActSID.DeptID,ka.allocatedQty,ka.SHORTQTY    
HAVING SUM(resIp.qtyAllocated) >0    
    
-- 07/22/2017 Sachin B Add Join With kamain for the current used kamain Data and Remove UnUsed parameter @DeptId and Add column in temp table @SIDQtyAllocated       
--get Those SID warehouse qty Which are not reserved    
INSERT INTO @SIDQtyAllocated (W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID,CurrentReqQty)    
SELECT ip.W_KEY,ip.IPKEYUNIQUE,(pkgBalance-qtyAllocatedTotal),0,CAST(0 AS BIT),ActSID.KaSeqNum,ActSID.DeptID,ka.allocatedQty+ka.SHORTQTY         
FROM WOActiveSID ActSID    
INNER JOIN IPKEY ip on ActSID.IPKEYUNIQUE = ip.IPKEYUNIQUE    
INNER JOIN KAMAIN ka on ip.UNIQ_KEY = ka.UNIQ_KEY and ActSID.KaSeqnum = ka.KaSeqnum    
WHERE  ip.IPKEYUNIQUE not in (SELECT IPKEYUNIQUE FROM @SIDQtyAllocated) and ActSID.wono = @wono and ActSID.DeptKey = @deptKey and (pkgBalance-qtyAllocatedTotal) >0    
    
    
SELECT DISTINCT ip.UNIQ_KEY,ip.W_KEY,ip.IPKEYUNIQUE AS SID,  
--RTRIM(i.PART_NO) +'/'+RTRIM(i.REVISION) AS PartNoWithRev,  
-- 08/20/2020 Sachin B Change the Logic for the getting PartNoWithRev if source is consg then get custPartNo/rev otherwise get PartNo/rev   
CASE i.PART_SOURC WHEN 'CONSG'   
      THEN CASE COALESCE(NULLIF(i.CUSTREV,''), '')  WHEN ''   
                  THEN  LTRIM(RTRIM(i.CUSTPARTNO))    
                  ELSE LTRIM(RTRIM(i.CUSTPARTNO)) + '/' + i.CUSTREV END  
                     ELSE CASE COALESCE(NULLIF(i.REVISION,''), '') WHEN ''   
                  THEN  LTRIM(RTRIM(i.PART_NO))    
                  ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION  END END as PartNoWithRev,    
ISNULL(lot.UNIQ_LOT,'') AS UNIQ_LOT,lot.LOTCODE,lot.EXPDATE,lot.REFERENCE,ip.PONUM,i.SERIALYES,    
RTRIM(i.PART_CLASS)+ '/' + RTRIM(i.PART_TYPE) + '/' + RTRIM(i.DESCRIPT) AS [Description],mfMaster.Partmfgr AS Mfgr,mfMaster.mfgr_pt_no AS MfgrPartNo,ISNULL(k.QTY,1) AS Each,ActSID.QtyEach,    
ISNULL(QtyAll.qty,1) as Quantity,ISNULL(QtyAll.ReserveQty,0) AS ReserveQuantity,CAST(ISNULL(QtyAll.IsReserve,0) AS BIT) as IsReserve,CAST(1 AS BIT) AS IsActiveSID,    
ActSID.SIDSequenceNo,ActSID.WOSIDUniqKey,QtyAll.KASEQNUM,QtyAll.DeptID    
-- 06/01/2018 Sachin B Add POCount Count Info     
,(SELECT ISNULL(COUNT(1),0) FROM POMAIN PM INNER JOIN  POITEMS PIT  ON PM.PONUM = PIT.PONUM      
      LEFT JOIN poitschd ps ON PIT.uniqlnno = ps.uniqlnno    
      WHERE UNIQ_KEY = i.UNIQ_KEY     
     AND PM.postatus <> 'CANCEL' AND PM.postatus <>  'CLOSED'     
     AND PIT.lcancel = 0 AND ps.balance > 0) AS POCount,i.PART_SOURC AS PartSource,CurrentReqQty   
FROM WOActiveSID ActSID    
INNER JOIN IPKEY ip ON ActSID.IPKEYUNIQUE = ip.IPKEYUNIQUE    
INNER JOIN INVENTOR i ON ip.UNIQ_KEY = i.UNIQ_KEY    
INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = ip.UNIQ_KEY and mpn.uniqmfgrhd =ip.UNIQMFGRHD    
INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
LEFT OUTER JOIN @SIDQtyAllocated QtyAll ON ip.W_KEY = QtyAll.W_KEY and ip.IPKEYUNIQUE = QtyAll.IPKEYUNIQUE    
LEFT OUTER JOIN KAMAIN k ON ip.UNIQ_KEY =k.UNIQ_KEY and k.WONO =@wono and QtyAll.KaSeqNum =k.KASEQNUM    
LEFT OUTER JOIN INVTLOT lot ON lot.W_KEY =ip.W_KEY and ISNULL(lot.EXPDATE,1) = ISNULL(ip.EXPDATE,1) and lot.LOTCODE = ip.LOTCODE and lot.REFERENCE = ip.REFERENCE and lot.PONUM = ip.PONUM    
-- 03/20/2017 Sachin B Add SID Done condition    
WHERE ActSID.wono = @wono and ActSID.DeptKey = @deptKey and QtyAll.qty >0 AND ActSID.IsSIDDone = 0    
order by ip.UNIQ_KEY,ActSID.SIDSequenceNo    
    
END