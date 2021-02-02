-- =====================================================    
-- Author: Shivshankar P  
-- Create date: 11/29/2017    
-- Description: Get MFGR Details  
-- Shivshankar P :  02/14/18 Added Lot Code filter conditionally  
-- Shivshankar P :  06/18/18 Changed the @InventorType 'Mfgr Part Number'  
-- Nitesh B : 10/05/2018 Added INVTLOT.UNIQ_LOT in select list  
-- Shivshankar P :  10/16/18 Added Parameter to filter the data applied the Case statement for WareHouse Location  
 --Rajendra K 11/02/2018: replaced by I.Part_Class REPLACE(I.Part_Class,'-','_')   
-- Nitesh B : 12/06/18 Added case to WarehouseLocation for trim '/' between CMF.LOCATION and W.WAREHOUSE  
-- Nitesh B : 12/07/18 Added @InventorType ='Manufacturer Part No' to if condition  
-- Rajendra K : 01/28/2019  Added default @sortExpression as "PARTMFGR, MFGR_PT_NO,WarehouseLocation,SUPNAME,CUSTNAME,ORDERPREF"  
-- Rajendra K : 01/29/2019 : Added Identity as "Number"   
-- Nitesh B : 02/25/2019 Remove Condition INM.IS_DELETED=0   
-- Shivshankar P : 02/26/2019 Filter the data even Uniq_key not available  
-- Shivshankar P : 03/21/2019 Filter by multiple uniq_key's  
-- Shivshankar P : 04/04/2019 Changed @tableName to work with multiple tables for lotted parts and join by left if table exists  
-- Shivshankar P : 04/04/2019 Added filter and sort expressions   
-- Shivshankar P : 04/25/2019 Checked If condition for value exists  
-- Rajendra K : 09/10/2019 : Added isnull condition to show QTY_OH,RESERVED,AVAILABLE as 0 if location is deleted.
-- Shivshankar P : 10/22/2019 : Get the calculated the count   
--12/23/2019 YS added space prio to ' on t.UniqLot =' +'UdfInvtlot_'
-- Shivshankar P : 02/10/2020 : Trimed the uniq_key value provided from API 
--DastanT 24/12/2020 added new Field MRBManualCnt, if field is MRB and Manual Resjection
--EXEC [GetManufacturerPartNO] '_01F0NBI73','Internal Inventory'  
-- =====================================================     
CREATE PROCEDURE [dbo].[GetManufacturerPartNO]  
(    
 @UniqKey NVARCHAR(MAX) ='',    
 @InventorType CHAR(30) = null,  
 @sortExpression NVARCHAR(1000) = null ,  
 @filter NVARCHAR(1000) = null,  
 @startRecord INT =1,    
 @endRecord INT =1000  
 --@uniqsupno CHAR(10) = null -- 6/7/2016 Added @uniqsupno parameter to check the supplier exists w r to mfgr    
)    
AS    
BEGIN    
   
 DECLARE @tUniq_Key as tUniq_key,   
   @sqlQuery NVARCHAR(MAX)  
      
    INSERT INTO @tUniq_Key   
 SELECT RTRIM(LTRIM(id)) from dbo.[fn_simpleVarcharlistToTable](@UniqKey,',') -- Shivshankar P : 03/21/2019 Filter by multiple uniq_key's  
-- Shivshankar P : 02/10/2020 : Trimed the uniq_key value provided from API 

  
 IF OBJECT_ID ('tempdb..#lotUniq') IS NOT NULL  
 BEGIN  
  DROP TABLE #tempMFGRData  
 END  
  
 -- Nitesh B : 12/07/18 Added @InventorType ='Manufacturer Part No' to if condition  
    IF(@InventorType = 'Internal Inventory' or @InventorType = 'In-Plant Customer (IPC)' OR @InventorType ='Manufacturer Part No' OR  @InventorType= 'Mfgr Part Number' or @InventorType='Inactive' OR  @InventorType='CONSG Part No')        
      BEGIN    
   ;WITH Mfgrdata AS   
   (  
     
   SELECT  M.MfgrMasterId, L.OrderPref, M.MFGR_PT_NO, M.PARTMFGR, L.UNIQ_KEY, L.UNIQMFGRHD,M.MATLTYPE, M.LDISALLOWBUY, M.LDISALLOWKIT,M.AUTOLOCATION,   
      SUM(ISNULL(INM.QTY_OH,0.00)) AS TOTAL_QTY_OH,   
   CASE WHEN  ISNULL(INM.LOCATION,'') =' ' THEN  RTRIM(W.WAREHOUSE) ELSE RTRIM(W.WAREHOUSE)  +'/'+ LTRIM(INM.LOCATION) END AS WarehouseLocation,  
   ISNULL(P.NUMBEROFPKGS,0) AS NUMBEROFPKGS,    
   -- Shivshankar P :  10/16/18 Added Parameter to filter the data applied the Case statement for WareHouse Location   
   -- Rajendra K : 09/10/2019 : Added isnull condition to show QTY_OH,RESERVED,AVAILABLE as 0 if location is deleted.   
   CASE WHEN INVTLOT.UNIQ_LOT <> ''  OR INVTLOT.UNIQ_LOT IS NOT NULL THEN  ISNULL(LOTQTY,0) ELSE ISNULL(INM.QTY_OH,0) END AS QTY_OH, -- Shivshankar P :  02/14/18 Added Lot Code filter conditionally  
   CASE WHEN INVTLOT.UNIQ_LOT <> ''  OR INVTLOT.UNIQ_LOT IS NOT NULL THEN  ISNULL(LOTRESQTY,0) ELSE ISNULL(INM.RESERVED,0) END AS RESERVED,  
   CASE WHEN INVTLOT.UNIQ_LOT <> ''  OR INVTLOT.UNIQ_LOT IS NOT NULL THEN  ISNULL(LOTQTY -LOTRESQTY,0) ELSE ISNULL(INM.QTY_OH-INM.RESERVED,0) END AS AVAILABLE,  
   INM.COUNT_DT AS LAST_COUNT,INM.NETABLE,INM.IS_VALIDATED,INM.W_KEY,INM.UNIQWH,W.WHNO,    
   W.WAREHOUSE,INM.LOCATION,M.SFTYSTK,S.SUPNAME,S.SUPID,'' AS CUSTNAME,'' AS CUSTPARTNO ,S.SUPNAME AS CustSup  
   ,LOTCODE,EXPDATE,REFERENCE,INVTLOT.UNIQ_LOT AS UniqLot,Invt.INT_UNIQ-- 10/05/2018 Nitesh B : Added INVTLOT.UNIQ_LOT in select lisе
   --DastanT 24/12/2020 added new Field MRBManualCnt, if field is MRB and Manual Resjection
   ,(select count(1) from warehous whs where whs.warehouse='MRB' and whs.UNIQWH=INM.UNIQWH
	and INM.location<>'' and exists (select 1 from inspectionHeader ith where ith.inspHeaderId=INM.location))  as MRBManualCnt
   FROM    INVTMPNLINK L    
   INNER JOIN MFGRMASTER M ON L.MFGRMASTERID=M.MFGRMASTERID    
   LEFT OUTER JOIN INVTMFGR INM ON L.UNIQMFGRHD=INM.UNIQMFGRHD AND INM.IS_DELETED=0    
   LEFT JOIN  INVTLOT  ON INVTLOT.W_KEY=INM.W_KEY    
   LEFT JOIN WAREHOUS W ON INM.UNIQWH=W.UNIQWH   
   LEFT JOIN SUPINFO S ON INM.UNIQSUPNO=S.UNIQSUPNO    
   LEFT JOIN INVENTOR Invt ON Invt.INT_UNIQ=INM.UNIQ_KEY  
   OUTER APPLY (SELECT W_KEY,COUNT(*) AS NUMBEROFPKGS FROM IPKEY WHERE IPKEY.W_KEY=INM.W_KEY AND PKGBALANCE<>0.00 GROUP BY IPKEY.W_KEY) P    
   WHERE  (ISNULL(@UniqKey,'') = '' OR EXISTS (select 1 from @tUniq_Key t where t.Uniq_key= L.UNIQ_KEY))  
    --L.UNIQ_KEY  in (select Uniq_key from @tUniq_Key)  
   --((ISNULL(@tUniq_Key,'') = '' AND L.UNIQ_KEY =L.UNIQ_KEY)  OR (L.UNIQ_KEY  in (SELECT id from dbo.[fn_simpleVarcharlistToTable]( @UniqKey,','))))   -- Shivshankar P : 02/26/2019 Filter the data even Uniq_key not available  
   AND L.IS_DELETED = 0  AND M.IS_DELETED = 0 -- Nitesh B : 02/25/2019 Remove Condition INM.IS_DELETED=0   
   GROUP BY M.MfgrMasterId, L.ORDERPREF, M.MFGR_PT_NO, M.PARTMFGR, L.UNIQ_KEY, L.UNIQMFGRHD, M.MATLTYPE, M.LDISALLOWBUY, M.LDISALLOWKIT,M.AUTOLOCATION,    
   W.WAREHOUSE,INM.LOCATION,ISNULL(P.NUMBEROFPKGS,0) , INM.QTY_OH,INM.RESERVED,INM.QTY_OH-INM.RESERVED, INM.COUNT_DT,INM.NETABLE,  
   INM.IS_VALIDATED,INM.W_KEY,INM.UNIQMFGRHD,INM.UNIQWH,W.WHNO,M.SFTYSTK,S.SUPNAME,S.SUPID,LOTCODE,EXPDATE,REFERENCE ,UNIQ_LOT  
   ,LOTQTY ,LOTRESQTY, Invt.INT_UNIQ  
                  --ORDER BY L.ORDERPREF, M.PARTMFGR, M.MFGR_PT_NO  
  UNION   
  
   SELECT CM.MFGRMASTERID,CM.OrderPref,CM.MFGR_PT_NO, CM.PARTMFGR, IC.UNIQ_KEY, CM.UNIQMFGRHD, CM.MATLTYPE, CM.LDISALLOWBUY,   
   CM.LDISALLOWKIT,CM.AUTOLOCATION, SUM(ISNULL(CMF.QTY_OH,0.00)) AS TOTAL_QTY_OH,  
   -- Nitesh B : 12/06/18 Added case to WarehouseLocation for trim '/' between CMF.LOCATION and W.WAREHOUSE  
   CASE WHEN  ISNULL(CMF.LOCATION,'') =' ' THEN  RTRIM(W.WAREHOUSE) ELSE RTRIM(W.WAREHOUSE)  +'/'+ LTRIM(CMF.LOCATION) END AS WarehouseLocation,   
   ISNULL(P.NUMBEROFPKGS,0) AS NUMBEROFPKGS,  
   -- Rajendra K : 09/10/2019 : Added isnull condition to show QTY_OH,RESERVED,AVAILABLE as 0 if location is deleted.  
   CASE WHEN INVTLOT.UNIQ_LOT <> ''  OR INVTLOT.UNIQ_LOT IS NOT NULL THEN  ISNULL(LOTQTY,0) ELSE ISNULL(CMF.QTY_OH,0) END AS QTY_OH,  -- Shivshankar P :  02/14/18 Added Lot Code filter conditionally  
   CASE WHEN INVTLOT.UNIQ_LOT <> ''  OR INVTLOT.UNIQ_LOT IS NOT NULL THEN  ISNULL(LOTRESQTY,0) ELSE ISNULL(CMF.RESERVED,0) END AS RESERVED,  
   CASE WHEN INVTLOT.UNIQ_LOT <> ''  OR INVTLOT.UNIQ_LOT IS NOT NULL THEN  ISNULL(LOTQTY -LOTRESQTY,0) ELSE ISNULL(CMF.QTY_OH-CMF.RESERVED,0) END AS AVAILABLE,  
   -- CMF.RESERVED,CMF.QTY_OH-CMF.RESERVED AS AVAILABLE,  
   CMF.COUNT_DT AS LAST_COUNT,CMF.NETABLE,CMF.IS_VALIDATED,CMF.W_KEY,CMF.UNIQWH,W.WHNO,W.WAREHOUSE ,CMF.LOCATION ,CM.SFTYSTK ,''  AS SUPNAME ,'' AS SUPID,  
   C.CUSTNAME,CUSTPARTNO,c.CUSTNAME AS CustSup,LOTCODE,EXPDATE,REFERENCE,INVTLOT.UNIQ_LOT AS UniqLot,IC.INT_UNIQ -- 10/05/2018 Nitesh B : Added INVTLOT.UNIQ_LOT in select list  
   --DastanT 24/12/2020 added new Field MRBManualCnt, if field is MRB and Manual Resjection
   ,(select count(1) from warehous whs where whs.warehouse='MRB' and whs.UNIQWH=CMF.UNIQWH
	and CMF.location<>'' and exists (select 1 from inspectionHeader ith where ith.inspHeaderId=CMF.location))  as MRBManualCnt
   FROM CUSTOMER C   
   INNER JOIN INVENTOR IC ON C.CUSTNO=IC.CUSTNO  
   INNER JOIN INVTMFGR CMF ON IC.UNIQ_KEY=CMF.UNIQ_KEY   
   LEFT JOIN  INVTLOT  ON INVTLOT.W_KEY=CMF.W_KEY    
   INNER JOIN WAREHOUS W ON CMF.UNIQWH=W.UNIQWH  
   CROSS APPLY (SELECT M.MFGRMASTERID,PARTMFGR,MFGR_PT_NO,L.UNIQMFGRHD ,L.orderpref, M.MATLTYPE, M.LDISALLOWBUY,M.LDISALLOWKIT,M.AUTOLOCATION,M.SFTYSTK  
       FROM MFGRMASTER M INNER JOIN INVTMPNLINK L ON L.MFGRMASTERID=M.MFGRMASTERID AND L.IS_DELETED=0  
       -- Shivshankar P : 02/26/2019 Filter the data even Uniq_key not available  
        WHERE (ISNULL(@UniqKey,'') = '' OR EXISTS (select 1 from @tUniq_Key t where t.Uniq_key= IC.INT_UNIQ))  
       --L.UNIQ_KEY  in (select Uniq_key from @tUniq_Key)  
       --((ISNULL(@tUniq_Key,'') = '' AND IC.INT_UNIQ  =IC.INT_UNIQ )  OR (ISNULL(@tUniq_Key,'') <> '' AND IC.INT_UNIQ  in (SELECT id from dbo.[fn_simpleVarcharlistToTable]( @UniqKey,',')))) -- Shivshankar P : 03/21/2019 Filter by multiple uniq_key's   
       AND M.IS_DELETED=0 AND L.UNIQ_KEY=IC.UNIQ_KEY AND CMF.UNIQMFGRHD=L.UNIQMFGRHD) CM
   OUTER APPLY (SELECT W_KEY,COUNT(*) AS NUMBEROFPKGS FROM IPKEY WHERE IPKEY.W_KEY=CMF.W_KEY AND PKGBALANCE<>0.00 GROUP BY IPKEY.W_KEY) P  
   WHERE IC.PART_SOURC='CONSG' AND CMF.IS_DELETED=0  
   GROUP BY CM.MFGRMASTERID,CM.orderpref,CM.MFGR_PT_NO, CM.PARTMFGR, IC.UNIQ_KEY, CM.UNIQMFGRHD, CM.MATLTYPE, CM.LDISALLOWBUY, CM.LDISALLOWKIT,CM.AUTOLOCATION,    
   W.WAREHOUSE ,CMF.LOCATION,P.NUMBEROFPKGS , CMF.QTY_OH,CMF.RESERVED,CMF.QTY_OH-CMF.RESERVED,CMF.COUNT_DT,CMF.NETABLE,CMF.IS_VALIDATED,CMF.W_KEY,CMF.UNIQMFGRHD,  
   CMF.UNIQWH,W.WHNO,CM.SFTYSTK,C.CUSTNAME,CUSTPARTNO,LOTCODE,EXPDATE,REFERENCE ,UNIQ_LOT,LOTQTY ,LOTRESQTY,IC.INT_UNIQ)  
    
  --Nitesh B 10/15/2018  : Modified following section to get Lot UDF setup data  
  --ORDER BY ISNULL(SUPNAME,''),ISNULL(CUSTNAME,''), ORDERPREF, PARTMFGR, MFGR_PT_NO--ORDERPREF, PARTMFGR, MFGR_PT_NO,  
    
  -- Rajendra K : 01/29/2019 : Added Identity as "Number"   
  SELECT  identity(int, 1, 1) as Number, * INTO #tempMFGRData FROM Mfgrdata  --ORDER BY ISNULL(SUPNAME,''),ISNULL(CUSTNAME,''), ORDERPREF, PARTMFGR, MFGR_PT_NO      
  
  -- Shivshankar P : 10/22/2019 : Get the calculated the count
    SELECT  @endRecord  = count(Number) FROM #tempMFGRData

  -- Shivshankar P :  10/16/18 Added Parameter to filter the data applied the Case statement for WareHouse Location  
  SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempMFGRData',@filter,@sortExpression,  
       --Rajendra K : 01/28/2019  Added default @sortExpression as "PARTMFGR, MFGR_PT_NO,WarehouseLocation,SUPNAME,CUSTNAME,ORDERPREF"    
       N'PARTMFGR, MFGR_PT_NO,WarehouseLocation,SUPNAME,CUSTNAME,ORDERPREF','',@startRecord,@endRecord))      
  
  IF OBJECT_ID ('tempdb..#lotUniq') IS NOT NULL  
  BEGIN  
   Drop table #lotUniq  
  END  
   
  select * into #lotUniq FROM   
  (  
   SELECT LOTDETAIL, UNIQ_KEY, P.PART_CLASS FROM INVENTOR I   
       INNER JOIN PARTTYPE P ON I.PART_TYPE = P.PART_TYPE AND I.PART_CLASS = P.PART_CLASS    
       WHERE UNIQ_KEY IN (select Uniq_key from @tUniq_Key) and LOTDETAIL = 1  
  ) lotUniq  
    
  if(@@Rowcount > 0)  
  BEGIN  
   DECLARE @tableName nvarchar(max),   
     --@SQL nvarchar(max),   
     @uniqField NVARCHAR (100)=''   
  
       
     -- Shivshankar P : 04/04/2019 Changed @tableName to work with multiple tables for lotted parts and join by left if table exists  
         
		   SET @tableName  = (SELECT  STUFF(  
                                          (SELECT DISTINCT N'' +   
             CASE WHEN (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'UdfInvtlot_'+REPLACE(I.Part_Class,'-','_')) =1 THEN  
            --12/23/2019 YS added space prio to ' on t.UniqLot =' +'UdfInvtlot_'
		    ' LEFT OUTER JOIN UdfInvtlot_'+REPLACE(I.Part_Class,'-','_')  + ' on t.UniqLot =' +'UdfInvtlot_' +REPLACE(RTRIM(I.Part_Class),'-','_')+'.fkUNIQ_LOT'  
            ELSE '' END FROM INVENTOR I  
          WHERE UNIQ_KEY in (SELECT Uniq_key FROM @tUniq_Key) FOR XML PATH('')),1,0,''))  
      
    -- Rajendra K 11/02/2018: replaced by I.Part_Class REPLACE(I.Part_Class,'-','_')   
       -- SET @SQL = 'SELECT * FROM #tempMFGRData t LEFT JOIN  '+ @tableName + ' s ON  t.UniqLot = s.fkUNIQ_LOT'  
    --SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempMFGRData t '+ @tableName ,@filter,@sortExpression,  
    --      -- Rajendra K : 01/28/2019  Added default @sortExpression as "PARTMFGR, MFGR_PT_NO,WarehouseLocation,SUPNAME,CUSTNAME,ORDERPREF"     
    --      N'PARTMFGR, MFGR_PT_NO,WarehouseLocation,SUPNAME,CUSTNAME,ORDERPREF','',@startRecord,@endRecord))     
      
   -- Shivshankar P : 04/25/2019 Checked If condition for value exists  
   IF(ISNULL(@tableName,'') <> '' )   
      BEGIN  
     -- Shivshankar P : 04/04/2019 Added filter and sort expressions   
     IF @filter <> '' AND @sortExpression <> ''  
      BEGIN  
       SET @sqlQuery ='SELECT * FROM #tempMFGRData t '+@tableName+' WHERE ' + @filter + ' ORDER BY '+ @sortExpression+'  
           OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS    
           FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'  
  
      END  
     ELSE IF @filter = '' AND @sortExpression <> ''  
      BEGIN  
       SET @sqlQuery='SELECT * FROM #tempMFGRData t '+@tableName+' ORDER BY '+ @sortExpression+'   
           OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS    
           FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'  
      END  
     ELSE IF @filter <> '' AND @sortExpression = ''  
      BEGIN  
	  --12/23/2019 YS added space prio to 'ORDER BY
       SET @sqlQuery='SELECT * FROM #tempMFGRData t '+@tableName+' WHERE ' +@filter+ ' ORDER BY   
          PARTMFGR, MFGR_PT_NO,WarehouseLocation,SUPNAME,CUSTNAME,ORDERPREF  
           OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS    
          FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'  
      END  
     ELSE  
      BEGIN  
       SET @sqlQuery='SELECT * FROM #tempMFGRData t '+@tableName+' ORDER BY   
          PARTMFGR, MFGR_PT_NO,WarehouseLocation,SUPNAME,CUSTNAME,ORDERPREF  
          OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS    
          FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'  
      END  
    END  
  END  
  
     EXEC sp_executesql @sqlQuery  
   END    
END