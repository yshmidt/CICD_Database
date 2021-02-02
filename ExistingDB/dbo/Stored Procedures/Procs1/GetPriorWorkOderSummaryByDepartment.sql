-- =============================================
-- Author:	Anuj K
-- Create date: 05/13/2016
-- Description:	this procedure will be called from the SF module and Pull the working work orders for provided work center
-- GetPriorWorkOderSummaryByDepartment 'FGI',1,60,'WcDueDate desc',''
-- 12/22/2016 Sachin b Add ITAR Column 
-- 01/18/2017 Sachin b get Dept_Id from the DEPTS table to show previous WC name
-- 06/21/2017 Sachin b Fix the Prior WO Sorting Issue Remove temp table #TEMP1 and update soring logic
-- 01/04/2018 Sachin B Fix the Prior WC Grid Filter Issue add space between and RowNumber
-- 09/15/2020 Sachin B Added WOStatus in the select statement
-- =============================================

CREATE PROCEDURE GetPriorWorkOderSummaryByDepartment  
 @wcName CHAR(10), 
 @StartRecord INT,
 @EndRecord INT, 
 @SortExpression CHAR(1000) = NULL,
 @Filter NVARCHAR(1000) = NULL

AS
DECLARE @sql NVARCHAR(MAX)

BEGIN
SET NOCOUNT ON;
 
IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP;

;WITH TempTable AS(
 SELECT number,dept_id,WONO,DUEOUTDT FROM DEPT_QTY WHERE DEPT_ID = @wcName
)
,PriorWorkOrderList AS(
	SELECT DISTINCT 
	  d.dueOutDT AS WcDueDate,
	  dbo.fRemoveLeadingZeros(w.WONO) AS Wono,
	  d.CURR_QTY AS 'WcQty',
	  CASE WHEN d.NUMBER<=2 THEN [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * w.BLDQTY ))/60)      
		   ELSE [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * d.CURR_QTY)+q.SETUPSEC)/60)
		   END AS 'TimeAlloc',
	  [dbo].[GetTimeInHoursAndMinByTimeInSeconds](q.SETUPSEC/60) AS 'SetupTime',
	  CASE WHEN d.NUMBER<=2 THEN [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * w.BLDQTY )+q.SETUPSEC )/60)      
		ELSE [dbo].[GetTimeInHoursAndMinByTimeInSeconds](((q.RUNTIMESEC * d.CURR_QTY)+q.SETUPSEC)/60)
		END AS 'TotalTime',
	  d.NUMBER,
	  -- 01/18/2017 Sachin b get Dept_Id from the DEPTS table to show previous WC name
	  dep.DEPT_ID AS 'WorkCenter',
	  --dep.DEPT_NAME AS 'WorkCenter',
	  c.CUSTNAME,
	  CASE COALESCE(NULLIF(inv.REVISION,''), '')
	  WHEN '' THEN  LTRIM(RTRIM(inv.PART_NO)) 
	  ELSE LTRIM(RTRIM(inv.PART_NO)) + '/' + inv.REVISION 
	  END AS PartNoWithRev,
	  inv.DESCRIPT AS 'Description',    
	  w.BLDQTY AS 'WoQty',
	  w.BALANCE AS 'WoQuantityBalance',
	  temp.WONO AS WONumber,
	  d.SCHED_STAT AS 'OPENCLOS',
	  --- 12/22/2016 Sachin b Add ITAR Column 
	  -- 09/15/2020 Sachin B Added WOStatus in the select statement
	  inv.ITAR,w.OPENCLOS AS WOStatus
	  FROM 
	  WOENTRY w 
	  LEFT OUTER JOIN DEPT_QTY d ON w.WONO = d.WONO
	  LEFT OUTER JOIN DEPTS dep ON dep.DEPT_ID = d.DEPT_ID
	  LEFT OUTER JOIN Inventor inv ON inv.UNIQ_KEY = w.UNIQ_KEY
	  LEFT OUTER JOIN QuotDept q ON q.UNIQNUMBER = d.DEPTKEY 
	  LEFT OUTER JOIN Customer c ON c.CUSTNO = w.CUSTNO
	  INNER JOIN TempTable temp ON temp.WONO = d.WONO
	  WHERE d.NUMBER = temp.NUMBER-1 and d.WONO =temp.WONO 
	  AND w.OPENCLOS<>'closed' AND w.OPENCLOS<>'cancel' AND d.CURR_QTY >0
)

--Because it need one select statement after the temp table creation 
SELECT * INTO #TEMP FROM PriorWorkOrderList t1 LEFT OUTER JOIN
(
	SELECT CONVERT(INT,min(allocatedQty/NULLIF(QTY, 0))) AS BuildQty,wono AS WonoNumber  FROM KAMAIN  GROUP BY wono
)b
ON b.WonoNumber = t1.WONumber

  -- 06/21/2017 Sachin b Fix the Prior WO Sorting Issue Remove temp table #TEMP1 and update soring logic
  IF @filter <> '' AND @sortExpression <> ''
  BEGIN
  -- 01/04/2018 Sachin B Fix the Prior WC Grid Filter Issue add space between and RowNumber
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
      SET @sql=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY RowNum ASC) AS RowNumber,*  from #TEMP )
	  select  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount from CETTemp  t  WHERE  '+@filter+' and
      RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''
   END
   ELSE
     BEGIN
      SET @sql=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY RowNum ASC) AS RowNumber,*  from #TEMP )
	  select  t.*,(SELECT COUNT(RowNumber) FROM CETTemp) AS TotalCount from CETTemp  t  WHERE 
   RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''
   END
   EXEC SP_EXECUTESQL @sql
END