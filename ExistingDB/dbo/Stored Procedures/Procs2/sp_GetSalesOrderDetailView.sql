-- Author:Sachin s
-- Create date:	03-10-2016
-- Description:	Return Sales order Line items with Sorting and Filtering
 --[dbo].sp_GetSalesOrderDetailView '0000000037',0,50,'','' 
CREATE PROCEDURE [dbo].sp_GetSalesOrderDetailView
 @Sono AS char(10) = '',
 @StartRecord int,
 @EndRecord int, 
 @SortExpression nvarchar(1000) = null,
 @Filter nvarchar(1000) = null
AS
DECLARE @SQL nvarchar(max)
BEGIN
;WITH packingList as(SELECT Sodetail.*, ISNULL(Part_no,SPACE(25)) AS Part_no, ISNULL(Revision,SPACE(8)) AS Revision, 
	ISNULL(Part_Class,SPACE(8)) AS Part_Class, ISNULL(Part_Type,SPACE(8)) AS Part_Type, 
	ISNULL(Descript,Sodet_Desc) AS Descript, ISNULL(U_of_meas,SPACE(4)) AS U_of_meas, 
	ISNULL(Custno, SPACE(10)) AS Custno, ISNULL(Part_Sourc, SPACE(10)) AS Part_Sourc,
	ISNULL(SerialYes,0) AS SerialYes, ISNULL(SaleTypeid, SPACE(10)) AS SaleTypeid, 
	ISNULL(Make_Buy,0) AS Make_Buy, ISNULL(MinOrd,0) AS MinOrd, ISNULL(OrdMult,0) AS OrdMult ,
	Inventor.useipkey 
	FROM Sodetail LEFT OUTER JOIN Inventor 
	ON Sodetail.Uniq_key = Inventor.Uniq_key
	WHERE Sono = @Sono
	--ORDER BY Line_no
	),
temptable as(SELECT *  from	packingList )
SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from temptable 
IF @filter <> '' AND @sortExpression <> ''
  BEGIN
   SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE '+@filter+' and
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @SortExpression+''
   END
  ELSE IF @filter = '' AND @sortExpression <> ''
  BEGIN
    SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
    RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @sortExpression+''
	END
  ELSE IF @filter <> '' AND @sortExpression = ''
  BEGIN
      SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+' and
      RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
   END
   ELSE
     BEGIN
      SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
   END
   exec sp_executesql @SQL
   END