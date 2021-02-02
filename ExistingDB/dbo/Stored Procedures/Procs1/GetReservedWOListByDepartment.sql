-- =============================================
-- Author:	Sachinb
-- Create date: 11/25/2016
-- Description:	this procedure will be called from the SF module and Pull the working work orders for which componant is Reserved
-- GetReservedWOListByDepartment 'WAVE','541',1,200,'WONO asc',''
-- 12/22/2016 Sachin B Combind PART_CLASS ,PART_TYPE,DESCRIPT as Description with /
-- 07/04/2017 Sachin B Add Order by Wono
-- 07/25/2017 Sachin B update condition for getting WOENTRY join with KAMAIN table and remove unused temp tables
-- 10/23/2017 Sachin B Apply Coding Standard for SP
-- 10/30/2017 Sachin B Add temp table #woData and implement logic for filter grid by wono and appy Code review Comments
-- 10/30/2017 Sachin B Get All those Workorder which having some allocated Qty although they are closed or cancel
-- 11/09/2017 Sachin B Add ITAR Column in reserved Work Order Grid in part Reconciliation tab
-- =============================================

CREATE PROCEDURE GetReservedWOListByDepartment 
 @wcName CHAR(10), 
 @woNo CHAR(10),
 @startRecord INT,
 @endRecord INT, 
 @sortExpression CHAR(1000) = NULL,
 @filter NVARCHAR(1000) = NULL
As

DECLARE @sql NVARCHAR(MAX)
BEGIN

SET NOCOUNT ON; 

IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP;

IF OBJECT_ID('dbo.#woData', 'U') IS NOT NULL      
DROP TABLE dbo.#woData;

-- 10/30/2017 Sachin B Add temp table #woData and implement logic for filter grid by wono and appy Code review Comments
CREATE TABLE #woData (
    RowNumber INT,
    UniqKey CHAR(10),
	WONO CHAR(10),
	PartNoWithRev CHAR(45),
	[Description] CHAR(65),
	ITAR bit
  )

-- 07/25/2017 Sachin B update condition for getting WOENTRY join with KAMAIN table and remove unused temp tables
;WITH AllopenWo AS (
SELECT DISTINCT 
	  w.UNIQ_KEY AS UniqKey, 
	  dbo.fRemoveLeadingZeros(w.WONO) AS Wono,
	  CASE COALESCE(NULLIF(inv.REVISION,''), '')
		WHEN '' THEN  LTRIM(RTRIM(inv.PART_NO)) 
		ELSE LTRIM(RTRIM(inv.PART_NO)) + '/' + inv.REVISION 
		END AS PartNoWithRev,
		-- 12/22/2016 Sachin B Combind PART_CLASS ,PART_TYPE,DESCRIPT as Description
		-- 11/09/2017 Sachin B Add ITAR Column in reserved Work Order Grid in part Reconciliation tab
		inv.PART_CLASS + '/' + inv.PART_TYPE +'/'+ inv.DESCRIPT AS [Description],inv.ITAR
	   FROM  WOENTRY w 
	   LEFT OUTER JOIN KAMAIN k ON w.WONO = k.WONO
	   INNER JOIN Inventor inv ON inv.UNIQ_KEY = w.UNIQ_KEY 
	   -- 10/30/2017 Sachin B Get All those Workorder which having some allocated Qty although they are closed or cancel
       WHERE k.DEPT_ID = @wcName AND k.allocatedQty >0 --AND w.OPENCLOS<>'closed' AND w.OPENCLOS<>'cancel'
  )

  -- 07/04/2017 Sachin B Add Order by Wono
  SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM AllopenWo ORDER BY Wono

  -- 10/30/2017 Sachin B Add temp table #woData and implement logic for filter grid by wono and appy Code review Comments
  -- 11/09/2017 Sachin B Add ITAR Column in reserved Work Order Grid in part Reconciliation tab
  SET @woNo =dbo.fRemoveLeadingZeros(@woNo)

   IF(@woNo!='')
	   BEGIN
		INSERT INTO #woData(RowNumber,UniqKey,WONO,PartNoWithRev,[Description],ITAR)
		SELECT RowNumber,UniqKey,WONO,PartNoWithRev,[Description],ITAR FROM #TEMP  WHERE WONO= @woNo --LIKE '%'+@woNo+'%'
	   END
   ELSE
	   BEGIN
	    INSERT INTO #woData(RowNumber,UniqKey,WONO,PartNoWithRev,[Description],ITAR)
		SELECT RowNumber,UniqKey,WONO,PartNoWithRev,[Description],ITAR FROM #TEMP
	   END

IF @filter <> '' AND @sortExpression <> ''
  BEGIN
     SET @sql=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #woData WHERE '+@filter+') AS TotalCount from #woData  t  WHERE '+@filter+' and
     RowNumber BETWEEN '+CONVERT(VARCHAR,@startRecord)+' AND '+CONVERT(VARCHAR,@endRecord)+' ORDER BY '+ @SortExpression+''
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
   EXEC SP_EXECUTESQL @sql
END
