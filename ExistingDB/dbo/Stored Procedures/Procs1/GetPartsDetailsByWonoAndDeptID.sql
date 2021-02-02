-- =============================================    
-- Author: Sachin b    
-- Create date: 01/02/2017    
-- Description: this procedure will be called from the SFT CheckList module and get parts Detials for workorder    
-- 04/08/2017 Sachin b Get Dept_ID from Kamin for remove Ambiguity    
-- 07/06/2017 Sachin b Add LINESHORT column in select And change calculation for the RequiredQty and Shortage and combind class,type with description    
-- 07/10/2017 Sachin b Add and p.PART_CLASS =i.PART_CLASS conition in join with parttype and get SHREASON in select    
-- 07/17/2017 Sachin b combind part_no,revision and PART_SOURC as PartNoWithRev and remove join with invt_res table    
-- 07/24/2017 Sachin b remove part_source from PartNoWithRev get it seprately    
-- 09/11/2017 Sachin B Convert Inner Join to Left outer Join with KaDetail    
-- 06/05/2018 Sachin B Add Line Shortage Condition in join with KaDetail    
-- 07/14/2018 Sachin B Add Add Condition ka.SHQUALIFY ='ADD' in Join with KADETAIL        
-- 08/18/2020 Sachin B Change the Logic for the getting PartNoWithRev if source is consg then get custPartNo/rev otherwise get PartNo/rev  
-- 08/18/2020 Sachin B Add Left join with BOM_Det to get UNIQBOMNO and Convet Inner join to left with PartType table 
-- 09/21/2020 Rajendra K Added @isLineShort parameter and condition on that 
-- GetPartsDetailsByWonoAndDeptID '0000021951','',1,150,null,null    
-- =============================================    
CREATE PROCEDURE [dbo].[GetPartsDetailsByWonoAndDeptID]      
  @wono CHAR(10),    
  @deptId CHAR(4) = NULL,    
  @StartRecord INT =1,    
  @EndRecord INT=10,     
  @SortExpression CHAR(1000) = NULL,    
  @Filter NVARCHAR(1000) = NULL,
  @isLineShort BIT = 0    -- 09/21/2020 Rajendra K Added @isLineshort parameter and condition on that 
AS    
BEGIN    
SET NOCOUNT ON;     
    
DECLARE @SQL NVARCHAR(MAX);    
    
IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL          
DROP TABLE dbo.#TEMP;    
    
IF OBJECT_ID('dbo.#TEMP1', 'U') IS NOT NULL          
DROP TABLE dbo.#TEMP1;    
    
SELECT  i.UNIQ_KEY AS UniqKey    
,i.part_no AS PartNo    
,I.REVISION    
,CASE COALESCE(NULLIF(inv.REVISION,''), '') WHEN ''   
           THEN  LTRIM(RTRIM(inv.PART_NO))    
              ELSE LTRIM(RTRIM(inv.PART_NO)) + '/' + inv.REVISION  END AS AssemblyNoWithRev ,  
--LTRIM(RTRIM(i.part_no))+' / '+ LTRIM(RTRIM(i.REVISION)) as PartNoWithRev,   
 -- 08/18/2020 Sachin B Change the Logic for the getting PartNoWithRev if source is consg then get custPartNo/rev otherwise get PartNo/rev   
 CASE i.PART_SOURC WHEN 'CONSG'   
      THEN CASE COALESCE(NULLIF(i.CUSTREV,''), '')  WHEN ''   
                  THEN  LTRIM(RTRIM(i.CUSTPARTNO))    
                  ELSE LTRIM(RTRIM(i.CUSTPARTNO)) + '/' + i.CUSTREV END  
                     ELSE CASE COALESCE(NULLIF(i.REVISION,''), '') WHEN ''   
                  THEN  LTRIM(RTRIM(i.PART_NO))    
                  ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION  END END AS PartNoWithRev    
,dbo.fRemoveLeadingZeros(k.Wono) AS Wono    
,k.dept_id AS DeptId    
,k.kaseqnum    
,k.qty AS Each    
,Sum(k.allocatedQty + k.act_qty) AS Total    
,k.act_qty AS QtyIssued    
,k.allocatedQty AS QtyAlloc    
-- 07/06/2017 Sachin b Add LINESHORT column in select And change calculation for the RequiredQty and Shortage and combind class,type with description    
,p.PART_CLASS+' / '+p.PART_TYPE+' / '+ i.DESCRIPT AS 'Description'    
,(K.ACT_QTY+K.SHORTQTY+K.allocatedQty) AS RequiredQty,     
K.SHORTQTY AS Shortage,    
k.LINESHORT AS IsLineShortage,    
-- 07/10/2017 Sachin b Add and p.PART_CLASS =i.PART_CLASS conition in join with parttype and get SHREASON in select    
IsNull(ka.SHREASON,'') AS 'TEXT',    
+LTRIM(RTRIM(i.PART_SOURC)) AS PartSource,ISNULL(bomDet.UNIQBOMNO,'') AS UniqBomNo  
INTO #TEMP    
FROM kamain k    
-- 09/11/2017 Sachin B Convert Ineer Join to Left outer Join with KaDetail    
-- 06/05/2018 Sachin B Add Line Shortage Condition in join with KaDetail    
LEFT JOIN KADETAIL ka ON k.KASEQNUM =ka.KASEQNUM AND ka.SHREASON<>'DELETE SHORTAGE' AND k.LINESHORT =1    
INNER JOIN WOENTRY w ON w.WONO =k.WONO    
INNER JOIN inventor inv ON w.UNIQ_KEY =inv.UNIQ_KEY    
INNER JOIN inventor i ON k.uniq_key=i.uniq_key    
-- 07/10/2017 Sachin b Add and p.PART_CLASS =i.PART_CLASS conition in join with parttype and get SHREASON in select    
-- 08/18/2020 Sachin B Add Left join with BOM_Det to get UNIQBOMNO and Convet Inner join to left with PartType table  
LEFT JOIN PARTTYPE p ON p.PART_TYPE = i.PART_TYPE AND p.PART_CLASS =i.PART_CLASS   
LEFT JOIN BOM_DET bomDet ON  bomDet.BOMPARENT =inv.UNIQ_KEY AND bomDet.UNIQ_KEY = i.UNIQ_KEY  
where  k.wono= @wono     
-- 04/08/2017 Sachin b Get Dept_ID from Kamin for remove Ambiguity    
AND (@deptId IS NULL OR @deptId='' OR K.DEPT_ID = @deptId)
AND ((@isLineShort = 1 AND k.LINESHORT = 1) OR (@isLineShort = 0 AND 1=1)) -- 09/21/2020 Rajendra K Added @isLineShort parameter and condition on that   
Group by i.UNIQ_KEY ,inv.REVISION,inv.PART_NO, i.part_no , I.REVISION, k.wono,k.dept_id ,k.kaseqnum,k.qty, k.act_qty,k.allocatedQty,w.bldqty,i.DESCRIPT,k.LINESHORT    
,p.PART_CLASS,p.PART_TYPE,K.SHORTQTY,ISNULL(ka.SHREASON,''),i.PART_SOURC,i.CUSTREV,i.CUSTPARTNO,bomDet.UNIQBOMNO    
ORDER BY k.dept_id    
    
SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP1 from #temp    
    
 IF @filter <> '' AND @sortExpression <> ''    
  BEGIN    
   SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP1 WHERE '+@filter+') AS TotalCount from #TEMP1  t  WHERE '+@filter+' and    
   RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+' ORDER BY '+ @SortExpression+''    
   END    
  ELSE IF @filter = '' AND @sortExpression <> ''    
  BEGIN    
    SET @SQL=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP1 ) AS TotalCount from #TEMP1  t  WHERE     
    RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+' ORDER BY '+ @sortExpression+''    
 END    
  ELSE IF @filter <> '' AND @sortExpression = ''    
  BEGIN    
      SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP1 WHERE '+@filter+') AS TotalCount from #TEMP1  t  WHERE  '+@filter+' and    
      RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''    
   END    
   ELSE    
     BEGIN    
      SET @SQL=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP1) AS TotalCount from #TEMP1  t  WHERE     
   RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''    
   END    
   EXEC sp_executesql @SQL    
END