-- =============================================  
-- Author:  Yelena Shmidt  
-- Create date: 03/24/2016  
-- Description: this procedure will be called from the SF module and will try to de-allocate components and issue to a work order  
-- Anuj 04/15/2016: Changed rs.SerialUniq to rs.IpKeyUniq  
-- Sachin B: 06/11/2016: Changed Add query for the Insert Data in the iReserveIpKey for the Serialized Item Also  
-- Sachin B: 09/12/2016: Correct the join for issueIpKey   
-- Sachin B: 12/12/2016: Update the Code put entry in the iReserveIpKey by the  iReserveSerial table trigger  
-- Sachin B: 06/12/2017: Add temp table @PartComponant for the lot info ,UseIpkey,Serialyes and lotDetail info  
-- Sachin B: 06/12/2017: Add condition for the lotted parts also with temp table in join with invt_res  
-- Sachin B: 06/12/2017: Add temp table WithoutSIDSerialPartsData, deallocateTableWithQty for consuming the Quantity for the multiple time reserved items from the same warehouse/lot without sid serial  
-- Sachin B: 06/12/2017: put entry in the UNIQUELN in Invt_res table  
-- Sachin B: 06/13/2017: put the lot info also when we issuing reserved componants  
-- Sachin B: 06/14/2017: Add temp table deallocateSerialTable for consuming the Quantity for the multiple time reserved items  
-- Sachin B: 06/14/2017: Add temp table deallocateIpKeyTable,deallocateIpKeyTableWithQty for consuming the Quantity for the multiple time reserved items  
-- Sachin B: 06/14/2017: Add temp table @WarehouseLotReserevedData for All data which we have to insert in invt_Res  
-- Sachin B: 07/13/2017: Put Entry in saveinit column from aspnet_profile tables initials  
-- Sachin B: 08/03/2017: Add kaSeqnum in join for handle scenario if same component is available in more than one work center  
---03/02/18 YS change size of the lotcode field to 25  
-- Sachin B: 05/31/2019: Change PartType table join 
-- Sachin B: 09/13/2019: Fix the Issue Wrong Data is Populated in the IresIpkey While Auto Issue Add group by Clause
-- =============================================  
CREATE PROCEDURE [dbo].[SFDeallocateAndIssueSP]  
 -- Add the parameters for the stored procedure here  
 @Tissue tComponentsIssue2Kit READONLY,  
 @tSerailIssue tSerialsIssue2Kit READONLY,  
 @tIpkeyIssue tIpkeyIssue2Kit READONLY,  
 @wono char(10) = '',  
 @userid uniqueidentifier= null  
  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
 -- get ready to handle any errors  
 DECLARE @ErrorMessage NVARCHAR(4000);  
    DECLARE @ErrorSeverity INT;  
    DECLARE @ErrorState INT;  
 -- declare "output into table" and use it when insert into invt_res  
 declare @intoInvtRes table (invtres_no char(10),refinvtres char(10),qtyAlloc numeric(12,2))  
  
 -- Sachin B: 06/14/2017: Add temp table @WarehouseLotReserevedData for All data which we have to insert in invt_Res  
 --Temp table for warehous/lot  
  ---03/02/18 YS change size of the lotcode field to 25  
 declare @WarehouseLotReserevedData table (w_key char(10),UNIQ_KEY char(10),wono char(10),newinvtres_no char(10),LotCode nvarchar(25),ExpDate smalldatetime,REFERENCE char(12),PONUM char(15),  
 FK_PRJUNIQUE char(10),kaseqnum char(10),deallocateQty numeric(12,2), totalLink char(10), UNIQUELN char(10),IsLotted bit,useipkey bit,serialyes bit)  
  
 -- get g/l # for the wip account  
 declare @wipGL char(13)  
 select @wipGl=dbo.fn_GetWIPGl()  
  
 -- Sachin B: 07/13/2017: Put Entry in saveinit column from aspnet_profile tables initials  
 Declare @Initials varchar(8)  
 Select @Initials = (select Initials from aspnet_Profile where UserId =@userid)  
   
 BEGIN TRY  
 BEGIN TRANSACTION  
  
     -- Sachin B: 06/12/2017: Add temp table @PartComponant for the lot info ,UseIpkey,Serialyes and lotDetail info  
   Declare  @PartComponant TABLE  
  (  
   ---03/02/18 YS change size of the lotcode field to 25  
   [PkCompIssueHeader] [char](10),  
   [Uniq_key] [char](10),  
   [W_key] [char](10),  
   [QtyIssued] [numeric](12, 2),  
   [KaSeqnum] [char](10) ,  
   [UNIQ_LOT] [char](10),  
   LOTCODE [nvarchar](25),  
   PONUM [char](15),  
   EXPDATE smalldatetime null,  
   REFERENCE char(12),  
   UseIpkey bit,  
   Serialyes bit,  
   lotDetail bit  
  )    
     insert into @PartComponant ([PkCompIssueHeader],[Uniq_key],[W_key],[QtyIssued],[KaSeqnum],[UNIQ_LOT])  
  select PkCompIssueHeader,Uniq_key,W_key,QtyIssued,KaSeqnum,UNIQ_LOT from @Tissue  
     -- update the lot details  
  UPDATE p  
  set p.LOTCODE =ISNULL(lot.LOTCODE,''),  
  p.EXPDATE = lot.EXPDATE,  
  p.REFERENCE = ISNULL(lot.REFERENCE,''),  
  p.PONUM = ISNULL(lot.PONUM,'')  
  from @PartComponant p  
  LEFT OUTER JOIN invtlot lot ON p.uniq_lot=lot.uniq_lot  
  
  -- update the useipkey,serialyes,LOTDETAIL info  
  UPDATE pa  
  set pa.UseIpkey =i.useipkey,  
  pa.serialyes = i.serialyes,  
  pa.lotDetail = p.LOTDETAIL  
  from @PartComponant pa  
  INNER JOIN INVENTOR i ON pa.Uniq_key=i.Uniq_key  
  LEFT JOIN PARTTYPE p on p.PART_TYPE =i.PART_TYPE and p.PART_CLASS = i.PART_CLASS -- Sachin B: 05/31/2019: Change PartType table join  
  
  -- find allocated records  
  -- Sachin B: 06/12/2017:  add condition for the lotted parts also with temp table in join with invt_res  
  -- Sachin B: 08/03/2017: Add kaSeqnum in join for handle scenario if same component is available in more than one work center  
  ;with totalReserved2Wo  
  as  
  (  
   SELECT invt_res.DATETIME, Invtres_no as totalLink,t.W_key,@wono as wono,invt_res.LotCode,invt_res.ExpDate,invt_res.REFERENCE,  
        invt_res.PoNum,invt_res.qtyalloc,  
        invt_res.fk_PrjUnique,Invt_res.UniqueLn ,t.KaSeqnum,  
        t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.lotDetail  
   from @PartComponant t   
   inner join Invt_res on   ((t.kaseqnum=' ' and  invt_res.wono=@wono) or (t.kaseqnum<>' ' and  invt_res.kaseqnum=t.kaseqnum))  
   and t.w_key = invt_res.w_key and t.LOTCODE =invt_res.LOTCODE and ISNULL(t.EXPDATE,1 )= ISNULL(invt_res.EXPDATE,1) and t.REFERENCE =invt_res.REFERENCE   
   and t.PONUM =invt_res.PONUM AND t.kaseqnum =INVT_RES.kaseqnum  
   where invt_res.refinvtres=' '  
  UNION   
   select invt_res.DATETIME, Invtres_no as totalLink,t.W_key,@wono as wono,invt_res.LotCode,invt_res.ExpDate,invt_res.REFERENCE,  
        invt_res.PoNum,invt_res.qtyalloc,  
        invt_res.fk_PrjUnique,Invt_res.UniqueLn ,t.KaSeqnum,  
        t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.lotDetail  
   from @PartComponant t   
   inner join Invt_res on invt_res.wono=@wono  
   and t.w_key = invt_res.w_key and t.LOTCODE =invt_res.LOTCODE and ISNULL(t.EXPDATE,1 )= ISNULL(invt_res.EXPDATE,1) and t.REFERENCE =invt_res.REFERENCE   
   and t.PONUM =invt_res.PONUM AND t.kaseqnum =INVT_RES.kaseqnum  
   where invt_res.refinvtres=' '  
  UNION  
   select invt_res.DATETIME, Invtres_no as totalLink,t.W_key,w.wono ,invt_res.LotCode,invt_res.ExpDate,invt_res.REFERENCE,  
        invt_res.PoNum,invt_res.qtyalloc,  
        invt_res.fk_PrjUnique,Invt_res.UniqueLn ,t.KaSeqnum,  
        t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.lotDetail  
   from @PartComponant t   
   inner join woentry w on w.wono=@wono  
   inner join Invt_res on invt_res.FK_PRJUNIQUE=w.PRJUNIQUE  
   and t.w_key = invt_res.w_key and t.LOTCODE =invt_res.LOTCODE and ISNULL(t.EXPDATE,1 )= ISNULL(invt_res.EXPDATE,1) and t.REFERENCE =invt_res.REFERENCE   
   and t.PONUM =invt_res.PONUM AND t.kaseqnum =INVT_RES.kaseqnum  
   where invt_res.refinvtres=' ' and invt_res.wono=' ' and w.PRJUNIQUE<>' '  
  UNION  
   SELECT invt_res.DATETIME, REFINVTRES as totalLink, invt_res.W_key,invt_res.wono,invt_res.LotCode,invt_res.ExpDate,invt_res.REFERENCE,  
        invt_res.PoNum,invt_res.qtyalloc,Invt_res.Fk_PrjUnique,Invt_res.UniqueLn ,invt_res.KaSeqnum,  
        t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.lotDetail  
   from Invt_res   
   inner join  @PartComponant t on ((t.kaseqnum=' ' and  invt_res.wono=@wono) or (t.kaseqnum<>' ' and  invt_res.kaseqnum=t.kaseqnum))  
   and invt_res.w_key=t.w_key and t.LOTCODE =invt_res.LOTCODE and ISNULL(t.EXPDATE,1 )= ISNULL(invt_res.EXPDATE,1) and t.REFERENCE =invt_res.REFERENCE   
   and t.PONUM =invt_res.PONUM AND t.kaseqnum =INVT_RES.kaseqnum  
   where invt_res.refinvtres<>' '  
  UNION  
   select   
   invt_res.DATETIME, REFINVTRES as totalLink, invt_res.W_key,invt_res.wono,invt_res.LotCode,invt_res.ExpDate,invt_res.REFERENCE,  
        invt_res.PoNum,invt_res.qtyalloc,Invt_res.Fk_PrjUnique,Invt_res.UniqueLn ,invt_res.KaSeqnum,  
        t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.lotDetail  
   from Invt_res   
   inner join  @PartComponant t on  invt_res.wono=@wono  
   and invt_res.w_key=t.w_key and t.LOTCODE =invt_res.LOTCODE and ISNULL(t.EXPDATE,1 )= ISNULL(invt_res.EXPDATE,1) and t.REFERENCE =invt_res.REFERENCE   
   and t.PONUM =invt_res.PONUM AND t.kaseqnum =INVT_RES.kaseqnum  
   where invt_res.refinvtres<>' '  
  UNION  
   select invt_res.DATETIME, REFINVTRES as totalLink,t.W_key,w.wono,invt_res.LotCode,invt_res.ExpDate,invt_res.REFERENCE,  
        invt_res.PoNum,invt_res.qtyalloc,  
        invt_res.fk_PrjUnique,Invt_res.UniqueLn ,t.KaSeqnum,  
        t.QtyIssued,t.Uniq_key,t.UseIpkey,t.serialyes,t.lotDetail  
   from @PartComponant t inner join woentry w on @wono=w.wono  
   inner join Invt_res on invt_res.FK_PRJUNIQUE=w.PRJUNIQUE  
   and t.w_key = invt_res.w_key and t.LOTCODE =invt_res.LOTCODE and ISNULL(t.EXPDATE,1 )= ISNULL(invt_res.EXPDATE,1) and t.REFERENCE =invt_res.REFERENCE   
   and t.PONUM =invt_res.PONUM AND t.kaseqnum =INVT_RES.kaseqnum  
   where invt_res.refinvtres<>' ' and invt_res.wono=' ' and w.PRJUNIQUE<>' '  
  )  
  --select * from totalReserved2Wo  
  ,composed  
  as  
  (  
  select totalLink,w_key,uniq_key,wono,lotcode,expdate,REFERENCE,ponum,fk_prjUnique,KaSeqnum,sum(qtyAlloc) as Allocated,  
  QtyIssued,UniqueLn,UseIpkey,serialyes,lotDetail  
  --,issueQty-sum(qtyAlloc) as Check4MoreQty  
  from totalReserved2Wo  
  group by totalLink,w_key,uniq_key,wono,lotcode,expdate,REFERENCE,ponum,fk_prjUnique,QtyIssued,KaSeqnum,UniqueLn,UseIpkey,serialyes,lotDetail  
  having sum(qtyAlloc)<>0  
  )  
  --select * from composed  
  ,deallocateTable  
  as  
  (  
  select ROW_NUMBER() over (partition by w_key,lotcode,expdate,REFERENCE,ponum,wono order by kaseqnum) as lot, totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,  
  fk_prjUnique,UniqueLn,KaSeqnum,Allocated,UseIpkey,serialyes,lotDetail,  
  sum(allocated) over (partition by w_key,lotcode,expdate,REFERENCE,ponum,wono order by kaseqnum desc, wono,fk_prjUnique) as qtyAllocated,   
  sum(allocated) over (partition by w_key,lotcode,expdate,REFERENCE,ponum,wono order by kaseqnum desc, wono,fk_prjUnique range unbounded preceding) - QtyIssued as BalanceAfterIssued,  
  case when sum(allocated) over (partition by w_key,lotcode,expdate,REFERENCE,ponum,wono order by kaseqnum desc, wono,fk_prjUnique range unbounded preceding) - QtyIssued<0   
   then sum(allocated) over (partition by w_key,lotcode,expdate,REFERENCE,ponum,wono order by kaseqnum desc, wono,fk_prjUnique range unbounded preceding)   
   when sum(allocated) over (partition by w_key,lotcode,expdate,REFERENCE,ponum,wono order by kaseqnum desc, wono,fk_prjUnique range unbounded preceding) - QtyIssued> 0  then QtyIssued   
   else 0 end as deallocateQty,dbo.fn_GenerateUniqueNumber() as newinvtres_no   
   from composed  
  )  
  -- Sachin B: 06/12/2017: Add temp table WithoutSIDSerialPartsData, deallocateTableWithQty for consuming the Quantity for the multiple time reserved items from the same warehouse/lot without sid serial  
  --temp table for parts do not have sid,serial  
  ,WithoutSIDSerialPartsData as  
  (  
      select * from deallocateTable where UseIpkey =0 and serialyes = 0  
  )  
  --select * from WithoutSIDSerialPartsData       
  , deallocateTableWithQty AS   
  (  
    -- Start with Lot 1 for each Pool.  
    SELECT PL.w_key,PL.LOTCODE,PL.EXPDATE,PL.REFERENCE, PL.PONUM,PL.Lot, PL.Allocated,PC.QtyIssued,PL.UseIpkey,PL.serialyes,PL.lotDetail,  
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
     PL.BalanceAfterIssued,PL.deallocateQty,PL.newinvtres_no  
   FROM WithoutSIDSerialPartsData AS PL   
   left outer join @PartComponant as PC ON PC.W_key = PL.w_key and pc.LOTCODE =pl.LOTCODE and ISNULL(pc.EXPDATE,1 )= ISNULL(pl.EXPDATE,1) and pc.REFERENCE =pl.REFERENCE and pc.PONUM =pl.PONUM  
   WHERE Lot = 1  
    UNION ALL  
    -- Add the next Lot for each Pool.  
    SELECT PL.w_key,PL.LOTCODE,PL.EXPDATE,PL.REFERENCE, PL.PONUM,PL.Lot, PL.Allocated, CTE.QtyIssued,PL.UseIpkey,PL.serialyes,PL.lotDetail,  
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
   FROM deallocateTableWithQty AS CTE  
    INNER JOIN WithoutSIDSerialPartsData AS PL ON PL.W_key = CTE.w_key and PL.LOTCODE =CTE.LOTCODE and ISNULL(PL.EXPDATE,1 )= ISNULL(CTE.EXPDATE,1) and PL.REFERENCE =CTE.REFERENCE and PL.PONUM =CTE.PONUM and PL.Lot = CTE.Lot + 1  
  )  
  --select * from deallocateTableWithQty  
  -- Sachin B: 06/14/2017: Add temp table deallocateIpKeyTable,deallocateIpKeyTableWithQty for consuming the Quantity for the multiple time reserved items  
  ,deallocateIpKeyTable  
  as  
  (  
     select ROW_NUMBER() over (partition by w_key,lotcode,expdate,REFERENCE,ponum,wono,issuIp.ipkeyunique order by de.kaseqnum) as lot,  
     totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,fk_prjUnique,UniqueLn,de.KaSeqnum,Allocated,UseIpkey,serialyes,lotDetail,de.qtyAllocated,  
     BalanceAfterIssued,sum(issuIp.ipKeyQtyIssued) as deallocateQty,issuIp.ipKeyUnique,dbo.fn_GenerateUniqueNumber() as newinvtres_no   
   from deallocateTable de   
     inner join ireserveipkey resip on de.totalLink = resip.invtres_no  
     inner join @tIpkeyIssue issuIp on issuIp.ipkeyunique = resip.ipkeyunique  
     where UseIpkey =1 and serialyes = 0  
     group by --de.lot,   
     totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,fk_prjUnique,UniqueLn,de.KaSeqnum,Allocated,UseIpkey,serialyes,lotDetail,de.qtyAllocated,  
     BalanceAfterIssued,issuIp.ipKeyUnique  
  )  
  --select * from deallocateIpKeyTable  
  , deallocateIpKeyTableWithQty AS   
  (  
    -- Start with Lot 1 for each Pool.  
    SELECT PL.w_key,PL.LOTCODE,PL.EXPDATE,PL.REFERENCE, PL.PONUM,PL.Lot, PL.Allocated,PC.ipKeyQtyIssued,PL.UseIpkey,PL.serialyes,PL.lotDetail,PL.ipKeyUnique,  
   CASE  
     WHEN PC.ipKeyQtyIssued is NULL THEN PL.Allocated  
     WHEN PL.Allocated >= PC.ipKeyQtyIssued THEN PL.Allocated - PC.ipKeyQtyIssued  
     WHEN PL.Allocated < PC.ipKeyQtyIssued THEN 0  
     END AS RunningQuantity,  
   CASE  
     WHEN PC.ipKeyQtyIssued is NULL THEN 0  
     WHEN PL.Allocated >= PC.ipKeyQtyIssued THEN 0  
     WHEN PL.Allocated < PC.ipKeyQtyIssued then PC.ipKeyQtyIssued - PL.Allocated  
     END AS RemainingDemand,  
     PL.totalLink,PL.uniq_key,PL.wono,PL.fk_prjUnique,PL.UniqueLn,PL.KaSeqnum,PL.qtyAllocated,  
     PL.BalanceAfterIssued,PL.deallocateQty,PL.newinvtres_no  
   FROM deallocateIpKeyTable AS PL   
   left outer join @tIpkeyIssue  as PC ON pc.ipKeyUnique =pl.ipKeyUnique  
   WHERE Lot = 1  
    UNION ALL  
    -- Add the next Lot for each Pool.  
    SELECT PL.w_key,PL.LOTCODE,PL.EXPDATE,PL.REFERENCE, PL.PONUM,PL.Lot, PL.Allocated, CTE.ipKeyQtyIssued,PL.UseIpkey,PL.serialyes,PL.lotDetail,PL.ipKeyUnique,  
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
   FROM deallocateIpKeyTableWithQty AS CTE  
    INNER JOIN deallocateIpKeyTable AS PL ON   
    PL.ipKeyUnique =CTE.ipKeyUnique   
     and PL.Lot = CTE.Lot + 1  
  )  
  --select * from deallocateIpKeyTableWithQty  
  -- Sachin B: 06/14/2017: Add temp table deallocateSerialTable for consuming the Quantity for the multiple time reserved items  
  ,deallocateSerialTable  
  as  
  (  
     select de.lot,totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,fk_prjUnique,UniqueLn,de.KaSeqnum,Allocated,UseIpkey,serialyes,lotDetail,de.qtyAllocated,  
     BalanceAfterIssued,-count(issuserial.serialuniq) as deallocateQty,dbo.fn_GenerateUniqueNumber() as newinvtres_no   
     from deallocateTable de  
     inner join ireserveSerial resser on de.totalLink = resser.invtres_no  
     inner join @tSerailIssue issuserial on issuserial.serialuniq = resser.serialuniq and isDeallocate =0  
     group by de.lot, totalLink,w_key,uniq_key,wono,lotcode,expdate,reference,ponum,fk_prjUnique,UniqueLn,de.KaSeqnum,Allocated,UseIpkey,serialyes,lotDetail,de.qtyAllocated,  
     BalanceAfterIssued  
  )  
  --select * from deallocateSerialTable   
  ,dataNeedtoInsertInInvtRes as  
  (  
     SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,  
    CASE   
     WHEN RemainingDemand >0 THEN -Allocated  
     WHEN RemainingDemand = 0 and allocated-runningquantity > 0 THEN -(allocated-runningquantity)  
    END AS deallocateQty  
    ,totalLink,UniqueLn,UseIpkey,serialyes,lotDetail  
   FROM deallocateTableWithQty   
   where (RemainingDemand >0 OR (RemainingDemand = 0 AND allocated-runningquantity >0))  
        UNION ALL  
     SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,UniqueLn,UseIpkey,serialyes,lotDetail FROM deallocateSerialTable  
        UNION ALL  
     SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,  
    CASE   
     WHEN RemainingDemand >0 THEN -Allocated  
     WHEN RemainingDemand = 0 and allocated-runningquantity > 0 THEN -(allocated-runningquantity)  
    END AS deallocateQty  
    ,totalLink,UniqueLn,UseIpkey,serialyes,lotDetail  
   FROM deallocateIpKeyTableWithQty   
   where (RemainingDemand >0 OR (RemainingDemand = 0 AND allocated-runningquantity >0))  
  )  
  
  -- Put All data in temp table for which we have to put entry in invt_res  
  --INSERT INTO @WarehouseLotReserevedData (w_key,UNIQ_KEY,wono,newinvtres_no,LotCode,ExpDate,REFERENCE,PONUM,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,UNIQUELN,IsLotted,useipkey,serialyes)  
  --SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,UNIQUELN,lotDetail,useipkey,serialyes 
  --FROM dataNeedtoInsertInInvtRes  
  -- Sachin B: 09/13/2019: Fix the Issue Wrong Data is Populated in the IresIpkey While Auto Issue Add group by Clause
  INSERT INTO @WarehouseLotReserevedData (w_key,UNIQ_KEY,wono,newinvtres_no,LotCode,ExpDate,REFERENCE,PONUM,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,UNIQUELN,IsLotted,useipkey,serialyes)  
  SELECT w_key,uniq_key,wono,dbo.fn_GenerateUniqueNumber() As newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,Sum(deallocateQty),totalLink,UNIQUELN,lotDetail,useipkey,serialyes 
  FROM dataNeedtoInsertInInvtRes  
  GROUP BY w_key,uniq_key,wono,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,totalLink,UNIQUELN,lotDetail,useipkey,serialyes 
  
  --If data exists without sid/serial then put entry in invt_res table  
  IF(Exists((SELECT 1 FROM @WarehouseLotReserevedData where useipkey =0 and serialyes =0)))  
  BEGIN  
   -- un-llocate header and save new invtres_no into the @intoInvtRes table variable  
   -- Sachin B: 06/12/2017: put entry in the UNIQUELN in Invt_res table  
   INSERT INTO invt_res (w_key,uniq_key,wono,invtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,qtyAlloc,refinvtres,fk_userid,UNIQUELN,SAVEINIT)  
   --OUTPUT inserted.INVTRES_NO,inserted.refinvtres,inserted.QTYALLOC  
   --into @intoInvtRes  
   SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,@userid,UniqueLn,@Initials  
    FROM @WarehouseLotReserevedData where useipkey =0 and serialyes =0  
  END  
    
  if (Exists (select 1 from @tSerailIssue))  
  BEGIN  
      -- Clear the @intoInvtRes table  
      Delete from @intoInvtRes  
  
   --insert data in invt_res for the serialized item  
   -- Sachin B: 07/13/2017: Put Entry in saveinit column from aspnet_profile tables initials  
   INSERT INTO invt_res (w_key,uniq_key,wono,invtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,qtyAlloc,refinvtres,fk_userid,UNIQUELN,SAVEINIT)  
   OUTPUT inserted.INVTRES_NO,inserted.refinvtres,inserted.QTYALLOC  
      into @intoInvtRes  
   SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,@userid,UniqueLn,@Initials  
   FROM @WarehouseLotReserevedData where serialyes =1  
  
   -- un-allocate serial # if any  
   -- Anuj: Changed rs.SerialUniq to rs.IpKeyUniq  
   --select *from @tSerailIssue  
   insert into iReserveSerial (invtres_no,serialuniq,ipkeyunique,kaseqnum,isDeallocate)  
    select res.invtres_no,rs.serialuniq,rs.ipkeyunique,rs.kaseqnum,1 from @intoInvtRes res   
    inner join iReserveSerial RS on res.refinvtres=rs.invtres_no  
       inner join @tSerailIssue iserial on rs.serialuniq=iserial.serialuniq  
  
    -- Sachin B: 06/11/2016: Changed Add query for the Insert Data in the iReserveIpKey for the Serialized Item Also  
    -- Sachin B: 12/12/2016: Update the Code put entry in the iReserveIpKey by the  iReserveSerial table trigger  
    --insert into iReserveIpKey (invtres_no,qtyallocated,ipkeyunique,kaseqnum)   
    --  select res.invtres_no,-1,rip.ipkeyunique,kaseqnum from @intoInvtRes res   
    --   inner join iReserveIpKey RIP on res.refinvtres=rip.invtres_no  
    --   inner join @tSerailIssue iserial on rip.ipkeyunique=iserial.ipKeyUnique  
  
  END  
  
  IF (EXISTS (SELECT 1 FROM @tIpkeyIssue))  
  BEGIN  
      -- Clear the @intoInvtRes table  
      Delete from @intoInvtRes  
  
   --insert data in invt_res for the item having useipkey =1 and serialyes =0  
   -- Sachin B: 07/13/2017: Put Entry in saveinit column from aspnet_profile tables initials  
   INSERT INTO invt_res (w_key,uniq_key,wono,invtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,qtyAlloc,refinvtres,fk_userid,UNIQUELN,SAVEINIT)  
   OUTPUT inserted.INVTRES_NO,inserted.refinvtres,inserted.QTYALLOC  
   INTO @intoInvtRes  
   SELECT w_key,uniq_key,wono,newinvtres_no,lotcode,expdate,REFERENCE,ponum,FK_PRJUNIQUE,kaseqnum,deallocateQty,totalLink,@userid,UniqueLn,@Initials  
   FROM @WarehouseLotReserevedData WHERE useipkey =1 and serialyes =0  
       
   -- un-allocate ipeky if any  
   --select *from @tIpkeyIssue  
    INSERT INTO iReserveIpKey (invtres_no,qtyAllocated,ipkeyunique,kaseqnum)  
    SELECT res.invtres_no,-ipissue.ipKeyQtyIssued,rip.ipkeyunique,rip.KaSeqnum   
    FROM @intoInvtRes res   
    INNER JOIN iReserveIpKey RIP ON res.refinvtres=rip.invtres_no  
    INNER JOIN @tIpkeyIssue ipissue ON rip.ipkeyunique=ipissue.ipKeyUnique  
   END  
     
     -- Sachin B: 06/13/2017: put the lot info also when we issuing reserved componants  
  --- now issue, use provided PkCompIssueHeader as new invtisu_no  
  insert into invt_isu (invtisu_no,w_key,UNIQ_KEY,issuedto,qtyisu,GL_NBR,wono,UNIQMFGRHD,fk_userid,kaseqnum,LOTCODE,EXPDATE,REFERENCE,PONUM)  
   select t.PkCompIssueHeader, t.W_key,t.Uniq_key,'(WO:'+@wono,t.QtyIssued, @wipGl,@wono,m.UNIQMFGRHD,@userid,t.KaSeqnum,t.LOTCODE,t.EXPDATE,t.REFERENCE,t.PONUM   
   from @PartComponant t inner join invtmfgr m on t.W_key=m.W_KEY  
   
  -- issue ipkey  
  
  -- Sachin B: 09/12/2016: Correct the join for issueIpKey   
  -- from inner join @Tissue h on t.PkIpKeyIssued=h.PkCompIssueHeader  
  -- to inner join @Tissue h on t.FkCompIssueHeader=h.PkCompIssueHeader  
  insert into issueipkey (invtisu_no,qtyissued,ipkeyunique,kaseqnum,issueIpKeyUnique)  
   select t.FkCompIssueHeader,t.ipKeyQtyIssued,t.ipKeyUnique,h.kaseqnum,t.PkIpKeyIssued FROM @tIpkeyIssue t   
   inner join @Tissue h on t.FkCompIssueHeader=h.PkCompIssueHeader  
    
  -- issue serial numbers  
  insert into issueSerial (serialno,SerialUniq,iIssueSerUnique,invtisu_no,ipkeyunique,kaseqnum)  
  select s.serialno,t.SerialUniq,t.PkSerialIssued,t.FkCompIssueHeader,t.ipkeyunique , h.KaSeqnum    
  from @tSerailIssue t  
     inner join @Tissue h on t.FkCompIssueHeader=h.PkCompIssueHeader  
  inner join invtser s on t.SerialUniq=s.SERIALUNIQ  
  
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