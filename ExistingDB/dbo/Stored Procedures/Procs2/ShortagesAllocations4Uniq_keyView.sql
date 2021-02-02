-- =============================================          
-- Author:  Yelena Shmidt        
-- Create date: 04/28/10 (Glynn's BD)        
--  Description: Get Shortage and allocations for one uniq_key        
--  10/09/14 YS removed invtmfhd table and replaced with 2 new tables        
--  04/14/15 YS Location length is changed to varchar(256)          
--  10/01/19 SatyawanH : modified the SP to connect kamain and invt_res table       
--    and Display serial number information for the part if it is serial typ      
--  10/16/19 SatyawanH : Display the Reserve/short qty      
-- 04/21/2020 Rajendra K : Added new CTE as Data and added outer join to get the "Extra kit Qty"     
-- EXEC ShortagesAllocations4Uniq_keyView @uniqKey='_20Y0TCBLW',@startRecord=1,@endRecord=500,@sortExpression='WONO desc' --_33P0R73ZH        
-- =============================================          
CREATE PROCEDURE ShortagesAllocations4Uniq_keyView          
(          
  @uniqKey char(10)=''          
 ,@startRecord int =1        
 ,@endRecord int =100        
 ,@filter NVARCHAR(1000) = null        
 ,@sortExpression NVARCHAR(1000) = null        
)          
AS          
BEGIN          
 -- SET NOCOUNT ON added to prevent extra result sets from        
 -- interfering with SELECT statements.        
 SET NOCOUNT ON;        
 -- Insert statements for procedure here        
 ---- Shortages        
 ----  10/09/14 YS removed invtmfhd table and replaced with 2 new tables        
 ---- 04/14/15 YS Location length is changed to varchar(256)        
 --SELECT KaMain.WoNo,CAST('' as char(10)) as PrjNumber, CAST(ISNULL(Dept_Name,'') as char(20)) AS Dept_name, CAST('' as char(8)) as PartMfgr,CAST('Short' as char(6)) AS Warehouse,         
 -- CAST(CASE WHEN LineShort=1 THEN 'Line Shortage' ELSE 'Kit Shortage' END as varchar(256)) AS Location,         
 -- CAST(0.00 as numeric(11,2)) AS AllocQty, ShortQty,CAST('' as char(10)) AS fk_PrjUnique        
 --FROM Kamain LEFT OUTER JOIN Depts         
 -- ON Kamain.Dept_id=Depts.Dept_id         
 -- INNER JOIN WoEntry ON  KaMain.WoNo=WoEntry.WoNo        
 --WHERE KaMain.Uniq_key = @lcUniq_Key         
 -- AND Kamain.IgnoreKit=0        
 -- AND ShortQty > 0         
 -- AND WoEntry.WoNo = KaMain.WoNo         
 -- AND WoEntry.Openclos <> 'Cancel'         
 -- AND WoEntry.Openclos <> 'Closed'         
 --UNION        
 ---- select allocations using derived data set in the "from"        
 --SELECT T1.Wono,T1.PrjNumber,SPACE(20) as Dept_name,T1.Partmfgr,T1.Warehouse,T1.Location,T1.AllocQty,        
 --CAST(0.00 as numeric(11,2)) as ShortQty,T1.Fk_PrjUnique         
 --FROM         
 --(        
 ---- first select for allocation for projects        
 --SELECT Invt_res.WoNo,PjctMain.PrjNumber,         
 -- m.PartMfgr, Warehouse, Location, SUM(QtyAlloc) AS AllocQty,         
 -- Invt_Res.Fk_PrjUnique         
 ----  10/09/14 YS removed invtmfhd table and replaced with 2 new tables        
 --FROM Invt_Res,PjctMain,InvtMfgr ,InvtMPNLink L,MfgrMaster M,Warehous        
 --WHERE Invt_res.Uniq_key = @lcUniq_Key         
 --and Invt_res.Fk_PrjUnique=PjctMain.PrjUnique         
 --AND Invt_Res.W_key =InvtMfgr.W_key        
 --and L.UniqMfgrHd = Invtmfgr.UniqMfgrHd        
 --and l.mfgrMasterId=m.MfgrMasterId        
 --AND Warehous.UniqWh = InvtMfgr.UniqWh        
 --GROUP BY wono,prjnumber,partmfgr,warehouse,location,fk_prjunique        
 --HAVING SUM(QtyAlloc)>0        
 --UNION        
 ---- second allocations for work order        
 --SELECT Invt_res.WoNo,SPACE(10) as PrjNumber,         
 -- m.PartMfgr, Warehouse, Location, SUM(QtyAlloc) AS AllocQty,         
 -- Invt_Res.Fk_PrjUnique         
 ----  10/09/14 YS removed invtmfhd table and replaced with 2 new tables        
 --FROM Invt_Res,InvtMfgr ,InvtMPNLink L, MfgrMaster M,Warehous        
 --WHERE Invt_res.Uniq_key = @lcUniq_Key         
 --AND Invt_Res.W_key =InvtMfgr.W_key        
 --and L.UniqMfgrHd = Invtmfgr.UniqMfgrHd        
 --and m.MfgrMasterId=l.mfgrMasterId        
 --AND Warehous.UniqWh = InvtMfgr.UniqWh        
 --AND Invt_res.Fk_PrjUnique=' '        
 --GROUP BY wono,partmfgr,warehouse,location,fk_prjunique         
 --HAVING SUM(QtyAlloc)>0) t1        
      
 DECLARE @sqlQuery NVARCHAR(MAX),@rowCount NVARCHAR(MAX)        
 CREATE TABLE #tempPartsDetails (          
              WONO CHAR(10)         
    ,UNIQ_KEY CHAR(10)        
    ,SerialYes BIT        
    ,UseIpKey BIT        
    ,IsLotted BIT        
    ,KASEQNUM CHAR(10)        
    ,W_KEY CHAR(10)        
    ,DEPT_ID CHAR(10)        
    ,SHORTQTY numeric(12,2))          
          
  INSERT INTO #tempPartsDetails          
     SELECT K.WONO          
     ,k.UNIQ_KEY          
     ,i.SERIALYES          
     ,i.useipkey          
     ,ISNULL(P.LOTDETAIL,CAST (0 as BIT) )             
     ,K.KASEQNUM          
     ,imfgr.W_KEY         
     ,k.DEPT_ID        
     ,k.SHORTQTY         
  FROM INVENTOR i          
     INNER JOIN KAMAIN k ON k.UNIQ_KEY = i.UNIQ_KEY          
     INNER JOIN WOENTRY wo ON wo.WONO = k.WONO          
     INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY          
     INNER JOIN INVTMFGR imfgr ON imfgr.UniqMfgrHd =mpn.UniqMfgrHd and i.uniq_key=imfgr.uniq_key      
     INNER JOIN MfgrMaster mfMaster ON mfMaster.MfgrMasterId = mpn.MfgrMasterId           
     INNER JOIN Warehous w  ON w.UNIQWH = imfgr.UNIQWH          
     LEFT JOIN PARTTYPE p ON p.PART_TYPE = i.PART_TYPE AND p.PART_CLASS =i.PART_CLASS                
     INNER JOIN INVT_RES ir ON wo.WONO = ir.WONO AND k.KASEQNUM = ir.KaSeqnum and imfgr.w_key=ir.w_key   
  WHERE           
     (@uniqKey IS NULL OR @uniqKey = '' OR i.UNIQ_KEY= @uniqKey)           
     AND w.Warehouse <> 'WIP'          
     AND w.Warehouse <> 'WO-WIP'          
     AND w.Warehouse <> 'MRB'          
     AND imfgr.IS_DELETED =0          
     AND imfgr.INSTORE =0          
  GROUP BY k.UNIQ_KEY         
    ,k.KASEQNUM          
    ,i.SERIALYES          
    ,i.useipkey          
    ,p.LOTDETAIL          
    ,k.WONO          
    ,imfgr.W_KEY          
    ,k.DEPT_ID         
    ,k.SHORTQTY        
      
 SELECT substring(tp.WONO, patindex('%[^0]%',tp.WONO), 10) WONO,tp.DEPT_ID,SUM(res.QTYALLOC) Quantity, k.SHORTQTY Shortage       
  ,TRIM(i.PART_NO) + IIF((TRIM(i.REVISION) = ''), '', '/'+TRIM(i.REVISION)) [AssemblyNoRev]        
  ,TRIM(mfMaster.PartMfgr) MFGR,TRIM(mfMaster.mfgr_pt_no) [MFGRPartNo]        
  ,TRIM(wa.WAREHOUSE) + IIF((TRIM(imfgr.[LOCATION])=''),'','/'+imfgr.[LOCATION]) [WHLoc]        
  ,NULL AS ExpDate          
  ,NULL AS Reference          
  ,NULL AS Uniq_lot          
  ,NULL AS LotCode          
  ,NULL AS PONUM        
  ,tp.KASEQNUM AS KaSeqNum          
  ,tp.SerialYes          
  ,tp.UseIpKey        
  ,tp.IsLotted        
  ,'' MTC        
  ,res.W_KEY       
 INTO #tempResult           
 FROM #tempPartsDetails tp         
 INNER JOIN KAMAIN k ON k.UNIQ_KEY = tp.UNIQ_KEY  AND tp.KASEQNUM = k.KASEQNUM         
 INNER JOIN INVENTOR i  ON k.BOMPARENT = i.UNIQ_KEY AND tp.IsLotted = 0 AND tp.UseIpKey = 0         
 INNER JOIN INVT_RES res ON tp.UNIQ_KEY = res.UNIQ_KEY AND tp.WONO = res.WONO AND tp.KASEQNUM = res.KASEQNUM AND tp.W_KEY = res.W_KEY           
 INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = k.UNIQ_KEY          
 INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId          
 INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =k.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = res.W_KEY          
 INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH          
 WHERE Warehouse <> 'WIP'          
 AND Warehouse <> 'WO-WIP'          
 AND Warehouse <> 'MRB'          
 AND imfgr.Is_Deleted = 0          
 AND mpn.Is_deleted = 0           
 AND mfMaster.IS_DELETED=0           
 GROUP BY tp.WONO,mfMaster.Partmfgr,mfMaster.mfgr_pt_no , wa.Warehouse, Location, wa.Whno, res.W_key, Wh_gl_nbr, mfMaster.Mfgr_pt_no,         
   mpn.UniqMfgrHd,mfMaster.qtyPerPkg,Reserved, UniqSupno, imfgr.UniqWh,i.U_OF_MEAS,tp.WONO,i.UNIQ_KEY,i.ITAR,i.part_no,        
   i.REVISION,imfgr.UniqMfgrHd,tp.SerialYes,tp.UseIpKey,tp.IsLotted,tp.KASEQNUM,i.matltype,tp.DEPT_ID,k.SHORTQTY         
 HAVING SUM(res.QTYALLOC)>0          
            
  UNION          
       
 SELECT substring(tp.WONO, patindex('%[^0]%',tp.WONO), 10) WONO,tp.DEPT_ID,SUM(res.QTYALLOC) Quantity,k.SHORTQTY Shortage        
  ,TRIM(i.PART_NO) + IIF((TRIM(i.REVISION) = ''), '', '/'+TRIM(i.REVISION)) [AssemblyNoRev]        
  ,TRIM(mfMaster.PartMfgr) MFGR,TRIM(mfMaster.mfgr_pt_no) [MFGRPartNo]        
  ,TRIM(wa.WAREHOUSE) + IIF((TRIM(imfgr.[LOCATION])=''),'','/'+imfgr.[LOCATION]) [WHLoc]        
  ,convert(varchar, lot.ExpDate, 1)          
  ,lot.Reference            
  ,lot.UNIQ_LOT           
  ,lot.LotCode          
  ,lot.PONUM AS PONUM        
  ,tp.KASEQNUM AS KaSeqNum          
  ,tp.SerialYes          
  ,tp.UseIpKey        
  ,tp.IsLotted        
     ,'' MTC        
  ,res.W_KEY       
 FROM #tempPartsDetails tp          
 INNER JOIN KAMAIN k ON k.UNIQ_KEY = tp.UNIQ_KEY AND tp.KASEQNUM = k.KASEQNUM        
 INNER JOIN INVENTOR i  ON k.BOMPARENT = i.UNIQ_KEY AND tp.IsLotted = 1 AND tp.UseIpKey = 0                
 INNER JOIN INVT_RES res ON tp.UNIQ_KEY = res.UNIQ_KEY AND tp.WONO = res.WONO AND tp.KASEQNUM = res.KASEQNUM AND tp.W_KEY = res.W_KEY          
 INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = k.UNIQ_KEY          
 INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId          
 INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =k.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = tp.W_KEY           
 INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH          
 INNER JOIN INVTLOT lot ON lot.W_KEY = imfgr.W_KEY AND  ISNULL(lot.EXPDATE,1) = ISNULL(res.EXPDATE,1)          
    AND lot.REFERENCE = res.REFERENCE AND lot.LOTCODE = res.LOTCODE          
 WHERE WAREHOUSE <> 'WIP'           
 AND WAREHOUSE <> 'WO-WIP'           
 AND Warehouse <> 'MRB'          
 AND imfgr.IS_DELETED = 0           
 AND imfgr.INSTORE = 0           
 GROUP BY mfMaster.Partmfgr,mfMaster.mfgr_pt_no , wa.Warehouse, Location, wa.Whno, res.W_key, Wh_gl_nbr, mfMaster.Mfgr_pt_no,         
   mpn.UniqMfgrHd,mfMaster.qtyPerPkg,Reserved, UniqSupno, imfgr.UniqWh,i.U_OF_MEAS,tp.WONO,i.UNIQ_KEY,i.ITAR,i.part_no,        
   i.REVISION,imfgr.UniqMfgrHd,tp.SerialYes,tp.UseIpKey,tp.IsLotted,tp.KASEQNUM,          
   i.matltype,tp.DEPT_ID,k.SHORTQTY,lot.ExpDate,lot.Reference,Uniq_lot,lot.LotCode,lot.PONUM         
 HAVING SUM(QTYALLOC) >0          
            
 UNION          
          
  SELECT substring(tp.WONO, patindex('%[^0]%',tp.WONO), 10) WONO,tp.DEPT_ID,tt.qty Quantity, k.SHORTQTY Shortage      
  ,TRIM(i.PART_NO) + IIF((TRIM(i.REVISION) = ''), '', '/'+TRIM(i.REVISION)) [AssemblyNoRev]      
  ,TRIM(mfMaster.PartMfgr) MFGR,TRIM(mfMaster.mfgr_pt_no) [MFGRPartNo]        
  ,TRIM(wa.WAREHOUSE) + IIF((TRIM(imfgr.[LOCATION])=''),'','/'+imfgr.[LOCATION]) [WHLoc]        
  ,NULL AS ExpDate          
  ,NULL AS Reference          
  ,NULL AS Uniq_lot          
  ,NULL AS LotCode          
  ,NULL AS PONUM        
  ,tp.KASEQNUM AS KaSeqNum          
  ,tp.SerialYes          
  ,tp.UseIpKey        
  ,tp.IsLotted        
  ,ip.IPKEYUNIQUE MTC        
  ,res.W_KEY        
  FROM #tempPartsDetails tp              
     INNER JOIN KAMAIN k ON tp.UNIQ_KEY = K.UNIQ_KEY AND tp.IsLotted = 0 AND tp.UseIpKey = 1  AND K.WONO = tp.WONO AND tp.KASEQNUM = k.KASEQNUM               
     INNER JOIN Inventor i  ON k.BOMPARENT=i.UNIQ_KEY       
     INNER JOIN INVT_RES res ON tp.UNIQ_KEY = res.UNIQ_KEY AND tp.WONO = res.WONO AND tp.KASEQNUM = res.KASEQNUM AND tp.W_KEY = res.W_KEY         
     outer apply(select ipkeyunique,SUM(qtyAllocated) qty from iReserveIpKey where  tp.KASEQNUM = iReserveIpKey.KASEQNUM       
                     group by KaSeqnum,ipkeyunique ) tt      
  INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = k.UNIQ_KEY          
     INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId          
     INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =k.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = tp.W_KEY          
     INNER JOIN IPKEY ip ON tt.ipkeyunique = ip.ipkeyunique  and ip.W_KEY=imfgr.W_KEY and ip.UNIQMFGRHD=imfgr.UNIQMFGRHD           INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH          
   WHERE ip.qtyAllocatedTotal > 0  AND tt.qty > 0        
   GROUP BY tp.WONO,mfMaster.Partmfgr,mfMaster.mfgr_pt_no , wa.Warehouse, Location, wa.Whno, res.W_key, Wh_gl_nbr, mfMaster.Mfgr_pt_no,         
   mpn.UniqMfgrHd,mfMaster.qtyPerPkg,Reserved, UniqSupno, imfgr.UniqWh,i.U_OF_MEAS,tp.WONO,i.UNIQ_KEY,i.ITAR,i.part_no,        
   i.REVISION,imfgr.UniqMfgrHd,tp.SerialYes,tp.UseIpKey,tp.IsLotted,ip.IPKEYUNIQUE,tp.KASEQNUM,          
   i.matltype,tp.DEPT_ID,k.SHORTQTY,tt.qty  
      
  UNION          
          
  SELECT substring(tp.WONO, patindex('%[^0]%',tp.WONO), 10) WONO,tp.DEPT_ID,tt.qty Quantity,k.SHORTQTY Shortage      
 ,TRIM(i.PART_NO) + IIF((TRIM(i.REVISION) = ''), '', '/'+TRIM(i.REVISION)) [AssemblyNoRev]        
  ,TRIM(mfMaster.PartMfgr) MFGR,TRIM(mfMaster.mfgr_pt_no) [MFGRPartNo]        
  ,TRIM(wa.WAREHOUSE) + IIF((TRIM(imfgr.[LOCATION])=''),'','/'+imfgr.[LOCATION]) [WHLoc]        
  ,convert(varchar, lot.ExpDate, 1)          
  ,lot.Reference            
  ,lot.UNIQ_LOT           
  ,lot.LotCode          
  ,lot.PONUM AS PONUM        
  ,tp.KASEQNUM AS KaSeqNum          
  ,tp.SerialYes          
  ,tp.UseIpKey        
  ,tp.IsLotted        
  ,ip.IPKEYUNIQUE MTC        
  ,res.W_KEY        
  FROM #tempPartsDetails tp         
  INNER JOIN KAMAIN k ON tp.UNIQ_KEY = k.UNIQ_KEY  AND tp.KASEQNUM = k.KASEQNUM         
   INNER JOIN INVENTOR i  ON k.BOMPARENT = i.UNIQ_KEY AND tp.IsLotted = 1 AND tp.UseIpKey = 1                
   INNER JOIN INVT_RES res ON tp.UNIQ_KEY = res.UNIQ_KEY AND tp.WONO = res.WONO AND tp.KASEQNUM = res.KASEQNUM AND tp.W_KEY = res.W_KEY          
   outer apply(SELECT ipkeyunique,SUM(qtyAllocated) qty FROM iReserveIpKey WHERE  tp.KASEQNUM = iReserveIpKey.KASEQNUM       
            GROUP BY KaSeqnum,ipkeyunique ) tt      
   INNER JOIN IPKEY ip ON tt.ipkeyunique = ip.IPKEYUNIQUE          
   INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = k.UNIQ_KEY          
   INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId          
   INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =k.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = tp.W_KEY          
   INNER JOIN WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH          
   INNER JOIN INVTLOT lot ON lot.W_KEY = imfgr.W_KEY AND  ISNULL(lot.EXPDATE,1) = ISNULL(res.EXPDATE,1)  AND lot.REFERENCE = res.REFERENCE AND lot.LOTCODE = res.LOTCODE          
  WHERE ip.qtyAllocatedTotal > 0 AND tt.qty > 0           
   GROUP BY tp.WONO,mfMaster.Partmfgr,mfMaster.mfgr_pt_no , wa.Warehouse, Location, wa.Whno, res.W_key, Wh_gl_nbr, mfMaster.Mfgr_pt_no,         
   mpn.UniqMfgrHd,mfMaster.qtyPerPkg,Reserved, UniqSupno, imfgr.UniqWh,i.U_OF_MEAS,tp.WONO,i.UNIQ_KEY,i.ITAR,i.part_no,        
   i.REVISION,imfgr.UniqMfgrHd,tp.SerialYes,tp.UseIpKey,tp.IsLotted,ip.IPKEYUNIQUE,          
   i.matltype,tp.DEPT_ID,k.SHORTQTY,lot.ExpDate,lot.Reference,Uniq_lot,lot.LotCode,lot.PONUM,tp.KASEQNUM,tt.qty      
      
--SELECT * into #TEMP FROM (
 ;with Data AS (    -- 04/21/2020 Rajendra K : Added new CTE as Data and added outer join to get the "Extra kit Qty" 
  SELECT 0 As IsShort, IIF(Quantity>0,1,0) As IsReserve, * FROM #tempResult WHERE Quantity > 0        
  UNION      
  SELECT IIF(shortage>0,1,0) As IsShort, 0 As IsReserve,WONO,DEPT_ID,Shortage AS Quantity,Shortage,AssemblyNoRev,      
  '' MFGR,'' MFGRPartNo,'' WHLoc,NULL ExpDate,'' Reference,'' Uniq_lot,'' LotCode,'' PONUM,KaSeqNum,SerialYes,UseIpKey,      
  IsLotted,'' MTC,'' W_KEY FROM #tempResult WHERE shortage > 0     
  GROUP BY WONO ,DEPT_ID,Shortage, AssemblyNoRev, KaSeqNum,SerialYes,UseIpKey,IsLotted     
  UNION       
  SELECT IIF(k.SHORTQTY>0,1,0) As IsShort, 0 As IsReserve,substring(k.WONO, patindex('%[^0]%',k.WONO), 10) WONO,      
  k.DEPT_ID,k.SHORTQTY Quantity,k.SHORTQTY Shortage,CONCAT(TRIM(i.PART_NO),IIF((TRIM(i.REVISION) = ''),'','/'+TRIM(i.REVISION))) AssemblyNoRev,      
  '' MFGR,'' MFGRPartNo,'' WHLoc,NULL ExpDate,'' Reference,'' Uniq_lot,'' LotCode,'' PONUM,      
  k.KaSeqNum,i.SerialYes,i.UseIpKey,'' IsLotted,'' MTC,'' W_KEY       
  FROM INVENTOR i        
  INNER JOIN KAMAIN k ON k.UNIQ_KEY = i.UNIQ_KEY    
  WHERE i.UNIQ_KEY = @uniqKey AND k.SHORTQTY > 0 and k.allocatedQty = 0       
 ) 
 --)a
 -- 04/21/2020 Rajendra K : Added new CTE as Data and added outer join to get the "Extra kit Qty" 
 SELECT d.*,ISNULL(kamainShort.ExtraKitQty,0) AS ExtraKitQty INTO #TEMP FROM Data d
 OUTER APPLY
 (
		SELECT ABS(SHORTQTY) AS ExtraKitQty FROM KAMAIN k
		JOIN WOENTRY w ON w.WONO = k.WONO
		WHERE KASEQNUM = d.KaSeqNum AND SHORTQTY < 0 AND OPENCLOS not like 'C%'
 ) AS kamainShort    
   
  SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('select *,ROW_NUMBER() OVER(ORDER BY wono) ID from #TEMP',@filter,@sortExpression,'','ID',@startRecord,@endRecord))               
  EXEC sp_executesql @rowCount            
         
  SET @sqlQuery =  (SELECT dbo.fn_GetDataBySortAndFilters('select *,ROW_NUMBER() OVER(ORDER BY wono) ID from #TEMP',@filter,@sortExpression,N'IsShort,IsReserve,WONO,LotCode','',@startRecord,@endRecord))          
  EXEC sp_executesql @sqlQuery        
      
  IF OBJECT_ID('tempdb..#TEMP') IS NOT NULL DROP TABLE #TEMP        
END