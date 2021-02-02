-- =============================================
-- Author:		<Author,Sachin Shevale>
-- Create date: <Create Date, 05/26/2016,>
-- Description:	<Description,Sales order shipping history>
-- Sachin s- 08-29-2016 get the all packing list data with packing list number and  manual items
-- Modified : Satish B  07-18-2017 : Comment part_class and part_type to combine them into single column value
-- Modified : Satish B  07-18-2017 : Combine part_class and part_type and descript to single column ClassTypeDescript
-- Modified : Satish B  07-18-2017 : Comment descript and combine it with part_class and part_type
-- Modified : Satish B  07-20-2017 : Removed leading zero from packiglist number
-- Modified : 10/24/2017 Satish B : Added inner join of PLMAIN to get SHIPDATE
-- Modified : 10/24/2017 Satish B : Get records default order br SHIPDATE desc
-- Modified : Satish B  10-24-2017 : Select SHIPDATE from PLMAIN
-- GetSalesOrderShippingHistory  '0000000542' ,'','',0,5000,'',''
-- =============================================
CREATE PROCEDURE GetSalesOrderShippingHistory 
	-- Add the parameters for the stored procedure here
@packlistno AS nvarchar(10) = null,
@uniqKey AS nvarchar(10) = null,
@slinkAdd AS nvarchar(10) = null,
@startRecord int,
@endRecord int, 
@sortExpression nvarchar(1000) = null,
@filter nvarchar(1000) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	
	DECLARE @SQL nvarchar(max)
   ;WITH packingList AS(
	SELECT  DISTINCT
	--SODETaIL.Line_no,
	ISNULL(dbo.fRemoveLeadingZeros(SODETaIL.Line_no),dbo.fRemoveLeadingZeros(pldetail.UNIQUELN)) AS Line_no
	--Modified : Satish B  07-18-2017 : Comment part_class and part_type to combine them into single column value
	--ISNULL(Inventor.part_class,Space(10)) part_class, 
	--ISNULL(Inventor.part_type,Space(10)) part_type, 
	,ISNULL(Inventor.part_no,Space(10)) AS part_no
	
	--Modified : Satish B  07-18-2017 : Combine part_class and part_type and descript to single column ClassTypeDescript
	,inventor.Part_Class +'/'+' '+ inventor.Part_Type +'/'+' '+ inventor.Descript  AS ClassTypeDescript

	,ISNULL(Inventor.Revision,pldetail.SHIPPEDREV) AS Revision,
	--Modified : Satish B  07-18-2017 : Comment descript and combine it with part_class and part_type
	--ISNULL(Inventor.descript,pldetail.cDESCR) AS descript,
	--Modified : Satish B  07-20-2017 : Removed leading zero from packiglist number
	dbo.fRemoveLeadingZeros(pldetail.packListno) AS packListno,
	pldetail.ShippedQty SHIPPEDQTY,
  --Modified : Satish B  10-24-2017 : Select SHIPDATE from PLMAIN
	p.SHIPDATE AS PLShipDate
	FROM PLDETAIL pldetail 
	LEFT OUTER JOIN SODETAIL sodetail  On pldetail.UNIQUELN=sodetail.UNIQUELN
	LEFT OUTER JOin Inventor inventor ON inventor.UNIQ_KEY=sodetail.UNIQ_KEY 
	--10/24/2017 Satish B : Added inner join of PLMAIN to get SHIPDATE
	INNER JOIN PLMAIN p ON p.PACKLISTNO=pldetail.PACKLISTNO
	--Inner JOin PLMAIN plmain ON plmain.PACKLISTNO = pldetail.PACKLISTNO and plmain.SONO=sodetail.SONO
	WHERE 
	--(pldetail.PACKLISTNO is null or pldetail.PACKLISTNO=@packlistno)
		pldetail.UNIQUELN IN (
		SELECT UNIQUELN FROM pldetail WHERE pldetail.PACKLISTNO is null or pldetail.PACKLISTNO=@packlistno)
			)
						
--SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from packingList 
--Sachin s- 08-29-2016 get the all packing list data with packing list number and  manual items
SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from packingList  where (Line_no not like '%*%') or (packlistno =@packlistno and line_no like '*%') 
--10/24/2017 Satish B : Get records default order br SHIPDATE desc
ORDER BY packingList.PLShipDate DESC

IF @filter <> '' AND @sortExpression <> ''
  BEGIN
   SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE '+@filter+' and
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @SortExpression+''
   END
  ELSE IF @filter = '' AND @sortExpression <> ''
  BEGIN
    SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
    RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @sortExpression+''
	END
  ELSE IF @filter <> '' AND @sortExpression = ''
  BEGIN
      SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE  '+@filter+' and
      RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
   END
   ELSE
     BEGIN
      SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
   END
   exec sp_executesql @SQL
   END