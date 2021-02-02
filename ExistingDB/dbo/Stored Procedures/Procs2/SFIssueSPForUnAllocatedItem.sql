-- =============================================  
-- Author:  Sachin B  
-- Create date: 09/06/2016  
-- Description: this procedure will be called from the SF module and will try to issue to a work order which are not allocated by work order  
-- Sachin B: 10/04/2016: Update Join Condition Change t.PkIpKeyIssued to t.FkCompIssueHeader  
-- Sachin B: 10/06/2016: Add the Column PONUM to fix issue lot is not updated correctly  
-- Sachin B: 11/12/2016: Add the partameter to assign componant to assembaly serial no  
-- Sachin B: 11/12/2016: Add the ipkey,Serial and lotinfo for assign componant to assembly  
-- Sachin B: 11/12/2016: Assign componant to assembly if @IsAssemblyUsed is true  
---03/02/18 YS change size of the lotcode field to 25  
-- 06/11/2019 Sachin B : Convert Inner Join With PARTTYPE to Left Join
-- =============================================  
CREATE PROCEDURE [dbo].[SFIssueSPForUnAllocatedItem]  
 -- Add the parameters for the stored procedure here  
 @TUnissue tComponentsIssue2Kit READONLY,  
 @tSerailUnIssue tSerialsIssue2Kit READONLY,  
 @tIpkeyUnIssue tIpkeyIssue2Kit READONLY,  
 @wono char(10) = '',  
 @userid uniqueidentifier= null,  
 -- Sachin B: 10/06/2016: Add the partameter to assign componant to assembaly serial no  
 @AssemblySerialNo char(30)= '',  
 @AssemblySerialUniq char(10)= '',  
 @IsAssemblyUsed bit  
  
AS  
BEGIN                     
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 -- get ready to handle any errors  
 DECLARE @ErrorMessage NVARCHAR(4000);  
    DECLARE @ErrorSeverity INT;  
    DECLARE @ErrorState INT;  
 -- get g/l # for the wip account  
 declare @wipGL char(13)  
 select @wipGl=dbo.fn_GetWIPGl()  
   
 BEGIN TRY  
 BEGIN TRANSACTION  
   
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
   -- Sachin B: 10/06/2016: Add the Column PONUM to fix issue lot is not updated correctly  
   PONUM [char](15),  
   EXPDATE smalldatetime null,  
   REFERENCE char(12),  
   -- Sachin B: 11/12/2016: Add the ipkey,Serial and lotinfo for assign componant to assembly  
   UseIpkey bit,  
   Serialyes bit,  
   lotDetail bit  
  )    
     insert into @PartComponant ([PkCompIssueHeader],[Uniq_key],[W_key],[QtyIssued],[KaSeqnum],[UNIQ_LOT])  
  select PkCompIssueHeader,Uniq_key,W_key,QtyIssued,KaSeqnum,UNIQ_LOT from @TUnissue  
  
  UPDATE p  
  set p.LOTCODE =ISNULL(lot.LOTCODE,''),  
  p.EXPDATE = lot.EXPDATE,  
  p.REFERENCE = ISNULL(lot.REFERENCE,''),  
  -- Sachin B: 10/06/2016: Add the Column PONUM to fix issue lot is not updated correctly  
  p.PONUM = ISNULL(lot.PONUM,'')  
  from @PartComponant p  
  LEFT OUTER JOIN invtlot lot ON p.uniq_lot=lot.uniq_lot  
  
  -- Sachin B: 11/12/2016: Add the ipkey,Serial and lotinfo for assign componant to assembly  
  UPDATE pa  
  set pa.UseIpkey =i.useipkey,  
  pa.serialyes = i.serialyes,  
  -- 06/11/2019 Sachin B : Convert Inner Join With PARTTYPE to Left Join
  pa.lotDetail = CASE WHEN p.LOTDETAIL IS NULL THEN CAST(0 as BIT) ELSE p.LOTDETAIL END 
  from @PartComponant pa  
  INNER JOIN INVENTOR i ON pa.Uniq_key=i.Uniq_key  
  LEFT JOIN PARTTYPE p on p.PART_TYPE =i.PART_TYPE  
  
  --- now issue, use provided PkCompIssueHeader as new invtisu_no  
  -- Sachin B: 10/06/2016: Add the Column PONUM to fix issue lot is not updated correctly  
  insert into invt_isu (invtisu_no,w_key,UNIQ_KEY,issuedto,qtyisu,GL_NBR,wono,UNIQMFGRHD,fk_userid,kaseqnum,LOTCODE,EXPDATE,REFERENCE,PONUM)  
   select t.PkCompIssueHeader, t.W_key,t.Uniq_key,'(WO:'+@wono,t.QtyIssued, @wipGl,@wono,m.UNIQMFGRHD,@userid,t.KaSeqnum ,t.LOTCODE,t.EXPDATE,t.REFERENCE,t.PONUM  
   from @PartComponant t   
   INNER JOIN invtmfgr m ON t.W_key=m.W_KEY  
   
  -- issue ipkey  
  insert into issueipkey (invtisu_no,qtyissued,ipkeyunique,kaseqnum,issueIpKeyUnique)  
   select t.FkCompIssueHeader,t.ipKeyQtyIssued,t.ipKeyUnique,h.kaseqnum,t.PkIpKeyIssued FROM @tIpkeyUnIssue t   
   -- Sachin B: 10/04/2016: Update Join Condition Change t.PkIpKeyIssued to t.FkCompIssueHeader  
   INNER JOIN @PartComponant h ON t.FkCompIssueHeader=h.PkCompIssueHeader  
    
  -- issue serial numbers  
  insert into issueSerial (serialno,SerialUniq,iIssueSerUnique,invtisu_no,ipkeyunique,kaseqnum)  
  select s.serialno,t.SerialUniq,t.PkSerialIssued,t.FkCompIssueHeader,t.ipkeyunique , h.KaSeqnum    
  from @tSerailUnIssue t   
  INNER JOIN @PartComponant h ON t.FkCompIssueHeader=h.PkCompIssueHeader  
  INNER JOIN invtser s ON t.SerialUniq=s.SERIALUNIQ  
  
  -- Sachin B: 11/12/2016: Assign componant to assembly if @IsAssemblyUsed is true  
  IF(@IsAssemblyUsed = 1)  
  BEGIN  
   -- Insert data to SerialComponentToAssembly if part is lotted  
   MERGE SerialComponentToAssembly T  
   USING (SELECT @AssemblySerialNo as AssemblySerialNo ,@AssemblySerialUniq as AssemblySerialUniq , i.PkCompIssueHeader, i.uniq_key,@wono as wono, i.lotcode,i.expdate,i.reference, i.ponum,i.QtyIssued  
   from @PartComponant I   
   where I.useIpkey =0 and i.serialyes = 0 and i.lotdetail =1 ) as S  
   ON ( s.AssemblySerialNo = t.serialno and s.AssemblySerialUniq =t.serialuniq and s.uniq_key = t.uniq_key AND s.wono = t.wono   
    and S.lotcode=T.lotcode and s.reference=t.reference and s.ponum=t.ponum and ISNULL(t.EXPDATE,1) = ISNULL(s.ExpDate,1))  
   WHEN MATCHED  THEN UPDATE SET T.qtyisu=t.qtyisu + s.QtyIssued  
   WHEN NOT MATCHED BY TARGET THEN   
   INSERT (serialno,serialuniq,CompToAssemblyUk,uniq_key,Wono,QTYISU,LOTCODE,EXPDATE,REFERENCE,PONUM)   
   VALUES (s.AssemblySerialNo,s.AssemblySerialUniq,s.PkCompIssueHeader,s.uniq_key,s.wono,s.QtyIssued,s.lotcode,s.Expdate,s.reference,s.ponum);  
  
   -- Insert data to SerialComponentToAssembly if part having sid but not serialized  
   MERGE SerialComponentToAssembly T  
   USING (SELECT @AssemblySerialNo as AssemblySerialNo ,@AssemblySerialUniq as AssemblySerialUniq , t.PkIpKeyIssued, i.uniq_key,@wono as wono, i.lotcode,i.expdate  
   ,i.reference, i.ponum,t.ipKeyQtyIssued,t.ipKeyUnique  
   FROM @tIpkeyUnIssue t   
   INNER JOIN @PartComponant i ON t.FkCompIssueHeader=i.PkCompIssueHeader  
   where I.useIpkey = 1 and i.serialyes = 0  ) as S  
    ON ( s.AssemblySerialNo = t.serialno and s.AssemblySerialUniq =t.serialuniq and s.uniq_key = t.uniq_key AND s.wono = t.wono and s.ipkeyunique =t.PartIpkeyUnique  
    and S.lotcode=T.lotcode and s.reference=t.reference and s.ponum=t.ponum and ISNULL(t.EXPDATE,1) = ISNULL(s.ExpDate,1))  
   WHEN MATCHED  THEN UPDATE SET T.qtyisu=t.qtyisu + s.ipKeyQtyIssued  
   WHEN NOT MATCHED BY TARGET THEN   
   INSERT (serialno,serialuniq,CompToAssemblyUk,uniq_key,Wono,partipkeyunique,QTYISU,LOTCODE,EXPDATE,REFERENCE,PONUM)   
   VALUES (s.AssemblySerialNo,s.AssemblySerialUniq,s.PkIpKeyIssued,s.uniq_key,s.wono,s.ipkeyunique,s.ipKeyQtyIssued,s.lotcode,s.Expdate,s.reference,s.ponum);  
  
   -- Insert data to SerialComponentToAssembly if part is serialized  
   Insert into SerialComponentToAssembly   
   (serialno,serialuniq,CompToAssemblyUk,uniq_key,Wono,PartIpkeyUnique,PartSerialNo,PartSerialUnique,QTYISU,LOTCODE,EXPDATE,REFERENCE,PONUM)  
   Select @AssemblySerialNo,@AssemblySerialUniq,t.PkSerialIssued,h.Uniq_key,@wono,t.ipkeyunique,s.serialno,t.SerialUniq,1,h.LOTCODE,h.EXPDATE,h.REFERENCE,h.PONUM  
   from @tSerailUnIssue t   
   INNER JOIN @PartComponant h ON t.FkCompIssueHeader=h.PkCompIssueHeader  
   INNER JOIN invtser s ON t.SerialUniq=s.SERIALUNIQ  
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