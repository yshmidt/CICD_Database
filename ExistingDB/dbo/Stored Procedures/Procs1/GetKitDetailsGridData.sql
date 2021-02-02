-- =============================================      
-- Author:  Rajendra K       
-- Create date: <02/28/2017>      
-- Description:Kit details data      
 --Modification      
   -- 03/15/2017 Rajendra K : Added UniqMfgrHd in Select       
   -- 03/16/2017 Rajendra K : Added W_Key in select      
   -- 03/23/2017 Rajendra K : Added Reserve from INVTMFGR       
   -- 04/18/2017 Rajendra K : Added paging       
   -- 04/17/2017 Rajendra K : Removed columns PartMfgr,mfgr_pt_no,UniqMfgrHd and W_KEY as it does not need to dsiplay in KitDetailMainGrid      
   -- 05/23/2017 Rajendra K : Removed commented code      
   -- 05/26/2017 Rajendra K : Modified order by with column SHORTQTY      
   -- 06/06/2017 Rajendra K : Modified order by with column SHORTQTY and WareHouse      
   -- 06/07/2017 Rajendra K : Removed column from select list RoHS      
   -- 06/13/2017 Rajendra K : Removed column INTRES.QTYALLOC from Available Qty      
   -- 06/14/2017 Rajendra K : Removed join with table INTRES      
   -- 06/15/2017 Rajendra K : Added condition INVTMF.QTY_OH > 0 to get records if parts avaialble in INVTMFGR table      
   -- 06/20/2017 Rajendra K : Modified from INVTMF.RESERVED to SUM(INVTMF.RESERVED) to get Reserved quantity      
   -- 06/20/2017 Rajendra K : Removed INVTMF.RESERVED from group by clause      
   -- 06/14/2017 Rajendra K : Removed table InvtLot,InvtMpnLink,MfgrMaster from join condition      
   -- 07/03/2017 Rajendra K : Added RTRIM to Part_No      
   -- 07/25/2017 Rajendra K : Added CTE to get allocated records from Invt_Res table      
   -- 07/28/2017 Rajendra K : Added K.ACT_QTY AS Used      
   -- 08/01/2017 Rajendra K : Added PARTTYPE table in join condition      
   -- 08/01/2017 Rajendra K : Added useipkey,SERIALYES,LOTDETAIL in select list and group by      
   -- 08/02/2017 Rajendra K : Added KaSeqNum       
   -- 08/11/2017 Rajendra K : Added condition to get valid records from InvtMfgr table      
   -- 08/31/2017 Rajendra K : Added ISNULL condition to get LOTDETAIL      
   -- 09/13/2017 Rajendra K : Added WO Reservation  default settings logic      
   -- 10/04/2017 Rajendra K : Setting Name changed in where clause for #temoWOSettings to get ICM default settings      
   -- 10/13/2017 Rajendra K : Separated columns in group by clasue      
   -- 10/13/2017 Rajendra K : Renamed Cte from InvtResCte to InvtReserve      
   -- 10/25/2017 Rajendra K : Removed condition INVTMF.QTY_OH > 0 to display all MFGR records       
   -- 10/31/2017 Rajendra K : Parameter name renamed as per naming conventions      
   -- 11/02/2017 Rajendra K : Removed columns 'I.PART_NO,I.REVISION,I.PART_CLASS,I.PART_TYPE,I.DESCRIPT,K.IGNOREKIT,I.ITAR,I.REVISION,D.dept_id' from group by for record count      
   -- 11/12/2017 Rajendra K : Added POCount and HistoryCount to check whether PO and History records exists      
   -- 12/08/2017 Rajendra K : Added column WH_GL_NBR in select and group by clause      
   -- 12/20/2017 Rajendra K : Added column CC to show whether row need to Cycle Count or not      
   -- 01/02/2018 Rajendra K : Added WONO in select and group by list for multiple WONO reservation      
   -- 13/03/2018 Rajendra K : Added filters      
   -- 03/14/2018 Rajendra K : Warehouse and Location in Select List      
   -- 03/15/2018 Rajendra K : Added RTRIM to Warehouse      
   -- 11/05/2018 Rajendra K : Converted select script to dynamic sql query      
   -- 11/15/2018 Rajendra K : Changed Filer related logic      
   -- 15/01/2019 Rajendra K : Added Outer Join with invtmfgr table for AvailableQty      
   -- 02/08/2019 Rajendra K : Added PART_NO columns for default sort      
   -- 2/20/2019 Mahesh B : Added IGNOREKIT Field on UI       
   -- 02/25/2019 Rajendra K : Added Condition "I.DESCRIPT" when PART_TYPE Is null       
   -- 03/25/2019 Rajendra K : Changed the default sorting "SHORTQTY,WH/Loc,Part_no" to "PART_NO,WH/Loc,SHORTQTY"      
   -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.      
   -- 05/31/2019 Rajendra K : Removed Dynamic SQL and added Static SQL       
   -- 05/31/2019 Rajendra K : Removed Get total counts table and added fn_GetDataBySortAndFilters() to get total count      
   -- 05/31/2019 Rajendra K : Removed Set Filter default values      
   -- 05/31/2019 Rajendra K : Added Outer join with invtmfgr table to getting part if part dont having MPN and warehouse and location      
   -- 05/04/2019 Rajendra K : Added Outer join with invtmfgr table to getting availableQty as sum of of approved MPN          
   -- 05/04/2019 Rajendra K : Changed AvailableQty as TotalStock           
   -- 05/04/2019 Rajendra K : Added BOMPARENT , TotalStock in selection list          
   -- 06/13/2019 Rajendra K : Changed Default Sort as Part_no , K.Shortage,Wh-Loc      
   -- 06/13/2019 Rajendra K : Added Outer Join PhantomComp to recognize phantom BOM components AS "IsPhantom"      
   -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations      
   -- 12/24/2019 Rajendra K : Added the condition to bring the part if all the location of that part are deleted      
   -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition         
   -- 03/25/2020 Rajendra K : Added @custNo and outer join to get consign uniq_key to calculate available Qty except AntiAvls       
   -- 06/24/2020 Rajendra K : Added Outer join to get OtherAvailable Qty and added into selection list      
   -- 07/23/2020 Rajendra K : Added conditions while calculating approved avilable Qty      
   -- 07/23/2020 Rajendra K : Added outer join to get CustPartNo and rev and added part_sourc, CustpartNo/rev in selection list      
   -- 07/28/2020 YS removed extra outer join. No need to. We only display custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision      
   -- 08/25/2020 Rajendra K : Added condition AllocatedQty > 0 when calculating the otheravailable Qty    
   -- 09/21/2020 Rajendra K : Added LINESHORT in selection list  
   -- 12/17/2020 Rajendra K : Added condition to skip issued Qty
   -- EXEC GetKitDetailsGridData '0000102128',1,100,'',0        
-- =============================================      
CREATE PROCEDURE [dbo].[GetKitDetailsGridData]    
(      
@woNumber AS CHAR(10),      
@startRecord INT =1,      
@endRecord INT =10,      
@Filter NVARCHAR(1000) = null,      
@out_TotalNumberOfRecord INT OUTPUT        
)      
AS      
BEGIN      
 SET NOCOUNT ON;       
 DECLARE @qryMain  NVARCHAR(MAX);      
 DECLARE @sqlQuery NVARCHAR(MAX);        
 DECLARE @rowCount NVARCHAR(MAX);      
 --09/13/2017 Rajendra K : Added WO Reservation  default settings logic      
    --Declare variables      
    DECLARE @nonNettable BIT,@bomParent CHAR(10),@custNo CHAR(10)--@mfgrDefault NVARCHAR(MAX)     -- 03/25/2020 Rajendra K : Added @custNo and outer join to get consign uniq_key to calculate available Qty except AntiAvls       
      
 -- 05/31/2019 Rajendra K : Removed Set Filter default values      
 -- 11/15/2018 Rajendra K : Set Filter default values      
 --IF (@Filter!='' AND @Filter LIKE '%Location%')      
 --BEGIN      
 --SET @Filter = REPLACE(@Filter,'[Location]','RTRIM(WH.WAREHOUSE) + (CASE WHEN InvtMf.LOCATION IS NULL OR InvtMf.LOCATION = '''' THEN '''' ELSE ''/''+  InvtMf.LOCATION END)')      
 --END      
 SELECT SettingName      
     ,LTRIM(WM.SettingValue) SettingValue      
 INTO  #tempWOSettings      
 FROM MnxSettingsManagement MS INNER JOIN WmSettingsManagement WM ON MS.settingId = WM.settingId       
 WHERE SettingName = 'allowUseOfNonNettableWarehouseLocation'--IN('manufacturersDefault','allowUseOfNonNettableWarehouseLocation') -- 10/04/2017 Rajendra K : Setting Name changed in where clause      
      
    --Assign values to variables to hold values for WO Reservation  default settings      
 -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.      
 --SET @mfgrDefault = ISNULL((SELECT SettingValue FROM #tempWOSettings WHERE SettingName = 'manufacturersDefault'),'All MFGRS')  -- 10/04/2017 Rajendra K : Setting Name changed in where clause      
 SET @nonNettable= ISNULL((SELECT CONVERT(BIT, SettingValue) FROM #tempWOSettings WHERE SettingName = 'allowUseOfNonNettableWarehouseLocation'),0) -- 10/04/2017 Rajendra K : Setting Name changed in where clause      
 SET @bomParent = (SELECT UNIQ_KEY FROM WOENTRY WHERE WONO = @woNumber)      
  SET @custNo = (SELECT BOMCUSTNO FROM INVENTOR WHERE UNIQ_KEY = @bomParent)   -- 03/25/2020 Rajendra K : Added @custNo and outer join to get consign uniq_key to calculate available Qty except AntiAvls       
       
 CREATE TABLE #CountTable(      
   totalCount INT      
 )      
 --       
 --SELECT COUNT(K.KASEQNUM) AS CountRecords -- Get total counts       
 --INTO #tempKitDetails       
 --FROM  KAMAIN K      
 --   INNER JOIN INVENTOR I ON K.UNIQ_KEY=I.UNIQ_KEY       
 --   INNER JOIN WOENTRY W ON W.WONO=K.WONO      
 --   INNER JOIN INVTMFGR INVTMF ON INVTMF.UNIQ_KEY = K.UNIQ_KEY       
 --    --AND INVTMF.QTY_OH > 0 --06/15/2017 Rajendra K : Added condition INVTMF.QTY_OH > 0 to get records if parts avaialble in INVTMFGR table       
 --    -- 10/25/2017 Rajendra K : Removed condition INVTMF.QTY_OH > 0 to display all MFGR records       
 --    AND (@nonNettable = 1 OR INVTMF.NETABLE = 1) -- 09/13/2017 Rajendra K : Apply WO Reservation default settings      
 --    AND INVTMF.InStore = 0 AND INVTMF.IS_DELETED = 0 -- 08/11/2017 Rajendra K : Added this condition to get valid records from InvtMfgr table                                
 --   -- 06/14/2017 Rajendra K : Removed join with table INTRES      
 --   LEFT JOIN Depts D ON K.dept_id = D.dept_id      
 --   LEFT JOIN WAREHOUS WH ON invtMf.UNIQWH = WH.UNIQWH      
 --   --06/14/2017 Rajendra K : Removed table InvtLot,InvtMpnLink,MfgrMaster from join condition      
 --WHERE k.WONO= @woNumber AND WH.WAREHOUSE NOT IN('WO-WIP','MRB')       
 --GROUP BY  K.KASEQNUM       
 --   --10/13/2017 Rajendra K : Separated PartNo and Revision in group by clasue      
 --   ,WH.UNIQWH      
 --   ,K.allocatedQty      
 --   ,K.ACT_QTY      
 --   ,K.SHORTQTY      
 --   ,I.uniq_key       
 --   --10/13/2017 Rajendra K : Separated WAREHOUSE and LOCATION in group by clasue      
 --   ,WH.WAREHOUSE      
 --   ,invtMf.LOCATION      
 --    --06/20/2017 Rajendra K : Removed INVTMF.RESERVED from group by clause on         
 --             --11/02/2017 Rajendra K : Removed columns 'I.PART_NO,I.REVISION,I.PART_CLASS,I.PART_TYPE,I.DESCRIPT,K.IGNOREKIT,I.ITAR,I.REVISION,D.dept_id' from group by for record count      
      
 --   --07/25/2017 Rajendra K : Added CTE to get allocated records from Invt_Res table      
 --   --10/13/2017 Rajendra K : Renamed Cte from InvtResCte to InvtReserve      
 --   --;WITH InvtReserve AS       
 -- --(      
    SELECT SUM(QTYALLOC) AS Allocated      
    ,W_KEY      
    ,KaSeqNum --08/02/2017 Rajendra K : Added KaSeqNum       
     INTO #tempData      
    FROM       
    INVT_RES IR       
    WHERE IR.WONO = @woNumber       
    GROUP BY W_KEY,KaSeqNum --08/02/2017 Rajendra K : Added KaSeqNum       
      
SELECT DISTINCT K.KASEQNUM       
   ,CASE WHEN INVTMF.IS_DELETED = 1 THEN '' ELSE WH.UNIQWH END AS UniqWHKey       
   ,CASE WHEN INVTMF.IS_DELETED = 1 THEN '' ELSE (RTRIM(WH.WAREHOUSE)       
   + (CASE WHEN InvtMf.LOCATION IS NULL OR InvtMf.LOCATION ='' THEN '' ELSE '/'+  InvtMf.LOCATION END)) END AS Location       
   ,D.dept_id AS WorkCenter,I.ITAR , K.IGNOREKIT      
     -- 07/23/2020 Rajendra K : Added outer join to get CustPartNo and rev and added part_sourc, CustpartNo/rev in selection list      
 --- 07/28/20 YS no need for outer join        
   --,CASE WHEN ISNULL(CustPtRev.PartNo,'')= '' THEN RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) ELSE CustPtRev.partNo END AS PART_NO       
   ,CASE WHEN i.Part_sourc='CONSG' then RTRIM(i.CUSTPARTNO) +       
   (CASE when i.CUSTREV = '' THEN CUSTREV ELSE '/'+ CUSTREV END) ELSE       
   RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) END as Part_no        
  ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE I.PART_CLASS +'/' END ) +       
   (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN ' / '+ I.DESCRIPT ELSE I.PART_TYPE + ' / '+I.DESCRIPT END) AS Descript         
   ,ISNULL(invtMfgrTotal.Qty,0) as AvailableQty -- 05/04/2019 Rajendra K : Added BOMPARENT , TotalStock in selection list      
   ,ISNULL( invtmfgrs.TotalStock,0) AS TotalStock -- 05/04/2019 Rajendra K : Changed AvailableQty as TotalStock       
   ,K.allocatedQty,(K.SHORTQTY+(K.ACT_QTY+K.allocatedQty)) AS Required      
    ,ISNULL(SUM(IRC.Allocated),0) AS Reserve       
   ,K.SHORTQTY AS Shortage      
  ,K.ACT_QTY AS Used       
  ,'' AS History      
  ,'' AS OnOrder      
    ,K.ACT_QTY      
    ,K.SHORTQTY      
    ,I.uniq_key       
    ,I.useipkey AS UseIpKey      
    ,I.SERIALYES AS Serialyes      
  ,ISNULL(PT.LOTDETAIL,0) AS IsLotted      
  ,(SELECT ISNULL(COUNT(1),0) FROM POMAIN PM       
       INNER JOIN  POITEMS PIT  ON PM.PONUM = PIT.PONUM        
       LEFT JOIN poitschd ps ON PIT.uniqlnno = ps.uniqlnno WHERE UNIQ_KEY = I.UNIQ_KEY AND PM.postatus <> 'CANCEL' AND PM.postatus <>  'CLOSED'       
     AND PIT.lcancel = 0 AND ps.balance > 0) AS POCount      
   ,(SELECT ISNULL(COUNT(1),0) FROM INVT_RES IR WHERE  IR.WONO = @woNumber AND IR.UNIQ_KEY = I.UNIQ_KEY) AS HistoryCount      
      ,WH.WH_GL_NBR AS WHNBR       
   ,CAST((CASE WHEN dbo.fn_GetCCQtyOH(I.UNIQ_KEY,'','','')>0 THEN 1 ELSE 0 END) AS BIT) AS CC       
   ,W.Wono       
   ,CAST(dbo.fremoveLeadingZeros(W.Wono) AS VARCHAR(MAX)) AS WorkOrderNumber             
   ,CASE WHEN INVTMF.IS_DELETED = 1 THEN '' ELSE WH.WAREHOUSE END AS Warehouse       
   ,CASE WHEN INVTMF.IS_DELETED = 1 THEN '' ELSE InvtMf.LOCATION END AS Loc      
   ,K.BOMPARENT -- 05/04/2019 Rajendra K : Added BOMPARENT , TotalStock in selection list      
  ,CAST(ISNULL(PhantomComp.Phantom ,0) AS BIT) AS IsPhantom -- 06/13/2019 Rajendra K : Added Outer Join PhantomComp to recognize phantom BOM components AS "IsPhantom"      
 -- 06/24/2020 Rajendra K : Added Outer join to get OtherAvailable Qty and added into selection list      
  ,ISNULL(ExtraQty.OtherAvailable,0) AS OtherAvailable      
    -- 07/23/2020 Rajendra K : Added outer join to get CustPartNo and rev and added part_sourc, CustpartNo/rev in selection list      
 -- 07/28/20 YS use strait forward part_sourc      
  --,CASE WHEN ISNULL(CustPtRev.PART_SOURC,'') = '' THEN I.PART_SOURC ELSE CustPtRev.PART_SOURC END AS Part_sourc      
  ,i.PART_SOURC      
  ,k.LINESHORT  -- 09/21/2020 Rajendra K : Added LINESHORT in selection list  
INTO #tempKitDet       
FROM INVENTOR I RIGHT JOIN KAMAIN K ON k.UNIQ_KEY=I.UNIQ_KEY       
  INNER JOIN WOENTRY W ON W.WONO=k.WONO      
  OUTER APPLY       
  (      
 SELECT wkeys.delWkey ,COUNT(w_key) AS wkey FROM INVTMFGR  -- 05/31/2019 Rajendra K : Added Outer join with invtmfgr table to getting part if part dont having MPN and warehouse and location        
  OUTER APPLY       
  (      
   SELECT TOP 1 w_key AS delWkey       
   FROM INVTMFGR        
   WHERE UNIQ_KEY = K.UNIQ_KEY AND IS_DELETED = 1      
  ) AS wkeys        
 WHERE UNIQ_KEY = K.UNIQ_KEY AND IS_DELETED = 1 GROUP BY  wkeys.delWkey      
 ) AS invtmCntDet        
  OUTER APPLY       
  (      
  SELECT  COUNT(w_key) AS wkey FROM INVTMFGR  WHERE UNIQ_KEY = K.UNIQ_KEY AND IS_DELETED = 0      
   ) AS invtmcnt        
  INNER JOIN INVTMFGR INVTMF ON INVTMF.UNIQ_KEY = K.UNIQ_KEY       
  -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition        
   AND ((CAST(@nonNettable AS CHAR(1)) = 1   AND INVTMF.SFBL = 0) OR INVTMF.NETABLE = 1)          
  -- AND INVTMF.InStore = 0   -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations      
   AND ((((invtmCntDet.wkey = 1) OR (invtmCntDet.wkey <> 1 AND invtmcnt.wkey=0 AND invtmCntDet.delWkey= INVTMF.w_key)) -- 12/24/2019 Rajendra K : Added the condition to bring the part if all the location of that part are deleted      
    AND ((invtmCntDet.wkey = 1 AND invtmcnt.wkey  = 0 ) OR INVTMF.IS_DELETED = 0 OR (invtmCntDet.wkey <> 1 AND invtmcnt.wkey  = 0)))       
     OR (invtmcnt.wkey <> 0 AND INVTMF.IS_DELETED = 0 AND INVTMF.w_key=INVTMF.w_key))        
    INNER JOIN InvtMpnLink IML ON INVTMF.UNIQMFGRHD = IML.uniqmfgrhd      
 INNER JOIN MfgrMaster MM ON IML.MfgrMasterId = MM.MfgrMasterId       
 LEFT JOIN Depts D ON K.dept_id = D.dept_id       
    LEFT JOIN WAREHOUS WH ON invtMf.UNIQWH = WH.UNIQWH       
    LEFT JOIN #tempData IRC ON invtMf.W_KEY = IRC.W_KEY AND IRC.KaSeqNum = K.KASEQNUM       
    LEFT JOIN PARTTYPE PT ON I.PART_CLASS = PT.PART_CLASS AND I.PART_TYPE = PT.PART_TYPE       
 -- 05/04/2019 Rajendra K : Changed AvailableQty as TotalStock       
 OUTER APPLY(SELECT  (SUM(QTY_OH) - SUM(RESERVED)) AS TotalStock FROM INVTMFGR WHERE UNIQ_KEY = INVTMF.UNIQ_KEY AND UNIQWH = INVTMF.UNIQWH       
 --AND INSTORE = 0    -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations      
 AND LOCATION = INVTMF.LOCATION) AS invtmfgrs          
 OUTER APPLY(SELECT  SUM(QTY_OH) - SUM(RESERVED) AS Qty FROM INVTMFGR IM    -- 05/04/2019 Rajendra K : Added Outer join with invtmfgr table to getting available Qty as sum of of approved MPN      
   INNER JOIN InvtMPNLink pn ON im.UNIQMFGRHD =  pn.uniqmfgrhd       
    INNER JOIN MfgrMaster mf ON pn.MfgrMasterId = mf.MfgrMasterId       
 AND (NOT EXISTS (SELECT bomParent,ConsgUniq.UNIQ_KEY       
       FROM ANTIAVL A       -- 03/25/2020 Rajendra K : Added @custNo and outer join to get consign uniq_key to calculate available Qty except AntiAvls       
       OUTER APPLY(      
           SELECT TOP 1 ISNULL(UNIQ_KEY,INVTMF.UNIQ_KEY)AS UNIQ_KEY       
           FROM INVENTOR -- 07/23/2020 Rajendra K : Added conditions while calculating approved avilable Qty      
           WHERE ((ISNULL(@custNo,'') != '' AND CUSTNO = @custNo AND INT_UNIQ = INVTMF.UNIQ_KEY)      
           OR (ISNULL(@custNo,'') = '' AND UNIQ_KEY = INVTMF.UNIQ_KEY))      
          )AS ConsgUniq      
          WHERE A.BOMPARENT = k.BOMPARENT              
        AND A.UNIQ_KEY = ConsgUniq.UNIQ_KEY        
        AND A.PARTMFGR = mf.PARTMFGR         
        AND A.MFGR_PT_NO = mf.MFGR_PT_NO)      
     )        
   WHERE IM.UNIQ_KEY = INVTMF.UNIQ_KEY AND UNIQWH = INVTMF.UNIQWH         
      AND LOCATION = INVTMF.LOCATION         
 ) AS invtMfgrTotal       
  OUTER APPLY (-- 06/24/2020 Rajendra K : Added Outer join to get OtherAvailable Qty and added into selection list      
  -- 12/17/2020 Rajendra K : Added condition to skip issued Qty
   SELECT CASE WHEN ABS(SUM(shortqty)) > SUM(ACT_QTY) THEN ABS(SUM(shortqty)) - SUM(ACT_QTY) ELSE 0.00 END AS OtherAvailable     
   FROM kamain WHERE INVTMF.UNIQ_KEY=kamain.UNIQ_KEY AND SHORTQTY < 0     
    AND kamain.allocatedQty > 0 -- 08/25/2020 Rajendra K : Added condition AllocatedQty > 0 when calculating the otheravailable Qty    
    AND EXISTS (SELECT 1 FROM woentry WHERE OPENCLOS NOT LIKE 'C%' and woentry.wono=kamain.wono AND kamain.WONO != @woNumber)     
 ) ExtraQty         
  -- 06/13/2019 Rajendra K : Added Outer Join PhantomComp to recognize phantom BOM components AS "IsPhantom"        
 OUTER APPLY (SELECT CAST(1 AS BIT) AS Phantom FROM KAMAIN WHERE BOMPARENT IN (SELECT B.UNIQ_KEY FROM INVENTOR I RIGHT JOIN BOM_DET B ON I.UNIQ_KEY = B.UNIQ_KEY         
    WHERE BOMPARENT = @bomParent AND i.PART_SOURC = 'PHANTOM') AND KASEQNUM = K.KASEQNUM AND WONO = @woNumber) AS PhantomComp        
 --OUTER APPLY(-- 07/23/2020 Rajendra K : Added outer join to get CustPartNo and rev and added part_sourc, CustpartNo/rev in selection list      
 -- SELECT RTRIM(CUSTPARTNO) + (CASE WHEN CUSTREV IS NULL OR CUSTREV = '' THEN CUSTREV ELSE '/'+ CUSTREV END) AS PartNo,PART_SOURC      
 --  FROM INVENTOR WHERE CUSTNO = @custNo AND INT_UNIQ = INVTMF.UNIQ_KEY      
 --) CustPtRev      
WHERE k.WONO= @woNumber AND WH.WAREHOUSE NOT IN('WO-WIP','MRB')         
           
  GROUP BY  K.KASEQNUM         
    ,WH.UNIQWH        
    ,I.PART_NO        
    ,I.REVISION            
    ,I.PART_CLASS        
    ,I.PART_TYPE        
    ,I.DESCRIPT        
    ,K.allocatedQty        
    ,K.ACT_QTY        
    ,K.SHORTQTY        
    ,I.uniq_key         
    ,K.IGNOREKIT        
    ,I.ITAR        
    ,I.REVISION        
    ,D.dept_id         
   ,WH.WAREHOUSE         
   ,InvtMf.LOCATION            
   ,I.useipkey         
    ,I.SERIALYES        
   ,PT.LOTDETAIL            
   ,WH.WH_GL_NBR         
   ,W.Wono        
   ,invtMfgrTotal.Qty         
   ,INVTMF.IS_DELETED        
   ,K.BOMPARENT          
   ,invtmfgrs.TotalStock         
   ,PhantomComp.Phantom       
   ,ExtraQty.OtherAvailable -- 06/24/2020 Rajendra K : Added Outer join to get OtherAvailable Qty and added into selection list      
  --- 07/28/20 YS no need for the outer join      
  --,CustPtRev.PartNo-- 07/23/2020 Rajendra K : Added outer join to get CustPartNo and rev and added part_sourc, CustpartNo/rev in selection list      
   --,CustPtRev.PART_SOURC      
   ,i.CUSTPARTNO,i.custrev      
   ,I.PART_SOURC      
   ,k.LINESHORT  -- 09/21/2020 Rajendra K : Added LINESHORT in selection list  
   ORDER BY PART_NO, K.SHORTQTY  ,CASE WHEN INVTMF.IS_DELETED = 1 THEN '' ELSE (RTRIM(WH.WAREHOUSE) +    -- 06/13/2019 Rajendra K : Changed Default Sort as Part_no , K.Shortage,Wh-Loc        
   (CASE WHEN InvtMf.LOCATION IS NULL OR InvtMf.LOCATION = '' THEN '' ELSE '/'+  InvtMf.LOCATION END)) END        
                
 SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempKitDet',@Filter,'PART_NO,Shortage','','Warehouse',@startRecord,@endRecord))                 
 INSERT INTO #CountTable EXEC sp_executesql @rowCount          
           
 SELECT @out_TotalNumberOfRecord =totalCount FROM #CountTable        
    -- 06/13/2019 Rajendra K : Changed Default Sort as Part_no , K.Shortage,Wh-Loc        
   SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempKitDet',@Filter,'PART_NO,Shortage','','',@startRecord,@endRecord))           
 EXEC  sp_executesql @sqlQuery        
    -- 05/31/2019 Rajendra K : Removed Dynamic SQL and added Static SQL         
        
 --SET @sqlQuery = 'SELECT DISTINCT K.KASEQNUM ,CASE WHEN INVTMF.IS_DELETED = 1 THEN '''' ELSE WH.UNIQWH END AS UniqWHKey ,CASE WHEN INVTMF.IS_DELETED = 1 THEN '''' ELSE (RTRIM(WH.WAREHOUSE) + (CASE WHEN InvtMf.LOCATION IS NULL OR InvtMf.LOCATION = '''' 
   
   
      
 --THEN '''' ELSE ''/''+  InvtMf.LOCATION END)) END AS Location '-- 03/15/2018 Rajendra K : Added RTRIM to Warehouse        
 --  +',D.dept_id AS WorkCenter,I.ITAR , K.IGNOREKIT ' -- 2/20/2019 Mahesh B:Added IGNOREKIT Field on UI           
 --   +',RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '''' THEN I.REVISION ELSE ''/''+ I.REVISION END) AS PART_NO '--07/03/2017 Rajendra K : Added RTRIM to Part_No        
 --   +',(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '''' THEN I.PART_CLASS ELSE I.PART_CLASS +''/ '' END ) +         
 --   (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='''' THEN '' / ''+ I.DESCRIPT ELSE I.PART_TYPE + ''/ ''+I.DESCRIPT END) AS Descript           
 --   ,invtmfgrs.Qty as AvailableQty '--06/13/2017 - Rajendra K : Removed column INTRES.QTYALLOC from Available Qty -- --15/01/2019 - Rajendra K :  Available Qty from invtmfgr table -- 02/25/2019 Rajendra K : Added Condition "I.DESCRIPT" when PART_TYPE Is
  
    
      
--  null        
 --  +',K.allocatedQty,(K.SHORTQTY+(K.ACT_QTY+K.allocatedQty)) AS Required        
 --   ,ISNULL(SUM(IRC.Allocated),0) AS Reserve '-- 06/20/2017 Rajendra K : Modified from INVTMF.RESERVED to SUM(INVTMF.RESERVED) to get Reserved quantity         
 --   -- 06/20/2017 - Rajendra K : Modified from SUM(INVTMF.RESERVED) to ISNULL(SUM(IRC.Allocated),0) to get Reserved quantity from Invt_Res tab                       
 --  +',K.SHORTQTY AS Shortage,K.ACT_QTY AS Used '-- 07/28/2017 Rajendra K : Added K.ACT_QTY AS Used        
 --   +','''' AS History,'''' AS OnOrder,K.ACT_QTY,K.SHORTQTY,I.uniq_key ,I.useipkey AS UseIpKey,I.SERIALYES AS Serialyes        
 --   ,ISNULL(PT.LOTDETAIL,0) AS IsLotted '--08/31/2017 Rajendra K : Added ISNULL condition to get LOTDETAIL -- 08/01/2017 Rajendra K : Added useipkey,SERIALYES,LOTDETAIL in select list            
 --  +',(SELECT ISNULL(COUNT(1),0) FROM POMAIN PM INNER JOIN  POITEMS PIT  ON PM.PONUM = PIT.PONUM          
 --     LEFT JOIN poitschd ps ON PIT.uniqlnno = ps.uniqlnno WHERE UNIQ_KEY = I.UNIQ_KEY AND PM.postatus <> ''CANCEL'' AND PM.postatus <>  ''CLOSED''         
 --    AND PIT.lcancel = 0 AND ps.balance > 0) AS POCount '-- 11/12/2017 Rajendra K : Added POCount  to check whether PONumber items exists for this record          
 --  +',(SELECT ISNULL(COUNT(1),0) FROM INVT_RES IR WHERE  IR.WONO = '''+@woNumber +''' AND IR.UNIQ_KEY = I.UNIQ_KEY) AS HistoryCount '-- 11/12/2017 Rajendra K : Added POCount                                        
 --     +',WH.WH_GL_NBR AS WHNBR '-- 12/08/2017 Rajendra K :Added WH_GL_NBR -- to check whether PONumber items exists for this record          
 --  +',CAST((CASE WHEN dbo.fn_GetCCQtyOH(I.UNIQ_KEY,'''','''','''')>0 THEN 1 ELSE 0 END) AS BIT) AS CC '--12/20/2017 Rajendra K : Added to show whether row need to CC or not        
 --  +',W.Wono '  --01/02/2018 Rajendra K :Added WONO for multiple WONO reservation        
 --  +',CAST(dbo.fremoveLeadingZeros(W.Wono) AS VARCHAR(MAX)) AS WorkOrderNumber               
 --   ,CASE WHEN INVTMF.IS_DELETED = 1 THEN '''' ELSE WH.WAREHOUSE END AS Warehouse '-- 03/14/2018 Rajendra K : Warehouse and Location in Select List        
 --  +',CASE WHEN INVTMF.IS_DELETED = 1 THEN '''' ELSE InvtMf.LOCATION END AS Loc        
 --   FROM INVENTOR I RIGHT JOIN KAMAIN K ON k.UNIQ_KEY=I.UNIQ_KEY         
 --   INNER JOIN WOENTRY W ON W.WONO=k.WONO OUTER APPLY (SELECT wkeys.wk ,COUNT(w_key) AS wkey1 FROM INVTMFGR         
 --                 outer apply (SELECT  top 1 w_key as wk FROM INVTMFGR  WHERE UNIQ_KEY = K.UNIQ_KEY AND IS_DELETED = 1) as wkeys        
 --      WHERE UNIQ_KEY = K.UNIQ_KEY AND IS_DELETED = 1 group by  wkeys.wk ) AS invtmcnt        
 --    OUTER APPLY (SELECT  COUNT(w_key) AS wkey1 FROM INVTMFGR  WHERE UNIQ_KEY = K.UNIQ_KEY AND IS_DELETED = 0) AS invtmcnt1        
 --   INNER JOIN INVTMFGR INVTMF ON INVTMF.UNIQ_KEY = K.UNIQ_KEY '--AND INVTMF.QTY_OH > 0 -- 06/15/2017 Rajendra K : Added condition INVTMF.QTY_OH > 0 to get records if parts avaialble in INVTMFGR table          
 --   -- 10/25/2017 Rajendra K : Removed condition INVTMF.QTY_OH > 0 to display all MFGR records                                       
 --     +'AND ('''+CAST(@nonNettable AS CHAR(1))+''' = 1 OR INVTMF.NETABLE = 1) '-- 09/13/2017 Rajendra K : Apply WO Reservation default settings        
 --  +'AND INVTMF.InStore = 0 AND  ((((invtmcnt.wkey1 = 1) OR  (invtmcnt.wkey1 <> 1 AND invtmcnt1.wkey1=0 AND invtmcnt.wk= INVTMF.w_key ))         
 --    AND (INVTMF.IS_DELETED = 1  OR INVTMF.IS_DELETED = 0)) OR  (invtmcnt1.wkey1 <> 0 AND INVTMF.IS_DELETED = 0 AND INVTMF.w_key=INVTMF.w_key)) '-- 08/11/2017 Rajendra K : Added this condition to get valid records from InvtMfgr table                    
  
    
     
                
 --         +'INNER JOIN InvtMpnLink IML ON INVTMF.UNIQMFGRHD = IML.uniqmfgrhd        
 --   INNER JOIN MfgrMaster MM ON IML.MfgrMasterId = MM.MfgrMasterId         
 --   LEFT JOIN Depts D ON K.dept_id = D.dept_id         
 --   LEFT JOIN WAREHOUS WH ON invtMf.UNIQWH = WH.UNIQWH '-- -- 06/14/2017 Rajendra K : Removed join with table INTRES --06/14/2017 Rajendra K : Removed table InvtLot,InvtMpnLink,MfgrMaster from join condition        
 --   +'LEFT JOIN #tempData IRC ON invtMf.W_KEY = IRC.W_KEY AND IRC.KaSeqNum = K.KASEQNUM '-- 08/02/2017 Rajendra K : Added KaSeqNum in join condition        
 --   +'LEFT JOIN PARTTYPE PT ON I.PART_CLASS = PT.PART_CLASS AND I.PART_TYPE = PT.PART_TYPE ' -- 08/01/2017 Rajendra K : Added PARTTYPE table in join condition            
 --+'OUTER APPLY(SELECT  SUM(QTY_OH) - SUM(RESERVED) AS Qty FROM INVTMFGR WHERE UNIQ_KEY = INVTMF.UNIQ_KEY AND UNIQWH =         
 --INVTMF.UNIQWH AND INSTORE = 0 AND LOCATION = INVTMF.LOCATION) AS invtmfgrs '         
        
 ---- 15/01/2019 - Rajendra K :Added Outer Join with invtmfgr table for AvailableQty        
 --+'WHERE ('+CASE WHEN @Filter IS NULL OR @Filter ='' THEN '1=1' ELSE @Filter END +') AND k.WONO= '''+@woNumber+''' AND WH.WAREHOUSE NOT IN(''WO-WIP'',''MRB'') ' -- 09/13/2017 Rajendra K : Apply WO Reservation default settings               
 --   -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.        
 --   --+'AND ('''+@mfgrDefault+''' = ''All MFGRS''         
 --   --OR (NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A         
 --   --    WHERE A.BOMPARENT = '''+@bomParent +''' AND A.UNIQ_KEY = I.UNIQ_KEY AND A.PARTMFGR = MM.PARTMFGR and A.MFGR_PT_NO = MM.MFGR_PT_NO))) '        
 --+' GROUP BY  K.KASEQNUM         
 --   ,WH.UNIQWH ' --10/13/2017 Rajendra K : Separated PartNo and Revision in group by clasue        
 --   +',I.PART_NO,I.REVISION,I.PART_CLASS,I.PART_TYPE,I.DESCRIPT,K.allocatedQty,K.ACT_QTY,K.SHORTQTY,I.uniq_key ,K.IGNOREKIT,I.ITAR,I.REVISION        
 --   ,D.dept_id  '--10/13/2017 Rajendra K : Separated WAREHOUSE and LOCATION in group by clasue            
 --  +',WH.WAREHOUSE ,InvtMf.LOCATION '-- 06/20/2017 - Rajendra K : Removed INVTMF.RESERVED from group by clause            
 --   +',I.useipkey ,I.SERIALYES ,PT.LOTDETAIL ' -- 08/01/2017 Rajendra K : Added useipkey,SERIALYES,LOTDETAIL in group by            
 --   +',WH.WH_GL_NBR ,W.Wono '-- 12/08/2017 Rajendra K : Added WH_GL_NBR --01/02/2018 Rajendra K :Added WONO for multiple WONO reservation         
 -- + ',invtmfgrs.Qty ,INVTMF.IS_DELETED  '        
 -- -- 03/25/2019 Rajendra K : Changed the default sorting "SHORTQTY,WH/Loc,Part_no" to "PART_NO,WH/Loc,SHORTQTY"        
 -- +' ORDER BY PART_NO, CASE WHEN INVTMF.IS_DELETED = 1 THEN '''' ELSE (RTRIM(WH.WAREHOUSE) + (CASE WHEN InvtMf.LOCATION IS NULL OR InvtMf.LOCATION = '''' THEN '''' ELSE ''/''+  InvtMf.LOCATION END)) END, K.SHORTQTY  '         
 --       + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord-1)  -- 02/08/2019 Rajendra K : Added PART_NO columns for default sort        
 --    + ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'              
 ----+' ORDER BY                 
 -- -- K.SHORTQTY  DESC        
 -- -- ,RTRIM(WH.WAREHOUSE) + (CASE WHEN InvtMf.LOCATION IS NULL OR InvtMf.LOCATION = '''' THEN '' ELSE ''/''+  InvtMf.LOCATION END)  '-- 03/15/2018 Rajendra K : Added RTRIM to Warehouse        
 --  -- As per change request Sort columns by SHORTQTY and WareHouse         
 --  --OFFSET (@startRecord-1) ROWS        
 --  --FETCH NEXT @endRecord ROWS ONLY;        
           
 --  SET @out_TotalNumberOfRecord = (SELECT COUNT(1) FROM #tempKitDetails) -- Set total count to Out parameter         
        
 --  --SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempKitDet',@filter,'','Wono','',@startRecord,@endRecord))        
 --   --EXEC sp_executesql @sqlQuery  -- 13/03/2018 Rajendra K :Added filters        
END 