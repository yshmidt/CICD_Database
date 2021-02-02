-- =============================================    
-- Author: Rajendra K     
-- Create date: <05/24/2019>    
-- Description:Get Issued Components    
-- Modification    
-- 09/11/2019 Rajendra K : Added Where condition for either ReserveQty or UsedQty greater than zero
-- 03/16/2020 Rajendra K : Removed the instore condition to display Supplier Bonded inventory material and added condition for IM.SFBL = 0
-- 08/07/2020 Rajendra K : Added part_source column into table
-- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list
-- EXEC GetIssuedComponents '0000102128',1,100    
-- =============================================   
CREATE PROCEDURE GetIssuedComponents    
(    
  @woNo char(10)='',    
  @startRecord INT =1,    
  @endRecord INT=1000     
)    
AS			
BEGIN    
SET NoCount ON;     
	 
  IF OBJECT_ID(N'tempdb..#IssuedData') IS NOT NULL  
     DROP TABLE #IssuedData ;  
  
  IF OBJECT_ID(N'tempdb..#tempPartsDetails') IS NOT NULL  
     DROP TABLE #tempPartsDetails ;    
  
 CREATE TABLE #tempPartsDetails ( WONO CHAR(10), UNIQ_KEY CHAR(10),SerialYes BIT, UseIpKey BIT,IsLotted BIT,KASEQNUM CHAR(10),W_KEY CHAR(10))    
  
 DECLARE  @KitBomView TABLE (Dept_id CHAR(8),Uniq_key CHAR(10),BomParent CHAR(10),Qty NUMERIC(10,2), ShortQty NUMERIC(10,2),   
 Used_inKit CHAR(8), Part_Sourc CHAR(10) ,Part_No CHAR(100),Revision CHAR(8), Descript varchar(100), Part_class CHAR(8), Part_type  CHAR(8)  
 , U_of_meas  CHAR(4), Scrap NUMERIC(6,2), SetupScrap NUMERIC(4,0) , CustPartNo  CHAR(35), SerialYes CHAR(8),Qty_Each numeric(12,2),UniqueId CHAR(10));  
  
 DECLARE  @ReservedComponents TABLE (WONO CHAR(10), KaSeqNum CHAR(10), SerialYes BIT,UseIpKey BIT,IsLotted BIT,Uniq_Key CHAR(10),PartNo	CHAR(35),REVISION CHAR(8),	
	PartNoWithRev CHAR(43),ITAR BIT,IPkeyunique CHAR(10), FromWarehouse NVARCHAR(210), ToWarehouse NVARCHAR(210), Partmfgr CHAR(8),	MfgrPartNo CHAR(30),
 	UniqMfgrHd CHAR(10), UniqWh CHAR(10),Warehouse CHAR(6), Location NVARCHAR(200),Whno CHAR(3),QtyOh NUMERIC(12,2),W_key CHAR(10),ExpDate SMALLDATETIME,
	Reference CHAR(12),Uniq_lot CHAR(10),LotCode CHAR(25),PONUM CHAR(15), Reserved NUMERIC(12,2),QtyUsed NUMERIC(12,2),IsReserve BIT,Unit CHAR(4),RoHSStr CHAR(10),
	SIDChk BIT,	ToWkey CHAR(10),Issued NUMERIC(12,2),part_source CHAR(10),Id INT)-- 08/07/2020 Rajendra K : Added part_source column into table

 INSERT INTO @KitBomView EXEC [dbo].[KitBomInfoView] @woNo; 
 INSERT INTO @ReservedComponents EXEC [dbo].[GetReservedComponents] @woNo,1,3000

  INSERT INTO #tempPartsDetails    
     SELECT K.WONO    
     ,K.UNIQ_KEY    
     ,i.SERIALYES    
     ,i.useipkey    
     ,ISNULL(P.LOTDETAIL,CAST(0 AS BIT)) AS IsLotted    
     ,K.KASEQNUM    
     ,Iss.W_KEY    
  FROM INVENTOR i    
     INNER JOIN  KAMAIN k ON k.UNIQ_KEY = i.UNIQ_KEY       
     LEFT JOIN  PARTTYPE p ON p.PART_TYPE = i.PART_TYPE AND p.PART_CLASS =i.PART_CLASS    
     INNER JOIN INVT_ISU Iss ON k.WONO = Iss.WONO AND k.KASEQNUM = Iss.KaSeqnum   
  WHERE     
     (@woNo IS NULL OR @woNo = '' OR k.wono= @woNo )          
  GROUP BY k.UNIQ_KEY    
    ,k.KASEQNUM    
    ,i.SERIALYES    
     ,i.useipkey    
    ,p.LOTDETAIL    
    ,k.WONO    
    ,Iss.W_KEY    
  
--;with ReturnData as (   
SELECT DISTINCT  
      tp.WONO,tp.KASEQNUM AS KaSeqNum,tp.SerialYes,tp.UseIpKey,tp.IsLotted,i.Uniq_Key,i.part_no AS PartNo,i.REVISION    
          ,CASE WHEN i.PART_SOURC <> 'CONSG' -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list
			THEN CASE COALESCE(NULLIF(i.REVISION,''), '')          
			WHEN '' THEN  LTRIM(RTRIM(i.PART_NO))           
			ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION END 
	  ELSE 
			CASE COALESCE(NULLIF(i.custrev,''), '')          
			WHEN '' THEN  LTRIM(RTRIM(i.CUSTPARTNO))           
			ELSE LTRIM(RTRIM(i.CUSTPARTNO)) + '/' + i.custrev END 
	   END AS PartNoWithRev 
     ,i.ITAR ,'' AS IPkeyunique     
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS FromWarehouse    
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS ToWarehouse    
     ,mfMaster.Partmfgr,mfMaster.mfgr_pt_no AS MfgrPartNo ,imfgr.UniqMfgrHd ,imfgr.UniqWh ,Warehouse ,Location ,wa.Whno  ,0 AS 'QtyOh' ,issu.W_key ,
	 NULL AS ExpDate,NULL AS Reference ,NULL AS Uniq_lot ,NULL AS LotCode  ,NULL AS PONUM ,CAST(0 AS bit) AS ReserveQty  
     ,SUM(issu.QTYISU) AS 'UsedQty' ,CAST(0 AS bit) AS IsReserve ,i.U_OF_MEAS AS Unit ,i.matltype RoHSStr ,tp.UseIpKey AS SIDChk ,issu.W_KEY AS ToWkey
	 ,Qty.OldRequired AS OldRequired ,ISNULL(kb.ShortQty,0) AS NewRequired 
	 ,i.PART_SOURC    -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list 
INTO #IssuedData 
FROM #tempPartsDetails tp    
  INNER JOIN  INVENTOR i  ON tp.UNIQ_KEY = i.UNIQ_KEY AND tp.IsLotted = 0 AND tp.UseIpKey = 0     
  INNER JOIN  INVT_ISU issu ON tp.UNIQ_KEY = issu.UNIQ_KEY   
    AND tp.WONO = issu.WONO AND tp.KASEQNUM = issu.KASEQNUM AND tp.W_KEY = issu.W_KEY    
  INNER JOIN  KAMAIN k ON k.UNIQ_KEY = i.UNIQ_KEY  AND k.WONO = issu.WONO  
  INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY    
  INNER JOIN  MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
  INNER JOIN  INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = issu.W_KEY    
  INNER JOIN  WAREHOUS wa ON imfgr.UNIQWH = wa.UNIQWH   
  OUTER APPLY(SELECT (SHORTQTY+(ACT_QTY+allocatedQty)) AS OldRequired FROM KAMAIN where UNIQ_KEY = i.UNIQ_KEY AND WONO = @woNo) AS Qty  
  LEFT JOIN @KitBomView kb ON k.UNIQ_KEY = kb.Uniq_key AND K.BOMPARENT = kb.BomParent  
WHERE Warehouse <> 'WIP' AND Warehouse <> 'WO-WIP' AND Warehouse <> 'MRB' 
AND Netable = 1 
AND imfgr.Is_Deleted = 0 
AND mpn.Is_deleted = 0 
AND mfMaster.IS_DELETED=0   
AND imfgr.SFBL = 0-- 03/16/2020 Rajendra K : Removed the instore condition to display Supplier Bonded inventory material and added condition for IM.SFBL = 0
   GROUP BY mfMaster.Partmfgr,mfMaster.mfgr_pt_no , Warehouse, Location, issu.W_key, Wh_gl_nbr, mfMaster.Mfgr_pt_no, mpn.UniqMfgrHd,mfMaster.qtyPerPkg,    
  Reserved, UniqSupno, imfgr.UniqWh,i.U_OF_MEAS,tp.WONO,i.UNIQ_KEY,i.ITAR,i.part_no,i.REVISION,imfgr.UniqMfgrHd,tp.SerialYes,tp.UseIpKey,tp.IsLotted,tp.KASEQNUM,    
  i.matltype,Qty.OldRequired,kb.ShortQty,wa.WHNO,i.PART_SOURC,i.CUSTPARTNO,i.CUSTREV 
   HAVING SUM(issu.QTYISU) > 0    
  
UNION  
  
 SELECT DISTINCT tp.WONO ,tp.KASEQNUM AS KaSeqNum ,tp.SerialYes ,tp.UseIpKey ,tp.IsLotted ,i.Uniq_Key ,i.part_no AS PartNo ,i.REVISION    
          ,CASE WHEN i.PART_SOURC <> 'CONSG' -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list
			THEN CASE COALESCE(NULLIF(i.REVISION,''), '')          
			WHEN '' THEN  LTRIM(RTRIM(i.PART_NO))           
			ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION END 
	  ELSE 
			CASE COALESCE(NULLIF(i.custrev,''), '')          
			WHEN '' THEN  LTRIM(RTRIM(i.CUSTPARTNO))           
			ELSE LTRIM(RTRIM(i.CUSTPARTNO)) + '/' + i.custrev END 
	   END AS PartNoWithRev 
     ,i.ITAR  ,'' AS IPkeyunique     
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS FromWarehouse    
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS ToWarehouse    
     ,mfMaster.Partmfgr ,mfMaster.mfgr_pt_no AS MfgrPartNo  ,imfgr.UniqMfgrHd ,imfgr.UniqWh ,Warehouse ,Location , w.Whno,0 AS 'QtyOh'    
     ,issu.W_key ,ISNULL(issu.EXPDATE,'') AS ExpDate ,ISNULL(issu.REFERENCE,'') AS Reference ,ISNULL(lot.UNIQ_LOT ,'') AS Uniq_lot    
     ,ISNULL(issu.LOTCODE,'') AS LotCode ,ISNULL(lot.PONUM,'') AS PONUM ,CAST(0 AS bit)  AS ReserveQty ,SUM(issu.QTYISU) AS 'UsedQty'    
     ,CAST(0 AS bit) AS IsReserve ,i.U_OF_MEAS AS Unit ,i.matltype RoHSStr  
     ,tp.UseIpKey AS SIDChk  ,issu.W_KEY AS ToWkey 
	 ,Qty.OldRequired AS OldRequired  
	 ,ISNULL(kb.ShortQty,0) AS NewRequired  
	 ,i.PART_SOURC    -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list
FROM #tempPartsDetails tp    
     INNER JOIN  INVENTOR i  ON tp.UNIQ_KEY = i.UNIQ_KEY AND tp.IsLotted = 1 AND tp.UseIpKey = 0          
     INNER JOIN  INVT_ISU issu ON tp.UNIQ_KEY = issu.UNIQ_KEY  
       AND tp.WONO = issu.WONO AND tp.KASEQNUM = issu.KASEQNUM AND tp.W_KEY = issu.W_KEY    
     INNER JOIN  KAMAIN k ON k.UNIQ_KEY = i.UNIQ_KEY  AND k.WONO = issu.WONO  
     INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY    
     INNER JOIN  MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
     INNER JOIN  INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = tp.W_KEY     
     INNER JOIN  WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH    
     OUTER APPLY(SELECT (SHORTQTY+(ACT_QTY+allocatedQty)) AS OldRequired FROM KAMAIN where UNIQ_KEY = i.UNIQ_KEY AND WONO = @woNo) AS Qty  
     LEFT JOIN  INVTLOT lot ON lot.W_KEY = imfgr.W_KEY AND  ISNULL(lot.EXPDATE,1) = ISNULL(issu.EXPDATE,1)  AND lot.REFERENCE = issu.REFERENCE AND lot.LOTCODE = issu.LOTCODE     
      LEFT JOIN @KitBomView kb ON k.UNIQ_KEY = kb.Uniq_key AND K.BOMPARENT = kb.BomParent  
  WHERE WAREHOUSE <> 'WIP'     
     AND WAREHOUSE <> 'WO-WIP'     
     AND Warehouse <> 'MRB'    
     AND Netable = 1    
     AND imfgr.IS_DELETED = 0
	 AND imfgr.SFBL = 0     
     -- AND imfgr.INSTORE = 0  -- 03/16/2020 Rajendra K : Removed the instore condition to display Supplier Bonded inventory material and added condition for IM.SFBL = 0
  GROUP BY mfMaster.Partmfgr,mfMaster.mfgr_pt_no , Warehouse, Location, issu.W_key, Wh_gl_nbr, mfMaster.Mfgr_pt_no, mpn.UniqMfgrHd,mfMaster.qtyPerPkg,    
  Reserved, UniqSupno, imfgr.UniqWh,i.U_OF_MEAS,tp.WONO,i.UNIQ_KEY,i.ITAR,i.part_no,i.REVISION,imfgr.UniqMfgrHd,tp.SerialYes,tp.UseIpKey,tp.IsLotted,tp.KASEQNUM,    
  i.matltype,issu.EXPDATE,issu.REFERENCE,issu.LOTCODE,lot.UNIQ_LOT,lot.PONUM,Qty.OldRequired,kb.ShortQty,w.WHNO,i.PART_SOURC,i.CUSTPARTNO,i.CUSTREV  
   HAVING SUM(issu.QTYISU) >0    
   
 UNION    
    
  SELECT DISTINCT  tp.WONO ,tp.KASEQNUM AS KaSeqNum ,tp.SerialYes ,tp.UseIpKey ,tp.IsLotted ,i.Uniq_Key ,i.part_no AS PartNo ,i.REVISION 
	      ,CASE WHEN i.PART_SOURC <> 'CONSG' -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list
			THEN CASE COALESCE(NULLIF(i.REVISION,''), '')          
			WHEN '' THEN  LTRIM(RTRIM(i.PART_NO))           
			ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION END 
	  ELSE 
			CASE COALESCE(NULLIF(i.custrev,''), '')          
			WHEN '' THEN  LTRIM(RTRIM(i.CUSTPARTNO))           
			ELSE LTRIM(RTRIM(i.CUSTPARTNO)) + '/' + i.custrev END 
	   END AS PartNoWithRev 
     ,i.ITAR ,issip.IPKEYUNIQUE AS IPkeyunique    
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS FromWarehouse    
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS ToWarehouse  
     ,PartMfgr,mfMaster.mfgr_pt_no AS MfgrPartNo,imfgr.UniqMfgrHd ,imfgr.UniqWh ,Warehouse ,Location , w.Whno,ip.qtyAllocatedTotal AS QtyOh ,Isu.W_KEY    
     ,NULL AS ExpDate,NULL AS Reference ,NULL AS Uniq_lot ,NULL AS LotCode ,NULL AS PONUM ,CAST(0 AS bit)  AS ReserveQty  
     ,qtyIssu.QtyUsed AS 'UsedQty' ,CAST(0 AS bit) AS IsReserve ,i.U_OF_MEAS AS Unit ,i.Matltype RoHSStr ,tp.UseIpKey AS SIDChk ,Isu.W_KEY AS ToWkey   
	 ,Qty.OldRequired AS OldRequired  
	 ,ISNULL(kb.ShortQty,0) AS NewRequired
	 ,i.PART_SOURC    -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list  
  FROM #tempPartsDetails tp    
     INNER JOIN  KAMAIN k ON tp.UNIQ_KEY = K.UNIQ_KEY AND tp.IsLotted = 0 AND tp.UseIpKey = 1  AND K.WONO = tp.WONO    
     JOIN Inventor i  ON k.Uniq_Key = i.Uniq_Key    
     INNER JOIN INVT_ISU Isu On tp.UNIQ_KEY = Isu.UNIQ_KEY AND tp.WONO = Isu.WONO AND tp.KASEQNUM = Isu.KASEQNUM AND tp.W_KEY = Isu.W_KEY  
     INNER JOIN issueipkey issip ON  issip.invtisu_no = Isu.INVTISU_NO  
     INNER JOIN  IPKEY ip ON issip.ipkeyunique = ip.IPKEYUNIQUE  
     INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY    
     INNER JOIN  MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
     INNER JOIN  INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = tp.W_KEY    
     INNER JOIN  WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH    
	 OUTER APPLY(SELECT (SHORTQTY+(ACT_QTY+allocatedQty)) AS OldRequired FROM KAMAIN where UNIQ_KEY = i.UNIQ_KEY AND WONO = @woNo) AS Qty  
     LEFT JOIN @KitBomView kb ON k.UNIQ_KEY = kb.Uniq_key AND K.BOMPARENT = kb.BomParent  
   OUTER APPLY 
   (			  SELECT DISTINCT isuIp.IPKEYUNIQUE,SUM(isuIP.qtyissued) AS QtyUsed
				  FROM INVENTOR i   
				  INNER JOIN invt_isu isu ON i.UNIQ_KEY = isu.UNIQ_KEY AND isu.kaseqnum = tp.KASEQNUM  
				  INNER JOIN issueipkey isuIP ON isu.invtisu_no = isuIP.invtisu_no   
				  INNER JOIN ipkey ip ON isuIP.ipkeyunique = ip.IPKEYUNIQUE  AND isuIP.ipkeyunique = issip.ipkeyunique
				  WHERE isu.ISSUEDTO LIKE '%(WO:'+@woNo+'%' AND isu.wono =@woNo AND isu.uniq_key = tp.UNIQ_KEY AND ip.W_KEY = tp.W_KEY   
				  GROUP BY isuIp.IPKEYUNIQUE,ip.pkgBalance,i.U_OF_MEAS,ip.EXPDATE,ip.LOTCODE,ip.REFERENCE,ip.PONUM  
				  HAVING SUM(isuIP.qtyissued) > 0 
	) AS qtyIssu
  WHERE issip.qtyissued > 0   
  
  UNION  
  
   SELECT DISTINCT tp.WONO ,tp.KASEQNUM AS KaSeqNum ,tp.SerialYes,tp.UseIpKey ,tp.IsLotted ,i.Uniq_Key ,i.part_no AS PartNo ,i.REVISION    
      ,CASE WHEN i.PART_SOURC <> 'CONSG' -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list
			THEN CASE COALESCE(NULLIF(i.REVISION,''), '')          
			WHEN '' THEN  LTRIM(RTRIM(i.PART_NO))           
			ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION END 
	  ELSE 
			CASE COALESCE(NULLIF(i.custrev,''), '')          
			WHEN '' THEN  LTRIM(RTRIM(i.CUSTPARTNO))           
			ELSE LTRIM(RTRIM(i.CUSTPARTNO)) + '/' + i.custrev END 
	   END AS PartNoWithRev 
     ,i.ITAR ,issip.IPKEYUNIQUE AS IPkeyunique    
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS FromWarehouse    
     ,RTRIM(Warehouse)+' / '+RTRIM(imfgr.Location) AS ToWarehouse  
     ,PartMfgr,mfMaster.mfgr_pt_no AS MfgrPartNo ,imfgr.UniqMfgrHd ,imfgr.UniqWh ,Warehouse ,Location , w.Whno,ip.qtyAllocatedTotal AS QtyOh ,Isu.W_KEY ,lot.ExpDate    
     ,lot.Reference ,lot.Uniq_lot ,lot.LotCode ,ISNULL(lot.PONUM,'') AS PONUM ,CAST(0 AS bit)  AS ReserveQty ,qtyIssu.QtyUsed AS 'UsedQty'      
     ,CAST(0 AS BIT) AS IsReserve ,i.U_OF_MEAS AS Unit ,i.MAtlType RoHSStr ,tp.UseIpKey AS SIDChk ,Isu.W_KEY AS ToWkey   
	 ,Qty.OldRequired AS OldRequired  
	 ,ISNULL(kb.ShortQty,0) AS NewRequired 
	 ,i.PART_SOURC    -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision and added part_sourc in selection list 
FROM #tempPartsDetails tp    
	 INNER JOIN  INVENTOR i  ON tp.UNIQ_KEY = i.UNIQ_KEY AND tp.IsLotted = 1 AND tp.UseIpKey = 1   
     INNER JOIN INVT_ISU Isu On tp.UNIQ_KEY = Isu.UNIQ_KEY AND tp.WONO = Isu.WONO AND tp.KASEQNUM = Isu.KASEQNUM AND tp.W_KEY = Isu.W_KEY  
	 INNER JOIN  KAMAIN k ON k.UNIQ_KEY = i.UNIQ_KEY  AND k.WONO = Isu.WONO  
	 JOIN issueipkey issip on  issip.invtisu_no = Isu.INVTISU_NO  
	 INNER JOIN IPKEY ip ON issip.ipkeyunique = ip.IPKEYUNIQUE    
     INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY    
     INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
     INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = tp.W_KEY    
     INNER JOIN WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH    
     LEFT JOIN INVTLOT lot ON lot.W_KEY = imfgr.W_KEY AND  ISNULL(lot.EXPDATE,1) = ISNULL(Isu.EXPDATE,1)  AND lot.REFERENCE = Isu.REFERENCE AND lot.LOTCODE = Isu.LOTCODE      
	 OUTER APPLY(SELECT (SHORTQTY+(ACT_QTY+allocatedQty)) AS OldRequired FROM KAMAIN where UNIQ_KEY = i.UNIQ_KEY AND WONO = @woNo) AS Qty  
	 LEFT JOIN @KitBomView kb ON k.UNIQ_KEY = kb.Uniq_key AND K.BOMPARENT = kb.BomParent
     OUTER APPLY 
	 ( 
				 SELECT DISTINCT isuIp.IPKEYUNIQUE,SUM(isuIP.qtyissued) AS QtyUsed
				 FROM INVENTOR i   
				 INNER JOIN invt_isu isu ON i.UNIQ_KEY = isu.UNIQ_KEY AND isu.kaseqnum = tp.KASEQNUM  
				 INNER JOIN issueipkey isuIP ON isu.invtisu_no = isuIP.invtisu_no   
				 INNER JOIN ipkey ip ON isuIP.ipkeyunique = ip.IPKEYUNIQUE  AND isuIP.ipkeyunique = issip.ipkeyunique
				 WHERE isu.ISSUEDTO LIKE '%(WO:'+@woNo+'%' AND isu.wono =@woNo AND isu.uniq_key = tp.UNIQ_KEY AND ip.W_KEY = tp.W_KEY   
				 GROUP BY isuIp.IPKEYUNIQUE,ip.pkgBalance,i.U_OF_MEAS,ip.EXPDATE,ip.LOTCODE,ip.REFERENCE,ip.PONUM  
				 HAVING SUM(isuIP.qtyissued) > 0  
	) AS qtyIssu  
  WHERE  issip.qtyissued > 0 
 UNION ALL

  SELECT R.WONO,R.KaSeqNum,	R.SerialYes,UseIpKey,IsLotted,R.Uniq_Key,PartNo,R.REVISION,PartNoWithRev,ITAR,IPkeyunique,FromWarehouse,ToWarehouse,Partmfgr,MfgrPartNo,
  	UniqMfgrHd,	UniqWh,	Warehouse,	Location,Whno,	QtyOh,	W_key,	ExpDate,Reference,Uniq_lot,LotCode,PONUM,QtyOh AS ReserveQty,QtyUsed AS UsedQty,CAST(1 AS bit) AS IsReserve,Unit,RoHSStr,SIDChk,	
	ToWkey,Qty.OldRequired AS OldRequired ,ISNULL(kb.ShortQty,0) AS NewRequired,part_source
  FROM @ReservedComponents R 
	INNER JOIN KAMAIN K ON R.Uniq_Key = K.UNIQ_KEY AND R.KaSeqNum = K.KASEQNUM
	LEFT JOIN @KitBomView kb ON k.UNIQ_KEY = kb.Uniq_key AND K.BOMPARENT = K.BomParent 
	OUTER APPLY(SELECT (SHORTQTY+(ACT_QTY+allocatedQty)) AS OldRequired FROM KAMAIN where UNIQ_KEY = K.UNIQ_KEY AND WONO = @woNo) AS Qty   
  WHERE K.WONO = @woNo

  SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY  Uniq_Key) AS Id,WONO,KaSeqNum,SerialYes,UseIpKey,IsLotted,Uniq_Key,PartNo,REVISION,PartNoWithRev,ITAR,IPkeyunique,FromWarehouse,ToWarehouse,Partmfgr,MfgrPartNo,
  	UniqMfgrHd,UniqWh,Warehouse,Location,Whno,W_key,ExpDate,Reference,Uniq_lot,LotCode,PONUM,SUM(ReserveQty) AS ReserveQty,SUM(UsedQty) AS UsedQty
	,Unit,RoHSStr,SIDChk,ToWkey,OldRequired ,NewRequired,PART_SOURC 
 FROM #IssuedData 
 WHERE (UsedQty > 0 OR ReserveQty > 0)-- 09/11/2019 Rajendra K : Added Where condition for either ReserveQty or UsedQty greater than zero
 GROUP BY WONO,KaSeqNum,SerialYes,UseIpKey,IsLotted,Uniq_Key,REVISION,ITAR,IPkeyunique,Partmfgr,MfgrPartNo,PartNo,PartNoWithRev,FromWarehouse,ToWarehouse,UniqMfgrHd
 ,UniqWh,Warehouse,Location,Whno,W_key,ExpDate,Reference,Uniq_lot,LotCode,PONUM,Unit,RoHSStr,SIDChk,OldRequired ,NewRequired,ToWkey,PART_SOURC
 
END