-- =============================================  
-- Author: Vijay G  
-- Create date: 12/24/2019  
-- DescriptiON: Used to de-kit qty of component which removed from BOM   
-- =============================================  
CREATE PROCEDURE [dbo].[CloseRemovedComponant]    
  @wono CHAR(10),  
  @kaSeqNum CHAR(10),  
  @userid UNIQUEIDENTIFIER= null,  
  @IsIssue BIT = 0   
AS  
BEGIN  
SET NoCount ON;  
  
    -- get ready to handle any errors  
 DECLARE @ErrorMessage NVARCHAR(4000);  
    DECLARE @ErrorSeverity INT;  
    DECLARE @ErrorState INT;  
  
 --Temp TABLE for warehous/lot  
  
 DECLARE @WarehouseLotReserevedData TABLE (invtres_no CHAR(10),UNIQ_KEY CHAR(10),w_key CHAR(10),ExpDate SMALLDATETIME,REFERENCE CHAR(12),LotCode NVARCHAR(25),PONUM CHAR(15)  
 ,QtyIssued NUMERIC(12,2),IsLotted BIT,useipkey BIT,serialyes BIT,kaseqnum CHAR(10))  
  
 --temp table @WarehouseLotReserevedData for All data which we have to insert in invt_Res with warehouse lot info  
  
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
 LEFT JOIN PARTTYPE p ON  p.PART_CLASS = i.PART_CLASS  AND p.PART_TYPE = i.PART_TYPE   
 WHERE  k.wono= @wono   
 AND (@kaSeqNum IS NULL OR @kaSeqNum='' OR k.KASEQNUM = @kaSeqNum) and k.allocatedQty > 0  
 GROUP BY   i.useipkey, i.serialyes, i.UNIQ_KEY ,k.allocatedQty,p.LOTDETAIL,KaSeqnum  
)  
--select * from ReservedComponantList  
  
INSERT INTO @WarehouseLotReserevedData   
SELECT Distinct dbo.fn_GenerateUniqueNumber() AS invtres_no,resComp.UniqKey,res.w_key,res.ExpDate,res.Reference,res.LotCode,res.PONUM,SUM(QTYALLOC) AS 'QtyIssued'  
,resComp.IsLotted,resComp.useipkey,resComp.serialyes,resComp.KaSeqnum  
 FROM INVENTOR i  
INNER JOIN ReservedComponantList resComp ON  i.UNIQ_KEY = resComp.UniqKey  
Inner join INVT_RES res ON res.UNIQ_KEY = i.UNIQ_KEY and res.WONO = @wono and res.KaSeqnum =resComp.KASEQNUM AND res.KaSeqnum=@kaSeqNum  
LEFT OUTER JOIN invtlot lot ON ISNULL(lot.W_KEY,'') =ISNULL(res.w_key,'') AND  ISNULL(lot.lotcode,'') = ISNULL(res.lotcode,'')    
AND  ISNULL(lot.EXPDATE,1) = ISNULL(res.EXPDATE,1) AND  ISNULL(lot.REFERENCE,'') = ISNULL(res.REFERENCE,'')   
GROUP BY res.W_KEY,res.ExpDate,res.Reference,res.LotCode,res.PONUM,resComp.UniqKey,resComp.IsLotted,resComp.useipkey,resComp.serialyes,resComp.KaSeqnum  
HAVING SUM(QTYALLOC) > 0  
  
--Getting Reserved IPkey Data for the WoNo   
INSERT INTO @ReserevedIpKeyData  
SELECT DISTINCT ware.invtres_no, resIP.IPKEYUNIQUE,SUM(resIP.qtyAllocated) AS QtyIssued  
FROM inventor i   
INNER JOIN @WarehouseLotReserevedData ware ON i.UNIQ_KEY = ware.UNIQ_KEY   
INNER JOIN INVT_RES res ON i.UNIQ_KEY = res.UNIQ_KEY and res.WONO = @wono and res.KaSeqnum =ware.KASEQNUM AND res.KaSeqnum=@kaSeqNum  
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
INNER JOIN @WarehouseLotReserevedData ware ON i.UNIQ_KEY = ware.UNIQ_KEY   
INNER JOIN INVT_RES res ON i.UNIQ_KEY = res.UNIQ_KEY and res.WONO = @wono and res.KaSeqnum =ware.KASEQNUM and res.REFINVTRES='' AND  
res.w_key = ware.w_key  and  ISNULL(res.ExpDate,1) = ISNULL(ware.ExpDate,1) and res.Reference = ware.Reference and res.LotCode = ware.LotCode and res.PONUM = ware.PONUM  
INNER JOIN iReserveSerial resSer ON res.invtres_no = resSer.invtres_no AND resSer.isDeallocate = 0   
INNER JOIN INVTSER ser ON resSer.SERIALUNIQ = ser.SERIALUNIQ    
AND (ser.ID_VALUE = ware.w_key and ser.ID_KEY='W_key') AND ISNULL(ser.ExpDate,1) = ISNULL(ware.ExpDate,1) and ser.Reference = ware.Reference and ser.LotCode = ware.LotCode and ser.PONUM = ware.PONUM  
WHERE res.wono =@wono   
AND resSer.isDeallocate = 0  
AND ser.ISRESERVED =1  
AND ser.RESERVEDFLAG = 'KaSeqnum'  
AND ser.RESERVEDNO = @kaSeqNum  
  
--select * from @ReserevedSerialData  
  
        -- find allocated records  
  
  ;with totalReserved2Wo  
  as  
  (  
   SELECT r.DATETIME, r.Invtres_no as totalLink,t.W_key,@wono AS wono,r.LotCode,r.ExpDate,r.REFERENCE,r.PoNum,r.qtyalloc,r.fk_PrjUnique,r.UniqueLn ,t.KaSeqnum,  
   t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.IsLotted,t.Invtres_no AS HeaderKey   
   FROM @WarehouseLotReserevedData t   
   inner join Invt_res r ON   ((t.kaseqnum=' ' and  r.wono=@wono) or (t.kaseqnum<>' ' and  r.kaseqnum=t.kaseqnum))  
   AND t.w_key = r.w_key AND  t.lotcode = r.lotcode  AND  ISNULL(t.EXPDATE,1) = ISNULL(r.EXPDATE,1)   
   AND  t.REFERENCE = r.REFERENCE AND t.PONUM =r.PONUM AND t.kaseqnum =r.kaseqnum  
   WHERE r.refinvtres=' '  
  UNION   
   SELECT r.DATETIME, r.Invtres_no AS totalLink,t.W_key,@wono AS wono,r.LotCode,r.ExpDate,r.REFERENCE,r.PoNum,r.qtyalloc,r.fk_PrjUnique,r.UniqueLn ,t.KaSeqnum,  
   t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.IsLotted,t.Invtres_no AS HeaderKey   
   FROM @WarehouseLotReserevedData t   
   inner join Invt_res r ON r.wono=@wono  
   AND t.w_key = r.w_key AND  t.lotcode = r.lotcode  AND  ISNULL(t.EXPDATE,1) = ISNULL(r.EXPDATE,1)   
   AND  t.REFERENCE = r.REFERENCE AND t.PONUM =r.PONUM AND t.kaseqnum =r.kaseqnum  
   WHERE r.refinvtres=' '  
  UNION  
   SELECT r.DATETIME, r.Invtres_no AS totalLink,t.W_key,w.wono ,r.LotCode,r.ExpDate,r.REFERENCE,r.PoNum,r.qtyalloc,r.fk_PrjUnique,r.UniqueLn ,t.KaSeqnum,  
   t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.IsLotted,t.Invtres_no AS HeaderKey   
   from @WarehouseLotReserevedData t   
   inner join woentry w ON w.wono=@wono  
   inner join Invt_res r ON r.FK_PRJUNIQUE=w.PRJUNIQUE  
   AND t.w_key = r.w_key AND  t.lotcode = r.lotcode  AND  ISNULL(t.EXPDATE,1) = ISNULL(r.EXPDATE,1)   
   AND  t.REFERENCE = r.REFERENCE AND t.PONUM =r.PONUM AND t.kaseqnum =r.kaseqnum  
   WHERE r.refinvtres=' ' and r.wono=' ' and w.PRJUNIQUE<>' '  
  UNION  
   SELECT r.DATETIME, r.REFINVTRES AS totalLink, r.W_key,r.wono,r.LotCode,r.ExpDate,r.REFERENCE,r.PoNum,r.qtyalloc,r.Fk_PrjUnique,r.UniqueLn ,r.KaSeqnum,  
   t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.IsLotted,t.Invtres_no AS HeaderKey   
   FROM Invt_res r  
   inner join  @WarehouseLotReserevedData t ON ((t.kaseqnum=' ' and  r.wono=@wono) or (t.kaseqnum<>' ' and  r.kaseqnum=t.kaseqnum))  
   AND t.w_key = r.w_key AND  t.lotcode = r.lotcode  AND  ISNULL(t.EXPDATE,1) = ISNULL(r.EXPDATE,1)   
   AND  t.REFERENCE = r.REFERENCE AND t.PONUM =r.PONUM AND t.kaseqnum =r.kaseqnum  
   WHERE r.refinvtres<>' '  
  UNION  
   SELECT   
   r.DATETIME, REFINVTRES AS totalLink, r.W_key,r.wono,r.LotCode,r.ExpDate,r.REFERENCE,r.PoNum,r.qtyalloc,r.Fk_PrjUnique,r.UniqueLn ,r.KaSeqnum,  
   t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.IsLotted,t.Invtres_no AS HeaderKey  
   FROM Invt_res r  
   inner join  @WarehouseLotReserevedData t ON  r.wono=@wono  
   AND t.w_key = r.w_key AND  t.lotcode = r.lotcode  AND  ISNULL(t.EXPDATE,1) = ISNULL(r.EXPDATE,1)   
   AND  t.REFERENCE = r.REFERENCE AND t.PONUM =r.PONUM AND t.kaseqnum =r.kaseqnum  
   WHERE r.refinvtres<>' '  
  UNION  
   SELECT r.DATETIME, REFINVTRES AS totalLink,t.W_key,w.wono,r.LotCode,r.ExpDate,r.REFERENCE,r.PoNum,r.qtyalloc,r.fk_PrjUnique,r.UniqueLn ,t.KaSeqnum,  
   t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.IsLotted,t.Invtres_no AS HeaderKey   
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
  QtyIssued,UseIpkey,serialyes,IsLotted,HeaderKey   
  FROM totalReserved2Wo  
  GROUP BY totalLink,w_key,uniq_key,wono,lotcode,expdate,REFERENCE,ponum,fk_prjUnique,UniqueLn,QtyIssued,KaSeqnum,UseIpkey,serialyes,IsLotted,HeaderKey --Rajendra K :09/22/2017 : Added column in temp table for Issue quantities  
  HAVING SUM(qtyAlloc)<>0  
  ),  
  deallocateTable  
  AS  
  (  
  SELECT ROW_NUMBER() over (partition by totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono order by kaseqnum) as lot, totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,  
  fk_prjUnique,UniqueLn,KaSeqnum,Allocated,UseIpkey,serialyes,IsLotted,  
  SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono ORDER BY kaseqnum DESC, wono,fk_prjUnique) AS qtyAllocated,   
  SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono ORDER BY kaseqnum DESC, wono,fk_prjUnique RANGE UNBOUNDED PRECEDING) - QtyIssued AS BalanceAfterIssued,  
  CASE WHEN SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono ORDER BY kaseqnum DESC, wono,fk_prjUnique RANGE UNBOUNDED PRECEDING) - QtyIssued<=0   
   THEN SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono ORDER BY kaseqnum DESC, wono,fk_prjUnique RANGE UNBOUNDED PRECEDING)   
   WHEN SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono ORDER BY kaseqnum DESC, wono,fk_prjUnique RANGE UNBOUNDED PRECEDING) - QtyIssued>= 0  THEN QtyIssued   
   ELSE 0 end AS deallocateQty,dbo.fn_GenerateUniqueNumber() AS newinvtres_no   
   ,HeaderKey   
   FROM composed  
  )  
  --temp TABLE for parts do not have sid,serial  
  ,WithoutSIDSerialPartsData as  
  (  
      select * from deallocateTable where UseIpkey =0 and serialyes = 0  
  )      
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
     HeaderKey   
   FROM WithoutSIDSerialPartsData AS PL   
   left outer join @WarehouseLotReserevedData as PC ON PC.W_key = PL.w_key and pc.LOTCODE =pl.LOTCODE and ISNULL(pc.EXPDATE,1 )= ISNULL(pl.EXPDATE,1) and pc.REFERENCE =pl.REFERENCE and pc.PONUM =pl.PONUM  
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
     ,PL.HeaderKey   
   FROM deallocateTableWithQty AS CTE  
    INNER JOIN WithoutSIDSerialPartsData AS PL ON PL.W_key = CTE.w_key and PL.LOTCODE =CTE.LOTCODE and ISNULL(PL.EXPDATE,1 )= ISNULL(CTE.EXPDATE,1) and PL.REFERENCE =CTE.REFERENCE and PL.PONUM =CTE.PONUM and PL.Lot = CTE.Lot + 1  
  )  
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
     BalanceAfterIssued,issuIp.ipKeyUnique,HeaderKey   
  )  
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
     PL.BalanceAfterIssued,PL.deallocateQty,PL.newinvtres_no,HeaderKey   
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
     PL.BalanceAfterIssued,PL.deallocateQty,PL.newinvtres_no,PL.HeaderKey  
   FROM deallocateIpKeyTableWithQty AS CTE  
    INNER JOIN deallocateIpKeyTable AS PL ON   
    PL.ipKeyUnique =CTE.ipKeyUnique   
     and PL.Lot = CTE.Lot + 1  
  )  
  
  ,deallocateSerialTable  
  as  
  (  
     select de.lot,totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,fk_prjUnique,UniqueLn,de.KaSeqnum,Allocated,UseIpkey,serialyes,IsLotted,de.qtyAllocated,  
     BalanceAfterIssued,-count(issuserial.serialuniq) as deallocateQty,dbo.fn_GenerateUniqueNumber() as newinvtres_no,HeaderKey   
     from deallocateTable de  
     inner join ireserveSerial resser on de.totalLink = resser.invtres_no  
     inner join @ReserevedSerialData issuserial on issuserial.serialuniq = resser.serialuniq and isDeallocate =0  
     group by de.lot, totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,fk_prjUnique,UniqueLn,de.KaSeqnum,Allocated,UseIpkey,serialyes,IsLotted,de.qtyAllocated,  
     BalanceAfterIssued,HeaderKey  
  )  
   
  ,dataNeedtoInsertInInvtRes as  
  (  
     SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,  
    CASE   
     WHEN RemainingDemand >0 THEN -deallocateQty  
     WHEN RemainingDemand = 0 and allocated-runningquantity > 0 THEN -(allocated-runningquantity)  
    END AS deallocateQty  
    ,totalLink,UniqueLn,UseIpkey,serialyes,IsLotted  
    ,HeaderKey   
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
    ,totalLink,UniqueLn,UseIpkey,serialyes,IsLotted,HeaderKey   
   FROM deallocateIpKeyTableWithQty   
   where (RemainingDemand >0 OR (RemainingDemand = 0 AND allocated-runningquantity >0))  
  )  
    
  -- Put All data in temp TABLE for which we have to put entry in invt_res  
  INSERT INTO @WarehouseLotAllData (w_key,UNIQ_KEY,wono,newinvtres_no,LotCode,ExpDate,REFERENCE,PONUM,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,UNIQUELN,IsLotted,useipkey,serialyes,HeaderKey)   
  SELECT w_key,uniq_key,wono,dbo.fn_GenerateUniqueNumber() As newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,Sum(deallocateQty),  
  totalLink,UNIQUELN,IsLotted,useipkey,serialyes,HeaderKey   
  FROM dataNeedtoInsertInInvtRes   
  GROUP BY w_key,uniq_key,wono,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,totalLink,UNIQUELN,IsLotted,useipkey,serialyes,HeaderKey   
  
  --If data exists without sid/serial then put entry in invt_res TABLE  
  IF(Exists((SELECT 1 FROM @WarehouseLotReserevedData where useipkey =0 and serialyes =0)))  
  BEGIN  
   -- un-llocate header and save new invtres_no into the @intoInvtRes TABLE variable  
   INSERT INTO invt_res (w_key,uniq_key,wono,invtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,qtyAlloc,refinvtres,fk_userid,UNIQUELN,SAVEINIT)  
   SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,@userid,UniqueLn,@Initials  
    FROM @WarehouseLotAllData where useipkey =0 and serialyes =0 AND kaseqnum=@kaSeqNum  
  
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
   FROM @WarehouseLotAllData where serialyes =1 AND kaseqnum=@kaSeqNum  
  
   INSERT INTO iReserveSerial (invtres_no,serialuniq,ipkeyunique,kaseqnum,isDeallocate)  
    SELECT res.invtres_no,rs.serialuniq,rs.ipkeyunique,rs.kaseqnum,1   
    FROM @intoInvtRes res   
    INNER JOIN iReserveSerial RS on res.refinvtres=rs.invtres_no AND rs.kaseqnum=@kaSeqNum  
       INNER JOIN @ReserevedSerialData iserial on rs.serialuniq=iserial.serialuniq  
  
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
   FROM @WarehouseLotAllData WHERE useipkey =1 and serialyes =0 AND kaseqnum=@kaSeqNum  
       
   INSERT INTO iReserveIpKey (invtres_no,qtyAllocated,ipkeyunique,kaseqnum)  
   SELECT res.invtres_no,-ipissue.QtyIssued,rip.ipkeyunique,rip.KaSeqnum   
   FROM @intoInvtRes res   
   INNER JOIN iReserveIpKey RIP ON res.refinvtres=rip.invtres_no   
   INNER JOIN @ReserevedIpKeyData ipissue ON rip.ipkeyunique=ipissue.ipKeyUnique  
   WHERE RIP.KaSeqnum=@kaSeqNum  
     
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