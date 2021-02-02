-- =============================================      
-- Author: Rajendra K       
-- Create date: <08/16/2017>      
-- Description:Get Reserved Components      
-- Modification      
   -- 08/29/2017 Rajendra K : Added condtion imfgr.W_KEY = tp.W_KEY to get correct records from MFGR table      
   -- 09/15/2017 Rajendra K : i.matltype ASsign to RoHS AND ranamed to RoHSStr      
   -- 09/18/2017 Rajendra K : Added i.matltype in GROUP BY clause       
   -- 11/13/2017 Rajendra K : Set Paramters AS per naming standard      
   -- 11/13/2017 Rajendra K : Change JOIN  condition for InvtRes AND Temp table in all select sections      
   -- 11/13/2017 Rajendra K : Removed GROUP BY , Added table IpKey in JOIN  section,removed SUM for Qty_OH and replaced iReserveIpkey.QtyAllocated by Ipkey.QtyAllocatedTotal for scenari Only IPkey used      
   -- 11/16/2017 Rajendra K : Added table Invt_Res to get only reserved components in temptable section      
   -- 11/13/2017 Rajendra K : Set Paramters AS per naming standard      
   -- 11/13/2017 Rajendra K : Added tempResult table to hold result      
   -- 11/13/2017 Rajendra K : Removed RowNumber(id) from all select list and placed in final select list      
   -- 03/25/2019 Sachin B : Add res.W_KEY AS ToWkey in the Select Statement    
   -- 05/13/2019 Sachin B : Get the WO Components Data Which Don't have any reserved Qty        
   -- 06/11/2019 Sachin B : Convert Inner Join With PARTTYPE to Left Join      
   -- 06/12/2019 Sachin B : Get Issued Qty as Zero for the components which having 0 reserved Qty      
   -- 07/30/2019 Rajendra K : Added Ponum in selection list    
   -- 03/16/2020 Rajendra K : Removed the instore condition to display Supplier Bonded inventory material and added condition for IM.SFBL = 0    
   -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list  
   -- EXEC GetReservedComponents '0000102128',1,100      
-- =============================================      
CREATE PROCEDURE GetReservedComponents      
(      
  @woNo char(10)='',      
  @startRecord INT =1,      
  @endRecord INT=1000       
)      
AS      
BEGIN      
SET NoCount ON;       
      
 CREATE TABLE #tempPartsDetails (      
              WONO CHAR(10),      
              UNIQ_KEY CHAR(10),      
        SerialYes BIT,      
        UseIpKey BIT,      
        IsLotted BIT,      
        KASEQNUM CHAR(10),      
        W_KEY CHAR(10),      
              )      
      
  INSERT INTO #tempPartsDetails      
     SELECT K.WONO      
     ,K.UNIQ_KEY      
     ,i.SERIALYES      
     ,i.useipkey      
     ,ISNULL(P.LOTDETAIL,CAST (0 as BIT) )         
     ,K.KASEQNUM      
     ,imfgr.W_KEY      
  FROM INVENTOR i      
     INNER JOIN  KAMAIN k ON k.UNIQ_KEY = i.UNIQ_KEY      
     INNER JOIN  WOENTRY wo ON wo.WONO = k.WONO      
     INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY      
     INNER JOIN  INVTMFGR imfgr ON imfgr.UniqMfgrHd =mpn.UniqMfgrHd         
     INNER JOIN  MfgrMaster mfMaster ON mfMaster.MfgrMasterId = mpn.MfgrMasterId       
     INNER JOIN  Warehous w  ON w.UNIQWH = imfgr.UNIQWH      
  -- 06/11/2019 Sachin B : Convert Inner Join With PARTTYPE to Left Join          
     LEFT JOIN  PARTTYPE p ON p.PART_TYPE = i.PART_TYPE AND p.PART_CLASS =i.PART_CLASS            
     INNER JOIN INVT_RES ir ON wo.WONO = ir.WONO AND k.KASEQNUM = ir.KaSeqnum -- 11/16/2017 Rajendra K : Added to get only reserved components      
  WHERE       
     (@woNo IS NULL OR @woNo = '' OR k.wono= @woNo )       
     AND Warehouse <> 'WIP'      
     AND Warehouse <> 'WO-WIP'      
     AND Warehouse <> 'MRB'      
     AND Netable = 1      
     AND imfgr.IS_DELETED =0     
  AND imfgr.SFBL = 0     
     --AND imfgr.INSTORE =0    -- 03/16/2020 Rajendra K : Removed the instore condition to display Supplier Bonded inventory material and added condition for IM.SFBL = 0    
  GROUP BY k.UNIQ_KEY      
    ,k.KASEQNUM      
    ,i.SERIALYES      
    ,i.useipkey      
    ,p.LOTDETAIL      
    ,k.WONO      
    ,imfgr.W_KEY      
      
  SELECT tp.WONO      
     ,tp.KASEQNUM AS KaSeqNum      
     ,tp.SerialYes      
     ,tp.UseIpKey      
     ,tp.IsLotted      
     ,i.Uniq_Key      
     ,i.part_no AS PartNo      
     ,i.REVISION      
     ,CASE WHEN i.PART_SOURC <> 'CONSG' -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list  
   THEN CASE COALESCE(NULLIF(i.REVISION,''), '')            
   WHEN '' THEN  LTRIM(RTRIM(i.PART_NO))             
   ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION END   
   ELSE   
   CASE COALESCE(NULLIF(i.custrev,''), '')            
   WHEN '' THEN  LTRIM(RTRIM(i.CUSTPARTNO))             
   ELSE LTRIM(RTRIM(i.CUSTPARTNO)) + '/' + i.custrev END   
    END AS PartNoWithRev      
     ,i.ITAR      
     ,'' AS IPkeyunique       
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS FromWarehouse      
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS ToWarehouse      
     ,mfMaster.Partmfgr      
     ,mfMaster.mfgr_pt_no AS MfgrPartNo      
     ,imfgr.UniqMfgrHd      
     ,imfgr.UniqWh      
     ,Warehouse      
     ,Location      
     ,wa.Whno      
     ,SUM(res.QTYALLOC) AS 'QtyOh'      
     ,res.W_key      
     ,NULL AS ExpDate      
     ,NULL AS Reference      
     ,NULL AS Uniq_lot      
     ,NULL AS LotCode      
     ,NULL AS PONUM    -- 07/30/2019 Rajendra K : Added Ponum in selection list    
     ,Reserved      
     ,0.0 AS 'QtyUsed'      
     ,CAST(0 AS bit) AS IsReserve      
     ,i.U_OF_MEAS AS Unit      
     ,i.matltype RoHSStr -- 09/15/2017 Rajendra K : i.matltype ASsign to RoHS AND ranamed to RoHSStr      
     ,tp.UseIpKey AS SIDChk      
  -- 03/25/2019 Sachin B : Add res.W_KEY AS ToWkey in the Select Statement    
  ,res.W_KEY AS ToWkey     
  ,CAST( 0.0 As Numeric(12,2)) AS Issued       
  ,i.PART_SOURC    -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list  
     -- 11/13/2017 Rajendra K : Removed RowNumber(id)      
  INTO #tempResult -- 11/13/2017 Rajendra K : Added tempResult table to hold result      
  FROM #tempPartsDetails tp          
  INNER JOIN  INVENTOR i  ON tp.UNIQ_KEY = i.UNIQ_KEY AND tp.IsLotted = 0 AND tp.UseIpKey = 0            
  INNER JOIN  INVT_RES res ON tp.UNIQ_KEY = res.UNIQ_KEY --11/13/2017 Rajendra K : Change JOIN  condition        
  AND tp.WONO = res.WONO AND tp.KASEQNUM = res.KASEQNUM AND tp.W_KEY = res.W_KEY       
  INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY      
  INNER JOIN  MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId      
  INNER JOIN  INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = res.W_KEY      
  INNER JOIN  WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH      
  WHERE Warehouse <> 'WIP'      
  AND Warehouse <> 'WO-WIP'      
  AND Warehouse <> 'MRB'      
  AND Netable = 1      
  AND imfgr.Is_Deleted = 0      
  AND mpn.Is_deleted = 0       
  AND mfMaster.IS_DELETED=0      
  AND imfgr.SFBL = 0 -- 03/16/2020 Rajendra K : Removed the instore condition to display Supplier Bonded inventory material and added condition for IM.SFBL = 0     
  GROUP BY mfMaster.Partmfgr,mfMaster.mfgr_pt_no , Warehouse, Location, wa.Whno, res.W_key, Wh_gl_nbr, mfMaster.Mfgr_pt_no, mpn.UniqMfgrHd,mfMaster.qtyPerPkg,      
  Reserved, UniqSupno, imfgr.UniqWh,i.U_OF_MEAS,tp.WONO,i.UNIQ_KEY,i.ITAR,i.part_no,i.REVISION,imfgr.UniqMfgrHd,tp.SerialYes,tp.UseIpKey,tp.IsLotted,tp.KASEQNUM,      
  i.matltype,i.PART_SOURC,i.CUSTPARTNO,i.CUSTREV -- 09/18/2017 Rajendra K : Added i.matltype in GROUP BY clause   
  -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list      
  HAVING SUM(res.QTYALLOC) >0      
        
  UNION      
      
  SELECT DISTINCT tp.WONO      
     ,tp.KASEQNUM AS KaSeqNum      
     ,tp.SerialYes      
     ,tp.UseIpKey      
    ,tp.IsLotted      
     ,i.Uniq_Key      
     ,i.part_no AS PartNo      
     ,i.REVISION     
  -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list   
     ,CASE WHEN i.PART_SOURC <> 'CONSG'   
   THEN CASE COALESCE(NULLIF(i.REVISION,''), '')            
   WHEN '' THEN  LTRIM(RTRIM(i.PART_NO))             
   ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION END   
   ELSE   
   CASE COALESCE(NULLIF(i.custrev,''), '')            
   WHEN '' THEN  LTRIM(RTRIM(i.CUSTPARTNO))             
   ELSE LTRIM(RTRIM(i.CUSTPARTNO)) + '/' + i.custrev END   
    END AS PartNoWithRev     
     ,i.ITAR      
     ,'' AS IPkeyunique      
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS FromWarehouse      
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS ToWarehousemfMaster      
     ,PartMfgr      
     ,mfMaster.mfgr_pt_no AS MfgrPartNo      
     ,imfgr.UniqMfgrHd      
     ,imfgr.UniqWh      
     ,Warehouse      
     ,Location      
     ,w.Whno      
     ,SUM(QTYALLOC) AS QtyOh      
     ,res.W_KEY      
     ,lot.ExpDate      
     ,lot.Reference      
     ,Uniq_lot      
     ,lot.LotCode      
     ,lot.PONUM AS PONUM     -- 07/30/2019 Rajendra K : Added Ponum in selection list    
     ,Reserved      
     ,0.0 AS 'QtyUsed'      
     ,CAST(0 AS bit) AS IsReserve      
     ,i.U_OF_MEAS AS Unit      
     ,i.matltype RoHSStr -- 09/15/2017 Rajendra K : i.matltype ASsign to RoHS AND ranamed to RoHSStr      
     ,tp.UseIpKey AS SIDChk     
  -- 03/25/2019 Sachin B : Add res.W_KEY AS ToWkey in the Select Statement    
  ,res.W_KEY AS ToWkey      
  ,CAST( 0.0 As Numeric(12,2)) AS Issued   
  ,i.PART_SOURC -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list          
     -- 11/13/2017 Rajendra K : Removed RowNumber(id)      
  FROM #tempPartsDetails tp          
  INNER JOIN  INVENTOR i  ON tp.UNIQ_KEY = i.UNIQ_KEY AND tp.IsLotted = 1 AND tp.UseIpKey = 0            
     INNER JOIN  INVT_RES res ON tp.UNIQ_KEY = res.UNIQ_KEY --11/13/2017 Rajendra K : Change JOIN  condition        
     AND tp.WONO = res.WONO AND tp.KASEQNUM = res.KASEQNUM AND tp.W_KEY = res.W_KEY      
     INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY      
     INNER JOIN  MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId      
     INNER JOIN  INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = tp.W_KEY       
          -- 08/29/2017 Rajendra K : Added condtion imfgr.W_KEY = tp.W_KEY to get correct records from MFGR table      
     INNER JOIN  WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH      
     INNER JOIN  INVTLOT lot ON lot.W_KEY = imfgr.W_KEY AND  ISNULL(lot.EXPDATE,1) = ISNULL(res.EXPDATE,1)  AND lot.REFERENCE = res.REFERENCE AND lot.LOTCODE = res.LOTCODE      
  where WAREHOUSE <> 'WIP   '       
     AND WAREHOUSE <> 'WO-WIP'       
     AND Warehouse <> 'MRB   '      
     AND Netable = 1      
     AND imfgr.IS_DELETED = 0      
  AND SFBL = 0     
     --AND imfgr.INSTORE = 0     -- 03/16/2020 Rajendra K : Removed the instore condition to display Supplier Bonded inventory material and added condition for IM.SFBL = 0    
  GROUP BY mfMaster.PartMfgr,Warehouse,Location, mfMaster.mfgr_pt_no,imfgr.W_KEY, lot.ExpDate, lot.Reference, Uniq_lot,lot.LotCode,i.U_OF_MEAS,imfgr.UniqMfgrHd,      
  tp.WONO,i.UNIQ_KEY,i.ITAR,i.part_no,i.REVISION,imfgr.UniqMfgrHd,imfgr.UniqWh, w.Whno,res.W_KEY,Reserved,tp.SerialYes,tp.UseIpKey,tp.IsLotted,tp.KASEQNUM,lot.PONUM,     
  -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list  
  i.matltype,i.PART_SOURC,i.CUSTPARTNO,i.CUSTREV -- 09/18/2017 Rajendra K : Added i.matltype in GROUP BY clause       
  HAVING SUM(QTYALLOC) >0      
        
  UNION      
      
  SELECT DISTINCT tp.WONO      
     ,tp.KASEQNUM AS KaSeqNum      
     ,tp.SerialYes     
     ,tp.UseIpKey      
     ,tp.IsLotted      
     ,i.Uniq_Key      
     ,i.part_no AS PartNo      
     ,i.REVISION    
  -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list    
     ,CASE WHEN i.PART_SOURC <> 'CONSG'   
   THEN CASE COALESCE(NULLIF(i.REVISION,''), '')            
   WHEN '' THEN  LTRIM(RTRIM(i.PART_NO))             
   ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION END   
   ELSE   
   CASE COALESCE(NULLIF(i.custrev,''), '')            
   WHEN '' THEN  LTRIM(RTRIM(i.CUSTPARTNO))             
   ELSE LTRIM(RTRIM(i.CUSTPARTNO)) + '/' + i.custrev END   
    END AS PartNoWithRev      
     ,i.ITAR      
     ,ipReserve.IPKEYUNIQUE AS IPkeyunique      
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS FromWarehouse      
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS ToWarehousemfMaster      
     ,PartMfgr      
     ,mfMaster.mfgr_pt_no AS MfgrPartNo      
     ,imfgr.UniqMfgrHd      
     ,imfgr.UniqWh      
     ,Warehouse      
     ,Location      
     ,w.Whno      
     ,ip.qtyAllocatedTotal QtyOh -- 11/16/2017 Rajendra K : Removed SUM      
     ,res.W_KEY      
     ,NULL AS ExpDate      
     ,NULL AS Reference      
     ,NULL AS Uniq_lot      
     ,NULL AS LotCode      
    ,NULL AS PONUM    -- 07/30/2019 Rajendra K : Added Ponum in selection list    
     ,Reserved      
     ,0.0 AS 'QtyUsed'      
     ,CAST(0 AS bit) AS IsReserve      
     ,i.U_OF_MEAS AS Unit      
     ,i.Matltype RoHSStr -- 09/15/2017 Rajendra K : i.matltype ASsign to RoHS AND ranamed to RoHSStr      
     ,tp.UseIpKey AS SIDChk     
  -- 03/25/2019 Sachin B : Add res.W_KEY AS ToWkey in the Select Statement    
  ,res.W_KEY AS ToWkey      
  ,CAST( 0.0 As Numeric(12,2)) AS Issued   
  ,i.PART_SOURC-- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list         
        -- 11/13/2017 Rajendra K : Removed RowNumber(id)      
  FROM #tempPartsDetails tp          
     INNER JOIN  KAMAIN k ON tp.UNIQ_KEY = K.UNIQ_KEY AND tp.IsLotted = 0 AND tp.UseIpKey = 1  AND K.WONO = tp.WONO            
     JOIN Inventor i  ON k.Uniq_Key = i.Uniq_Key      
     JOIN INVT_RES res ON tp.UNIQ_KEY = res.UNIQ_KEY AND tp.WONO = res.WONO AND tp.KASEQNUM = res.KASEQNUM AND tp.W_KEY = res.W_KEY --11/13/2017 Rajendra K : Change JOIN  condition        
     JOIN iReserveIpKey ipReserve ON res.INVTRES_NO = ipReserve.invtres_no       
     INNER JOIN  IPKEY ip ON ipReserve.ipkeyunique = ip.ipkeyunique -- 11/16/2017 Rajendra K : Added table IPKEY in JOIN  condition      
     INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY      
     INNER JOIN  MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId      
     INNER JOIN  INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = tp.W_KEY      
                 -- 08/29/2017 Rajendra K : Added condtion imfgr.W_KEY = tp.W_KEY to get correct records from MFGR table      
     INNER JOIN  WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH      
  WHERE ip.qtyAllocatedTotal > 0  -- 11/16/2017 Rajendra K : Added Where Condition      
    -- 11/16/2017 Rajendra K : Removed GROUP BY section      
         
  UNION      
      
  SELECT DISTINCT tp.WONO      
     ,tp.KASEQNUM AS KaSeqNum      
     ,tp.SerialYes      
     ,tp.UseIpKey      
     ,tp.IsLotted      
     ,i.Uniq_Key      
     ,i.part_no AS PartNo      
     ,i.REVISION    
  -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list    
     ,CASE WHEN i.PART_SOURC <> 'CONSG'   
   THEN CASE COALESCE(NULLIF(i.REVISION,''), '')            
   WHEN '' THEN  LTRIM(RTRIM(i.PART_NO))             
   ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION END   
   ELSE   
   CASE COALESCE(NULLIF(i.custrev,''), '')            
   WHEN '' THEN  LTRIM(RTRIM(i.CUSTPARTNO))             
   ELSE LTRIM(RTRIM(i.CUSTPARTNO)) + '/' + i.custrev END   
    END AS PartNoWithRev     
     ,i.ITAR      
     ,ipReserve.IPKEYUNIQUE AS IPkeyunique      
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS FromWarehouse      
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS ToWarehousemfMaster      
     ,PartMfgr      
     ,mfMaster.mfgr_pt_no AS MfgrPartNo      
     ,imfgr.UniqMfgrHd      
     ,imfgr.UniqWh      
     ,Warehouse      
     ,Location      
      ,w.Whno      
     ,ip.qtyAllocatedTotal AS QtyOh -- 11/16/2017 Rajendra K : Removed SUM and replaced ipReserve.QtyAllocated by  ip.qtyAllocatedTotal       
     ,res.W_KEY      
     ,lot.ExpDate      
     ,lot.Reference      
     ,lot.Uniq_lot      
     ,lot.LotCode      
     ,lot.PONUM AS PONUM    -- 07/30/2019 Rajendra K : Added Ponum in selection list    
     ,Reserved      
     ,0.0 AS 'QtyUsed'      
     ,CAST(0 AS BIT) AS IsReserve      
     ,i.U_OF_MEAS AS Unit      
     ,i.MAtlType RoHSStr -- 09/15/2017 Rajendra K : i.matltype ASsign to RoHS AND ranamed to RoHSStr      
     ,tp.UseIpKey AS SIDChk     
  -- 03/25/2019 Sachin B : Add res.W_KEY AS ToWkey in the Select Statement    
  ,res.W_KEY AS ToWkey     
  ,CAST( 0.0 As Numeric(12,2)) AS Issued   
  ,i.PART_SOURC-- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list          
     -- 11/13/2017 Rajendra K : Removed RowNumber(id)      
     FROM #tempPartsDetails tp          
  INNER JOIN  INVENTOR i  ON tp.UNIQ_KEY = i.UNIQ_KEY AND tp.IsLotted = 1 AND tp.UseIpKey = 1            
     INNER JOIN INVT_RES res ON tp.UNIQ_KEY = res.UNIQ_KEY AND tp.WONO = res.WONO AND tp.KASEQNUM = res.KASEQNUM AND tp.W_KEY = res.W_KEY      
     JOIN iReserveIpKey ipReserve ON res.INVTRES_NO = ipReserve.invtres_no       
     INNER JOIN IPKEY ip ON ipReserve.ipkeyunique = ip.IPKEYUNIQUE      
     INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY      
     INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId      
     INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = tp.W_KEY      
             -- 08/29/2017 Rajendra K Added condtion imfgr.W_KEY = tp.W_KEY to get correct records from MFGR table      
     INNER JOIN WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH      
     INNER JOIN INVTLOT lot ON lot.W_KEY = imfgr.W_KEY AND  ISNULL(lot.EXPDATE,1) = ISNULL(res.EXPDATE,1)  AND lot.REFERENCE = res.REFERENCE AND lot.LOTCODE = res.LOTCODE      
      
  WHERE ip.qtyAllocatedTotal > 0  -- 11/16/2017 Rajendra K : Added Where Condition      
    -- 11/16/2017 Rajendra K : Removed GROUP BY section         
      
  -- 05/13/2019 Sachin B : Get the WO Components Data Which Don't have any reserved Qty        
  INSERT INTO #tempResult        
  SELECT DISTINCT tp.WONO            
     ,tp.KASEQNUM AS KaSeqNum            
     ,i.SerialYes            
     ,i.UseIpKey            
     ,ISNULL(p.LOTDETAIL,CAST(0 AS BIT) ) AS LOTDETAIL          
     ,i.Uniq_Key            
     ,i.part_no AS PartNo            
     ,i.REVISION    
  -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list          
     ,CASE WHEN i.PART_SOURC <> 'CONSG'   
   THEN CASE COALESCE(NULLIF(i.REVISION,''), '')            
   WHEN '' THEN  LTRIM(RTRIM(i.PART_NO))             
   ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION END   
   ELSE   
   CASE COALESCE(NULLIF(i.custrev,''), '')            
   WHEN '' THEN  LTRIM(RTRIM(i.CUSTPARTNO))             
   ELSE LTRIM(RTRIM(i.CUSTPARTNO)) + '/' + i.custrev END   
    END AS PartNoWithRev            
     ,i.ITAR            
     ,'' AS IPkeyunique            
     ,'' AS FromWarehouse            
     ,'' AS ToWarehousemfMaster            
     ,'' ASPartMfgr            
     ,'' AS MfgrPartNo            
     ,'' AS UniqMfgrHd            
     ,'' AS UniqWh            
     ,'' AS Warehouse            
     ,'' AS Location            
,'' AS Whno            
     ,0 AS QtyOh           
     ,'' AS W_KEY            
     ,NULL AS ExpDate            
     ,NULL AS Reference            
     ,NULL AS Uniq_lot            
     ,NULL AS LotCode    
  ,NULL AS PONUM    -- 07/30/2019 Rajendra K : Added Ponum in selection list           
     ,CAST(0 AS BIT) AS Reserved            
     ,0.0 AS 'QtyUsed'            
     ,CAST(0 AS BIT) AS IsReserve            
     ,i.U_OF_MEAS AS Unit            
     ,i.MAtlType RoHSStr          
     ,i.UseIpKey AS SIDChk             
     ,'' AS ToWkey        
  -- 06/12/2019 Sachin B : Get Issued Qty as Zero for the components which having 0 reserved Qty      
     ,0.0 AS Issued    
  ,i.PART_SOURC-- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list           
     FROM KAMAIN tp          
  INNER JOIN  INVENTOR i  ON tp.UNIQ_KEY = i.UNIQ_KEY         
  LEFT JOIN PARTTYPE p on i.PART_CLASS = p.PART_CLASS AND i.PART_TYPE = p.PART_TYPE       
  WHERE tp.UNIQ_KEY NOT IN (SELECT UNIQ_KEY FROM #tempResult) and tp.WONO =@woNo        
    SELECT *,ROW_NUMBER() OVER (ORDER BY  Uniq_Key) AS Id FROM #tempResult -- 11/13/2017 Rajendra K : Added to fetch result      
END