-- =============================================  
-- Author:  Sachin B  
-- Create date: 09/08/2016  
-- Description: this procedure will be called from the SF module AND will try to get lot from which we issued qty to work order  
-- [dbo].[GetIssuedPartLotInformation] 'EUBN3VNJQQ','0000000666','ZZKEY7DYU7',0,''  
-- [dbo].[GetIssuedPartLotInformation] '_25P0KOSEA','0000000555',0,1,'J01TOHN3YO'  
-- 11/21/2016 Sachin b update the Query get all information with invt_isu table as per discussion with yelena  
-- 12/05/2016 Sachin b Add If/Else block conditions for Get Assembly Allocated Lot Data  
-- 1/19/2017 Sachin b Add temp table for get the Correct Lot qty which are associated to Assembly  
-- 0/6/22/2017 Sachin b update the Query reserved Column information AND remove outer apply  
-- 7/31/2017 Sachin b Remove Unused parameter @IsReserve AND add @kaseqnum number  
-- 08/08/2017 Rajendra K Added FromWarehouse & ToWareHouse used for KitTransfer 
-- 01/17/2019 Sachin B Added Column ToWkey,mpn.UniqMfgrHd,i.Uniq_Key In the Select Statement 
-- 02/21/2019 Rajendra k : Changed INNER join to LEFT OUTER join of Invtlot 
-- [GetIssuedPartLotInformation] 'XUNHM4X9RN','0002536215','5N2PDF8EYW',0,''
-- =============================================  
  
CREATE PROCEDURE [dbo].[GetIssuedPartLotInformation]   
 -- Add the parameters for the stored procedure here  
 @Uniq_key char(10)=' ',  
 @wono CHAR(10),  
 @kaseqnum CHAR(10),  
 @IsAssemblyAllocated Bit,  
 @AssemblySerialUniq char(10)   
AS  
BEGIN  
  
-- SET NOCOUNT ON added to prevent extra result sets from  
-- interfering with SELECT statements.  
SET NOCOUNT ON;  
  
     -- 12/05/2016 Sachin b Add If/Else block conditions for Get Assembly Allocated Lot Data  
  if(@IsAssemblyAllocated =0)   
   BEGIN  
     -- 11/21/2016 Sachin b update the Query get all information with invt_isu table as per discussion with yelena        
     SELECT  ROW_NUMBER() OVER( ORDER BY isu.w_key,isu.ExpDate,isu.Lotcode,isu.Reference,isu.ponum ) AS id,        
     isu.w_key,isu.ExpDate,isu.Reference,isu.LotCode,isu.PONUM,sum(Qtyisu) AS 'QtyUsed',  mfMaster.PartMfgr,mfMaster.mfgr_pt_no AS MfgrPartNo,Warehouse,  
     RTRIM(Warehouse)+' / '+RTRIM(Location) AS FromWarehouse,RTRIM(Warehouse)+' / '+RTRIM(Location) AS ToWarehouse 
	 -- 08/08/2017 Rajendra K Added FromWarehouse & ToWareHouse used for KitTransfer 	 
     ,Location,(ISNULL(LotQTY,0)-ISNULL(LotResQty,0)) AS QtyOh, cast(0 AS BIT) AS IsReserve,i.U_OF_MEAS AS Unit,CAST(1 AS BIT) RoHS,0 AS 'ReverseQty'
	 -- 01/17/2019 Sachin B Added Column ToWkey,mpn.UniqMfgrHd,i.Uniq_Key In the Select Statement 
	 ,mf.W_KEY ToWkey,mpn.UniqMfgrHd,i.Uniq_Key  
     -- 06/22/2017 Sachin b update the Query reserved Column information AND remove outer apply  
     --ISNULL(Reserved.ReserveQty,0.0) AS 'ReserveQty'  
     FROM invt_isu isu  
     INNER JOIN inventor i ON i.UNIQ_KEY = isu.UNIQ_KEY   
     INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY AND isu.UNIQMFGRHD = mpn.uniqmfgrhd  
     INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId  
     INNER JOIN INVTMFGR mf ON isu.uniq_key = mf.uniq_key AND isu.UNIQMFGRHD = mf.UNIQMFGRHD AND mf.W_KEY =isu.W_KEY  
     INNER JOIN WAREHOUS w ON mf.UNIQWH = w.UNIQWH  
     -- 06/22/2017 Sachin b update the Query reserved Column information  
	 -- 02/21/2019 Rajendra k : Changed INNER join to LEFt OUTER join of Invtlot 
     LEFT OUTER JOIN invtlot lot ON lot.W_KEY =isu.w_key AND  lot.lotcode = isu.lotcode  AND  ISNULL(lot.EXPDATE,1) = ISNULL(isu.EXPDATE,1) AND lot.REFERENCE = isu.REFERENCE AND lot.PONUM = isu.PONUM  
     --OUTER APPLY (select SUM(QTYALLOC)  AS ReserveQty from INVT_RES where INVT_RES.UNIQ_KEY=i.UNIQ_KEY AND INVT_RES.WONO = isu.WONO    
     --Group by INVT_RES.W_KEY ,INVT_RES.LOTCODE,INVT_RES.EXPDATE,INVT_RES.REFERENCE,INVT_RES.PONUM  
     --Having  SUM(QTYALLOC)>0  
     --) Reserved  
     -- 07/31/2017 Sachin b Remove Unused parameter @IsReserve AND add @kaseqnum number  
     WHERE isu.ISSUEDTO LIKE '%(WO:'+@wono+'%'  
     --AND (isu.lotcode <>'' OR isu.expdate <>'' OR isu.reference <>'' OR isu.PONUM <>'')  
     AND isu.wono =@wono AND isu.uniq_key = @Uniq_key AND isu.kaseqnum =@kaseqnum  
     GROUP BY Partmfgr,mfgr_pt_no,Warehouse,Location, mf.W_key,isu.ExpDate,isu.Reference,isu.LotCode,isu.PONUM,i.U_OF_MEAS,LotQTY,LotResQty,isu.W_KEY,mpn.UniqMfgrHd,i.Uniq_Key  
     HAVING sum(Qtyisu) > 0  
   END   
  ELSE  
   BEGIN  
   ;WITH temp AS(                
	  SELECT isu.w_key,ass.ExpDate,ass.Reference,ass.LotCode,ass.PONUM,ass.Qtyisu AS 'QtyUsed',mfMaster.PartMfgr,mfMaster.mfgr_pt_no AS MfgrPartNo,Warehouse,           
      Location,ass.PartSerialUnique,ass.PartIpkeyUnique,(ISNULL(LotQTY,0)-ISNULL(LotResQty,0)) AS QtyOh,cast(0 AS BIT) AS IsReserve,i.U_OF_MEAS AS Unit,CAST(1 AS BIT) RoHS
	  -- 01/17/2019 Sachin B Added Column ToWkey,mpn.UniqMfgrHd,i.Uniq_Key In the Select Statement 
	  ,0 AS 'ReverseQty' ,mf.W_KEY ToWkey,mpn.UniqMfgrHd,i.Uniq_Key 
      FROM invt_isu isu  
      INNER JOIN inventor i ON i.UNIQ_KEY = isu.UNIQ_KEY   
      INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY AND isu.UNIQMFGRHD = mpn.uniqmfgrhd  
      INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId  
      INNER JOIN INVTMFGR mf ON isu.uniq_key = mf.uniq_key AND isu.UNIQMFGRHD = mf.UNIQMFGRHD AND mf.W_KEY =isu.W_KEY  
      INNER JOIN WAREHOUS w ON mf.UNIQWH = w.UNIQWH  
      LEFT OUTER JOIN invtlot lot ON ISNULL(lot.W_KEY,'') =ISNULL(isu.w_key,'') AND  ISNULL(lot.lotcode,'') = ISNULL(isu.lotcode,'')  AND  ISNULL(lot.EXPDATE,1) = ISNULL(isu.EXPDATE,1)   
      AND  ISNULL(lot.REFERENCE,'') = ISNULL(isu.REFERENCE,'')   
      INNER JOIN SerialComponentToAssembly ass on ISNULL(ass.lotcode,'') = ISNULL(isu.lotcode,'')  AND  ISNULL(ass.EXPDATE,1) = ISNULL(isu.EXPDATE,1)   
      AND  ISNULL(ass.REFERENCE,'') = ISNULL(isu.REFERENCE,'')   
      WHERE isu.ISSUEDTO LIKE '%(WO:'+@wono+'%'  
      AND (isu.lotcode <>'' OR isu.expdate <>'' OR isu.reference <>'' OR isu.PONUM <>'')  
      AND isu.wono =@wono AND isu.uniq_key = @Uniq_key   
      AND ass.serialuniq = @AssemblySerialUniq AND ass.uniq_key = @Uniq_key AND ass.wono =@wono  
      GROUP BY Partmfgr,mfgr_pt_no,Warehouse,Location,ass.serialuniq, mf.W_key,ass.ExpDate,ass.Reference,ass.LotCode,ass.PONUM,i.U_OF_MEAS,isu.W_KEY,ass.PartSerialUnique
	  ,ass.PartIpkeyUnique ,LotQTY,LotResQty,ass.Qtyisu,mpn.UniqMfgrHd,i.Uniq_Key   
      )        
      SELECT ROW_NUMBER() OVER(ORDER BY w_key,ExpDate,Lotcode,Reference,ponum ) AS id ,w_key,ExpDate,Reference,LotCode,PONUM,SUM(QtyUsed) AS QtyUsed,PartMfgr,  
       MfgrPartNo,Warehouse,Location,QtyOh,cast(0 AS BIT) AS IsReserve, Unit,CAST(1 AS BIT) RoHS,ReverseQty,  
	    -- 08/08/2017 Rajendra K Added FromWarehouse & ToWareHouse used for KitTransfer  
       RTRIM(Warehouse)+' / '+RTRIM(Location) AS FromWarehouse,RTRIM(Warehouse)+' / '+RTRIM(Location) AS ToWarehouse,ToWkey,UniqMfgrHd,Uniq_Key
       FROM temp GROUP BY w_key,ExpDate,Reference,LotCode,PONUM,PartMfgr,MfgrPartNo,Warehouse,Location,QtyOh,Unit,ReverseQty ,ToWkey,UniqMfgrHd,Uniq_Key 
   END              
END