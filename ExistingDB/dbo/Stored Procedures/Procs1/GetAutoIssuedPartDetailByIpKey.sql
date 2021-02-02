-- =============================================    
-- Author:  Sachin B    
-- Create date: 02/20/2017    
-- Description: this procedure will be called from the SF module and get part detail by ipkey for the Auto issue parts    
-- UnReserve SID [dbo].[GetAutoIssuedPartDetailByIpKey] 'TY6OK32YHX','0000000516','STAG'    
-- Reserve SID [dbo].[GetAutoIssuedPartDetailByIpKey] 'SWXMAHPH6A','0000000517','STAG'    
-- 07/22/2017 Sachin B Add logic for the SID Kaseqnum regardingthe selected work center and add temp table @SelectedSIDQtyAllocated    
-- 07/31/2017 Sachin B Remove wrong and condition LINESHORT = 0     
-- 09/15/2017 Sachin b Add LINESHORT column in select statement  
-- 04/18/2019 Sachin B Get the Approved Manufacture List and Add Join with IpKey Table  
-- 02/04/2020 Sachin B Remove imfgr.Instore = 0 for MTC Scan within MOC is not identifying Supplier Bonded inventory 
-- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)   
-- [GetAutoIssuedPartDetailByIpKey] '6ZMD64MB9F','0000102039','STAG'  
-- =============================================    
    
CREATE PROCEDURE [dbo].[GetAutoIssuedPartDetailByIpKey]     
 -- Add the parameters for the stored procedure here    
 @ipkey char(10) ='',    
 @wono char(10) ='',    
 @deptID char(4)    
AS    
BEGIN    
    
-- SET NOCOUNT ON added to prevent extra result sets from    
SET NOCOUNT ON;    
    
--Temp table for get SID qtyAllocated(if reserved)/warehouse qty (pkgBalance-qtyAllocatedTotal If SID Not reserved)    
Declare @SIDQtyAllocated    
TABLE(                  
    W_Key CHAR(10),IPKEYUNIQUE CHAR(10),qty NUMERIC(12,2),ReserveQty NUMERIC(12,2),IsReserve BIT,KaSeqNum CHAR(10),DeptID char(4),LINESHORT bit,Number numeric(4,0)     
  )    
-- 07/22/2017 Sachin B Add logic for the SID Kaseqnum regarding the selected work center and add temp table @SelectedSIDQtyAllocated    
Declare @SelectedSIDQtyAllocated    
TABLE(                  
    W_Key CHAR(10),IPKEYUNIQUE CHAR(10),qty NUMERIC(12,2),ReserveQty NUMERIC(12,2),IsReserve BIT,KaSeqNum CHAR(10),DeptID char(4)    
  )
  
DECLARE @nonNettable BIT;

 -- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)
 SET @nonNettable = (SELECT CONVERT(Bit,ISNULL(WM.settingValue,MS.settingValue)) 
 FROM MnxSettingsManagement MS 
 LEFT JOIN WmSettingsManagement WM ON  MS.settingId = WM.settingId          
 WHERE SettingName  = 'allowUseOfNonNettableWarehouseLocation')    
    
-- 07/22/2017 Sachin B Add logic for the SID Kaseqnum regardingthe selected work center and add temp table @SelectedSIDQtyAllocated    
--Get Reservd SID Data    
INSERT INTO @SIDQtyAllocated (W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID,LINESHORT,Number)    
SELECT ip.W_KEY,ip.IPKEYUNIQUE,SUM(resIp.qtyAllocated),SUM(resIp.qtyAllocated),CAST(1 AS BIT),resIp.KaSeqnum,ka.DEPT_ID,LINESHORT,Number    
FROM IPKEY ip    
INNER JOIN INVT_RES res ON res.UNIQ_KEY = ip.UNIQ_KEY and res.WONO = @wono    
INNER JOIN KAMAIN ka ON res.KaSeqnum = ka.KaSeqnum    
INNER JOIN iReserveIpKey resIp ON res.INVTRES_NO = resIp.INVTRES_NO and resIp.IPKEYUNIQUE =@ipkey    
LEFT OUTER JOIN DEPT_QTY dept on ka.DEPT_ID = dept.DEPT_ID AND dept.WONO = @wono     
WHERE ip.IPKEYUNIQUE = @ipkey    
GROUP BY ip.W_KEY,ip.IPKEYUNIQUE,resIp.KaSeqnum,dept.NUMBER,ka.DEPT_ID,LINESHORT,Number    
HAVING SUM(resIp.qtyAllocated) >0    
    
--If SID Reserved for selected Work Center and LINESHORT = 0     
INSERT INTO @SelectedSIDQtyAllocated (W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID)    
Select W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID from @SIDQtyAllocated where DeptID = @deptID and LINESHORT =0    
    
--If SID is Reserved for selected Work Center and LINESHORT = 1     
IF Not Exists(SELECT 1 FROM @SelectedSIDQtyAllocated)     
BEGIN    
    INSERT INTO @SelectedSIDQtyAllocated (W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID)    
    Select W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID from @SIDQtyAllocated where DeptID = @deptID and LINESHORT =1    
END    
    
--If SID is Reserved for other Work Center and LINESHORT = 0     
IF Not Exists(SELECT 1 FROM @SelectedSIDQtyAllocated)     
BEGIN    
      INSERT INTO @SelectedSIDQtyAllocated (W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID)    
      Select TOP 1 W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID from @SIDQtyAllocated where DeptID <> @deptID and LINESHORT =0    
   ORDER BY NUMBER    
END    
    
--If SID is Reserved for other Work Center and LINESHORT = 1     
IF Not Exists(SELECT 1 FROM @SelectedSIDQtyAllocated)     
BEGIN    
    INSERT INTO @SelectedSIDQtyAllocated (W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID)    
 Select TOP 1 W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID from @SIDQtyAllocated where DeptID <> @deptID and LINESHORT =1    
 ORDER BY NUMBER    
END    
    
-- 07/22/2017 Sachin B Add logic for the SID Kaseqnum regarding the selected work center and add temp table @SelectedSIDQtyAllocated    
--If SID is not reserved for any of components    
IF Not Exists(SELECT 1 FROM @SelectedSIDQtyAllocated)     
BEGIN    
   INSERT INTO @SIDQtyAllocated (W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID,LINESHORT,Number)    
   SELECT ip.W_KEY,ip.IPKEYUNIQUE,(pkgBalance-qtyAllocatedTotal),0,CAST(0 AS BIT),ka.KASEQNUM,ka.DEPT_ID,LINESHORT,Number     
   FROM IPKEY ip    
   INNER JOIN KAMAIN ka on ip.UNIQ_KEY = ka.UNIQ_KEY    
   LEFT OUTER JOIN DEPT_QTY dept on ka.DEPT_ID = dept.DEPT_ID AND dept.WONO = @wono AND dept.DEPT_ID = @deptID    
   -- 07/31/2017 Sachin B Remove wrong and condition LINESHORT = 0     
   WHERE  ip.IPKEYUNIQUE = @ipkey AND ka.WONO =@wono     
   AND (pkgBalance-qtyAllocatedTotal) >0    
END    
    
--If SID is not Reserved for selected Work Center and LINESHORT = 0     
IF Not Exists(SELECT 1 FROM @SelectedSIDQtyAllocated)     
BEGIN    
    INSERT INTO @SelectedSIDQtyAllocated (W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID)    
    Select W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID from @SIDQtyAllocated where DeptID = @deptID and LINESHORT =0    
END    
    
--If SID is not Reserved for selected Work Center and LINESHORT = 1     
IF Not Exists(SELECT * FROM @SelectedSIDQtyAllocated)     
BEGIN    
   INSERT INTO @SelectedSIDQtyAllocated (W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID)    
   Select W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID from @SIDQtyAllocated where DeptID = @deptID and LINESHORT =1    
END    
    
--If SID is not Reserved for other Work Center and LINESHORT = 0     
IF Not Exists(SELECT * FROM @SelectedSIDQtyAllocated)     
BEGIN    
   INSERT INTO @SelectedSIDQtyAllocated (W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID)    
   Select TOP 1 W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID from @SIDQtyAllocated where DeptID <> @deptID and LINESHORT =0    
   ORDER BY NUMBER    
END    
    
--If SID is not Reserved for other Work Center and LINESHORT = 1     
IF Not Exists(SELECT * FROM @SelectedSIDQtyAllocated)     
BEGIN    
   INSERT INTO @SelectedSIDQtyAllocated (W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID)    
   Select TOP 1 W_Key,IPKEYUNIQUE,qty,ReserveQty,IsReserve,KaSeqNum,DeptID from @SIDQtyAllocated where DeptID <> @deptID and LINESHORT =1    
   ORDER BY NUMBER    
END    
  
-- 04/18/2019 Sachin B Get the Approved Manufacture List and Add Join with IpKey Table    
DECLARE @bomParentUniqKey char(10), @congUniqKey CHAR(10) ='',@CustNo CHAR(10) ='',@uniqkey CHAR(10) ='';  
SET @bomParentUniqKey = (SELECT uniq_key FROM WOENTRY WHERE WONO =@wono);  
SET @CustNo =(SELECT BOMCUSTNO FROM INVENTOR WHERE UNIQ_KEY =@bomParentUniqKey);  
SET @uniqkey =(SELECT UNIQ_KEY FROM IPKEY WHERE IPKEYUNIQUE =@ipkey);  
  
IF(@CustNo<>'' AND @uniqkey<>'')  
BEGIN  
  SET @congUniqKey = (SELECT Uniq_Key FROM INVENTOR WHERE INT_UNIQ =@uniqkey AND CUSTNO =@CustNo)  
END   
  
Declare @AllocatedMFGR Table(W_Key Char(10))  
    
IF (@congUniqKey IS NOT NULL AND @congUniqKey<>'')  
  BEGIN  
  ;With InternalPartAVL AS(    
    SELECT i.UNIQ_KEY,mfMaster.Partmfgr,mfMaster.mfgr_pt_no AS MfgrPartNo,W_KEY  
    FROM Inventor i   
    INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY  and mpn.uniq_key =@uniqkey  
    INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
    INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd  
    INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH    
    AND Warehouse <> 'WIP' AND Warehouse <> 'WO-WIP' AND Warehouse <> 'MRB' 
	 -- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)
	AND ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1) 
	AND imfgr.Is_Deleted = 0 AND mpn.Is_deleted = 0 and mfMaster.IS_DELETED=0    
    --AND imfgr.Instore = 0  -- 02/04/2020 Sachin B Remove imfgr.Instore = 0 for MTC Scan within MOC is not identifying Supplier Bonded inventory  
   )  
   ,ConsgPartAVL AS(    
    SELECT mfMaster.Partmfgr,mfMaster.mfgr_pt_no AS MfgrPartNo, W_key,i.INT_UNIQ,i.UNIQ_KEY    
    FROM Inventor i   
    INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY  AND mpn.uniq_key =@congUniqKey  
    INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
    INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd  
    INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH 
	 -- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)   
    AND Warehouse <> 'WIP' AND Warehouse <> 'WO-WIP' AND Warehouse <> 'MRB' AND ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)  
	AND imfgr.Is_Deleted = 0 AND mpn.Is_deleted = 0 AND mfMaster.IS_DELETED=0    
    --AND imfgr.Instore = 0  -- 02/04/2020 Sachin B Remove imfgr.Instore = 0 for MTC Scan within MOC is not identifying Supplier Bonded inventory  
   )  
   INSERT INTO @AllocatedMFGR  
   SELECT i.W_key  
   FROM ConsgPartAVL c  
   INNER JOIN InternalPartAVL i ON i.UNIQ_KEY =c.INT_UNIQ  AND i.PartMfgr =c.PartMfgr AND i.MfgrPartNo =c.MfgrPartNo     
   WHERE c.UNIQ_KEY NOT IN  
   (  
   SELECT UNIQ_KEY   
   FROM ANTIAVL A   
   WHERE A.BOMPARENT =@bomParentUniqKey AND A.UNIQ_KEY = c.UNIQ_KEY AND A.PARTMFGR =c.Partmfgr AND A.MFGR_PT_NO =c.MfgrPartNo   
   )  
    END  
  ELSE  
    BEGIN  
       INSERT INTO @AllocatedMFGR  
       SELECT W_key  
    FROM Inventor i   
    INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY  and mpn.uniq_key =@uniqkey  
    INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
    INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd  
    INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH    
    AND Warehouse <> 'WIP' AND Warehouse <> 'WO-WIP' AND Warehouse <> 'MRB' 
	-- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)
	AND ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)  
	AND imfgr.Is_Deleted = 0 AND mpn.Is_deleted = 0 AND mfMaster.IS_DELETED=0    
    --AND imfgr.Instore = 0  -- 02/04/2020 Sachin B Remove imfgr.Instore = 0 for MTC Scan within MOC is not identifying Supplier Bonded inventory  
    WHERE i.UNIQ_KEY NOT IN  
    (    SELECT UNIQ_KEY   
      FROM ANTIAVL A   
      WHERE A.BOMPARENT =@bomParentUniqKey and A.UNIQ_KEY = i.UNIQ_KEY AND A.PARTMFGR =mfMaster.Partmfgr AND A.MFGR_PT_NO =mfMaster.mfgr_pt_no  
    )  
 END   
  
-- 09/15/2017 Sachin b Add LINESHORT column in select statement    
SELECT DISTINCT ip.UNIQ_KEY,ip.W_KEY,ip.IPKEYUNIQUE AS SID,RTRIM(i.PART_NO) +'/'+rtrim(i.REVISION) AS PartNoWithRev,QtyAll.DeptID,    
ISNULL(lot.UNIQ_LOT,'') AS UNIQ_LOT,lot.LOTCODE,lot.EXPDATE,lot.REFERENCE,ip.PONUM,i.SERIALYES,    
RTRIM(i.PART_CLASS)+ '/' + RTRIM(i.PART_TYPE) + '/' + RTRIM(i.DESCRIPT) AS [Description],mfMaster.Partmfgr AS Mfgr,mfMaster.mfgr_pt_no AS MfgrPartNo,ISNULL(k.QTY,1) AS Each,    
ISNULL(k.QTY,1) AS QtyEach,ISNULL(QtyAll.qty,0) AS Quantity,ISNULL(QtyAll.ReserveQty,0) AS ReserveQuantity,CAST(ISNULL(QtyAll.IsReserve,0) AS BIT) AS IsReserve,    
CAST(0 AS BIT) AS IsActiveSID,CAST(1 AS BIT) AS IsAdded,1 as SIDSequenceNo,k.KASEQNUM,dbo.fn_GenerateUniqueNumber() as WOSIDUniqKey,k.KASEQNUM,k.LINESHORT as IsLineShortage    
FROM IPKEY ip    
INNER JOIN INVENTOR i ON ip.UNIQ_KEY = i.UNIQ_KEY    
INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = ip.UNIQ_KEY and mpn.uniqmfgrhd =ip.UNIQMFGRHD    
INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
-- 04/18/2019 Sachin B Get the Approved Manufacture List and Add Join with IpKey Table    
INNER JOIN @AllocatedMFGR allMfgr ON allMfgr.W_Key = ip.W_KEY  
LEFT OUTER JOIN @SelectedSIDQtyAllocated QtyAll ON ip.W_KEY = QtyAll.W_KEY and ip.IPKEYUNIQUE = QtyAll.IPKEYUNIQUE    
LEFT OUTER JOIN KAMAIN k on ip.UNIQ_KEY =k.UNIQ_KEY and k.WONO =@wono and QtyAll.KaSeqNum =k.KASEQNUM     
LEFT OUTER JOIN INVTLOT lot ON lot.W_KEY =ip.W_KEY and ISNULL(lot.EXPDATE,1) = ISNULL(ip.EXPDATE,1) AND lot.LOTCODE = ip.LOTCODE 
and lot.REFERENCE = ip.REFERENCE and lot.PONUM = ip.PONUM    
WHERE ip.IPKEYUNIQUE = @ipkey and ISNULL(QtyAll.qty,0) >0    
    
END