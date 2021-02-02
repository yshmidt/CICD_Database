-- =============================================
-- Author:	Rajendra k
-- Create date: 01/25/2019
-- Description:	To Get Issued WONO details data  
-- GetComponantIssuedWOListByWono '0000000495,0000000496,0000000497,0000000498,0000000499,0000000549,0000000649','1','200','',''
-- =============================================
CREATE PROCEDURE GetComponantIssuedWOListByWono
 @woNo NVARCHAR(MAX),
 @startRecord int,
 @endRecord int, 
 @sortExpression char(1000) = NULL,
 @filter nvarchar(1000) = NULL
As

DECLARE @sql nvarchar(max)
BEGIN

SET NOCOUNT ON;  
 DECLARE @sqlQuery NVARCHAR(MAX); 
 SET @woNo = @woNo + ',';
 SET @sortExpression = CASE WHEN @sortExpression IS NULL OR @sortExpression = '' THEN 'wono' ELSE @sortExpression END 

 IF OBJECT_ID(N'tempdb..#TEMP') IS NOT NULL
     DROP TABLE #TEMP ;

 IF OBJECT_ID(N'tempdb..#woData') IS NOT NULL
     DROP TABLE #woData ;

IF OBJECT_ID(N'tempdb..#woList') IS NOT NULL
     DROP TABLE #woList ;


  CREATE TABLE #woList  
 (  
  RowNum INT Identity(1,1),  
  WONO CHAR(10),  
  WO VARCHAR(MAX)  
 )  
  
 --Get WONOList list from comma separeted string  
    ;WITH WONOList AS  
  (  
   SELECT SUBSTRING(@woNo,1,CHARINDEX(',',@woNo,1)-1) AS WONO, SUBSTRING(@woNo,CHARINDEX(',',@woNo,1)+1,LEN(@woNo)) AS WO   
   UNION ALL  
   SELECT SUBSTRING(A.WO,1,CHARINDEX(',',A.WO,1)-1)AS WONO, SUBSTRING(A.WO,charindex(',',A.WO,1)+1,LEN(A.WO))   
   FROM WONOList A WHERE LEN(a.WO)>=1  
        )   
  
  INSERT INTO #woList (WONO,WO)  
  SELECT WONO,WO FROM WONOList  
  
    --Declare variables  
    DECLARE @mfgrDefault NVARCHAR(MAX),@nonNettable BIT,@bomParent CHAR(10)  

;WITH AllopenWo AS (
      SELECT DISTINCT w.UNIQ_KEY,w.WONO,
	  CASE COALESCE(NULLIF(inv.REVISION,''), '')
		WHEN '' THEN  LTRIM(RTRIM(inv.PART_NO)) 
		ELSE LTRIM(RTRIM(inv.PART_NO)) + '/' + inv.REVISION 
		END as PartNoWithRev,
		inv.PART_CLASS + '/' + inv.PART_TYPE +'/'+ inv.DESCRIPT AS [Description],inv.ITAR
	   FROM  WOENTRY w 
	   INNER JOIN #woList wo ON w.WONO= wo.WONO
	   INNER JOIN Kamain km ON wo.WONO = km.WONO AND km.ACT_QTY > 0   
	   LEFT OUTER JOIN Inventor inv ON inv.UNIQ_KEY = w.UNIQ_KEY 
	   WHERE w.WONO= wo.WONO AND w.OPENCLOS<>'closed' AND w.OPENCLOS<>'cancel'
  )
  ,IssuedData AS (
	  SELECT DISTINCT t.UNIQ_KEY,dbo.fRemoveLeadingZeros(t.WONO) AS WONO,PartNoWithRev,[Description],ITAR 
	  FROM invt_isu isu
	  INNER JOIN AllopenWo t ON t.WONO =isu.WONO
	  WHERE isu.wono !=''
	  GROUP BY t.UNIQ_KEY,PartNoWithRev,[Description], w_key,expdate,lotcode,reference,ponum,t.wono,t.ITAR
	  HAVING SUM(QTYISU) > 0 
  )

  SELECT * INTO #TEMP FROM IssuedData ORDER BY Wono 

SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * FROM #TEMP',@filter,@sortExpression,'','',@startRecord,@endRecord))   
EXEC sp_executesql @sqlQuery 
END 