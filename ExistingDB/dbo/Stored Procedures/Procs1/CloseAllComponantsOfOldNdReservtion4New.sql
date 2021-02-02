  
-- =============================================    
-- Author:Vijay G   
-- Create date: 07/10/2019  
-- Description :Used to unreserve qty of Old wo for all component and qty reservation for newly created work order
-- Modified Vijay G: 12/30/2019 added new condition of @newWONo   
-- =============================================    
CREATE PROCEDURE [dbo].[CloseAllComponantsOfOldNdReservtion4New]                        
@wono VARCHAR(10),           
@newUniqKey VARCHAR(10),                      
@newWONo VARCHAR(10),                    
@userid UNIQUEIDENTIFIER= null                    
                    
AS                      
BEGIN                      
SET NoCount ON;     
                   
BEGIN TRY                      
BEGIN TRANSACTION                       
 -- get ready to handle any errors                      
 DECLARE @ErrorMessage NVARCHAR(4000);                      
 DECLARE @ErrorSeverity INT;                      
 DECLARE @ErrorState INT;                      
                            
 DECLARE @WarehouseLotReserevedData TABLE (invtres_no CHAR(10),UNIQ_KEY CHAR(10),w_key CHAR(10),ExpDate SMALLDATETIME,REFERENCE CHAR(12),LotCode NVARCHAR(25),PONUM CHAR(15)                                    
 ,QtyIssued NUMERIC(12,2),IsLotted BIT,useipkey BIT,serialyes BIT,kaseqnum CHAR(10))                                    
                                     
 --temp table @WarehouseLotReserevedData for All data which we have to insert in invt_Res with warehouse lot info                                    
                                 
 DECLARE @WarehouseLotAllData TABLE (w_key CHAR(10),UNIQ_KEY CHAR(10),wono CHAR(10),newinvtres_no CHAR(10),LotCode NVARCHAR(25),ExpDate SMALLDATETIME,REFERENCE CHAR(12),PONUM CHAR(15),                                    
 FK_PRJUNIQUE CHAR(10),kaseqnum CHAR(10),deallocateQty numeric(12,2), totalLink CHAR(10), UNIQUELN CHAR(10),IsLotted BIT,useipkey BIT,serialyes BIT,HeaderKey CHAR(10))                                     
                                   
    DECLARE @NewWarehouseLotAllData TABLE (w_key CHAR(10),UNIQ_KEY CHAR(10),wono CHAR(10),newinvtres_no CHAR(10),LotCode NVARCHAR(25),ExpDate SMALLDATETIME,REFERENCE CHAR(12),PONUM CHAR(15),                                    
 FK_PRJUNIQUE CHAR(10),kaseqnum CHAR(10),deallocateQty numeric(12,2),totalLink CHAR(10), UNIQUELN CHAR(10),IsLotted BIT,useipkey BIT,serialyes BIT,HeaderKey CHAR(10),DEPT_ID VARCHAR(20))                                     
                             
 DECLARE @TempWarehouseLotAllData TABLE (w_key CHAR(10),UNIQ_KEY CHAR(10),wono CHAR(10),newinvtres_no CHAR(10),LotCode NVARCHAR(25),ExpDate SMALLDATETIME,REFERENCE CHAR(12),PONUM CHAR(15),                                    
 FK_PRJUNIQUE CHAR(10),kaseqnum CHAR(10),deallocateQty numeric(12,2), totalLink CHAR(10), UNIQUELN CHAR(10),IsLotted BIT,useipkey BIT,serialyes BIT,HeaderKey CHAR(10))                                     
                           
                    
 --Temp TABLE for ReserveIpKey                                    
 DECLARE @ReserevedIpKeyData TABLE (invtisu_no CHAR(10),IPKEYUNIQUE CHAR(10),QtyIssued NUMERIC(12,2))                                    
                                     
 --Temp TABLE for IssueSerial                                    
 DECLARE @ReserevedSerialData TABLE (invtisu_no CHAR(10),IPKEYUNIQUE CHAR(10),SERIALUNIQ CHAR(10),SERIALNO CHAR(30),kaseqnum VARCHAR(10))                                    
                                       
 -- declare "output into TABLE" and use it when insert into invt_res                                    
 DECLARE @intoInvtRes TABLE (invtres_no CHAR(10),refinvtres CHAR(10),qtyAlloc NUMERIC(12,2),KaSeqnum VARCHAR(10))                                    
                                                    
                                     
 Declare @Initials varCHAR(8)                         
 SELECT @Initials = (SELECT Initials from aspnet_Profile WHERE UserId =@userid)                                    
                                     
 ;WITH ReservedComponantList AS (                                    
  SELECT i.UNIQ_KEY AS UniqKey,p.LOTDETAIL AS IsLotted, i.useipkey, i.serialyes, k.allocatedQty AS QtyIssued,KaSeqnum                                    
  FROM kamain k                                    
  INNER JOIN WOENTRY w ON w.WONO =k.WONO                                    
  INNER JOIN inventor i ON k.uniq_key=i.uniq_key                                    
  LEFT JOIN PARTTYPE p ON  p.PART_CLASS = i.PART_CLASS  AND p.PART_TYPE = i.PART_TYPE                                   
  WHERE  k.wono= @wono           
  AND k.allocatedQty > 0                                    
  GROUP BY   i.useipkey, i.serialyes, i.UNIQ_KEY ,k.allocatedQty,p.LOTDETAIL,KaSeqnum                                    
  )                                    
                                  
  INSERT INTO @WarehouseLotReserevedData                         
  SELECT Distinct dbo.fn_GenerateUniqueNumber() AS invtres_no,resComp.UniqKey,res.w_key,res.ExpDate,res.Reference,res.LotCode,    
   res.PONUM,SUM(QTYALLOC) AS 'QtyIssued',resComp.IsLotted,resComp.useipkey,resComp.serialyes,resComp.KaSeqnum                                    
   FROM INVENTOR i                                    
                                     
  INNER JOIN ReservedComponantList resComp ON  i.UNIQ_KEY = resComp.UniqKey                                    
  Inner join INVT_RES res ON res.UNIQ_KEY = i.UNIQ_KEY and res.WONO = @wono and res.KaSeqnum =resComp.KASEQNUM                                     
  LEFT OUTER JOIN invtlot lot ON ISNULL(lot.W_KEY,'') =ISNULL(res.w_key,'') AND  ISNULL(lot.lotcode,'') = ISNULL(res.lotcode,'')                                      
  AND  ISNULL(lot.EXPDATE,1) = ISNULL(res.EXPDATE,1) AND  ISNULL(lot.REFERENCE,'') = ISNULL(res.REFERENCE,'')                                     
  GROUP BY res.W_KEY,res.ExpDate,res.Reference,res.LotCode,res.PONUM,resComp.UniqKey,resComp.IsLotted,resComp.useipkey,resComp.serialyes,resComp.KaSeqnum                                     
  HAVING SUM(QTYALLOC) > 0                                    
                                  
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
                                  
  --Getting Reserved Serial Data for the WoNo                                    
  INSERT INTO @ReserevedSerialData                                    
  SELECT DISTINCT ware.invtres_no,ser.IPKEYUNIQUE,ser.SERIALUNIQ,ser.SERIALNO ,ware.kaseqnum                                    
  FROM inventor i                                     
  INNER JOIN @WarehouseLotReserevedData ware ON i.UNIQ_KEY = ware.UNIQ_KEY                                     
  INNER JOIN INVT_RES res ON i.UNIQ_KEY = res.UNIQ_KEY and res.WONO = @wono and res.KaSeqnum =ware.KASEQNUM                                    
  INNER JOIN iReserveSerial resSer ON res.invtres_no = resSer.invtres_no                                     
  INNER JOIN INVTSER ser ON resSer.SERIALUNIQ = ser.SERIALUNIQ                                    
  AND ISNULL(ser.ExpDate,1) = ISNULL(ware.ExpDate,1) and ser.Reference = ware.Reference and ser.LotCode = ware.LotCode and ser.PONUM = ware.PONUM                        
  WHERE res.wono =@wono                                     
  AND resSer.isDeallocate = 0                                    
  AND ser.ISRESERVED =1                      
  AND ser.RESERVEDFLAG = 'KaSeqnum'                                    
  AND ser.RESERVEDNO = ware.kaseqnum                                    
                        
                                
  -- find allocated records                                    
                                
  ;with totalReserved2Wo                                    
  AS                                    
  (                                   
   SELECT r.DATETIME, r.Invtres_no AS totalLink,t.W_key,@wono AS wono,r.LotCode,r.ExpDate,r.REFERENCE,r.PoNum,r.qtyalloc,r.fk_PrjUnique,r.UniqueLn ,t.KaSeqnum,                                    
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
  SELECT totalLink,w_key,uniq_key,wono,lotcode,expdate,REFERENCE,ponum,fk_prjUnique,UniqueLn,KaSeqnum,SUM(qtyAlloc) AS Allocated,                                    
  QtyIssued,UseIpkey,serialyes,IsLotted,HeaderKey                                     
  FROM totalReserved2Wo                   
  GROUP BY totalLink,w_key,uniq_key,wono,lotcode,expdate,REFERENCE,ponum,fk_prjUnique,UniqueLn,QtyIssued,KaSeqnum,UseIpkey,serialyes,IsLotted,HeaderKey                                     
  HAVING SUM(qtyAlloc)<>0                                    
  ),                                    
  deallocateTable                                    
  AS                                    
  (                     
  SELECT ROW_NUMBER() OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono     
          ORDER BY kaseqnum) AS lot, totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,                                    
             fk_prjUnique,UniqueLn,KaSeqnum,Allocated,UseIpkey,serialyes,IsLotted,                                    
  SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono     
          ORDER BY kaseqnum DESC, wono,fk_prjUnique) AS qtyAllocated,                                     
  SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono     
          ORDER BY kaseqnum DESC, wono,fk_prjUnique RANGE UNBOUNDED PRECEDING) - QtyIssued AS BalanceAfterIssued,                                    
  CASE WHEN SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono     
          ORDER BY kaseqnum DESC, wono,fk_prjUnique RANGE UNBOUNDED PRECEDING) - QtyIssued<=0                                     
   THEN SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono     
          ORDER BY kaseqnum DESC, wono,fk_prjUnique RANGE UNBOUNDED PRECEDING)                                     
   WHEN SUM(allocated) OVER (PARTITION BY totallink,w_key,lotcode,expdate,REFERENCE,ponum,wono     
   ORDER BY kaseqnum DESC, wono,fk_prjUnique RANGE UNBOUNDED PRECEDING) - QtyIssued>= 0  THEN QtyIssued                                     
   ELSE 0 end AS deallocateQty,dbo.fn_GenerateUniqueNumber() AS newinvtres_no                                     
   ,HeaderKey                                   
   FROM composed                                    
  )                                    
                      
  --temp TABLE for parts do not have sid,serial           
  ,WithoutSIDSerialPartsData AS                                    
  (                                    
      select * from deallocateTable WHERE UseIpkey =0 and serialyes = 0                                    
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
 left outer join @WarehouseLotReserevedData AS PC ON PC.W_key = PL.w_key and pc.LOTCODE =pl.LOTCODE     
 and ISNULL(pc.EXPDATE,1 )= ISNULL(pl.EXPDATE,1) and pc.REFERENCE =pl.REFERENCE and pc.PONUM =pl.PONUM                                    
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
   INNER JOIN WithoutSIDSerialPartsData AS PL ON PL.W_key = CTE.w_key and PL.LOTCODE =CTE.LOTCODE     
   and ISNULL(PL.EXPDATE,1 )= ISNULL(CTE.EXPDATE,1) and PL.REFERENCE =CTE.REFERENCE and PL.PONUM =CTE.PONUM and PL.Lot = CTE.Lot + 1                               
      
        
         
 )                                    
                               
 ,deallocateIpKeyTable                                    
 AS                                    
 (                                    
    select ROW_NUMBER() over (partition by w_key,lotcode,expdate,REFERENCE,ponum,wono,issuIp.ipkeyunique order by de.kaseqnum) AS lot,                                
    totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,fk_prjUnique,UniqueLn,de.KaSeqnum,Allocated,UseIpkey,serialyes,IsLotted,de.qtyAllocated,                                    
    BalanceAfterIssued,sum(issuIp.QtyIssued) AS deallocateQty,issuIp.ipKeyUnique,dbo.fn_GenerateUniqueNumber() AS newinvtres_no,HeaderKey                                     
  from deallocateTable de                                     
    inner join ireserveipkey resip on de.totalLink = resip.invtres_no                                    
    inner join @ReserevedIpKeyData issuIp on issuIp.ipkeyunique = resip.ipkeyunique                                    
    WHERE UseIpkey =1 and serialyes = 0                                    
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
  left outer join @ReserevedIpKeyData  AS PC ON pc.ipKeyUnique =pl.ipKeyUnique                                    
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
   AS(                                    
         SELECT de.lot,totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,fk_prjUnique,UniqueLn,de.KaSeqnum,                    
   Allocated,UseIpkey,serialyes,IsLotted,de.qtyAllocated,BalanceAfterIssued,-count(issuserial.serialuniq) AS deallocateQty,                    
   dbo.fn_GenerateUniqueNumber() AS newinvtres_no,HeaderKey                                     
         FROM deallocateTable de                    
         inner join ireserveSerial resser ON de.totalLink = resser.invtres_no                                    
         inner join @ReserevedSerialData issuserial ON issuserial.serialuniq = resser.serialuniq and isDeallocate =0                                    
         GROUP BY de.lot, totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,fk_prjUnique,UniqueLn,de.KaSeqnum,Allocated,    
   UseIpkey,serialyes,IsLotted,de.qtyAllocated,BalanceAfterIssued,HeaderKey)                                    
                                        
 ,dataNeedtoInsertInInvtRes AS                                    
  (                                    
   SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,                                    
   CASE                                     
         WHEN RemainingDemand >0 THEN -deallocateQty                                    
         WHEN RemainingDemand = 0 and allocated-runningquantity > 0 THEN -(allocated-runningquantity)                                    
   END AS deallocateQty                                    
   ,totalLink,UniqueLn,UseIpkey,serialyes,IsLotted             
        ,HeaderKey                                   
  FROM deallocateTableWithQty                                     
  WHERE (RemainingDemand >0 OR (RemainingDemand = 0 AND allocated-runningquantity >0))                         
        UNION ALL                                    
        SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,UniqueLn,    
  UseIpkey,serialyes,IsLotted,HeaderKey                                      
        FROM deallocateSerialTable                                    
      UNION ALL                                    
         SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,                                    
        CASE                                     
         WHEN RemainingDemand >0 THEN -deallocateQty                                    
         WHEN RemainingDemand = 0 and allocated-runningquantity > 0 THEN -(allocated-runningquantity)                 
        END AS deallocateQty                                    
        ,totalLink,UniqueLn,UseIpkey,serialyes,IsLotted,HeaderKey                                   
       FROM deallocateIpKeyTableWithQty                                     
       WHERE (RemainingDemand >0 OR (RemainingDemand = 0 AND allocated-runningquantity >0))                                    
      )                                    
                                    
     INSERT INTO @TempWarehouseLotAllData (w_key,UNIQ_KEY,wono,newinvtres_no,LotCode,ExpDate,REFERENCE,PONUM,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,
	 UNIQUELN,IsLotted,useipkey,serialyes,HeaderKey)                     
     SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,UNIQUELN,IsLotted,    
     useipkey,serialyes,HeaderKey              
     FROM dataNeedtoInsertInInvtRes                      
                                    
	INSERT INTO @WarehouseLotAllData (w_key,UNIQ_KEY,wono,newinvtres_no,LotCode,ExpDate,REFERENCE,PONUM,FK_PRJUNIQUE,kaseqnum,                    
	deallocateQty,totalLink,UNIQUELN,IsLotted,useipkey,serialyes,HeaderKey)                       
	SELECT w_key,uniq_key,wono,dbo.fn_GenerateUniqueNumber() AS newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,Sum(deallocateQty),                      
	totalLink,UNIQUELN,IsLotted,useipkey,serialyes,HeaderKey                       
	FROM @TempWarehouseLotAllData                       
	GROUP BY w_key,uniq_key,wono,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,totalLink,UNIQUELN,IsLotted,useipkey,serialyes,HeaderKey                      
                           
  --close all components of old workorder                        
  --If data exists without sid/serial then put entry in invt_res TABLE                      
 IF(EXISTS((SELECT 1 FROM @WarehouseLotReserevedData WHERE useipkey =0 AND serialyes =0)))                      
  BEGIN                      
     -- un-llocate header and save new invtres_no into the @intoInvtRes TABLE variable                      
     INSERT INTO invt_res (w_key,uniq_key,wono,invtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,qtyAlloc,refinvtres,fk_userid,UNIQUELN,SAVEINIT)                      
     SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,@userid,UniqueLn,@Initials                      
     FROM @WarehouseLotAllData WHERE useipkey =0 and serialyes =0            
 END                      
                      
 IF (EXISTS (SELECT 1 FROM @ReserevedSerialData))                      
 BEGIN                      
  -- Clear the @intoInvtRes TABLE                      
  Delete from @intoInvtRes                      
                      
  --insert data in invt_res for the serialized item                      
  INSERT INTO invt_res (w_key,uniq_key,wono,invtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,qtyAlloc,refinvtres,fk_userid,UNIQUELN,SAVEINIT)                      
  OUTPUT inserted.INVTRES_NO,inserted.refinvtres,inserted.QTYALLOC ,inserted.KaSeqnum                     
  into @intoInvtRes                      
  SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,@userid,UniqueLn,@Initials                      
  FROM @WarehouseLotAllData WHERE serialyes =1                      
                      
  INSERT INTO iReserveSerial (invtres_no,serialuniq,ipkeyunique,kaseqnum,isDeallocate)                      
  SELECT res.invtres_no,rs.serialuniq,rs.ipkeyunique,rs.kaseqnum,1             
  FROM @intoInvtRes res                       
  INNER JOIN iReserveSerial RS ON res.refinvtres=rs.invtres_no                      
  INNER JOIN @ReserevedSerialData iserial ON rs.serialuniq=iserial.serialuniq                      
 END                      
             
 IF (EXISTS (SELECT 1 FROM @ReserevedIpKeyData))                      
 BEGIN                      
  -- Clear the @intoInvtRes TABLE                      
  Delete from @intoInvtRes                      
                      
  --insert data in invt_res for the item having useipkey =1 and serialyes =0                      
  INSERT INTO invt_res (w_key,uniq_key,wono,invtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,qtyAlloc,refinvtres,fk_userid,UNIQUELN,SAVEINIT)                      
  OUTPUT inserted.INVTRES_NO,inserted.refinvtres,inserted.QTYALLOC ,inserted.KaSeqnum                     
  INTO @intoInvtRes                      
  SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,@userid,UniqueLn,@Initials                      
  FROM @WarehouseLotAllData WHERE useipkey =1 and serialyes =0                   
                        
  INSERT INTO iReserveIpKey (invtres_no,qtyAllocated,ipkeyunique,kaseqnum)                      
  SELECT res.invtres_no,-ipissue.QtyIssued,rip.ipkeyunique,rip.KaSeqnum                       
  FROM @intoInvtRes res                       
  INNER JOIN iReserveIpKey RIP ON res.refinvtres=rip.invtres_no                      
  INNER JOIN @ReserevedIpKeyData ipissue ON rip.ipkeyunique=ipissue.ipKeyUnique                      
 END                       
                  
            
 DECLARE @tKamain tKamain                            
 INSERT INTO @tKamain EXEC [KitBomInfoView] @gWono=@newWono                     
 -- Used to qty reservation of new wo         
 INSERT INTO @NewWarehouseLotAllData (w_key,UNIQ_KEY,wono,newinvtres_no,LotCode,ExpDate,REFERENCE,PONUM,FK_PRJUNIQUE,kaseqnum,DEPT_ID ,totalLink,                                
                                        deallocateQty,UNIQUELN,IsLotted,useipkey,serialyes,HeaderKey)                                     
 SELECT w_key,n.uniq_key,@newWono,dbo.fn_GenerateUniqueNumber() AS newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,n.kaseqnum,k.DEPT_ID ,totalLink,                                 
 SUM(deallocateQty),UNIQUELN,IsLotted,useipkey,n.serialyes,HeaderKey                                     
 FROM @TempWarehouseLotAllData n            
 JOIN KAMAIN k on k.KASEQNUM =n.kaseqnum          
 JOIN @tKamain t ON k.DEPT_ID=t.Dept_id AND t.Uniq_key=k.UNIQ_KEY                                     
 GROUP BY w_key,n.uniq_key,n.wono,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,n.kaseqnum,k.DEPT_ID ,totalLink,UNIQUELN,IsLotted,useipkey,n.serialyes,
 HeaderKey   
	           
 --new workorder reservation                              
 IF EXISTS((SELECT 1 FROM @NewWarehouseLotAllData WHERE useipkey =0 and serialyes =0))                                   
 BEGIN                                     
  INSERT INTO invt_res (w_key,uniq_key,wono,invtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,qtyAlloc,fk_userid,UNIQUELN,SAVEINIT)                                    
  SELECT w_key,n.uniq_key,k.WONO,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,k.kaseqnum,-deallocateQty,@userid,UniqueLn,@Initials                                    
  FROM @NewWarehouseLotAllData n        
  JOIN KAMAIN k ON n.DEPT_ID=k.DEPT_ID AND n.UNIQ_KEY=k.UNIQ_KEY AND k.BOMPARENT=@newUniqKey AND k.WONO = @newWono  -- Modified Vijay G: 12/30/2019 added new condition of @newWONo       
  WHERE useipkey =0 and serialyes =0                                   
 END                       
                                     
 IF EXISTS (SELECT 1 FROM @ReserevedSerialData)  and EXISTS (SELECT 1 FROM @NewWarehouseLotAllData WHERE serialyes =1)                                   
 BEGIN                                    
  -- Clear the @intoInvtRes TABLE                                    
  DELETE FROM @intoInvtRes                                    
                                    
  --insert data in invt_res for the serialized item                                    
  INSERT INTO invt_res (w_key,uniq_key,wono,invtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,qtyAlloc,fk_userid,UNIQUELN,SAVEINIT)                                                               
  SELECT w_key,n.uniq_key,@newWono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,k.kaseqnum,-deallocateQty,@userid,UniqueLn,@Initials                                    
  FROM @NewWarehouseLotAllData n        
  JOIN KAMAIN k ON n.DEPT_ID=k.DEPT_ID AND n.UNIQ_KEY=k.UNIQ_KEY AND k.BOMPARENT=@newUniqKey AND k.WONO = @newWono  -- Modified Vijay G: 12/30/2019 added new condition of @newWONo   
   WHERE serialyes =1                      
       
  INSERT INTO @intoInvtRes  
  SELECT  newinvtres_no ,totalLink,-deallocateQty,k.KaSeqnum                         
  FROM @NewWarehouseLotAllData  n    
  JOIN KAMAIN k ON n.DEPT_ID=k.DEPT_ID AND n.UNIQ_KEY=k.UNIQ_KEY AND k.BOMPARENT=@newUniqKey    
  WHERE serialyes =1    
                                 
  INSERT INTO iReserveSerial (invtres_no,serialuniq,ipkeyunique,kaseqnum,isDeallocate)                                    
  SELECT rs.invtres_no,iserial.serialuniq,iserial.ipkeyunique,res.kaseqnum,0                   
  FROM @intoInvtRes res                       
  INNER JOIN iReserveSerial RS ON res.refinvtres=rs.invtres_no                      
  INNER JOIN @ReserevedSerialData iserial ON rs.serialuniq=iserial.serialuniq                                     
 END                                  
                                 
 IF EXISTS (SELECT 1 FROM @ReserevedIpKeyData)AND EXISTS (SELECT 1 FROM @NewWarehouseLotAllData WHERE useipkey =1 and serialyes =0)                                   
 BEGIN                                    
  -- Clear the @intoInvtRes TABLE                                    
  Delete from @intoInvtRes                                    
                                     
  --insert data in invt_res for the item having useipkey =1 and serialyes =0                                    
  INSERT INTO invt_res (w_key,uniq_key,wono,invtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,qtyAlloc,fk_userid,UNIQUELN,SAVEINIT)                                                                    
  SELECT w_key,n.uniq_key,@newWono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,k.kaseqnum,-deallocateQty,@userid,UniqueLn,@Initials                                    
  FROM @NewWarehouseLotAllData  n        
  JOIN KAMAIN k ON n.DEPT_ID=k.DEPT_ID AND n.UNIQ_KEY=k.UNIQ_KEY AND k.BOMPARENT=@newUniqKey AND k.WONO = @newWono    -- Modified Vijay G: 12/30/2019 added new condition of @newWONo       
  WHERE useipkey =1 and serialyes =0                            
       
  Insert into @intoInvtRes  
  SELECT  newinvtres_no ,totalLink,-deallocateQty,k.KaSeqnum                         
  FROM @NewWarehouseLotAllData  n    
  JOIN KAMAIN k ON n.DEPT_ID=k.DEPT_ID AND n.UNIQ_KEY=k.UNIQ_KEY AND k.BOMPARENT=@newUniqKey    
  WHERE useipkey =1 and serialyes =0      
     
                               
  INSERT INTO iReserveIpKey (invtres_no,qtyAllocated,ipkeyunique,kaseqnum)                                    
  SELECT res.invtres_no,ipissue.QtyIssued,rip.ipkeyunique,res.KaSeqnum                                 
  FROM @intoInvtRes res                                 
  INNER JOIN iReserveIpKey RIP ON res.refinvtres=rip.invtres_no                                
  INNER JOIN @ReserevedIpKeyData ipissue ON rip.ipkeyunique=ipissue.ipKeyUnique                                     
 END 
 IF @@TRANCOUNT>0                      
  COMMIT                              
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
                    
END