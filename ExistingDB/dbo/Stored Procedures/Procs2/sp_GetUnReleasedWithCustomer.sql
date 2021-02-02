-- Author:		Sachin s
-- Create date:	02-19-2016
-- Description:	get packing list unreleased with Customer
-- Modified : Sachin S-05-16-2016 Change the order of columns as discussed in Call
--			: Sachin S-05-16-2016:Get the filtered list based on the column and fifty records at a time
--			: Sachin S-05-16-2016:Drop temp table
--			: Satish B :01/18/18 : Removed selection of '*' and select count of INV_LINK from PLDETAIL
--			: Satish B :03/13/18 : Added the filter of PLDETAIL.SHIPPEDQTY>0 to get data in PL edit mode
--          : Nitesh B : 01/20/2020 : Remove fRemoveLeadingZeros to get all records in minimum time
--          : Nitesh B : 01/20/2020 : Change condition to get City and State from shipbill linked with plmain LINKADD
--[dbo].sp_GetUnReleasedWithCustomer   'BETA',0 ,20,'',''
-- ==========================================================================================
CREATE PROCEDURE [dbo].sp_GetUnReleasedWithCustomer 
	@custname AS nvarchar(20) = null,
	@startRecord int,
	@endRecord int, 
	@sortExpression nvarchar(1000) = null,
	@filter nvarchar(1000) = null
AS
DECLARE @SQL nvarchar(max)
BEGIN
;WITH packingList AS(
--Sachin S-05-16-2016 Change the order of columns as discussed in Call
	SELECT  DISTINCT
		CUSTOMER.CREDITOK Credit, 
		CUSTOMER.CUSTNAME Company, 
		--SUBSTRING(PLMAIN.SONO, PATINDEX('%[^0 ]%', PLMAIN.SONO + ' '), LEN(PLMAIN.SONO)) AS SalesOrderNumber,
		--dbo.fRemoveLeadingZeros(PLMAIN.SONO) AS SalesOrderNumber,
		PLMAIN.SONO AS SalesOrderNumber,   -- Nitesh B : 01/20/2020 : Remove fRemoveLeadingZeros to get all records in minimum time
		-- Remove leading zeros
		--SUBSTRING(PLMAIN.PACKLISTNO, PATINDEX('%[^0 ]%', PLMAIN.PACKLISTNO+ ' '), LEN(PLMAIN.PACKLISTNO)) AS PackListNo,
		--dbo.fRemoveLeadingZeros(PLMAIN.PACKLISTNO) AS PackListNo,
		PLMAIN.PACKLISTNO AS PackListNo,  -- Nitesh B : 01/20/2020 : Remove fRemoveLeadingZeros to get all records in minimum time
		SHIPBILL.CITY City,
		SHIPBILL.State,
		SHIPDATE DueDate, 
		--Satish B :01/18/18 : Removed selection of '*' and select count of INV_LINK from PLDETAIL
		--(SELECT COUNT(*) AS ITEMS  from PLDETAIL where PLDETAIL.PACKLISTNO  = PLMAIN.PACKLISTNO) AS Items,
		--Satish B :03/13/18 : Added the filter of PLDETAIL.SHIPPEDQTY>0 to get data in PL edit mode
		(SELECT COUNT(INV_LINK) AS ITEMS  from PLDETAIL where PLDETAIL.PACKLISTNO  = PLMAIN.PACKLISTNO AND PLDETAIL.SHIPPEDQTY>0) AS Items,
		CASE  
		WHEN PLMAIN.SONO='' THEN 'Manual'     
		ELSE 'Sales Order'
		END as Type
	FROM PLMAIN, CUSTOMER,SHIPBILL  
	WHERE PLMAIN.CUSTNO = CUSTOMER.CUSTNO
	AND SHIPBILL.LINKADD  = PLMAIN.LINKADD  -- Nitesh B : 01/20/2020 : Change condition to get City and State from shipbill linked with plmain LINKADD
	 AND NOT PRINT_INVO=1 
	 AND CHARINDEX(@custname ,UPPER(CUSTNAME))>0
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