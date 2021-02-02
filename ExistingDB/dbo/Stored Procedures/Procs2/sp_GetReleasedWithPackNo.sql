-- =============================================
-- Author:		Sachin s
-- Create date:	02-19-2016
-- Description:	get packing list released with pack number
--[dbo].sp_GetReleasedWithPackNo  '36', 0,50,'',''
--Modified : Sachin S-05-16-2016 : Change the order of columns as discussed in Call
--		   : Sachin S-05-16-2016 : Get the filtered list based on the column and fifty records at a time
--		   : Sachin S-05-16-2016 : Drop temp table
--		   : Sachin S-07-23-2019 : remove CUSTOMER.SLINKADD join and put the PLMAIN.LINKADD join customer linkAddress join, according to latest multiple billing shipping address change
--         : Nitesh B : 01/20/2020 : Remove fRemoveLeadingZeros to get all records in minimum time
-- =============================================
CREATE PROCEDURE [dbo].sp_GetReleasedWithPackNo 
 @packListNo AS NVARCHAR(10) = NULL,
 @startRecord INT,
 @endRecord INT, 
 @sortExpression NVARCHAR(1000) = NULL,
 @filter NVARCHAR(1000) = NULL
AS
DECLARE @SQL NVARCHAR(MAX)
BEGIN
;WITH packingList AS(
--Sachin S-05-16-2016 Change the order of columns as discussed in Call
	SELECT  DISTINCT
		CUSTOMER.CREDITOK Credit, 
		CUSTOMER.CUSTNAME Company, 
		--SUBSTRING(PLMAIN.SONO, PATINDEX('%[^0 ]%', PLMAIN.SONO + ' '), LEN(PLMAIN.SONO)) AS SalesOrderNumber,
		--dbo.fRemoveLeadingZeros(PLMAIN.SONO) AS SalesOrderNumber,
		PLMAIN.SONO AS SalesOrderNumber, -- Nitesh B : 01/20/2020 : Remove fRemoveLeadingZeros to get all records in minimum time
		-- Remove leading zeros
		--SUBSTRING(PLMAIN.PACKLISTNO, PATINDEX('%[^0 ]%', PLMAIN.PACKLISTNO+ ' '), LEN(PLMAIN.PACKLISTNO)) AS PackListNo,
		--dbo.fRemoveLeadingZeros(PLMAIN.PACKLISTNO) AS PackListNo,
		PLMAIN.PACKLISTNO AS PackListNo, -- Nitesh B : 01/20/2020 : Remove fRemoveLeadingZeros to get all records in minimum time
		SHIPBILL.CITY City,
		SHIPBILL.State,
		SHIPDATE DueDate, 
		(SELECT COUNT(*) AS ITEMS  FROM PLDETAIL WHERE PLDETAIL.PACKLISTNO  = PLMAIN.PACKLISTNO) AS Items,
		CASE  
		WHEN PLMAIN.SONO='' THEN 'Manual'     
		ELSE 'Sales Order'
		END as Type
FROM PLMAIN, CUSTOMER,SHIPBILL  
WHERE PLMAIN.CUSTNO = CUSTOMER.CUSTNO 
--Sachin -07-23-2019:remove CUSTOMER.SLINKADD join and put the PLMAIN.LINKADD join customer linkAddress join, according to latest multiple billing shipping address change
AND SHIPBILL.LINKADD  = PLMAIN.LINKADD 
AND NOT PRINT_INVO=1 
AND CHARINDEX(@packListNo ,UPPER(PACKLISTNO))>0 
AND PRINTED=1 
)
--Sachin S-05-16-2016:Get the filtered list based on the column and fifty records at a time
SELECT (SELECT ROW_NUMBER() OVER (ORDER BY PackListNo)) AS RowNum,*INTO #TEMP1 FROM packingList

IF @filter <> '' AND @sortExpression <> ''
  BEGIN
   SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+Convert(VARCHAR,@sortExpression)+') AS RowNumber,*  from #TEMP1 )
   SELECT  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount 
   FROM CETTemp  t  WHERE '+@filter+' AND
   RowNumber BETWEEN '+Convert(VARCHAR,@StartRecord)+' AND '+Convert(varchar,@EndRecord)--+' ORDER BY '+ @SortExpression+''
   END
  ELSE IF @filter = '' AND @sortExpression <> ''
  BEGIN
    SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+Convert(VARCHAR,@sortExpression)+') AS RowNumber,*  from #TEMP1 )
	SELECT  t.*,(SELECT COUNT(RowNumber) FROM CETTemp ) AS TotalCount FROM CETTemp  t  WHERE 
    RowNumber BETWEEN '+Convert(VARCHAR,@StartRecord)+' AND '+Convert(VARCHAR,@EndRecord)--+' ORDER BY '+ @sortExpression+''
	END
  ELSE IF @filter <> '' AND @sortExpression = ''
  BEGIN
      SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY RowNum ASC) AS RowNumber,*  from #TEMP1 )
	  SELECT  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount FROM CETTemp  t  WHERE  '+@filter+' AND
      RowNumber BETWEEN '+Convert(VARCHAR,@StartRecord)+' AND '+Convert(VARCHAR,@EndRecord)+''
   END
   ELSE
     BEGIN
      SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY RowNum ASC) AS RowNumber,*  from #TEMP1 )
	  SELECT  t.*,(SELECT COUNT(RowNumber) FROM CETTemp) AS TotalCount FROM CETTemp  t  WHERE 
   RowNumber BETWEEN '+Convert(VARCHAR,@StartRecord)+' AND '+Convert(VARCHAR,@EndRecord)+''
   END
   EXEC sp_executesql @SQL
--Sachin S-05-16-2016:Drop temp table
    DROP TABLE #TEMP1
   END