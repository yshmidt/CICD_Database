-- =============================================      
-- Author:  Sachin B      
-- Create date: 09/08/2016      
-- Description: this procedure will be called from the SF module and will try to issue looted part to a work order which are not allocated by work order      
-- 09/30/16 Sachin B Add two parameter for get the reserve Lot Details and Select Data for those lots      
-- 10/25/16 Sachin B Add two parameter U_OF_MEAS and RoHS      
-- 12/12/16 Sachin B Add Group by clause for the resered componants and sum(QTYALLOC) as QtyOh       
-- 07/20/2017 Sachin B Add parameter @kaSeqNum and check kaseqnum for the line items implementation      
-- 06/22/2017 Sachin B Check IsNull With ExpDate      
-- 09/26/2017 Sachin B Add Parameter ToWarehouse,ToWkey and UniqMfgrHd      
-- 11/06/2017 Sachin B Add And condition in join with invtmfgr with W_KEY and Apply Code review Comments      
-- 11/27/2017 Sachin B Add @isReconciliation Parameter and get ReturnQty Conditionaliy      
-- 04/01/2019 Sachin B Get ReturnQty As Zero   
-- 04/16/2019 Sachin B get consign Part uniqkey if it exists   
-- 04/18/2019 Sachin B Get the Approved Manufactures Lot List for un-reserved Parts  
-- 04/25/2019 Sachin B Add UniqWH in Select Statment, Add in Join Also  
-- 05/09/2019 Sachin B Get PONUM column  
-- 11/13/2019 Sachin B Added Column auto-Allocation which will not allow user to add new location  
-- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials
-- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)
-- 03/31/2020 Sachin B Remove And condition  of uniqwh from join 
-- [dbo].[GetPartLotInformation] 'J2VJZNV7D3','0000001333',1,'8YEBO3NAVS',1,''     
-- =============================================      
      
CREATE PROCEDURE [dbo].[GetPartLotInformation]       
 -- Add the parameters for the stored procedure here      
 @uniqKey CHAR(10)=' ',      
 -- 09/30/16 Sachin B Add two parameter for get the reserve Lot Details and Select Data for those lots      
 @wono CHAR(10),      
 @isReserve BIT,      
 @kaSeqNum CHAR(10),      
 -- 11/27/2017 Sachin B Add @isReconciliation Parameter and get ReturnQty Conditionaliy      
 @isReconciliation BIT =0 ,  
 @CustNo CHAR(10)=''      
AS      
BEGIN      
      
-- SET NOCOUNT ON added to prevent extra result sets from      
-- interfering with SELECT statements.      
SET NOCOUNT ON;   
  
-- 04/16/2019 Sachin B get consign Part uniqkey if it exists   
--SET @UniqKey = ISNULL((SELECT UNIQ_KEY FROM INVENTOR WHERE INT_UNIQ = @UniqKey AND CUSTNO = @CustNo),@UniqKey);  
-- 04/18/2019 Sachin B Get the Approved Manufactures Lot List for un-reserved Parts  
DECLARE @congUniqKey CHAR(10) ='',@bomParentUniqKey char(10),@nonNettable BIT;
SET @bomParentUniqKey = (SELECT uniq_key FROM WOENTRY WHERE WONO =@wono);  
  
-- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)
SET @nonNettable = (SELECT CONVERT(Bit,ISNULL(WM.settingValue,MS.settingValue)) FROM MnxSettingsManagement MS 
 LEFT JOIN WmSettingsManagement WM ON  MS.settingId = WM.settingId          
 WHERE SettingName  = 'allowUseOfNonNettableWarehouseLocation')

IF(@CustNo<>'' AND @uniqKey<>'')  
BEGIN  
  SET @congUniqKey = (SELECT Uniq_Key FROM INVENTOR WHERE INT_UNIQ =@uniqKey AND CUSTNO =@CustNo)  
END   
      
IF(@isReserve = 0)      
 BEGIN    
  IF (@congUniqKey IS NOT NULL AND @congUniqKey<>'')  
   BEGIN  
   ;With InternalPartAVL AS(    
        -- 04/25/2019 Sachin B Add UniqWH in Select Statment, Add in Join Also  
     SELECT DISTINCT (LotQTY-LotResQty) AS QtyOh, LotResQty AS Reserved,i.UNIQ_KEY,mfMaster.Partmfgr,mfMaster.mfgr_pt_no AS MfgrPartNo,imfgr.W_KEY,  
     ExpDate, Reference, Uniq_lot,LotCode,wa.UNIQWH,PONUM          
     FROM Inventor i   
     INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY  and mpn.uniq_key =@uniqKey  
     INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
     INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd  
     INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH   
     INNER JOIN INVTLOT lot ON lot.W_KEY =imfgr.W_KEY 
     -- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)  
     AND Warehouse <> 'WIP' AND Warehouse <> 'WO-WIP' AND Warehouse <> 'MRB' AND ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)  
     AND imfgr.Is_Deleted = 0  AND mpn.Is_deleted = 0 
     and mfMaster.IS_DELETED=0    
     --AND imfgr.Instore = 0  -- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials
	   AND (LotQTY-LotResQty) >0   
    )  
    ,ConsgPartAVL AS(    
       SELECT DISTINCT mfMaster.PartMfgr,Warehouse,Location, mfMaster.mfgr_pt_no AS MfgrPartNo,      
     (LotQTY-LotResQty) AS QtyOh,imfgr.W_KEY, ExpDate, Reference, Uniq_lot,LotCode,PONUM,CAST(0 AS BIT) AS IsReserve,i.U_OF_MEAS AS Unit,CAST(1 AS BIT) RoHS,  
     i.INT_UNIQ,i.UNIQ_KEY,i.U_OF_MEAS,wa.UNIQWH     
     FROM Inventor i   
     INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY  and mpn.uniq_key =@congUniqKey  
     INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
     INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.Is_Deleted = 0   
     INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH   
     LEFT JOIN INVTLOT lot ON lot.W_KEY =imfgr.W_KEY  
     -- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)    
     AND Warehouse <> 'WIP' AND Warehouse <> 'WO-WIP' AND Warehouse <> 'MRB' AND ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)  
    AND imfgr.Is_Deleted = 0 AND mpn.Is_deleted = 0 AND mfMaster.IS_DELETED=0    
     --AND imfgr.Instore = 0 -- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials
	 AND (LotQTY-LotResQty) >0   
    )  
    SELECT  DISTINCT c.PartMfgr,c.Warehouse,c.[Location], c.MfgrPartNo,i.QtyOh,i.W_KEY, i.ExpDate, i.Reference, i.Uniq_lot,i.LotCode,i.PONUM,CAST(0 AS BIT) AS IsReserve,  
    c.U_OF_MEAS AS Unit,CAST(1 AS BIT) RoHS   
    FROM ConsgPartAVL c  
    -- 04/25/2019 Sachin B Add UniqWH in Select Statment, Add in Join Also  
	-- 03/31/2020 Sachin B Remove And condition  of uniqwh from join 
    INNER JOIN InternalPartAVL i ON i.UNIQ_KEY =c.INT_UNIQ  AND i.PartMfgr =c.PartMfgr AND i.MfgrPartNo =c.MfgrPartNo --AND i.UNIQWH =c.UNIQWH       
    WHERE c.UNIQ_KEY NOT IN  
    (  
       SELECT UNIQ_KEY   
    FROM ANTIAVL A   
    WHERE A.BOMPARENT =@bomParentUniqKey AND A.UNIQ_KEY = c.UNIQ_KEY AND A.PARTMFGR =c.Partmfgr AND A.MFGR_PT_NO =c.MfgrPartNo   
    )  
  END  
   ELSE  
  BEGIN  
   -- 10/25/16 Sachin B Add two parameter U_OF_MEAS and RoHS      
   SELECT DISTINCT mfMaster.PartMfgr,Warehouse,Location, mfMaster.mfgr_pt_no AS MfgrPartNo,      
   (LotQTY-LotResQty) AS QtyOh,imfgr.W_KEY, ExpDate, Reference, Uniq_lot,LotCode,PONUM,CAST(0 AS BIT) AS IsReserve,i.U_OF_MEAS AS Unit,CAST(1 AS BIT) RoHS      
   FROM INVENTOR i      
   INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY      
   INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId      
   INNER JOIN INVTMFGR imfgr on imfgr.UNIQ_KEY =i.UNIQ_KEY and imfgr.UNIQMFGRHD = mpn.uniqmfgrhd      
   INNER JOIN WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH      
   INNER JOIN INVTLOT lot ON lot.W_KEY =imfgr.W_KEY      
   where i.UNIQ_KEY = @uniqKey      
   AND WAREHOUSE <> 'WIP   ' AND WAREHOUSE <> 'WO-WIP' AND Warehouse <> 'MRB   '  AND LotQTY-LotResQty > 0 
   -- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)
   AND ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)  AND imfgr.IS_DELETED = 0       
   --AND imfgr.INSTORE = 0 -- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials
   AND (LotQTY-LotResQty) >0   
   AND NOT EXISTS   
   (   
       SELECT bomParent,UNIQ_KEY   
    FROM ANTIAVL A   
    WHERE A.BOMPARENT =@bomParentUniqKey and A.UNIQ_KEY = i.UNIQ_KEY and A.PARTMFGR =mfMaster.Partmfgr and A.MFGR_PT_NO =mfMaster.mfgr_pt_no   
   )  
  END       
 END      
ELSE      
 BEGIN      
   -- 09/30/16 Sachin B Add two parameter for get the reserve Lot Details and Select Data for those lots      
   -- 10/25/16 Sachin B Add two parameter U_OF_MEAS and RoHS      
   -- 09/26/2017 Sachin B Add Parameter ToWarehouse,ToWkey and UniqMfgrHd   
   -- 11/13/2019 Sachin B Added Column auto-Allocation which will not allow user to add new location     
   SELECT DISTINCT mfMaster.PartMfgr,Warehouse,Location, mfMaster.mfgr_pt_no AS MfgrPartNo,SUM(QTYALLOC) AS QtyOh,      
   -- 11/27/2017 Sachin B Add @isReconciliation Parameter and get ReturnQty Conditionaliy      
   --, CASE WHEN @isReconciliation =1 THEN (SUM(QTYALLOC)) ELSE 0 END AS ReturnQty,      
    -- 04/01/2019 Sachin B Get Return Qty As Zero    
   0.0 AS ReturnQty,     
   imfgr.W_KEY, lot.ExpDate, lot.Reference, Uniq_lot,lot.LotCode,lot.PONUM,CAST(0 AS BIT) AS IsReserve,i.U_OF_MEAS AS Unit,CAST(1 AS BIT) RoHS      
   ,RTRIM(w.Warehouse)+' / '+RTRIM(imfgr.[Location]) AS ToWarehouse,imfgr.W_key AS ToWkey,mpn.UniqMfgrHd,i.UNIQ_KEY, mfMaster.autolocation      
   FROM INVENTOR i      
   INNER JOIN INVT_RES res ON res.UNIQ_KEY = i.UNIQ_KEY and res.WONO = @wono      
   INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY      
   INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId      
   -- 11/06/2017 Sachin B Add And condition in join with invtmfgr with W_KEY and Apply Code review Comments      
   INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = res.W_KEY      
   INNER JOIN WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH      
   -- 06/22/2017 Sachin B Check IsNull With ExpDate      
   INNER JOIN INVTLOT lot ON lot.W_KEY =imfgr.W_KEY AND  ISNULL(lot.EXPDATE,1) = ISNULL(res.EXPDATE,1)  AND lot.REFERENCE =res.REFERENCE AND lot.LOTCODE = res.LOTCODE      
   WHERE i.UNIQ_KEY = @uniqKey
    -- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)          
   AND WAREHOUSE <> 'WIP   ' AND WAREHOUSE <> 'WO-WIP' AND Warehouse <> 'MRB   ' AND ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)
   AND imfgr.IS_DELETED = 0  
   --AND imfgr.INSTORE = 0-- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials       
   -- 07/20/2017 Sachin B Add parameter @kaSeqNum and check kaseqnum for the line items implementation      
   AND res.KASEQNUM = @kaSeqNum      
   -- 12/12/16 Sachin B Add Group by clause for the resered componants and sum(QTYALLOC) as QtyOh       
   GROUP BY mfMaster.PartMfgr,Warehouse,[Location], mfMaster.mfgr_pt_no,imfgr.W_KEY, lot.ExpDate, lot.Reference, Uniq_lot,lot.LotCode,  
	  -- 11/13/2019 Sachin B Added Column auto-Allocation which will not allow user to add new location 
  lot.PONUM,i.U_OF_MEAS,mpn.UniqMfgrHd,i.UNIQ_KEY, mfMaster.autolocation      
   HAVING SUM(QTYALLOC) >0      
 END      
END