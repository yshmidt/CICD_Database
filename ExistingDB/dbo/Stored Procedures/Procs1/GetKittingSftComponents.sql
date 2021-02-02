-- =============================================      
-- Author: Anuj K      
-- Create date: 05/13/2016      
-- Description: this procedure will be called from the SF module and Pull the working work orders for provided work center      
-- 08/30/16 Sachin b remove the qty allocated > 0 condition because we have to show all componants which are pulled from kit but allocated or not      
-- 08/30/16 Sachin b add inner join with woentry for calculate RequiredQty and Add Inner Join with PartType for getting lot info      
-- 08/30/16 Sachin b add inner join with woentry for calculate RequiredQty       
-- 09/06/16 Sachin b add Add temp table get the total warehouse qty and Add Inner Join       
-- 10/18/16 Sachin b Reducing the Issued qty form the Total required Qty      
-- 10/22/16 Sachin b Add Column MATLTYPE,Description       
-- 12/07/16 Sachin b Removed Join with invtmfgr,invtmpnlink,mfgrmaster      
-- 12/22/16 Sachin b Combind Partno with Revision      
-- 06/08/2017 Sachin b Remove W-Key from Select info and Add and condition for PART_CLASS in join with part_type      
-- 07/10/2017 Sachin b Change logic for calculate RequiredQty      
-- 07/25/2017 Sachin b Remove Unused temp table      
-- 07/31/2017 Sachin b Fix the Issue for the find correct AvailableQty Add condition in Where clause imfgr.IS_DELETED =0 and imfgr.INSTORE =0 and check isnull      
-- 09/15/2017 Sachin b Add LINESHORT column in select statement      
-- 10/16/2017 Sachin B Remove unused Parameter @StartRecord,@EndRecord,@SortExpression,@Filter and apply coding standard       
-- 02/01/2018 Sachin B Add PART_SOURC,SHORTQTY is select statement and Combine class/type/description      
-- 06/01/2018 Sachin B Add POCount Count Info       
-- 02/25/2019 Sachin b Change Inner Join to Left Join in PARTTYPE Table and Check Null in p.LOTDETAIL     
-- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials    
-- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)    
-- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision 
-- 08/20/2020 Sachin B : Add CustPartNoWithRev and PartNoWithRevData in the Select Statement  
-- 12/11/2020 Sachin B Calculate AvailableQty only from the approved manufacture
-- GetKittingSftComponents '0000000567','WAVE'      
-- GetKittingSftComponents '0000102142',''      
-- =============================================      
CREATE PROCEDURE [dbo].[GetKittingSftComponents]        
  -- 10/16/2017 Sachin B Remove unused Parameter @StartRecord,@EndRecord,@SortExpression,@Filter        
  @wono CHAR(10),      
  @deptId CHAR(10) = null    
AS      
BEGIN      
      
SET NOCOUNT ON;       
      
DECLARE @SQL NVARCHAR(MAX),@nonNettable BIT;      
          
-- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)    
 SET @nonNettable = (SELECT CONVERT(Bit,ISNULL(WM.settingValue,MS.settingValue))     
 FROM MnxSettingsManagement MS     
 LEFT JOIN WmSettingsManagement WM ON  MS.settingId = WM.settingId              
 WHERE SettingName  = 'allowUseOfNonNettableWarehouseLocation')    
 -- 07/25/2017 Sachin b Remove Unused temp table      
 -- 09/06/16 Sachin b add Add temp table get the total warehouse qty and Add Inner Join  
 
DECLARE @bomParent CHAR(10)    
SELECT  @bomParent = UNIQ_KEY from WOENTRY where WONO =@wono   
    
 ;With TempTotalAvailableQTY      
  AS(      
    SELECT k.UNIQ_KEY,      
    ISNULL(SUM(ISNULL(imfgr.QTY_OH, 0))-SUM(ISNULL(imfgr.RESERVED, 0)),0) as AvailableQty       
    FROM INVENTOR i      
    INNER JOIN KAMAIN k ON k.UNIQ_KEY = i.UNIQ_KEY      
    INNER JOIN WOENTRY wo ON wo.WONO = k.WONO      
    INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY      
    INNER JOIN INVTMFGR imfgr ON imfgr.UniqMfgrHd =mpn.UniqMfgrHd         
    INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId       
    INNER JOIN Warehous w  ON w.UNIQWH = imfgr.UNIQWH      
     WHERE  k.wono= @wono        
     AND Warehouse <> 'WIP'      
     AND Warehouse <> 'WO-WIP'      
     AND Warehouse <> 'MRB'    
   -- 02/27/2020 Sachin b Add the allowUseOfNonNettable setting data and change the Netable = 1 by ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)      
   AND ((@nonNettable =1 AND imfgr.SFBL =0) OR Netable = 1)      
    -- 07/31/2017 Sachin b Fix the Issue for the find correct AvailableQty Add condition in Where clause imfgr.IS_DELETED =0 and imfgr.INSTORE =0      
    AND imfgr.IS_DELETED =0      
   -- AND imfgr.INSTORE =0  -- 02/26/2020 Rajendra K : Removed condition Instore = 0 to show instore materials    
   AND (@deptId IS NULL OR @deptId='' OR DEPT_ID=@deptId) 
    -- 12/11/2020 Sachin B Calculate AvailableQty only from the approved manufacture   
	AND i.UNIQ_KEY NOT IN  
	(  
		SELECT UNIQ_KEY   
		FROM ANTIAVL A   
		WHERE A.BOMPARENT =@bomParent AND A.UNIQ_KEY = i.UNIQ_KEY 
		AND A.PARTMFGR =mfMaster.Partmfgr AND A.MFGR_PT_NO =mfMaster.mfgr_pt_no   
	)          
    GROUP BY k.UNIQ_KEY,k.KASEQNUM      
  )      
-- 10/22/16 Sachin b Add Column MATLTYPE ,Description      
SELECT i.MATLTYPE, i.useipkey, i.serialyes, i.UNIQ_KEY AS UniqKey,      
-- 12/22/16 Sachin b Combind Partno with Revision      
-- 02/01/2018 Sachin B Add PART_SOURC,SHORTQTY is select statement      
 i.part_no AS PartNo, I.REVISION,I.PART_SOURC AS PartSource,K.SHORTQTY AS Shortage,      
     CASE WHEN i.PART_SOURC <> 'CONSG' -- 08/07/2020 Rajendra K : get custpartno/custrev if the part_sourc='CONSG' otherwise part_no/revision   
   THEN CASE COALESCE(NULLIF(i.REVISION,''), '')            
   WHEN '' THEN  LTRIM(RTRIM(i.PART_NO))             
   ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION END   
   ELSE   
   CASE COALESCE(NULLIF(i.custrev,''), '')            
   WHEN '' THEN  LTRIM(RTRIM(i.CUSTPARTNO))             
   ELSE LTRIM(RTRIM(i.CUSTPARTNO)) + '/' + i.custrev END   
    END AS PartNoWithRev ,
	
   CASE COALESCE(NULLIF(i.REVISION,''), '')            
	WHEN '' THEN  LTRIM(RTRIM(i.PART_NO))             
	ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION END AS PartNoWithRevData,

	CASE COALESCE(NULLIF(i.custrev,''), '')            
   WHEN '' THEN  LTRIM(RTRIM(i.CUSTPARTNO))             
   ELSE LTRIM(RTRIM(i.CUSTPARTNO)) + '/' + i.custrev END AS CustPartNoWithRev,      
   k.wono,k.dept_id as DeptId,k.kaseqnum,k.qty AS Each,      
  -- 06/08/2017 Sachin b Remove W-Key from Select info and Add and condition for PART_CLASS in join with part_type      
SUM(k.allocatedQty + k.act_qty) AS Total,k.act_qty AS QtyIssued, k.allocatedQty AS QtyAlloc,      
-- 02/01/2018 Sachin B Add PART_SOURC,SHORTQTY is select statement and Combine class/type/description      
LTRIM(RTRIM(i.PART_CLASS)) + '/' + LTRIM(RTRIM(i.PART_TYPE)) + '/' + LTRIM(RTRIM(i.DESCRIPT)) AS [Description]      
-- 10/18/16 Sachin b Reducing the Issued qty form the Total required Qty      
-- 07/10/2017 Sachin b Change logic for calculate RequiredQty      
,(k.ACT_QTY+k.SHORTQTY+k.allocatedQty) AS RequiredQty,      
-- 02/25/2019 Sachin b Change Inner Join to Left Join in PARTTYPE Table and Check Null in p.LOTDETAIL      
ISNULL(p.LOTDETAIL, Cast (0 as bit)) AS IsLotted,ISNULL(allQty.AvailableQty,0) AS AvailableQty,k.LINESHORT AS IsLineShortage       
-- 06/01/2018 Sachin B Add POCount Count Info       
,(SELECT ISNULL(COUNT(1),0) FROM POMAIN PM INNER JOIN  POITEMS PIT  ON PM.PONUM = PIT.PONUM        
      LEFT JOIN poitschd ps ON PIT.uniqlnno = ps.uniqlnno      
      WHERE UNIQ_KEY = i.UNIQ_KEY       
     AND PM.postatus <> 'CANCEL' AND PM.postatus <>  'CLOSED'       
     AND PIT.lcancel = 0 AND ps.balance > 0) AS POCount      
FROM kamain k      
-- 08/30/16 Sachin b add inner join with woentry for calculate RequiredQty and Add Inner Join with PartType for getting lot info      
INNER JOIN WOENTRY w ON w.WONO =k.WONO      
INNER JOIN inventor i ON k.uniq_key=i.uniq_key      
-- 06/08/2017 Sachin b Remove W-Key from Select info and Add and condition for PART_CLASS in join with part_type      
-- 02/25/2019 Sachin b Change Inner Join to Left Join in PARTTYPE Table and Check Null in p.LOTDETAIL      
LEFT JOIN PARTTYPE p ON p.PART_TYPE = i.PART_TYPE AND p.PART_CLASS =i.PART_CLASS      
-- 12/07/16 Sachin b Removed Join with invtmfgr,invtmpnlink,mfgrmaster      
LEFT OUTER JOIN invt_res r ON k.uniq_key=r.uniq_key and k.wono=r.wono      
-- 09/06/16 Sachin b add Add temp table get the total warehouse qty and Add Inner Join       
LEFT OUTER JOIN TempTotalAvailableQTY allQty ON allQty.UNIQ_KEY = k.UNIQ_KEY      
WHERE  k.wono= @wono       
-- 08/30/16 Sachin b remove the qty allocated > 0 condition because we have to show all componants which are pulled from kit but allocated or not      
--and r.QtyAlloc > 0      
AND (@deptId IS NULL OR @deptId='' OR k.DEPT_ID=@deptId)      
-- 06/08/2017 Sachin b Remove W-Key from Select info      
GROUP BY i.MATLTYPE,  i.useipkey, i.serialyes, i.UNIQ_KEY , i.part_no , I.REVISION,I.PART_SOURC, k.wono,k.dept_id ,k.kaseqnum,k.qty, k.act_qty,k.allocatedQty      
,w.bldqty,p.LOTDETAIL,allQty.AvailableQty,i.DESCRIPT,k.SHORTQTY,k.LINESHORT,i.PART_CLASS,i.PART_TYPE,i.CUSTPARTNO,i.CUSTREV      
ORDER BY k.dept_id      
      
END