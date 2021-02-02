-- =============================================    
-- Author:  Sachin B    
-- Create date: 11/21/2016    
-- Description: this procedure will be called from the SF Part Issue history module and for the DeKit the Issued Componants    
-- Sachin B 11/29/2016 Add IsLotted,UseIpKey,SerialYes column on the temp table for Update/remove records in SerialComponentToAssembly table    
-- Sachin B 11/29/2016 update the QTYISU column in SerialComponentToAssembly for the part Which have only IsLotted or UseIpKey true if qty becomes zero or less than zero then delete those records    
-- Sachin B 11/29/2016 if we dekit serialize part then we directly remove that records from table    
-- Sachin B: 11/29/2016: Add the partameter to assign componant to assembaly serial no    
-- Sachin B: 12/06/2016: Add Else condition for the lotted and SID Part if they are allocated to only one assembly for updated/delete assembly    
-- Sachin B: 12/06/2016: Remove UnUsed or Condition from where clause    
-- Sachin B: 06/19/2017: Remove Parameter @AssemblySerialNo,@AssemblySerialUniq,@IsAssemblyUsed and Code for un issued Assembly    
-- Rajendra K : 02/26/2019 : Added ExpDate as EXPDATEString and convert it into smalldatetime formate   
-- Rajendra K : 05/30/2019 : Change the join INNER to LEFT with PARTTYPE table   
-- Rajendra K : 06/11/2019 : Check Is NULL Condition for the Lot Details
---03/02/18 YS change size of the lotcode field to 25     
-- =============================================    
CREATE PROCEDURE [dbo].[SFDeKitIssuedComponants]    
 -- Add the parameters for the stored procedure here    
 @TUnissue tComponentsIssue2Kit READONLY,    
 @tSerailUnIssue tSerialsIssue2Kit READONLY,    
 @tIpkeyUnIssue tIpkeyIssue2Kit READONLY,    
 @tUniqLot tUniqLot READONLY,    
 @wono CHAR(10) = '',    
 @userid UNIQUEIDENTIFIER= null    
 -- Sachin B: 11/29/2016: Add the partameter to assign componant to assembaly serial no    
 -- Sachin B: 06/19/2017: Remove Parameter @AssemblySerialNo,@AssemblySerialUniq,@IsAssemblyUsed and Code for un issued Assembly     
 --@AssemblySerialNo char(30)= '',    
 --@AssemblySerialUniq char(10)= '',    
 --@IsAssemblyUsed bit    
    
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
 DECLARE @wipGL CHAR(13)    
 SELECT @wipGl=dbo.fn_GetWIPGl()    
     
 BEGIN TRY    
 BEGIN TRANSACTION    
     
     -- Sachin B 11/29/2016 Add IsLotted,UseIpKey,SerialYes column on the temp table for Update/remove records in SerialComponentToAssembly table    
     DECLARE  @PartComponant TABLE    
  (    
   ---03/02/18 YS change size of the lotcode field to 25    
   [PkCompIssueHeader] [char](10),    
   [Uniq_key] [char](10),    
   [W_key] [char](10),    
   [QtyIssued] [numeric](12, 2),    
   [KaSeqnum] [char](10) ,    
   [UNIQ_LOT] [char](10),    
   [LOTCODE] [nvarchar](25),    
   [PONUM] [char](15),    
   [EXPDATE] SMALLDATETIME null,    
   [REFERENCE] CHAR(12),    
   [IsLotted] BIT,    
   [UseIpKey] BIT,    
   [SerialYes] BIT    
  )      

  INSERT INTO @PartComponant ([PkCompIssueHeader],[Uniq_key],[W_key],[QtyIssued],[KaSeqnum],[LOTCODE],[PONUM],[EXPDATE],[REFERENCE],[IsLotted],[UseIpKey],[SerialYes])    
  SELECT PkCompIssueHeader,t.Uniq_key,t.W_key,QtyIssued,KaSeqnum,lot.LOTCODE,lot.PONUM,  
  -- Rajendra K : 06/11/2019 : Check Is NULL Condition for the Lot Details
  CASE WHEN lot.EXPDATEString ='' THEN NULL ELSE  CONVERT(smalldatetime,lot.EXPDATEString) END,lot.REFERENCE,ISNULL(LOTDETAIL,CAST(0 AS BIT)),i.useipkey,i.SERIALYES    
  -- Rajendra K : 02/26/2019 : Added EXPDATE as EXPDATEString and convert it into smalldatetime formate   
  FROM @TUnissue t     
  INNER JOIN @tUniqLot lot ON t.PkCompIssueHeader = lot.uniq_lot    
  INNER JOIN inventor i ON t.Uniq_key = i.UNIQ_KEY    
  LEFT JOIN PARTTYPE p ON i.PART_TYPE = p.PART_TYPE and i.PART_CLASS = p.PART_CLASS  -- Rajendra K : 05/30/2019 : Change the join INNER to LEFT with PARTTYPE table   
    
  --- now issue, use provided PkCompIssueHeader as new invtisu_no    
  INSERT INTO invt_isu (invtisu_no,w_key,UNIQ_KEY,issuedto,qtyisu,GL_NBR,wono,UNIQMFGRHD,fk_userid,kaseqnum,LOTCODE,EXPDATE,REFERENCE,PONUM)    
   SELECT t.PkCompIssueHeader, t.W_key,t.Uniq_key,'(WO:'+@wono,- t.QtyIssued, @wipGl,@wono,m.UNIQMFGRHD,@userid,t.KaSeqnum ,t.LOTCODE,t.EXPDATE,t.REFERENCE,t.PONUM    
   FROM @PartComponant t INNER JOIN invtmfgr m ON t.W_key=m.W_KEY    
     
  -- De-Kit ipkey    
  INSERT INTO issueipkey (invtisu_no,qtyissued,ipkeyunique,kaseqnum,issueIpKeyUnique)    
   SELECT t.FkCompIssueHeader,-t.ipKeyQtyIssued,t.ipKeyUnique,h.kaseqnum,t.PkIpKeyIssued FROM @tIpkeyUnIssue t     
   INNER JOIN @PartComponant h ON t.FkCompIssueHeader=h.PkCompIssueHeader    
      
  -- De-Kit serial numbers    
  INSERT INTO issueSerial (serialno,SerialUniq,iIssueSerUnique,invtisu_no,ipkeyunique,kaseqnum)    
  SELECT s.serialno,t.SerialUniq,t.PkSerialIssued,t.FkCompIssueHeader,t.ipkeyunique , h.KaSeqnum      
  FROM @tSerailUnIssue t     
  INNER JOIN @PartComponant h ON t.FkCompIssueHeader=h.PkCompIssueHeader    
  INNER JOIN invtser s ON t.SerialUniq=s.SERIALUNIQ     
      
  -- Sachin B: 06/19/2017: Remove Parameter @AssemblySerialNo,@AssemblySerialUniq,@IsAssemblyUsed and Code for un issued Assembly     
  --IF(@IsAssemblyUsed = 1)    
  -- BEGIN    
  --  -- Sachin B 11/29/2016 update the QTYISU column in SerialComponentToAssembly for the part Which have only IsLotted or UseIpKey true if qty becomes zero or less than zero then delete those records    
  --  -- Sachin B: 12/06/2016: Remove UnUsed or Condition from where clause    
  --  --Decrease the DeKit Quantity in the Assembly Which is linked for the lotted Part    
  --  UPDATE  ser    
  --  SET    ser.QTYISU = ser.QTYISU - part.QtyIssued    
  --  FROM   SerialComponentToAssembly AS ser     
  --  INNER JOIN @PartComponant AS part    
  --  ON ser.uniq_key = part .Uniq_key and ser.LOTCODE = part.LOTCODE and ISNULL(ser.EXPDATE,1) = ISNULL(part.EXPDATE,1) and ser.REFERENCE =part.REFERENCE and ser.PONUM =part.PONUM    
  --  WHERE ser.Wono = @wono and (part.IsLotted =1 and part.SerialYes = 0 and part.UseIpKey =0 and ser.serialuniq = @AssemblySerialUniq and ser.serialno =@AssemblySerialNo)    
              
  --  -- Sachin B: 12/06/2016: Remove UnUsed or Condition from where clause    
  --  --if after these update QTYISU is become zero or less than zero then delete those records    
  --  DELETE ser    
  --  FROM SerialComponentToAssembly ser    
  --  INNER JOIN @PartComponant AS part     
  --  ON ser.uniq_key = part .Uniq_key and ser.LOTCODE = part.LOTCODE and ISNULL(ser.EXPDATE,1) = ISNULL(part.EXPDATE,1) and ser.REFERENCE =part.REFERENCE and ser.PONUM =part.PONUM    
  --  WHERE ser.Wono = @wono and (part.IsLotted =1 and part.SerialYes = 0 and part.UseIpKey =0) and ser.QTYISU <=0 and ser.serialuniq = @AssemblySerialUniq     
  --  and ser.serialno =@AssemblySerialNo    
    
  --  --Decrease the DeKit Quantity in the Assembly Which is linked for the SID Part    
  --  UPDATE  ser    
  --  SET    ser.QTYISU = ser.QTYISU - ip.ipKeyQtyIssued    
  --  FROM   SerialComponentToAssembly AS ser     
  --  INNER JOIN @PartComponant AS part ON ser.uniq_key = part .Uniq_key and ser.LOTCODE = part.LOTCODE and ISNULL(ser.EXPDATE,1) = ISNULL(part.EXPDATE,1) and ser.REFERENCE =part.REFERENCE and ser.PONUM =part.PONUM    
  --  INNER JOIN @tIpkeyUnIssue ip ON ser.PartIpkeyUnique = ip.IpkeyUnique     
  --  WHERE ser.Wono = @wono and part.SerialYes = 0 and part.UseIpKey =1 and ser.serialuniq = @AssemblySerialUniq and ser.serialno =@AssemblySerialNo    
    
  --  --if after these update QTYISU is become zero or less than zero then delete those records    
  --  DELETE ser    
  --  FROM SerialComponentToAssembly ser    
  --  INNER JOIN @PartComponant AS part ON ser.uniq_key = part .Uniq_key and ser.LOTCODE = part.LOTCODE and ISNULL(ser.EXPDATE,1) = ISNULL(part.EXPDATE,1) and ser.REFERENCE =part.REFERENCE and ser.PONUM =part.PONUM    
  --  INNER JOIN @tIpkeyUnIssue ip ON ser.PartIpkeyUnique = ip.IpkeyUnique     
  --  WHERE ser.Wono = @wono and part.SerialYes = 0 and part.UseIpKey =1 and ser.QTYISU <=0 and ser.serialuniq = @AssemblySerialUniq and ser.serialno =@AssemblySerialNo       
  -- END    
  --      -- Sachin B: 12/06/2016: Add Else condition for the lotted and SID Part if they are allocated to only one assembly for updated/delete assembly    
  --ELSE          
  -- BEGIN    
    
  --Decrease the DeKit Quantity in the Assembly Which is linked for the lotted Part    
  UPDATE  ser    
  SET    ser.QTYISU = ser.QTYISU - part.QtyIssued    
  FROM   SerialComponentToAssembly AS ser     
  INNER JOIN @PartComponant AS part    
  ON ser.uniq_key = part .Uniq_key and ser.LOTCODE = part.LOTCODE and ISNULL(ser.EXPDATE,1) = ISNULL(part.EXPDATE,1) and ser.REFERENCE =part.REFERENCE and ser.PONUM =part.PONUM    
  WHERE ser.Wono = @wono and (part.IsLotted =1 and part.SerialYes = 0 and part.UseIpKey =0)    
      
  --if after these update QTYISU is become zero or less than zero then delete those records    
  DELETE ser    
  FROM SerialComponentToAssembly ser    
  INNER JOIN @PartComponant AS part     
  ON ser.uniq_key = part .Uniq_key and ser.LOTCODE = part.LOTCODE and ISNULL(ser.EXPDATE,1) = ISNULL(part.EXPDATE,1) and ser.REFERENCE =part.REFERENCE and ser.PONUM =part.PONUM    
  WHERE ser.Wono = @wono and (part.IsLotted =1 and part.SerialYes = 0 and part.UseIpKey =0) and ser.QTYISU <=0     
    
  --Decrease the DeKit Quantity in the Assembly Which is linked for the SID Part    
  UPDATE  ser    
  SET    ser.QTYISU = ser.QTYISU - ip.ipKeyQtyIssued    
  FROM   SerialComponentToAssembly AS ser     
  INNER JOIN @PartComponant AS part ON ser.uniq_key = part .Uniq_key and ser.LOTCODE = part.LOTCODE and ISNULL(ser.EXPDATE,1) = ISNULL(part.EXPDATE,1) and ser.REFERENCE =part.REFERENCE and ser.PONUM =part.PONUM    
  INNER JOIN @tIpkeyUnIssue ip ON ser.PartIpkeyUnique = ip.IpkeyUnique     
  WHERE ser.Wono = @wono and part.SerialYes = 0 and part.UseIpKey =1    
    
  --if after these update QTYISU is become zero or less than zero then delete those records    
  DELETE ser    
  FROM SerialComponentToAssembly ser    
  INNER JOIN @PartComponant AS part ON ser.uniq_key = part .Uniq_key and ser.LOTCODE = part.LOTCODE and ISNULL(ser.EXPDATE,1) = ISNULL(part.EXPDATE,1) and ser.REFERENCE =part.REFERENCE and ser.PONUM =part.PONUM    
  INNER JOIN @tIpkeyUnIssue ip ON ser.PartIpkeyUnique = ip.IpkeyUnique     
  WHERE ser.Wono = @wono and part.SerialYes = 0 and part.UseIpKey =1 and ser.QTYISU <=0    
  --END    
    
  -- Sachin B 11/29/2016 if we dekit serialize part then we directly remove that records from table    
  --If We DeKit the Serialize item then we need to delete those item from SerialComponentToAssembly    
  DELETE ser    
  FROM SerialComponentToAssembly ser    
  INNER JOIN @PartComponant AS part     
  ON ser.uniq_key = part .Uniq_key and ser.LOTCODE = part.LOTCODE and ISNULL(ser.EXPDATE,1) = ISNULL(part.EXPDATE,1) and ser.REFERENCE =part.REFERENCE and ser.PONUM =part.PONUM    
  Inner join @tSerailUnIssue isuSer ON ser.PartSerialUnique = isuSer.SerialUniq      
  WHERE ser.Wono = @wono and part.SerialYes = 1     
    
    
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