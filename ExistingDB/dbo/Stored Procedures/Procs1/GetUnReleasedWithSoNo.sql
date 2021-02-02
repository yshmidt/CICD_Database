
-- Author: Sachin s
-- Create date:	02-19-2016
-- Description:	get packing list unreleased with sales order number
--[dbo].GetUnReleasedWithSoNo '',0,50,'','' 
--Sachin S-05-16-2016 Change the display order of columns as discussed in Call
CREATE PROCEDURE [dbo].GetUnReleasedWithSoNo
 @sono AS nvarchar(10) = null,
 @startRecord int,
 @endRecord int, 
 @sortExpression nvarchar(1000) = null,
 @filter nvarchar(1000) = null
AS
DECLARE @SQL nvarchar(max)
BEGIN
;WITH packingList as(
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
	FROM PLMAIN, CUSTOMER, SOMAIN ,SHIPBILL
	WHERE 
	PLMAIN.CUSTNO = CUSTOMER.CUSTNO
	AND SHIPBILL.LINKADD  = CUSTOMER.SLINKADD 
	--AND PLMAIN.SONO = SOMAIN.SONO
	--Sachin s-Added a condition for get released an
	AND ( PLMAIN.SONO ='' or PLMAIN.SONO <> '') 
	AND NOT SOMAIN.IS_RMA=1 AND NOT PRINT_INVO=1 
	AND CHARINDEX(@sono  ,UPPER(PLMAIN.SONO))>0 
	AND NOT PRINTED=1
),
temptable as(SELECT *  from	packingList )
SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from temptable 
IF @filter <> '' AND @sortExpression <> ''
  BEGIN
   SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE '+@filter+' and
   RowNumber BETWEEN '+Convert(varchar,@startRecord)+' AND '+Convert(varchar,@endRecord)+' ORDER BY '+ @sortExpression+''
   END
  ELSE IF @filter = '' AND @sortExpression <> ''
  BEGIN
    SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
    RowNumber BETWEEN '+Convert(varchar,@startRecord)+' AND '+Convert(varchar,@endRecord)+' ORDER BY '+ @sortExpression+''
	END
  ELSE IF @filter <> '' AND @sortExpression = ''
  BEGIN
      SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+' and
      RowNumber BETWEEN '+Convert(varchar,@startRecord)+' AND '+Convert(varchar,@endRecord)+''
   END
   ELSE
     BEGIN
      SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
   RowNumber BETWEEN '+Convert(varchar,@startRecord)+' AND '+Convert(varchar,@endRecord)+''
   END
   exec sp_executesql @SQL
   END