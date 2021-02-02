-- =============================================      
-- Author:Sachin B      
-- Create date: 06/12/2016      
-- Description: this procedure will be called from the SF module and Pull the transfer history for the work center between two dates      
-- 08/01/16 Sachin B remove unuseful temporary table      
-- 09/14/16 Sachin b Adding the multiple filter options filter with workOrder,PartNo,DateRange      
--- 03/28/17 YS changed length of the part_no column from 25 to 35      
-- 04/12/2017 Sachin b Adding Parameter @StartRecord,@EndRecord,@SortExpression,@Filter and remove adding Time from toDate and return dataset and Add as in columns      
-- 11/03/2017 Sachin B Add XFER_UNIQ in Select Statement and Add Join with INVT_REC table      
-- 01/04/2018 Sachin B Add the Dynamic Query for the Implement filter functionality and Remove First Select Statement for count      
-- 04/05/2018 Sachin B Fix the History Screen Shorting Issue reported by QA      
-- 06/13/2018 Sachin B Remove join with DEPT_QTY table      
-- 06/25/2018 Sachin B Use FR_DEPT_ID in Select Statement      
-- 09/03/2018 Sachin B Short Transfer History Data by order by date Desc    
-- 05/23/2019 Sachin B Change the join table aspnet_Profile to aspnet_Users for getting UserName    
-- 08/02/2020 Sachin B Get XFER_UNIQ from transfer Table and Add SerialYes Column in the Select Statement
-- GetWorkCenterTransferHistory 'STAG','1/4/2018','1/4/2019 11:59:59 PM','0000000349','','Work Order',0,150,''       
-- =============================================      
      
CREATE PROCEDURE GetWorkCenterTransferHistory       
@DepID CHAR(10),      
@FromDate DATETIME,      
@ToDate DATETIME,      
@WoNo CHAR(10),      
--- 03/28/17 YS changed length of the part_no column from 25 to 35      
@PartNo CHAR(35),      
@filterType CHAR(25),      
@StartRecord INT,      
@EndRecord INT,       
@SortExpression CHAR(1000) = NULL,      
@Filter NVARCHAR(1000) = NULL      
      
AS      
SET NOCOUNT ON;       
      
DECLARE @sql NVARCHAR(MAX)      
      
IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL            
DROP TABLE dbo.#TEMP;      

-- 08/02/2020 Sachin B Get XFER_UNIQ from transfer Table and Add SerialYes Column in the Select Statement      
SELECT DISTINCT       
ROW_NUMBER() OVER (ORDER BY t.XFER_UNIQ) AS RowNum,      
t.[DATE] AS [Date],      
0.0   AS QuantityIn,      
SUM(QTY) AS QuantityOut,      
dbo.fRemoveLeadingZeros(w.WONO) AS Wono,      
CASE COALESCE(NULLIF(i.REVISION,''), '')      
  WHEN '' THEN  LTRIM(RTRIM(i.PART_NO))       
  ELSE LTRIM(RTRIM(i.PART_NO)) + '/' + i.REVISION       
  END AS PartNoWithRev,      
TO_DEPT_ID AS ToDepartment,      
FR_NUMBER AS Number,      
i.REVISION AS Revision ,      
--d.CURR_QTY AS WcQty,      
i.DESCRIPT AS [Description],    
LTRIM(RTRIM(au.UserName)) AS [By],        
c.CUSTNAME as CustName,      
-- 11/03/2017 Sachin B Add XFER_UNIQ in Select Statement      
ISNULL(t.XFER_UNIQ,''  ) AS XFER_UNIQ,      
FR_DEPT_ID AS FromDepartment,i.SERIALYES  As SerailYes     
INTO #TEMP      
FROM WOENTRY w      
INNER JOIN INVENTOR i ON i.UNIQ_KEY = w.UNIQ_KEY      
INNER JOIN [TRANSFER] t ON t.WONO = w.WONO      
LEFT OUTER JOIN Customer c ON c.CUSTNO = w.CUSTNO      
-- 06/13/2018 Sachin B Remove join with DEPT_QTY table       
--INNER JOIN DEPT_QTY d ON d.WONO = w.WONO      
LEFT OUTER JOIN INVT_REC rec ON t.XFER_UNIQ = rec.XFER_UNIQ      
LEFT JOIN aspnet_Users au ON t.[BY] = au.UserId   -- 05/23/2019 Sachin B Change the join table aspnet_Profile to aspnet_Users for getting UserName    
WHERE       
-- 09/14/16 Sachin b Adding the multiple filter options filter with workOrder,PartNo,DateRange      
-- 04/12/2017 Sachin b Adding Parameter @StartRecord,@EndRecord,@SortExpression,@Filter and remove adding Time from toDate and return dataset and Add as in columns      
(@filterType ='Work Order' AND w.WONO = @woNo AND (@DepID IS NULL OR @DepID='' OR FR_DEPT_ID = @DepID))       
OR (@filterType ='Part No' AND i.PART_NO = @PartNo AND t.[DATE] >=@fromDate AND t.[DATE] <=@toDate AND (@DepID IS NULL OR @DepID='' OR FR_DEPT_ID = @DepID))      
OR (@filterType ='Date Range' AND t.[DATE] >=@fromDate  AND t.[DATE] <=@toDate AND (@DepID IS NULL OR @DepID='' OR FR_DEPT_ID = @DepID))      
GROUP BY t.[DATE],w.wono,FR_DEPT_ID,FR_NUMBER,i.PART_NO,TO_DEPT_ID,i.REVISION,i.DESCRIPT,au.UserName,c.CUSTNAME,t.XFER_UNIQ,i.SERIALYES  --,d.CURR_QTY        
-- 04/05/2018 Sachin B Fix the History Screen Shorting Issue reported by QA      
-- 09/03/2018 Sachin B Short Transfer History Data by order by date Desc    
ORDER BY Wono,[Date] Desc      
      
-- 01/04/2018 Sachin B Add the Dynamic Query for the Implement filter functionality and Remove First Select Statement for count      
IF @filter <> '' AND @sortExpression <> ''      
 BEGIN      
  SET @sql=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+CONVERT(VARCHAR,@sortExpression)+') AS RowNumber,*  from #TEMP )      
  select  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount       
  from CETTemp  t  WHERE '+@filter+' and RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)      
 END      
ELSE IF @filter = '' AND @sortExpression <> ''      
 BEGIN      
  SET @sql=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+CONVERT(VARCHAR,@sortExpression)+') AS RowNumber,*  from #TEMP )      
  select  t.*,(SELECT COUNT(RowNumber) FROM CETTemp ) AS TotalCount from CETTemp  t  WHERE       
  RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)      
 END      
ELSE IF @filter <> '' AND @sortExpression = ''      
 BEGIN      
     -- 04/05/2018 Sachin B Fix the History Screen Shorting Issue reported by QA      
  -- 09/03/2018 Sachin B Short Transfer History Data by order by date Desc    
  SET @sql=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY Wono,[Date] Desc) AS RowNumber,*  from #TEMP )      
  select  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount from CETTemp  t  WHERE  '+@filter+' and      
  RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''      
 END      
ELSE      
 BEGIN      
     -- 04/05/2018 Sachin B Fix the History Screen Shorting Issue reported by QA      
  -- 09/03/2018 Sachin B Short Transfer History Data by order by date Desc    
  SET @sql=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY Wono,[Date] Desc) AS RowNumber,*  from #TEMP )      
  select  t.*,(SELECT COUNT(RowNumber) FROM CETTemp) AS TotalCount from CETTemp  t  WHERE       
  RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''      
 END      
EXEC SP_EXECUTESQL @sql