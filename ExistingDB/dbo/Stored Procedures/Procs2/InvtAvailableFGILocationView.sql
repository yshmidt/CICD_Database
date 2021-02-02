-- =============================================    
-- Author:  ???    
-- Create date: ???    
-- Description: ???    
-- 03/19/14 VL remove CountFlag='' criteria and changed to catch in form level, becaue if user only has one and try to select the one WH    
--    that's in cycle count, the original code would return 0 record and new invtmfgr record will be created    
-- Modified:  10/09/14 YS remove invtmfhd table and replace with 2 new tables    
-- 07/18/16 Sachin B Add QtyUsed in Select statement    
-- 09/06/16 Sachin B change QTY_OH to (QTY_OH - Reserved) AS 'QtyOh' and Add mfgr_pt_no in select statement    
-- 09/21/16 Sachin B Add qtyPerPkg in Select statement    
-- 09/30/16 Sachin B Add two parameter for get the reserve warehouse Data and Select Data for those warehouse    
-- 10/25/16 Sachin B Add one parameter U_OF_MEAS     
-- 11/15/16 Sachin B check delted flag and warehouse not equal 'WIP','WO-WIP','MRB' conditions and QtyUsed to 0.0    
-- 12/12/16 Sachin B Add having clause sum(QTYALLOC) > 0 condition     
-- 07/20/2017 Sachin B Add parameter @kaseqnum and check kaseqnum for the line items implementation    
-- 09/26/2017 Sachin B Add Parameter ToWarehouse and ToWkey    
-- 11/27/2017 Sachin B Add @isReconciliation Parameter and get ReturnQty Conditionaliy    
-- 04/01/2019 Sachin B Get ReturnQty As Zero  
-- 04/16/2019 Sachin B get consign Part uniqkey if it exists   
-- 04/18/2019 Sachin B Get the Approved Manufacture List for un-reserved Parts  
-- 04/25/2019 Sachin B Add UniqWH in Select Statment, Add in Join Also  
-- 11/13/2019 Sachin B Added Column auto-Allocation which will not allow user to add new location   
-- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials  
-- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1) 
-- 03/31/2020 Sachin B Remove And condition  of uniqwh from join 
-- InvtAvailableFGILocationView '_1LR0NAL9P','0000102065',0,'81PCMCX5M3',0,'0000000002'     
-- =============================================        
CREATE PROCEDURE [dbo].[InvtAvailableFGILocationView]     
 -- Add the parameters for the stored procedure here    
 @gUniq_key CHAR(10)=' ',    
     -- 09/30/16 Sachin B Add two parameter for get the reserve warehouse Data and Select Data for those warehouse    
 @wono CHAR(10),    
 @IsReserve BIT,    
 @kaseqnum CHAR(10),    
 -- 11/27/2017 Sachin B Add @isReconciliation Parameter and get ReturnQty Conditionaliy    
 @isReconciliation BIT =0,  
 @CustNo CHAR(10)=''         
AS    
BEGIN    
    
-- SET NOCOUNT ON added to prevent extra result sets from    
-- interfering with SELECT statements.    
SET NOCOUNT ON;    
  
-- 04/16/2019 Sachin B get consign Part uniqkey if it exists   
--SET @gUniq_key = ISNULL((SELECT UNIQ_KEY FROM INVENTOR WHERE INT_UNIQ = @gUniq_key AND CUSTNO = @CustNo),@gUniq_key);  
-- 04/18/2019 Sachin B Get the Approved Manufacture List for un-reserved Parts  
DECLARE @bomParentUniqKey char(10), @congUniqKey CHAR(10) ='',@nonNettable BIT;  
SET @bomParentUniqKey = (SELECT uniq_key FROM WOENTRY WHERE WONO =@wono);  
  
SET @nonNettable = (SELECT CONVERT(Bit,ISNULL(WM.settingValue,MS.settingValue)) FROM MnxSettingsManagement MS   
 LEFT JOIN WmSettingsManagement WM ON  MS.settingId = WM.settingId            
 WHERE SettingName  = 'allowUseOfNonNettableWarehouseLocation')  
  
  
IF(@CustNo<>'' AND @gUniq_key<>'')  
BEGIN  
  SET @congUniqKey = (SELECT Uniq_Key FROM INVENTOR WHERE INT_UNIQ =@gUniq_key AND CUSTNO =@CustNo)  
END   
    
--10/09/14 YS remove invtmfhd table and replace with 2 new tables    
--07/18/16 Sachin B Add QtyUsed in Select statement    
--09/21/16 Sachin B Add qtyPerPkg in Select statement    
IF(@IsReserve = 0)    
 BEGIN   
  IF (@congUniqKey IS NOT NULL AND @congUniqKey<>'')  
   BEGIN  
  ;With InternalPartAVL AS(    
       -- 04/25/2019 Sachin B Add UniqWH in Select Statment, Add in Join Also  
    SELECT QTY_OH - Reserved AS 'QtyOh', Reserved,i.UNIQ_KEY,mfMaster.Partmfgr,mfMaster.mfgr_pt_no AS MfgrPartNo,W_KEY,wa.UNIQWH  
    FROM Inventor i   
    INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY  AND mpn.uniq_key =@gUniq_key  
    INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
    INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd  
    INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH    
      -- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)   
    AND Warehouse <> 'WIP' AND Warehouse <> 'WO-WIP' AND Warehouse <> 'MRB' AND ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)   
      AND imfgr.Is_Deleted = 0 AND mpn.Is_deleted = 0 AND mfMaster.IS_DELETED=0    
     -- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials    
      --AND imfgr.Instore = 0  
   )  
   ,ConsgPartAVL AS(    
    SELECT mfMaster.Partmfgr,mfMaster.mfgr_pt_no AS MfgrPartNo, Warehouse, Location, wa.Whno, W_key, Wh_gl_nbr, mpn.UniqMfgrHd,mfMaster.qtyPerPkg,  
    UniqSupno, imfgr.UniqWh,0.0 AS 'QtyUsed',CAST(0 AS BIT) AS IsReserve,i.U_OF_MEAS AS Unit,  
    i.INT_UNIQ,i.UNIQ_KEY    
    FROM Inventor i   
    INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY  AND mpn.uniq_key =@congUniqKey  
    INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
    INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd  
    INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH   
      -- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)    
    AND Warehouse <> 'WIP' AND Warehouse <> 'WO-WIP' AND Warehouse <> 'MRB'  AND ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)  
      AND imfgr.Is_Deleted = 0 AND mpn.Is_deleted = 0 AND mfMaster.IS_DELETED=0    
 -- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials    
    --AND imfgr.Instore = 0      
   )  
   SELECT c.Partmfgr,c.MfgrPartNo, c.Warehouse, c.[Location], c.Whno, i.W_key, c.Wh_gl_nbr,c.UniqMfgrHd,c.qtyPerPkg,i.QtyOh,i.Reserved,c.UniqSupno, c.UniqWh,  
   c.QtyUsed,c.IsReserve,c.Unit  
   FROM ConsgPartAVL c  
   -- 04/25/2019 Sachin B Add UniqWH in Select Statment, Add in Join Also  
   -- 03/31/2020 Sachin B Remove And condition  of uniqwh from join 
   INNER JOIN InternalPartAVL i ON i.UNIQ_KEY =c.INT_UNIQ  AND i.PartMfgr =c.PartMfgr AND i.MfgrPartNo =c.MfgrPartNo --AND i.UNIQWH =c.UNIQWH      
   WHERE c.UNIQ_KEY NOT IN  
   (  
         SELECT UNIQ_KEY   
   FROM ANTIAVL A   
   WHERE A.BOMPARENT = @bomParentUniqKey AND A.UNIQ_KEY = c.UNIQ_KEY AND A.PARTMFGR =c.Partmfgr AND A.MFGR_PT_NO =c.MfgrPartNo   
   )  
    END  
  ELSE  
    BEGIN  
       SELECT mfMaster.Partmfgr,mfMaster.mfgr_pt_no AS MfgrPartNo, Warehouse, Location, wa.Whno, W_key, Wh_gl_nbr, mpn.UniqMfgrHd,mfMaster.qtyPerPkg,  
    QTY_OH - Reserved AS 'QtyOh', Reserved,UniqSupno, imfgr.UniqWh,0.0 AS 'QtyUsed',CAST(0 AS BIT) AS IsReserve,i.U_OF_MEAS AS Unit,i.UNIQ_KEY    
    FROM Inventor i   
    INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY  and mpn.uniq_key =@gUniq_key  
    INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
    INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd  
    INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH    
       -- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)   
    AND Warehouse <> 'WIP' AND Warehouse <> 'WO-WIP' AND Warehouse <> 'MRB' AND ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)  
      AND imfgr.Is_Deleted = 0 AND mpn.Is_deleted = 0 AND mfMaster.IS_DELETED=0    
    -- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials    
 --AND imfgr.Instore = 0      
    WHERE i.UNIQ_KEY NOT IN  
    (  
         SELECT UNIQ_KEY   
      FROM ANTIAVL A   
      WHERE A.BOMPARENT =@bomParentUniqKey AND A.UNIQ_KEY = i.UNIQ_KEY AND A.PARTMFGR =mfMaster.Partmfgr AND A.MFGR_PT_NO =mfMaster.mfgr_pt_no   
       )  
 END   
 END    
ELSE    
    BEGIN    
   -- 09/30/16 Sachin B Add two parameter for get the reserve warehouse Data and Select Data for those warehouse    
   -- 10/25/16 Sachin B Add one parameter U_OF_MEAS    
   -- 09/26/2017 Sachin B Add Parameter ToWarehouse and ToWkey    
   SELECT mfMaster.Partmfgr,mfMaster.mfgr_pt_no AS MfgrPartNo, Warehouse, Location, wa.Whno, res.W_key, Wh_gl_nbr, mfMaster.Mfgr_pt_no,  
  mpn.UniqMfgrHd,mfMaster.qtyPerPkg,     
   SUM(res.QTYALLOC) AS 'QtyOh', Reserved,    
   -- 11/27/2017 Sachin B Add @isReconciliation Parameter and get ReturnQty Conditionaliy   
   --, CASE WHEN @isReconciliation =1 THEN (SUM(QTYALLOC)) ELSE 0 END AS ReturnQty,    
   -- 04/01/2019 Sachin B Get Return Qty As Zero  
   0.0 AS ReturnQty,   
    UniqSupno, imfgr.UniqWh,0.0 AS 'QtyUsed',cast(0 AS BIT) AS IsReserve,i.U_OF_MEAS AS Unit    
   ,RTRIM(wa.Warehouse)+' / '+RTRIM(imfgr.Location) AS ToWarehouse,res.W_key AS ToWkey,i.UNIQ_KEY    
-- 11/13/2019 Sachin B Added Column auto-Allocation which will not allow user to add new location   
    , mfMaster.autolocation     
   FROM INVENTOR i    
   INNER JOIN INVT_RES res ON res.UNIQ_KEY = i.UNIQ_KEY AND res.WONO = @wono    
   INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY    
   INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
   INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = res.W_KEY    
   INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH    
   WHERE     
   -- 11/15/16 Sachin B check delted flag and warehouse not equal 'WIP','WO-WIP','MRB' conditions    
    -- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)    
   Warehouse <> 'WIP' AND Warehouse <> 'WO-WIP' AND Warehouse <> 'MRB'  AND ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)   
  AND imfgr.Is_Deleted = 0 AND mpn.Is_deleted = 0 AND mfMaster.IS_DELETED=0     
   AND i.UNIQ_KEY = @gUniq_key     
   -- 07/20/2017 Sachin B Add parameter @kaseqnum and check kaseqnum for the line items implementation    
   AND res.KASEQNUM = @kaseqnum    
   GROUP BY mfMaster.Partmfgr,mfMaster.mfgr_pt_no , Warehouse, Location, wa.Whno, res.W_key, Wh_gl_nbr, mfMaster.Mfgr_pt_no, mpn.UniqMfgrHd,mfMaster.qtyPerPkg,    
-- 11/13/2019 Sachin B Added Column auto-Allocation which will not allow user to add new location   
   Reserved, UniqSupno, imfgr.UniqWh,i.U_OF_MEAS,i.UNIQ_KEY, mfMaster.autolocation     
   -- 12/12/16 Sachin B Add having clause sum(QTYALLOC) > 0 condition    
   HAVING SUM(res.QTYALLOC) >0    
 END    
END