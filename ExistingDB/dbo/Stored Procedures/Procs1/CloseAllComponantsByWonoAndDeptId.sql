-- =============================================      
-- Author: Sachin B      
-- Create date: 12/21/2016      
-- Description: this procedure will be called from the SF module and Close all the reserved componants to work ORDER BY WONo and DeptID      
-- Sachin B: 08/01/2017: Add temp table @WarehouseLotReserevedData and @WarehouseLotAllData      
-- Sachin B: 08/01/2017: Add condition for the lotted parts also with temp table in join with invt_res      
-- Sachin B: 08/01/2017: Add temp table WithoutSIDSerialPartsData, deallocateTableWithQty for consuming the Quantity for the multiple time reserved items from the same warehouse/lot without sid serial      
-- Sachin B: 08/01/2017: Add temp table deallocateIpKeyTable,deallocateIpKeyTableWithQty for consuming the Quantity for the multiple time reserved items      
-- Sachin B: 08/01/2017: Add temp table deallocateSerialTable for consuming the Quantity for the multiple time reserved items      
-- Sachin B: 09/13/2017: Change logic for getting lot and warehouse data and create alias of invt_res table      
-- Sachin B: 09/14/2017: Add totallink in the PARTITION BY      
-- Rajendra K : 09/22/2017  Added parameter @IsIssue to issue all reserved components to Work Order      
-- YS 02/06/2018 Changed lotcode column length to 25 char      
-- Rajendra K : 02/25/2019  Changed INNER to LEFT Join of PARTTYPE with Inventor      
-- Rajendra K : 10/09/2019: Fix the Issue Wrong Data is Populated in the IresIpkey While deallocating, Added group by Clause      
-- Rajendra K : 12/09/2019 : Added conditions in join as Lot details and w_key for invt_res table and Id_value,ID_Key for INVTSER    
-- Rajendra K : 02/24/2020 : Added column oldInvtres_no  and added condition on that to group by the records 
-- Rajendra K : 04/27/2020 : Added kaseqnum condition for avoid the duplication of records and remove the oldInvtres_no column and condition
--09/09/20 YS limit issue to the parts that were deallocated 
-- otherwise if the kit has mixed components, e.g. MTC and none MTC the code will try to issue twice ending up in the qty are not available error
-- CloseAllComponantsByWonoAndDeptId 'LASN18A11','','49F80792-E15E-4B62-B720-21B360E3108A',1     
-- =============================================      
CREATE PROCEDURE [dbo].[CloseAllComponantsByWonoAndDeptId]        
  @wono CHAR(10),      
  @deptId CHAR(10) = null,      
  @userid UNIQUEIDENTIFIER= null,      
  @IsIssue BIT = 0 --09/19/2017 Rajendra K : Added parameter @IsIssue to issue all reserved components to Work Order      
AS      
BEGIN      
SET NoCount ON;      
      
    -- get ready to handle any errors      
 DECLARE @ErrorMessage NVARCHAR(4000);      
    DECLARE @ErrorSeverity INT;      
    DECLARE @ErrorState INT;      
      
 -- Sachin B: 08/01/2017: Add temp table @WarehouseLotReserevedData and @WarehouseLotAllData      
 --Temp TABLE for warehous/lot      
 -- YS 02/06/2018 Changed lotcode column length to 25 char      
 declare @WarehouseLotReserevedData TABLE (invtres_no CHAR(10),UNIQ_KEY CHAR(10),w_key CHAR(10),ExpDate SMALLDATETIME,REFERENCE CHAR(12),LotCode NVARCHAR(25)  
 ,PONUM CHAR(15),QtyIssued NUMERIC(12,2),IsLotted BIT,useipkey BIT,serialyes BIT,kaseqnum CHAR(10))--,oldInvtres_no CHAR(10))  -- Rajendra K : 02/24/2020 : Added column oldInvtres_no  and added condition on that to group by the records  
  -- Rajendra K : 04/27/2020 : Added kaseqnum condition for avoid the duplication of records and remove the oldInvtres_no column and condition 
      
 --temp table @WarehouseLotReserevedData for All data which we have to insert in invt_Res with warehouse lot info      
 -- YS 02/06/2018 Changed lotcode column length      
 DECLARE @WarehouseLotAllData TABLE (w_key char(10),UNIQ_KEY char(10),wono char(10),newinvtres_no char(10),LotCode nvarchar(25),ExpDate smalldatetime,REFERENCE char(12),PONUM char(15),      
 FK_PRJUNIQUE char(10),kaseqnum char(10),deallocateQty numeric(12,2), totalLink char(10), UNIQUELN char(10),IsLotted bit,useipkey bit,serialyes bit,HeaderKey char(10)) --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
      
 --Temp TABLE for ReserveIpKey      
 DECLARE @ReserevedIpKeyData TABLE (invtisu_no CHAR(10),IPKEYUNIQUE CHAR(10),QtyIssued NUMERIC(12,2))      
      
 --Temp TABLE for IssueSerial      
 DECLARE @ReserevedSerialData TABLE (invtisu_no CHAR(10),IPKEYUNIQUE CHAR(10),SERIALUNIQ CHAR(10),SERIALNO CHAR(30))      
      
 -- declare "output into TABLE" and use it when insert into invt_res      
 DECLARE @intoInvtRes TABLE (invtres_no CHAR(10),refinvtres CHAR(10),qtyAlloc NUMERIC(12,2))      
      
 -- get g/l # for the wip account      
 DECLARE @wipGL CHAR(13)      
 SELECT @wipGl=dbo.fn_GetWIPGl()      
      
BEGIN TRY      
BEGIN TRANSACTION       
      
Declare @Initials varchar(8)      
Select @Initials = (select Initials from aspnet_Profile where UserId =@userid)      
      
;WITH ReservedComponantList AS (      
 SELECT i.UNIQ_KEY AS UniqKey,p.LOTDETAIL AS IsLotted, i.useipkey, i.serialyes, k.allocatedQty AS QtyIssued,KaSeqnum      
 FROM kamain k      
 INNER JOIN WOENTRY w ON w.WONO =k.WONO      
 INNER JOIN inventor i ON k.uniq_key=i.uniq_key      
 LEFT JOIN PARTTYPE p ON  p.PART_CLASS = i.PART_CLASS  AND p.PART_TYPE = i.PART_TYPE -- Rajendra K : 02/25/2019  Changed INNER to LEFT Join of PARTTYPE with Inventor      
 WHERE  k.wono= @wono       
 AND (@deptId IS NULL OR @deptId='' OR k.DEPT_ID = @deptId) and k.allocatedQty > 0      
 GROUP BY   i.useipkey, i.serialyes, i.UNIQ_KEY ,k.allocatedQty,p.LOTDETAIL,KaSeqnum      
)      
--select * from ReservedComponantList      
      
INSERT INTO @WarehouseLotReserevedData      
SELECT Distinct dbo.fn_GenerateUniqueNumber() AS invtres_no,resComp.UniqKey,res.w_key,res.ExpDate,res.Reference,res.LotCode,res.PONUM,SUM(QTYALLOC) AS 'QtyIssued'      
-- Rajendra K : 04/27/2020 : Added kaseqnum condition for avoid the duplication of records and remove the oldInvtres_no column and condition
,resComp.IsLotted,resComp.useipkey,resComp.serialyes,resComp.KaSeqnum--,res.INVTRES_NO AS oldInvtres_no -- Rajendra K : 02/24/2020 : Added column oldInvtres_no  and added condition on that to group by the records  
 FROM INVENTOR i      
 -- Sachin B: 09/13/2017: Change logic for getting lot and warehouse data      
INNER JOIN ReservedComponantList resComp ON  i.UNIQ_KEY = resComp.UniqKey      
Inner join INVT_RES res ON res.UNIQ_KEY = i.UNIQ_KEY and res.WONO = @wono and res.KaSeqnum =resComp.KASEQNUM       
LEFT OUTER JOIN invtlot lot ON ISNULL(lot.W_KEY,'') =ISNULL(res.w_key,'') AND  ISNULL(lot.lotcode,'') = ISNULL(res.lotcode,'')        
AND  ISNULL(lot.EXPDATE,1) = ISNULL(res.EXPDATE,1) AND  ISNULL(lot.REFERENCE,'') = ISNULL(res.REFERENCE,'')       
GROUP BY res.W_KEY,res.ExpDate,res.Reference,res.LotCode,res.PONUM,resComp.UniqKey,resComp.IsLotted,resComp.useipkey,resComp.serialyes,resComp.KaSeqnum--,res.INVTRES_NO       
HAVING SUM(QTYALLOC) > 0      
--select * from @WarehouseLotReserevedData      
      
--Getting Reserved IPkey Data for the WoNo       
INSERT INTO @ReserevedIpKeyData      
SELECT DISTINCT ware.invtres_no, resIP.IPKEYUNIQUE,SUM(resIP.qtyAllocated) AS QtyIssued      
FROM inventor i       
INNER JOIN @WarehouseLotReserevedData ware ON i.UNIQ_KEY = ware.UNIQ_KEY       
INNER JOIN INVT_RES res ON i.UNIQ_KEY = res.UNIQ_KEY and res.WONO = @wono and res.KaSeqnum =ware.KASEQNUM      
INNER JOIN iReserveIpKey resIP ON res.invtres_no = resIP.invtres_no       
INNER JOIN ipkey ip ON resIP.ipkeyunique = ip.IPKEYUNIQUE       
AND ip.W_KEY = ware.W_KEY and ISNULL(res.ExpDate,1) = ISNULL(ware.ExpDate,1) and ISNULL(res.Reference,'') = ISNULL(ware.Reference,'') and       
ISNULL(res.LotCode,'') = ISNULL(ware.LotCode,'') and ISNULL(res.PONUM,'') = ISNULL(ware.PONUM,'')      
WHERE  res.wono =@wono AND ware.useipkey =1 AND ware.SERIALYES = 0      
GROUP BY ware.invtres_no,resIP.IPKEYUNIQUE      
HAVING SUM(resIP.qtyAllocated) >0      
--select * from @ReserevedIpKeyData      
      
--Getting Reserved Serial Data for the WoNo      
INSERT INTO @ReserevedSerialData      
SELECT DISTINCT ware.invtres_no,ser.IPKEYUNIQUE,ser.SERIALUNIQ,ser.SERIALNO       
FROM inventor i       
INNER JOIN @WarehouseLotReserevedData ware ON i.UNIQ_KEY = ware.UNIQ_KEY -- Rajendra K : 12/09/2019 : Added conditions in join as Lot details and w_key for invt_res table and Id_value,ID_Key for INVTSER    
INNER JOIN INVT_RES res ON i.UNIQ_KEY = res.UNIQ_KEY and res.WONO = @wono and res.KaSeqnum =ware.KASEQNUM and res.REFINVTRES='' AND    
res.w_key = ware.w_key  and  ISNULL(res.ExpDate,1) = ISNULL(ware.ExpDate,1) and res.Reference = ware.Reference and res.LotCode = ware.LotCode and res.PONUM = ware.PONUM    
INNER JOIN iReserveSerial resSer ON res.invtres_no = resSer.invtres_no AND resSer.isDeallocate = 0     
INNER JOIN INVTSER ser ON resSer.SERIALUNIQ = ser.SERIALUNIQ      
AND (ser.ID_VALUE = ware.w_key and ser.ID_KEY='W_key') AND ISNULL(ser.ExpDate,1) = ISNULL(ware.ExpDate,1) and ser.Reference = ware.Reference and ser.LotCode = ware.LotCode and ser.PONUM = ware.PONUM    
WHERE res.wono =@wono       
AND resSer.isDeallocate = 0      
AND ser.ISRESERVED =1      
AND ser.RESERVEDFLAG = 'KaSeqnum'      
AND ser.RESERVEDNO = ware.kaseqnum      
--select * from @ReserevedSerialData      
      
        -- Sachin B: 08/01/2017: Add condition for the lotted parts also with temp table in join with invt_res      
        -- find allocated records      
  -- Sachin B: 09/13/2017: Change logic for getting lot and warehouse data and create alias of invt_res table      
  ;with totalReserved2Wo      
  as      
  (      
   SELECT r.DATETIME, r.Invtres_no as totalLink,t.W_key,@wono AS wono,r.LotCode,r.ExpDate,r.REFERENCE,r.PoNum,r.qtyalloc,r.fk_PrjUnique,r.UniqueLn ,t.KaSeqnum,      
   t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.IsLotted,t.Invtres_no AS HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
   FROM @WarehouseLotReserevedData t       
   inner join Invt_res r ON   ((t.kaseqnum=' ' and  r.wono=@wono) or (t.kaseqnum<>' ' and  r.kaseqnum=t.kaseqnum))      
   AND t.w_key = r.w_key AND  t.lotcode = r.lotcode  AND  ISNULL(t.EXPDATE,1) = ISNULL(r.EXPDATE,1)       
   AND  t.REFERENCE = r.REFERENCE AND t.PONUM =r.PONUM AND t.kaseqnum =r.kaseqnum      
   WHERE r.refinvtres=' '      
  UNION       
   SELECT r.DATETIME, r.Invtres_no AS totalLink,t.W_key,@wono AS wono,r.LotCode,r.ExpDate,r.REFERENCE,r.PoNum,r.qtyalloc,r.fk_PrjUnique,r.UniqueLn ,t.KaSeqnum,      
   t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.IsLotted,t.Invtres_no AS HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
   FROM @WarehouseLotReserevedData t       
   inner join Invt_res r ON r.wono=@wono      
   AND t.w_key = r.w_key AND  t.lotcode = r.lotcode  AND  ISNULL(t.EXPDATE,1) = ISNULL(r.EXPDATE,1)       
   AND  t.REFERENCE = r.REFERENCE AND t.PONUM =r.PONUM AND t.kaseqnum =r.kaseqnum      
   WHERE r.refinvtres=' '      
  UNION      
   SELECT r.DATETIME, r.Invtres_no AS totalLink,t.W_key,w.wono ,r.LotCode,r.ExpDate,r.REFERENCE,r.PoNum,r.qtyalloc,r.fk_PrjUnique,r.UniqueLn ,t.KaSeqnum,      
   t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.IsLotted,t.Invtres_no AS HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
   from @WarehouseLotReserevedData t       
   inner join woentry w ON w.wono=@wono      
   inner join Invt_res r ON r.FK_PRJUNIQUE=w.PRJUNIQUE      
   AND t.w_key = r.w_key AND  t.lotcode = r.lotcode  AND  ISNULL(t.EXPDATE,1) = ISNULL(r.EXPDATE,1)       
   AND  t.REFERENCE = r.REFERENCE AND t.PONUM =r.PONUM AND t.kaseqnum =r.kaseqnum      
   WHERE r.refinvtres=' ' and r.wono=' ' and w.PRJUNIQUE<>' '      
  UNION      
   SELECT r.DATETIME, r.REFINVTRES AS totalLink, r.W_key,r.wono,r.LotCode,r.ExpDate,r.REFERENCE,r.PoNum,r.qtyalloc,r.Fk_PrjUnique,r.UniqueLn ,r.KaSeqnum,      
   t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.IsLotted,t.Invtres_no AS HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
   FROM Invt_res r      
   inner join  @WarehouseLotReserevedData t ON ((t.kaseqnum=' ' and  r.wono=@wono) or (t.kaseqnum<>' ' and  r.kaseqnum=t.kaseqnum))      
   AND t.w_key = r.w_key AND  t.lotcode = r.lotcode  AND  ISNULL(t.EXPDATE,1) = ISNULL(r.EXPDATE,1)       
   AND  t.REFERENCE = r.REFERENCE AND t.PONUM =r.PONUM AND t.kaseqnum =r.kaseqnum      
   WHERE r.refinvtres<>' '      
  UNION      
   SELECT       
   r.DATETIME, REFINVTRES AS totalLink, r.W_key,r.wono,r.LotCode,r.ExpDate,r.REFERENCE,r.PoNum,r.qtyalloc,r.Fk_PrjUnique,r.UniqueLn ,r.KaSeqnum,      
   t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.IsLotted,t.Invtres_no AS HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
   FROM Invt_res r      
   inner join  @WarehouseLotReserevedData t ON  r.wono=@wono      
   AND t.w_key = r.w_key AND  t.lotcode = r.lotcode  AND  ISNULL(t.EXPDATE,1) = ISNULL(r.EXPDATE,1)       
   AND  t.REFERENCE = r.REFERENCE AND t.PONUM =r.PONUM AND t.kaseqnum =r.kaseqnum      
   WHERE r.refinvtres<>' '      
  UNION      
   SELECT r.DATETIME, REFINVTRES AS totalLink,t.W_key,w.wono,r.LotCode,r.ExpDate,r.REFERENCE,r.PoNum,r.qtyalloc,r.fk_PrjUnique,r.UniqueLn ,t.KaSeqnum,      
   t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.IsLotted,t.Invtres_no AS HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
   FROM @WarehouseLotReserevedData t       
   inner join woentry w ON @wono=w.wono      
   inner join Invt_res r ON r.FK_PRJUNIQUE=w.PRJUNIQUE      
   AND t.w_key = r.w_key AND  t.lotcode = r.lotcode  AND  ISNULL(t.EXPDATE,1) = ISNULL(r.EXPDATE,1)       
   AND  t.REFERENCE = r.REFERENCE AND t.PONUM =r.PONUM AND t.kaseqnum =r.kaseqnum      
   WHERE r.refinvtres<>' ' and r.wono=' ' and w.PRJUNIQUE<>' '      
  ),      
  composed      
  AS      
  (      
  SELECT totalLink,w_key,uniq_key,wono,lotcode,expdate,REFERENCE,ponum,fk_prjUnique,UniqueLn,KaSeqnum,SUM(qtyAlloc) as Allocated,      
  QtyIssued,UseIpkey,serialyes,IsLotted,HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
  FROM totalReserved2Wo      
  GROUP BY totalLink,w_key,uniq_key,wono,lotcode,expdate,REFERENCE,ponum,fk_prjUnique,UniqueLn,QtyIssued,KaSeqnum,UseIpkey,serialyes,IsLotted,HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
  HAVING SUM(qtyAlloc)<>0      
  ),      
  deallocateTable      
  AS      
  (      
  -- Sachin B: 09/14/2017: Add totallink in the PARTITION BY      
  SELECT ROW_NUMBER() over (partition by totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono order by kaseqnum) as lot, totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,      
  fk_prjUnique,UniqueLn,KaSeqnum,Allocated,UseIpkey,serialyes,IsLotted,      
  SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono ORDER BY kaseqnum DESC, wono,fk_prjUnique) AS qtyAllocated,       
  SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono ORDER BY kaseqnum DESC, wono,fk_prjUnique RANGE UNBOUNDED PRECEDING) - QtyIssued AS BalanceAfterIssued,      
  CASE WHEN SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono ORDER BY kaseqnum DESC, wono,fk_prjUnique RANGE UNBOUNDED PRECEDING) - QtyIssued<=0       
   THEN SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono ORDER BY kaseqnum DESC, wono,fk_prjUnique RANGE UNBOUNDED PRECEDING)       
   WHEN SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono ORDER BY kaseqnum DESC, wono,fk_prjUnique RANGE UNBOUNDED PRECEDING) - QtyIssued>= 0  THEN QtyIssued       
   ELSE 0 end AS deallocateQty,dbo.fn_GenerateUniqueNumber() AS newinvtres_no       
   ,HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
   FROM composed      
  )      
  --select * from deallocateTable      
      
  -- Sachin B: 08/01/2017: Add temp TABLE WithoutSIDSerialPartsData, deallocateTableWithQty for consuming the Quantity for the multiple time reserved items from the same warehouse/lot without sid serial      
  --temp TABLE for parts do not have sid,serial      
  ,WithoutSIDSerialPartsData as      
  (      
      select * from deallocateTable where UseIpkey =0 and serialyes = 0      
  )      
  --select * from WithoutSIDSerialPartsData           
  , deallocateTableWithQty AS       
  (      
    -- Start with Lot 1 for each Pool.      
    SELECT PL.w_key,PL.LOTCODE,PL.EXPDATE,PL.REFERENCE, PL.PONUM,PL.Lot, PL.Allocated,PC.QtyIssued,PL.UseIpkey,PL.serialyes,PL.IsLotted,      
   CASE      
     WHEN PC.QtyIssued is NULL THEN PL.Allocated      
     WHEN PL.Allocated >= PC.QtyIssued THEN PL.Allocated - PC.QtyIssued      
     WHEN PL.Allocated < PC.QtyIssued THEN 0      
     END AS RunningQuantity,      
   CASE      
     WHEN PC.QtyIssued is NULL THEN 0      
     WHEN PL.Allocated >= PC.QtyIssued THEN 0      
     WHEN PL.Allocated < PC.QtyIssued then PC.QtyIssued - PL.Allocated      
     END AS RemainingDemand,      
     PL.totalLink,PL.uniq_key,PL.wono,PL.fk_prjUnique,PL.UniqueLn,PL.KaSeqnum,PL.qtyAllocated,      
     PL.BalanceAfterIssued,PL.deallocateQty,PL.newinvtres_no,      
     HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
   FROM WithoutSIDSerialPartsData AS PL       
   left outer join @WarehouseLotReserevedData as PC ON PC.W_key = PL.w_key and pc.LOTCODE =pl.LOTCODE and ISNULL(pc.EXPDATE,1 )= ISNULL(pl.EXPDATE,1)   
   and pc.REFERENCE =pl.REFERENCE and pc.PONUM =pl.PONUM  
   AND PC.kaseqnum = PL.kaseqnum-- Rajendra K : 04/27/2020 : Added kaseqnum condition for avoid the duplication of records and remove the oldInvtres_no column and condition 
    --AND PL.totalLink = PC.oldInvtres_no -- Rajendra K : 02/24/2020 : Added column oldInvtres_no  and added condition on that to group by the records  
   WHERE Lot = 1      
    UNION ALL      
    -- Add the next Lot for each Pool.      
    SELECT PL.w_key,PL.LOTCODE,PL.EXPDATE,PL.REFERENCE, PL.PONUM,PL.Lot, PL.Allocated, CTE.QtyIssued,PL.UseIpkey,PL.serialyes,PL.IsLotted,      
   CASE      
     WHEN CTE.RunningQuantity + PL.Allocated >= CTE.RemainingDemand THEN CTE.RunningQuantity + PL.Allocated - CTE.RemainingDemand      
     WHEN CTE.RunningQuantity + PL.Allocated < CTE.RemainingDemand THEN 0      
     END AS RunningQuantity,      
   CASE      
     WHEN CTE.RunningQuantity + PL.Allocated >= CTE.RemainingDemand THEN 0      
     WHEN CTE.RunningQuantity + PL.Allocated < CTE.RemainingDemand THEN CTE.RemainingDemand - CTE.RunningQuantity - PL.Allocated      
     END AS RemainingDemand,      
     PL.totalLink,PL.uniq_key,PL.wono,PL.fk_prjUnique,PL.UniqueLn,PL.KaSeqnum,PL.qtyAllocated,      
     PL.BalanceAfterIssued,PL.deallocateQty,PL.newinvtres_no      
     ,PL.HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
   FROM deallocateTableWithQty AS CTE      
    INNER JOIN WithoutSIDSerialPartsData AS PL ON PL.W_key = CTE.w_key and PL.LOTCODE =CTE.LOTCODE and ISNULL(PL.EXPDATE,1 )= ISNULL(CTE.EXPDATE,1)   
 AND PL.REFERENCE =CTE.REFERENCE and PL.PONUM =CTE.PONUM 
 AND CTE.kaseqnum = PL.kaseqnum -- Rajendra K : 04/27/2020 : Added kaseqnum condition for avoid the duplication of records and remove the oldInvtres_no column and condition
 --AND  PL.totalLink = CTE.totalLink -- Rajendra K : 02/24/2020 : Added column oldInvtres_no  and added condition on that to group by the records  
 and PL.Lot = CTE.Lot + 1      
  )      
  --select * from deallocateTableWithQty      
  -- Sachin B: 08/01/2017: Add temp TABLE deallocateIpKeyTable,deallocateIpKeyTableWithQty for consuming the Quantity for the multiple time reserved items      
  ,deallocateIpKeyTable      
  as      
  (      
     select ROW_NUMBER() over (partition by w_key,lotcode,expdate,REFERENCE,ponum,wono,issuIp.ipkeyunique order by de.kaseqnum) as lot,      
     totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,fk_prjUnique,UniqueLn,de.KaSeqnum,Allocated,UseIpkey,serialyes,IsLotted,de.qtyAllocated,      
     BalanceAfterIssued,sum(issuIp.QtyIssued) as deallocateQty,issuIp.ipKeyUnique,dbo.fn_GenerateUniqueNumber() as newinvtres_no,HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
   from deallocateTable de       
     inner join ireserveipkey resip on de.totalLink = resip.invtres_no      
     inner join @ReserevedIpKeyData issuIp on issuIp.ipkeyunique = resip.ipkeyunique      
     where UseIpkey =1 and serialyes = 0      
     group by --de.lot,       
     totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,fk_prjUnique,UniqueLn,de.KaSeqnum,Allocated,UseIpkey,serialyes,IsLotted,de.qtyAllocated,      
     BalanceAfterIssued,issuIp.ipKeyUnique,HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
  )      
  --select * from deallocateIpKeyTable      
  , deallocateIpKeyTableWithQty AS       
  (      
    -- Start with Lot 1 for each Pool.      
    SELECT PL.w_key,PL.LOTCODE,PL.EXPDATE,PL.REFERENCE, PL.PONUM,PL.Lot, PL.Allocated,PC.QtyIssued,PL.UseIpkey,PL.serialyes,PL.IsLotted,PL.ipKeyUnique,      
   CASE      
     WHEN PC.QtyIssued is NULL THEN PL.Allocated      
     WHEN PL.Allocated >= PC.QtyIssued THEN PL.Allocated - PC.QtyIssued      
     WHEN PL.Allocated < PC.QtyIssued THEN 0      
     END AS RunningQuantity,      
   CASE      
     WHEN PC.QtyIssued is NULL THEN 0      
     WHEN PL.Allocated >= PC.QtyIssued THEN 0      
     WHEN PL.Allocated < PC.QtyIssued then PC.QtyIssued - PL.Allocated      
     END AS RemainingDemand,      
     PL.totalLink,PL.uniq_key,PL.wono,PL.fk_prjUnique,PL.UniqueLn,PL.KaSeqnum,PL.qtyAllocated,      
     PL.BalanceAfterIssued,PL.deallocateQty,PL.newinvtres_no,HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
   FROM deallocateIpKeyTable AS PL       
   left outer join @ReserevedIpKeyData  as PC ON pc.ipKeyUnique =pl.ipKeyUnique      
   WHERE Lot = 1      
  UNION ALL      
    -- Add the next Lot for each Pool.      
    SELECT PL.w_key,PL.LOTCODE,PL.EXPDATE,PL.REFERENCE, PL.PONUM,PL.Lot, PL.Allocated, CTE.QtyIssued,PL.UseIpkey,PL.serialyes,PL.IsLotted,PL.ipKeyUnique,      
   CASE      
     WHEN CTE.RunningQuantity + PL.Allocated >= CTE.RemainingDemand THEN CTE.RunningQuantity + PL.Allocated - CTE.RemainingDemand      
     WHEN CTE.RunningQuantity + PL.Allocated < CTE.RemainingDemand THEN 0      
     END AS RunningQuantity,      
   CASE      
     WHEN CTE.RunningQuantity + PL.Allocated >= CTE.RemainingDemand THEN 0      
     WHEN CTE.RunningQuantity + PL.Allocated < CTE.RemainingDemand THEN CTE.RemainingDemand - CTE.RunningQuantity - PL.Allocated      
     END AS RemainingDemand,      
     PL.totalLink,PL.uniq_key,PL.wono,PL.fk_prjUnique,PL.UniqueLn,PL.KaSeqnum,PL.qtyAllocated,      
     PL.BalanceAfterIssued,PL.deallocateQty,PL.newinvtres_no,PL.HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
   FROM deallocateIpKeyTableWithQty AS CTE      
    INNER JOIN deallocateIpKeyTable AS PL ON       
    PL.ipKeyUnique =CTE.ipKeyUnique       
     and PL.Lot = CTE.Lot + 1      
  )      
  --select * from deallocateIpKeyTableWithQty      
      
  -- Sachin B: 08/01/2017: Add temp TABLE deallocateSerialTable for consuming the Quantity for the multiple time reserved items      
  ,deallocateSerialTable      
  as      
  (      
     select de.lot,totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,fk_prjUnique,UniqueLn,de.KaSeqnum,Allocated,UseIpkey,serialyes,IsLotted,de.qtyAllocated,      
     BalanceAfterIssued,-count(issuserial.serialuniq) as deallocateQty,dbo.fn_GenerateUniqueNumber() as newinvtres_no,HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
     from deallocateTable de      
     inner join ireserveSerial resser on de.totalLink = resser.invtres_no      
     inner join @ReserevedSerialData issuserial on issuserial.serialuniq = resser.serialuniq and isDeallocate =0      
     group by de.lot, totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,fk_prjUnique,UniqueLn,de.KaSeqnum,Allocated,UseIpkey,serialyes,IsLotted,de.qtyAllocated,      
     BalanceAfterIssued,HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
  )      
  --select * from deallocateSerialTable       
  ,dataNeedtoInsertInInvtRes as      
  (      
     SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,      
    CASE       
     WHEN RemainingDemand >0 THEN -deallocateQty      
     WHEN RemainingDemand = 0 and allocated-runningquantity > 0 THEN -(allocated-runningquantity)      
    END AS deallocateQty      
    ,totalLink,UniqueLn,UseIpkey,serialyes,IsLotted      
    ,HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
   FROM deallocateTableWithQty       
   where (RemainingDemand >0 OR (RemainingDemand = 0 AND allocated-runningquantity >0))      
        UNION ALL      
     SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,UniqueLn,UseIpkey,serialyes,IsLotted,HeaderKey  --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
                   FROM deallocateSerialTable      
        UNION ALL      
     SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,      
    CASE       
     WHEN RemainingDemand >0 THEN -deallocateQty      
     WHEN RemainingDemand = 0 and allocated-runningquantity > 0 THEN -(allocated-runningquantity)      
    END AS deallocateQty      
    ,totalLink,UniqueLn,UseIpkey,serialyes,IsLotted,HeaderKey --Rajendra K : 09/22/2017 : Added column in temp table for Issue quantities      
   FROM deallocateIpKeyTableWithQty       
   where (RemainingDemand >0 OR (RemainingDemand = 0 AND allocated-runningquantity >0))      
  )      
  --select * from dataNeedtoInsertInInvtRes      
        
  -- Put All data in temp TABLE for which we have to put entry in invt_res      
  --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities      
  INSERT INTO @WarehouseLotAllData (w_key,UNIQ_KEY,wono,newinvtres_no,LotCode,ExpDate,REFERENCE,PONUM,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,UNIQUELN,IsLotted,useipkey,serialyes,HeaderKey)       
  --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities        
  --SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,UNIQUELN,IsLotted,useipkey,serialyes,HeaderKey       
  --FROM dataNeedtoInsertInInvtRes       
  -- Rajendra K : 10/09/2019: Fix the Issue Wrong Data is Populated in the IresIpkey While deallocating, Added group by Clause      
  SELECT w_key,uniq_key,wono,dbo.fn_GenerateUniqueNumber() As newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,Sum(deallocateQty),      
  totalLink,UNIQUELN,IsLotted,useipkey,serialyes,HeaderKey       
  FROM dataNeedtoInsertInInvtRes       
  GROUP BY w_key,uniq_key,wono,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,totalLink,UNIQUELN,IsLotted,useipkey,serialyes,HeaderKey       
      
  --If data exists without sid/serial then put entry in invt_res TABLE    
  --test
  --select * from @WarehouseLotReserevedData
  --end test  
  IF(Exists((SELECT 1 FROM @WarehouseLotReserevedData where useipkey =0 and serialyes =0)))      
  BEGIN      
   -- un-llocate header and save new invtres_no into the @intoInvtRes TABLE variable      
   INSERT INTO invt_res (w_key,uniq_key,wono,invtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,qtyAlloc,refinvtres,fk_userid,UNIQUELN,SAVEINIT)      
   SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,@userid,UniqueLn,@Initials      
    FROM @WarehouseLotAllData where useipkey =0 and serialyes =0      
      
   IF(@isIssue = 1 )      
   --Rajendra K : 09/22/2019 : Issue Lot/Mfgr parts     
   
   BEGIN      
    INSERT INTO invt_isu (w_key,UNIQ_KEY,issuedto,qtyisu,GL_NBR,wono,UNIQMFGRHD,fk_userid,kaseqnum,LOTCODE,EXPDATE,REFERENCE,PONUM)      
    SELECT t.W_key,t.Uniq_key,'(WO:'+@wono,-t.deallocateQty, @wipGl,@wono,m.UNIQMFGRHD,@userid,t.KaSeqnum,t.LOTCODE,t.EXPDATE,t.REFERENCE,t.PONUM       
    FROM @WarehouseLotAllData t INNER JOIN invtmfgr m ON t.W_key=m.W_KEY     
	--09/09/20 YS limit issue to the parts that were deallocated 
	-- otherwise if the kit has mixed components, e.g. MTC and none MTC the code will try to issue twice ending up in the qty are not available error
	where useipkey =0 and serialyes =0  
   END      
  END      
        
  if (Exists (select 1 from @ReserevedSerialData))      
  BEGIN      
      -- Clear the @intoInvtRes TABLE      
      Delete from @intoInvtRes      
      
   --insert data in invt_res for the serialized item      
   INSERT INTO invt_res (w_key,uniq_key,wono,invtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,qtyAlloc,refinvtres,fk_userid,UNIQUELN,SAVEINIT)      
   OUTPUT inserted.INVTRES_NO,inserted.refinvtres,inserted.QTYALLOC      
      into @intoInvtRes      
   SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,@userid,UniqueLn,@Initials      
   FROM @WarehouseLotAllData where serialyes =1      
      
   insert into iReserveSerial (invtres_no,serialuniq,ipkeyunique,kaseqnum,isDeallocate)      
    select res.invtres_no,rs.serialuniq,rs.ipkeyunique,rs.kaseqnum,1 from @intoInvtRes res       
    inner join iReserveSerial RS on res.refinvtres=rs.invtres_no      
       inner join @ReserevedSerialData iserial on rs.serialuniq=iserial.serialuniq      
      
   IF(@isIssue = 1 )      
   --Rajendra K : 09/22/2019 : Issue Serial Number parts      
   BEGIN      
    INSERT INTO invt_isu (invtisu_no,w_key,UNIQ_KEY,issuedto,qtyisu,GL_NBR,wono,UNIQMFGRHD,fk_userid,kaseqnum,LOTCODE,EXPDATE,REFERENCE,PONUM)         
    SELECT HeaderKey,t.W_key,t.Uniq_key,'(WO:'+@wono,-t.deallocateQty, @wipGl,@wono,m.UNIQMFGRHD,@userid,t.KaSeqnum,t.LOTCODE,t.EXPDATE,t.REFERENCE,t.PONUM       
    FROM @WarehouseLotAllData t INNER JOIN invtmfgr m ON t.W_key=m.W_KEY     
	--09/09/20 YS limit issue to the parts that were deallocated 
	-- otherwise if the kit has mixed components, e.g. MTC and none MTC the code will try to issue twice ending up in the qty are not available error 
     where serialyes =1      
	      
    INSERT INTO issueSerial (iIssueSerUnique,invtisu_no,serialno,SerialUniq,ipkeyunique,kaseqnum)      
    SELECT dbo.fn_GenerateUniqueNumber(),HeaderKey,iserial.serialno,iserial.SerialUniq,iserial.ipkeyunique,wl.KaSeqnum        
    FROM @ReserevedSerialData iserial       
    INNER JOIN @WarehouseLotAllData wl ON iserial.invtisu_no = wl.HeaderKey      
   END      
      
  END      
      
  IF (EXISTS (SELECT 1 FROM @ReserevedIpKeyData))      
  BEGIN      
      -- Clear the @intoInvtRes TABLE      
     Delete from @intoInvtRes      
      
  --insert data in invt_res for the item having useipkey =1 and serialyes =0      
   INSERT INTO invt_res (w_key,uniq_key,wono,invtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,qtyAlloc,refinvtres,fk_userid,UNIQUELN,SAVEINIT)      
   OUTPUT inserted.INVTRES_NO,inserted.refinvtres,inserted.QTYALLOC      
      into @intoInvtRes      
   SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,@userid,UniqueLn,@Initials      
   FROM @WarehouseLotAllData WHERE useipkey =1 and serialyes =0      
           
   INSERT INTO iReserveIpKey (invtres_no,qtyAllocated,ipkeyunique,kaseqnum)      
   SELECT res.invtres_no,-ipissue.QtyIssued,rip.ipkeyunique,rip.KaSeqnum       
   FROM @intoInvtRes res       
   INNER JOIN iReserveIpKey RIP ON res.refinvtres=rip.invtres_no      
   INNER JOIN @ReserevedIpKeyData ipissue ON rip.ipkeyunique=ipissue.ipKeyUnique      
         
   IF(@isIssue = 1 )      
   --Rajendra K : 09/22/2019 : Issue SID parts      
   BEGIN      
    INSERT INTO invt_isu (invtisu_no,w_key,UNIQ_KEY,issuedto,qtyisu,GL_NBR,wono,UNIQMFGRHD,fk_userid,kaseqnum,LOTCODE,EXPDATE,REFERENCE,PONUM)         
    SELECT newinvtres_no,t.W_key,t.Uniq_key,'(WO:'+@wono,-t.deallocateQty, @wipGl,@wono,m.UNIQMFGRHD,@userid,t.KaSeqnum,t.LOTCODE,t.EXPDATE,t.REFERENCE,t.PONUM       
    FROM @WarehouseLotAllData t INNER JOIN invtmfgr m ON t.W_key=m.W_KEY      
   --09/09/20 YS limit issue to the parts that were deallocated 
	-- otherwise if the kit has mixed components, e.g. MTC and none MTC the code will try to issue twice ending up in the qty are not available error 
    where useipkey =1 and serialyes =0   
	  
    INSERT INTO issueipkey (issueIpKeyUnique,invtisu_no,qtyissued,ipkeyunique,kaseqnum)      
    SELECT dbo.fn_GenerateUniqueNumber(),HeaderKey,ipissue.QtyIssued,ipissue.ipKeyUnique,WL.kaseqnum       
    FROM @ReserevedIpKeyData ipissue       
    INNER JOIN @WarehouseLotAllData WL ON ipissue.invtisu_no = WL.HeaderKey      
   END      
   END       
      
END TRY      
 BEGIN CATCH      
  IF @@TRANCOUNT>0      
   ROLLBACK      
   SELECT @ErrorMessage = ERROR_MESSAGE(),      
   @ErrorSeverity = ERROR_SEVERITY(),      
   @ErrorState = ERROR_STATE();      
   RAISERROR (@ErrorMessage, -- Message text.      
               @ErrorSeverity, -- Severity.      
               @ErrorState -- State.      
               );      
      
 END CATCH       
 IF @@TRANCOUNT>0      
  COMMIT       
END