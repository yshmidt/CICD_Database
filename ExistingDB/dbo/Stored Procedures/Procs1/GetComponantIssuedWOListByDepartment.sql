-- =============================================
-- Author:	Sachin B
-- Create date: 12/01/2016
-- Description:	this procedure will be called from the SF module and Pull the working work orders for which componant is issued
-- GetComponantIssuedWOListByDepartment 'WAVE','149',1,200,'WONO asc',''
-- 12/07/2016 Sachin B removed Unused join
-- 12/09/2016 Sachin B Add column Parttype and PartClass and remove column Buildable and WO Balance
-- 12/22/2016 Sachin B Combind PART_CLASS ,PART_TYPE,DESCRIPT as Description with /
-- 04/05/2017 Sachin B remove Extra temp table and use function fRemoveLeadingZeros at last
-- 07/04/2017 Sachin B Add Order by Wono
-- 10/30/2017 Sachin B Add temp table #woData and implement logic for filter grid by wono and appy Code review Comments
-- 04/09/2018 Sachin B Remove and condition d.CURR_QTY >0 for the geeting those WO in Issue Adjustment Whom current WC is Zero
-- 05/05/2018 Sachin B Fix WO Serachin Issue on Issue Adjustment and History Remove Identity and use row_number() function in select
-- GetComponantIssuedWOListByDepartment 'STAG','',1,4000,'',''
-- =============================================

CREATE PROCEDURE GetComponantIssuedWOListByDepartment 
 @wcName char(10), 
 @woNo char(10),
 @startRecord int,
 @endRecord int, 
 @sortExpression char(1000) = NULL,
 @filter nvarchar(1000) = NULL
As

DECLARE @sql nvarchar(max)
BEGIN

SET NOCOUNT ON; 

IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP;

IF OBJECT_ID('dbo.#woData', 'U') IS NOT NULL      
DROP TABLE dbo.#woData;

-- 10/30/2017 Sachin B Add temp table #woData and implement logic for filter grid by wono and appy Code review Comments
CREATE TABLE #woData (
    RowNumber INT,
    UNIQ_KEY CHAR(10),
	WONO CHAR(10),
	PartNoWithRev CHAR(45),
	[Description] CHAR(65),
	ITAR bit
  )

-- 12/09/2016 Sachin B Add column Parttype and PartClass and remove column Buildable and WO Balance
;WITH AllopenWo AS (
      SELECT DISTINCT w.UNIQ_KEY,w.WONO,
	  CASE COALESCE(NULLIF(inv.REVISION,''), '')
		WHEN '' THEN  LTRIM(RTRIM(inv.PART_NO)) 
		ELSE LTRIM(RTRIM(inv.PART_NO)) + '/' + inv.REVISION 
		END as PartNoWithRev,
		-- 12/22/2016 Sachin B Combind PART_CLASS ,PART_TYPE,DESCRIPT as Description
		inv.PART_CLASS + '/' + inv.PART_TYPE +'/'+ inv.DESCRIPT AS [Description],inv.ITAR
	   FROM  WOENTRY w 
	   -- 12/07/2016 Sachin B removed Unused join
	   LEFT OUTER JOIN DEPT_QTY d ON w.WONO = d.WONO
	   LEFT OUTER JOIN Inventor inv ON inv.UNIQ_KEY = w.UNIQ_KEY 
	   -- 04/09/2018 Sachin B Remove and condition d.CURR_QTY >0 for the geeting those WO in Issue Adjustment Whom current WC is Zero
	   WHERE d.DEPT_ID = @wcName AND w.OPENCLOS<>'closed' AND w.OPENCLOS<>'cancel' --AND d.CURR_QTY >0
  )
  -- 04/05/2017 Sachin B remove Extra temp table and use function fRemoveLeadingZeros at last
  ,IssuedData AS (
	  SELECT DISTINCT t.UNIQ_KEY,dbo.fRemoveLeadingZeros(t.WONO) AS WONO,PartNoWithRev,[Description],ITAR 
	  FROM invt_isu isu
	  INNER JOIN AllopenWo t ON t.WONO =isu.WONO
	  WHERE isu.wono !=''
	  GROUP BY t.UNIQ_KEY,PartNoWithRev,[Description], w_key,expdate,lotcode,reference,ponum,t.wono,t.ITAR
	  HAVING SUM(QTYISU) >0 
  )
  -- 07/04/2017 Sachin B Add Order by Wono
  -- 05/05/2018 Sachin B Fix WO Serachin Issue on Issue Adjustment and History Remove Identity and use row_number() function in select
  SELECT *INTO #TEMP FROM IssuedData ORDER BY Wono  

  -- 10/30/2017 Sachin B Add temp table #woData and implement logic for filter grid by wono and appy Code review Comments
  SET @woNo =dbo.fRemoveLeadingZeros(@woNo)

   IF(@woNo!='')
	   BEGIN    
		INSERT INTO #woData(RowNumber,UNIQ_KEY,WONO,PartNoWithRev,[Description],ITAR)
		-- 05/05/2018 Sachin B Fix WO Serachin Issue on Issue Adjustment and History Remove Identity and use row_number() function in select
		SELECT row_number() OVER (ORDER BY WONO) RowNumber,UNIQ_KEY,WONO,PartNoWithRev,[Description],ITAR FROM #TEMP WHERE WONO= @woNo --LIKE '%'+@woNo+'%'
	   END
   ELSE
	   BEGIN
	    INSERT INTO #woData(RowNumber,UNIQ_KEY,WONO,PartNoWithRev,[Description],ITAR)
		-- 05/05/2018 Sachin B Fix WO Serachin Issue on Issue Adjustment and History Remove Identity and use row_number() function in select
		SELECT row_number() OVER (ORDER BY WONO) RowNumber,UNIQ_KEY,WONO,PartNoWithRev,[Description],ITAR FROM #TEMP
	   END
  

IF @filter <> '' AND @sortExpression <> ''
  BEGIN
   SET @sql=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #woData WHERE '+@filter+') AS TotalCount from #woData  t  WHERE '+@filter+' and
   RowNumber BETWEEN '+CONVERT(VARCHAR,@startRecord)+' AND '+CONVERT(VARCHAR,@endRecord)+' ORDER BY '+ @sortExpression+''
  END
ELSE IF @filter = '' AND @sortExpression <> ''
   BEGIN
    SET @sql=N'select  t.*,(SELECT COUNT(RowNumber) FROM #woData ) AS TotalCount from #woData  t  WHERE 
RowNumber BETWEEN '+CONVERT(VARCHAR,@startRecord)+' AND '+CONVERT(VARCHAR,@endRecord)+' ORDER BY '+ @sortExpression+''
   END
ELSE IF @filter <> '' AND @sortExpression = ''
   BEGIN
      SET @sql=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #woData WHERE '+@filter+') AS TotalCount from #woData  t  WHERE  '+@filter+' and
      RowNumber BETWEEN '+CONVERT(VARCHAR,@startRecord)+' AND '+CONVERT(VARCHAR,@endRecord)+''
   END
ELSE
   BEGIN
      SET @sql=N'select  t.*,(SELECT COUNT(RowNumber) FROM #woData) AS TotalCount from #woData  t  WHERE 
      RowNumber BETWEEN '+CONVERT(VARCHAR,@startRecord)+' AND '+CONVERT(VARCHAR,@endRecord)+''
   END
   EXEC SP_EXECUTESQL @SQL
END