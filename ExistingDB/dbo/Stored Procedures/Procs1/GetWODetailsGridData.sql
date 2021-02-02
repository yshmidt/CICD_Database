  -- =============================================
-- Author:		Rajendra K	
-- Create date: <01/02/2018>
-- Description:Kit WO details data 
-- 13/03/2018 Rajendra K :Added filters
-- 03/29/2018 Rajendra K : Warehouse and Location in Select List
-- 11/13/2018 Rajendra K : Changed sorting condition
-- 15/01/2019 Rajendra K : Added Outer join with invtmfgrs table for AvailableQty
-- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.
-- 05/31/2019 Rajendra K : Removed Get total counts table and added fn_GetDataBySortAndFilters() to get total count
-- 05/31/2019 Rajendra K : Added Outer join with invtmfgr table to getting part if part dont having MPN and warehouse and location
-- 05/04/2019 Rajendra K : Added Outer join with invtmfgr table to getting availableQty as sum of of approved MPN    
-- 05/04/2019 Rajendra K : Changed AvailableQty as TotalStock     
-- 05/04/2019 Rajendra K : Added BOMPARENT , TotalStock in selection list    
-- 06/13/2019 Rajendra K : Added Outer Join PhantomComp to recognize phantom BOM components AS "IsPhantom"
-- 06/14/2019 Rajendra K : Added table #BomParList to hold BOMPARENT list
-- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations
-- 12/24/2019 Rajendra K : Added the condition to bring the part if all the location of that part are deleted
-- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition  
-- 06/24/2020 Rajendra K : Added Outer join to get OtherAvailable Qty and added into selection list
-- 07/23/2020 Rajendra K : Added outer join to get CustPartNo and rev and added part_sourc, CustpartNo/rev in selection list
-- 07/28/2020 YS removed extra outer join. No need to. We only display custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision
-- EXEC GetWODetailsGridData '0000102126,0000102128',1,1000,'',''   
-- =============================================
CREATE PROCEDURE [dbo].[GetWODetailsGridData]
(
@woNumber NVARCHAR(MAX)='',
@startRecord INT =1,
@endRecord INT =1000,
@Filter NVARCHAR(1000) = null,
@out_TotalNumberOfRecord INT OUTPUT
)
AS 
BEGIN
	SET NOCOUNT ON;	
  DECLARE @qryMain  NVARCHAR(MAX), @rowCount NVARCHAR(MAX);  
	 DECLARE @sqlQuery NVARCHAR(MAX);	    
	SET @woNumber = @woNumber + ',';

	--10/09/2017 Rajendra K : Added Temp table #woList to hold WONO list
	CREATE TABLE #woList
	(
	 RowNum INT Identity(1,1),
	 WONO CHAR(10),
	 WO VARCHAR(MAX)
	)

	-- 06/13/2019 Rajendra K : Added table #BomParList to hold BOMPARENT list
	CREATE TABLE #BomParList
	(
	 BOMPARENT CHAR(10)
	)
	 -- 05/31/2019 Rajendra K : Added #CountTable to get total count
	 CREATE TABLE #CountTable(
		  totalCount INT
	 )
	--Get WONOList list from comma separeted string
	   ;WITH WONOList AS
		(
			SELECT SUBSTRING(@woNumber,1,CHARINDEX(',',@woNumber,1)-1) AS WONO, SUBSTRING(@woNumber,CHARINDEX(',',@woNumber,1)+1,LEN(@woNumber)) AS WO 
			UNION ALL
			SELECT SUBSTRING(A.WO,1,CHARINDEX(',',A.WO,1)-1)AS WONO, SUBSTRING(A.WO,charindex(',',A.WO,1)+1,LEN(A.WO)) 
			FROM WONOList A WHERE LEN(a.WO)>=1
        ) 

		--10/09/2017 Rajendra K : Insert #woList List from CTE WONOList
		INSERT INTO #woList (WONO,WO)
		SELECT WONO,WO FROM WONOList

		-- 06/13/2019 Rajendra K : Added table #BomParList to hold BOMPARENT list
		INSERT INTO #BomParList (BOMPARENT)
		SELECT UNIQ_KEY FROM WOENTRY W INNER JOIN #woList WL ON W.WONO = WL.WONO

	--Default settings logic
    --Declare variables
    DECLARE @nonNettable BIT,@bomParent CHAR(10)--@mfgrDefault NVARCHAR(MAX)  

	SELECT SettingName
		   ,LTRIM(WM.SettingValue) SettingValue
	INTO  #tempWOSettings
	FROM MnxSettingsManagement MS INNER JOIN WmSettingsManagement WM ON MS.settingId = WM.settingId   -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.  
	 WHERE SettingName  = 'allowUseOfNonNettableWarehouseLocation'--IN('manufacturersDefault','allowUseOfNonNettableWarehouseLocation')  

    --Assign values to variables to hold values for WO Reservation  default settings
 -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.
 --SET @mfgrDefault = ISNULL((SELECT SettingValue FROM #tempWOSettings WHERE SettingName = 'manufacturersDefault'),'All MFGRS')  
	SET @nonNettable= ISNULL((SELECT CONVERT(BIT, SettingValue) FROM #tempWOSettings WHERE SettingName = 'allowUseOfNonNettableWarehouseLocation'),0)
	SELECT UNIQ_KEY INTO #tempBomParent FROM WOENTRY W INNER JOIN #woList WL ON W.WONO = WL.WONO
	
   -- 05/31/2019 Rajendra K : Removed Get total counts table and added fn_GetDataBySortAndFilters() to get total count 
 --SELECT COUNT(K.KASEQNUM) AS CountRecords -- Get total counts   
 --INTO #tempKitDetails   
 --FROM  KAMAIN K  
 --   INNER JOIN INVENTOR I ON K.UNIQ_KEY=I.UNIQ_KEY   
 --   INNER JOIN WOENTRY W ON W.WONO=K.WONO  
 --   INNER JOIN INVTMFGR INVTMF ON INVTMF.UNIQ_KEY = K.UNIQ_KEY AND (@nonNettable = 1 OR INVTMF.NETABLE = 1) AND INVTMF.InStore = 0 AND INVTMF.IS_DELETED = 0   
 --   LEFT JOIN Depts D ON K.dept_id = D.dept_id  
 --   INNER JOIN WAREHOUS WH ON invtMf.UNIQWH = WH.UNIQWH  
 --   INNER JOIN #woList WL ON W.WONO = WL.WONO  
 --WHERE WH.WAREHOUSE NOT IN('WO-WIP','MRB')   
 --GROUP BY  K.KASEQNUM   
 --   ,WH.UNIQWH  
 --   ,K.allocatedQty  
 --   ,K.ACT_QTY  
 --   ,K.SHORTQTY  
 --   ,I.uniq_key   
 --   ,WH.WAREHOUSE  
 --   ,invtMf.LOCATION  
	   --Create CTE to get allocated records from Invt_Res table
	   ;WITH InvtReserve AS 
		(
		  SELECT SUM(QTYALLOC) AS Allocated
		  ,W_KEY
		  ,KaSeqNum
		  FROM 
		  INVT_RES IR 
		  INNER JOIN #woList WL ON IR.WONO = WL.WONO
		  GROUP BY W_KEY,KaSeqNum
		)
	    --Get records by pagination
		SELECT  DISTINCT W.Wono
		  ,CAST(dbo.fremoveLeadingZeros(W.Wono) AS VARCHAR(MAX)) AS WorkOrderNumber
		  , K.KASEQNUM 
    ,CASE WHEN INVTMF.IS_DELETED = 1 THEN '' ELSE WH.UNIQWH END AS UniqWHKey  
    ,CASE WHEN INVTMF.IS_DELETED = 1 THEN '' ELSE WH.WAREHOUSE + (CASE WHEN InvtMf.LOCATION IS NULL OR InvtMf.LOCATION = '' THEN '' ELSE '/'+  InvtMf.LOCATION END) END  AS Location  
		  ,D.dept_id AS WorkCenter
		  ,I.ITAR ,
		  -- 07/23/2020 Rajendra K : Added outer join to get CustPartNo and rev and added part_sourc, CustpartNo/rev in selection list
		  --- 07/28/2020 YS no need for the outer join if the part_sourc='CONSG' we need to use customer part number if not internal
		  --,CASE WHEN ISNULL(CustPtRev.PartNo,'')= '' THEN RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) ELSE CustPtRev.partNo END AS PART_NO 
		   CASE WHEN Part_sourc='CONSG' then RTRIM(i.CUSTPARTNO) + 
			(CASE when i.CUSTREV = '' THEN CUSTREV ELSE '/'+ CUSTREV END) ELSE 
			RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) END as Part_no  
		  ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE I.PART_CLASS +'/ ' END ) + 
    (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN ' / '+ I.DESCRIPT ELSE I.PART_TYPE + ' / '+I.DESCRIPT END) AS Descript  
    --,(SUM(ISNULL(INVTMF.QTY_OH, 0))-SUM(ISNULL(INVTMF.RESERVED, 0))) as AvailableQty  -- 15/01/2019 Rajendra K : added comment for AvailableQty
		  ,K.allocatedQty
		  ,(K.SHORTQTY+(K.ACT_QTY+K.allocatedQty)) AS Required
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
		  ,(SELECT ISNULL(COUNT(1),0) FROM POMAIN PM INNER JOIN  POITEMS PIT  ON PM.PONUM = PIT.PONUM  
		    LEFT JOIN poitschd ps ON PIT.uniqlnno = ps.uniqlnno
		    WHERE UNIQ_KEY = I.UNIQ_KEY 
		   AND PM.postatus <> 'CANCEL' AND PM.postatus <>  'CLOSED' 
		   AND PIT.lcancel = 0 AND ps.balance > 0) AS POCount 
		   ,(SELECT ISNULL(COUNT(1),0) FROM INVT_RES IR  INNER JOIN #woList WL ON IR.WONO = WL.WONO  WHERE  IR.UNIQ_KEY = I.UNIQ_KEY) AS HistoryCount   
	      ,WH.WH_GL_NBR AS WHNBR 
		  ,CAST((CASE WHEN dbo.fn_GetCCQtyOH(I.UNIQ_KEY,'','','')>0 THEN 1 ELSE 0 END) AS BIT) AS CC 
		   -- 03/29/2018 Rajendra K : Warehouse and Location in Select List
		 ,CASE WHEN INVTMF.IS_DELETED = 1 THEN '' ELSE WH.WAREHOUSE END AS Warehouse  
		 ,CASE WHEN INVTMF.IS_DELETED = 1 THEN '' ELSE InvtMf.LOCATION END AS Loc  
		--,ISNULL(invtmfgrs.Qty,0) AS AvailableQty          -- 15/01/2019 Rajendra K :   AvailableQty from invtmfgrs table    
		,ISNULL(invtMfgrTotal.Qty,0) as AvailableQty -- 05/04/2019 Rajendra K : Added BOMPARENT , TotalStock in selection list    
		,ISNULL( invtmfgrs.TotalStock,0) AS TotalStock -- 05/04/2019 Rajendra K : Changed AvailableQty as TotalStock       
		 ,INVTMF.IS_DELETED
		,K.BOMPARENT      
		 ,CAST(ISNULL(PhantomComp.Phantom ,0) AS BIT) AS IsPhantom -- 06/13/2019 Rajendra K : Added Outer Join PhantomComp to recognize phantom BOM components AS "IsPhantom"
		 -- 06/24/2020 Rajendra K : Added Outer join to get OtherAvailable Qty and added into selection list
		,ISNULL(ExtraQty.OtherAvailable,0) AS OtherAvailable
    -- 07/23/2020 Rajendra K : Added outer join to get CustPartNo and rev and added part_sourc, CustpartNo/rev in selection list
		--- 07/28/20 YS just use i.part_sourc
		--,CASE WHEN ISNULL(CustPtRev.PART_SOURC,'') = '' THEN I.PART_SOURC ELSE CustPtRev.PART_SOURC END AS Part_sourc
		,I.PART_SOURC
	INTO #tempKitDet  
	FROM INVENTOR I
	 RIGHT JOIN KAMAIN K ON k.UNIQ_KEY=I.UNIQ_KEY 
	 INNER JOIN WOENTRY W ON W.WONO=k.WONO
	 OUTER APPLY (SELECT wkeys.delWkey ,COUNT(w_key) AS wkey FROM INVTMFGR -- 05/31/2019 Rajendra K : Added Outer join with invtmfgr table to getting part if part dont having MPN and warehouse and location
	 OUTER APPLY (SELECT  TOP 1 w_key AS delWkey FROM INVTMFGR  WHERE UNIQ_KEY = K.UNIQ_KEY AND IS_DELETED = 1) AS wkeys
						 WHERE UNIQ_KEY = K.UNIQ_KEY AND IS_DELETED = 1 GROUP BY  wkeys.delWkey ) AS invtmCntDet
	 OUTER APPLY (SELECT  COUNT(w_key) AS wkey FROM INVTMFGR  WHERE UNIQ_KEY = K.UNIQ_KEY AND IS_DELETED = 0) AS invtmcnt
	 INNER JOIN INVTMFGR INVTMF ON INVTMF.UNIQ_KEY = K.UNIQ_KEY 
    -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition   
      AND ((CAST(@nonNettable AS CHAR(1)) = 1  AND INVTMF.SFBL = 0) OR INVTMF.NETABLE = 1)    
			--AND INVTMF.InStore = 0    -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations
   AND  ((((invtmCntDet.wkey = 1) OR  (invtmCntDet.wkey <> 1 AND invtmcnt.wkey=0 AND invtmCntDet.delWkey= INVTMF.w_key ))   -- 12/24/2019 Rajendra K : Added the condition to bring the part if all the location of that part are deleted
   AND ((invtmCntDet.wkey = 1 AND invtmcnt.wkey  = 0 )OR INVTMF.IS_DELETED = 0 OR (invtmCntDet.wkey <> 1 AND invtmcnt.wkey  = 0))) OR  (invtmcnt.wkey <> 0 AND INVTMF.IS_DELETED = 0 AND INVTMF.w_key=INVTMF.w_key ))     
          INNER JOIN InvtMpnLink IML ON INVTMF.UNIQMFGRHD = IML.uniqmfgrhd  AND i.UNIQ_KEY= IML.UNIQ_KEY
		  INNER JOIN MfgrMaster MM ON IML.MfgrMasterId = MM.MfgrMasterId
		  LEFT JOIN Depts D ON K.dept_id = D.dept_id
		  INNER JOIN WAREHOUS WH ON invtMf.UNIQWH = WH.UNIQWH
		  LEFT JOIN InvtReserve IRC ON invtMf.W_KEY = IRC.W_KEY AND IRC.KaSeqNum = K.KASEQNUM
		  LEFT JOIN PARTTYPE PT ON I.PART_CLASS = PT.PART_CLASS AND I.PART_TYPE = PT.PART_TYPE 
		  INNER JOIN #woList WL ON W.WONO = WL.WONO
 -- 05/04/2019 Rajendra K : Changed AvailableQty as TotalStock     
  OUTER APPLY(SELECT  (SUM(QTY_OH) - SUM(RESERVED)) AS TotalStock FROM INVTMFGR WHERE UNIQ_KEY = INVTMF.UNIQ_KEY AND UNIQWH = INVTMF.UNIQWH 
  AND INSTORE = 0    -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations
	AND LOCATION = INVTMF.LOCATION) AS invtmfgrs 
OUTER APPLY(SELECT  SUM(QTY_OH) - SUM(RESERVED) AS Qty FROM INVTMFGR IM    -- 05/04/2019 Rajendra K : Added Outer join with invtmfgr table to getting available Qty as sum of of approved MPN    
   INNER JOIN InvtMPNLink pn ON im.UNIQMFGRHD =  pn.uniqmfgrhd     
   INNER JOIN MfgrMaster mf ON pn.MfgrMasterId = mf.MfgrMasterId AND (NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A      
      WHERE A.BOMPARENT = W.UNIQ_KEY   
       AND A.UNIQ_KEY = INVTMF.UNIQ_KEY     
       AND A.PARTMFGR = mf.PARTMFGR     
       AND A.MFGR_PT_NO = mf.MFGR_PT_NO))    
  WHERE IM.UNIQ_KEY = INVTMF.UNIQ_KEY AND UNIQWH = INVTMF.UNIQWH     
   AND LOCATION = INVTMF.LOCATION     
 ) AS invtMfgrTotal     
 -- -- 15/01/2019 Rajendra K : Added Outer join with invtmfgrs table for AvailableQty    
	-- 06/13/2019 Rajendra K : Added Outer Join PhantomComp to recognize phantom BOM components AS "IsPhantom"
	OUTER APPLY (SELECT CAST(1 AS BIT) AS Phantom FROM KAMAIN ka INNER JOIN #woList WL ON ka.WONO = WL.WONO 
					WHERE BOMPARENT IN (SELECT B.UNIQ_KEY FROM INVENTOR I RIGHT JOIN BOM_DET B ON I.UNIQ_KEY = B.UNIQ_KEY 
																		  INNER JOIN #BomParList BL ON B.BOMPARENT = BL.BOMPARENT
			 WHERE i.PART_SOURC = 'PHANTOM') AND ka.KASEQNUM = K.KASEQNUM) AS PhantomComp
  	OUTER APPLY (-- 06/24/2020 Rajendra K : Added Outer join to get OtherAvailable Qty and added into selection list
			SELECT ABS(SUM(shortqty)) AS OtherAvailable 
			FROM kamain WHERE INVTMF.UNIQ_KEY=kamain.UNIQ_KEY AND  SHORTQTY<0 AND EXISTS
			(SELECT 1 FROM woentry WHERE OPENCLOS NOT LIKE 'C%' and woentry.wono=kamain.wono AND kamain.WONO != W.WONO) 
	) ExtraQty 
	--	OUTER APPLY(-- 07/23/2020 Rajendra K : Added outer join to get CustPartNo and rev and added part_sourc, CustpartNo/rev in selection list
	--	SELECT RTRIM(CUSTPARTNO) + (CASE WHEN CUSTREV IS NULL OR CUSTREV = '' THEN CUSTREV ELSE '/'+ CUSTREV END) AS PartNo,PART_SOURC
	--	 FROM INVENTOR 
	--	 Outer APPLY(
	--			SELECT BOMCUSTNO FROM INVENTOR WHERE UNIQ_KEY  = W.UNIQ_KEY
	--	 )cust 
	--	 WHERE CUSTNO = cust.BOMCUSTNO AND INT_UNIQ =INVTMF.UNIQ_KEY

	--) CustPtRev
	WHERE WH.WAREHOUSE NOT IN('WO-WIP','MRB') 
    --AND (@mfgrDefault = 'All MFGRS'    -- 04/18/2019 Rajendra K : Removed setting "@mfgrDefault" for all manufacture.
    --OR (NOT EXISTS (SELECT bomParent FROM ANTIAVL A INNER JOIN #tempBomParent TBP ON A.BOMPARENT = TBP.UNIQ_KEY  
    --    WHERE A.UNIQ_KEY = I.UNIQ_KEY AND A.PARTMFGR = MM.PARTMFGR and A.MFGR_PT_NO = MM.MFGR_PT_NO))  
    --    )
	GROUP BY  W.WONO,K.KASEQNUM 
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
			,invtMfgrTotal.Qty     
			,INVTMF.IS_DELETED
			,K.BOMPARENT     
			 ,invtmfgrs.TotalStock      
			,PhantomComp.Phantom
			,ExtraQty.OtherAvailable -- 06/24/2020 Rajendra K : Added Outer join to get OtherAvailable Qty and added into selection list  
			-- 07/28/20 YS
			,I.CustPartNo,I.CustRev
			--,CustPtRev.PartNo-- 07/23/2020 Rajendra K : Added outer join to get CustPartNo and rev and added part_sourc, CustpartNo/rev in selection list
			--,CustPtRev.PART_SOURC
			,I.PART_SOURC
	ORDER BY 
  --RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END),  	       
   PART_NO,
   CASE WHEN INVTMF.IS_DELETED = 1 THEN '' ELSE WH.WAREHOUSE+ (CASE WHEN InvtMf.LOCATION IS NULL OR InvtMf.LOCATION = '' THEN '' ELSE '/'+  InvtMf.LOCATION END) END,W.WONO   
			--OFFSET (@startRecord-1) ROWS
			--FETCH NEXT @endRecord ROWS ONLY;
   
-- 05/31/2019 Rajendra K : Removed Get total counts table and added fn_GetDataBySortAndFilters() to get total count
   --SET @out_TotalNumberOfRecord = (SELECT COUNT(1) FROM #tempKitDetails) -- Set total count to Out parameter   
  SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempKitDet',@Filter,'PART_NO,Shortage','','Warehouse',@startRecord,@endRecord))          
	INSERT INTO #CountTable EXEC sp_executesql @rowCount  
	
	SELECT @out_TotalNumberOfRecord =totalCount FROM #CountTable

-- 13/03/2018 Rajendra K :Added filters --11/13/2018 Rajendra K : Changed sorting condition
SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempKitDet',@Filter,'PART_NO,Shortage','','',@startRecord,@endRecord))   
EXEC sp_executesql @sqlQuery
--SELECT * FROM #tempKitDet
END
