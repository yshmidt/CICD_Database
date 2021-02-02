-- =============================================
-- Author:	Sachin b
-- Create date: 01/09/2017
-- Description:	this procedure will be called from the SFT Tools Details by Department
-- GetToolsDetailsByDeptID '_1ZN0OV698','STAG'
-- 04/19/2017 Sachin B update TOOLDESCR as column name
-- 08/22/2017 Sachin B Add join with ToolsAndFixtures and get [Description] and CalibrationDate from there and Add Parameter @UniqNumber
-- =============================================
CREATE PROCEDURE [dbo].[GetToolsDetailsByDeptID] 
  @uniqKey char(10) = null,
  @deptId char(10) = null,
  @UniqNumber char(10) = null,
  @StartRecord INT =1,
  @EndRecord INT=10, 
  @SortExpression CHAR(1000) = null,
  @Filter NVARCHAR(1000) = null
AS
BEGIN
SET NoCount ON; 

DECLARE @SQL nvarchar(max);

IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP;

IF OBJECT_ID('dbo.#TEMP1', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP1;

-- 04/19/2017 Sachin B update TOOLDESCR as column name
-- 08/22/2017 Sachin B Add join with ToolsAndFixtures and get [Description] and CalibrationDate from there and Add Parameter @UniqNumber
SELECT TOOLID,UNIQ_KEY ,t.DEPT_ID,tools.[Description],tools.CalibrationDate,tools.ToolsAndFixtureId
INTO #TEMP 
FROM TOOLING t 
INNER JOIN ToolsAndFixtures tools  ON t.ToolsAndFixtureId = tools.ToolsAndFixtureId
WHERE  t.DEPT_ID= @deptId and t.UNIQ_KEY = @uniqKey and t.UNIQNUMBER = @UniqNumber

SELECT IDENTITY(INT,1,1) as RowNumber,*INTO #TEMP1 FROM #temp

	IF @filter <> '' AND @sortExpression <> ''
  BEGIN
   SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP1 WHERE '+@filter+') AS TotalCount from #TEMP1  t  WHERE '+@filter+' and
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @SortExpression+''
   END
  ELSE IF @filter = '' AND @sortExpression <> ''
  BEGIN
    SET @SQL=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP1 ) AS TotalCount from #TEMP1  t  WHERE 
    RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @sortExpression+''
	END
  ELSE IF @filter <> '' AND @sortExpression = ''
  BEGIN
      SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP1 WHERE '+@filter+') AS TotalCount from #TEMP1  t  WHERE  '+@filter+' and
      RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
   END
   ELSE
     BEGIN
      SET @SQL=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP1) AS TotalCount from #TEMP1  t  WHERE 
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
   END
   exec sp_executesql @SQL
END