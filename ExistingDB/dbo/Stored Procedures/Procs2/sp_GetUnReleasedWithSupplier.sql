﻿-- Author:		Sachin s
-- Create date:	02-19-2016
-- Description:	get packing list unreleased with Customer
--Sachin S-05-16-2016 Change the order of columns as discussed in Call	
--Sachin S-05-16-2016:Get the filtered list based on the column and fifty records at a time
--Sachin S-05-16-2016:Drop temp table
--[dbo].sp_GetUnReleasedWithSupplier   'GAMMA GAMING GURUS',0 ,20,'',''

CREATE PROCEDURE [dbo].sp_GetUnReleasedWithSupplier 
	@supName AS nvarchar(20) = null,
	@startRecord int,
	@endRecord int, 
	@sortExpression nvarchar(1000) = null,
	@filter nvarchar(1000) = null
AS
DECLARE @SQL nvarchar(max)
BEGIN
;WITH packingList AS(
	SELECT DISTINCT
	--Sachin S-05-16-2016 Change the order of columns as discussed in Call	
		CUSTOMER.CREDITOK Credit, 
		CUSTOMER.CUSTNAME Company, 
		--SUBSTRING(PLMAIN.SONO, PATINDEX('%[^0 ]%', PLMAIN.SONO + ' '), LEN(PLMAIN.SONO)) AS SalesOrderNumber,
		dbo.fRemoveLeadingZeros(PLMAIN.SONO) AS SalesOrderNumber,
		-- Remove leading zeros
		--SUBSTRING(PLMAIN.PACKLISTNO, PATINDEX('%[^0 ]%', PLMAIN.PACKLISTNO+ ' '), LEN(PLMAIN.PACKLISTNO)) AS PackListNo,
		dbo.fRemoveLeadingZeros(PLMAIN.PACKLISTNO) AS PackListNo,
		SHIPBILL.CITY City,
		SHIPBILL.State,
		SHIPDATE DueDate, 
		(SELECT COUNT(*) AS ITEMS  from PLDETAIL where PLDETAIL.PACKLISTNO  = PLMAIN.PACKLISTNO) AS Items,
		CASE  
		WHEN PLMAIN.SONO='' THEN 'Manual'     
		ELSE 'Sales Order'
		END as Type

	FROM PLMAIN, CUSTOMER,SHIPBILL   
	WHERE PLMAIN.CUSTNO = CUSTOMER.CUSTNO
	AND SHIPBILL.LINKADD  = CUSTOMER.SLINKADD 
	 AND NOT PRINT_INVO=1 
	 AND CHARINDEX(@supName ,UPPER(CUSTNAME))>0
	 AND NOT PRINTED = 1
	 )	
	 --Sachin S-05-16-2016:Get the filtered list based on the column and fifty records at a time
SELECT (Select ROW_NUMBER() OVER (ORDER BY PackListNo)) AS RowNum,*INTO #TEMP1 from packingList

IF @filter <> '' AND @sortExpression <> ''
  BEGIN
   SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+Convert(varchar,@sortExpression)+') AS RowNumber,*  from #TEMP1 )
   select  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount 
   from CETTemp  t  WHERE '+@filter+' and
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)--+' ORDER BY '+ @SortExpression+''
   END
  ELSE IF @filter = '' AND @sortExpression <> ''
  BEGIN
    SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+Convert(varchar,@sortExpression)+') AS RowNumber,*  from #TEMP1 )
	select  t.*,(SELECT COUNT(RowNumber) FROM CETTemp ) AS TotalCount from CETTemp  t  WHERE 
    RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)--+' ORDER BY '+ @sortExpression+''
	END
  ELSE IF @filter <> '' AND @sortExpression = ''
  BEGIN
      SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY RowNum ASC) AS RowNumber,*  from #TEMP1 )
	  select  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount from CETTemp  t  WHERE  '+@filter+' and
      RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
   END
   ELSE
     BEGIN
      SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY RowNum ASC) AS RowNumber,*  from #TEMP1 )
	  select  t.*,(SELECT COUNT(RowNumber) FROM CETTemp) AS TotalCount from CETTemp  t  WHERE 
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
   END
   exec sp_executesql @SQL
   --Sachin S-05-16-2016:Drop temp table
    DROP TABLE #TEMP1
   END