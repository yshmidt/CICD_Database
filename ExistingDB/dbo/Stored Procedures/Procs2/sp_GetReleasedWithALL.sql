-- =============================================  
-- Author:  Sachin s  
-- Create date: 02-19-2016  
-- Description: get packing list with released and All combination  
-- Modified : Sachin S-05-16-2016 Change the order of columns as discussed in Call  
--          : Sachin S-05-28-2016 Get unacknowledge false sales order is no need to display and Remove leading zeros use dunction  
--          : Sachin S-05-16-2016:Get the filtered list based on the column and fifty records at a time  
--          : Sachin S-05-16-2016:Drop temp table  
--          : Satish B 07-18-2017 Remove filter of SOMAIN.SONO=PLMAIN.SONO to get printed manual parts  
--          : Satish B : 03/28/2018 : Select packing list number with leading zeros for sorting  
--          : Shrikant B :  07/08/2019 : Added IsSFBL column for getting issfbl for sfbl warehouse  
--          : Shrikant B  : 07/08/2019 : Added sodetail table join for getting issfbl column for sfbl warehouse   
--          : Sachin B : 07/24/2019 : remove customer SLINKADD join and added with plmain linkAddd to fix the issue of packing list created with latest customer in web with its address not displayed due to latest customer address structure change  
--          : Nitesh B : 07/30/2019 : Remove fRemoveLeadingZeros to get all records in minimum time    
--          : Nitesh B : 01/20/2020 : Change condition to get City and State from shipbill linked with plmain LINKADD  
--   : Sachin B : 06/25/2020 : Fix the Issue manual packing list are not displaying Remove Join from SOdetail Table  
-- [dbo].sp_GetReleasedWithALL    0,150,'Type asc',''   
-- =============================================  
CREATE PROCEDURE [dbo].sp_GetReleasedWithALL   
@startRecord INT,  
@endRecord INT,   
@sortExpression NVARCHAR(1000) = null,  
@filter NVARCHAR(1000) = null  
AS  
DECLARE @SQL NVARCHAR(max)  
BEGIN  
;WITH packingList AS(   
 --Sachin S-05-16-2016 Change the order of columns as discussed in Call  
 SELECT  DISTINCT  
  CUSTOMER.CREDITOK Credit,   
  CUSTOMER.CUSTNAME Company,   
  --SUBSTRING(PLMAIN.SONO, PATINDEX('%[^0 ]%', PLMAIN.SONO + ' '), LEN(PLMAIN.SONO)) AS SalesOrderNumber,  
  --dbo.fRemoveLeadingZeros(PLMAIN.SONO) AS SalesOrderNumber,      
  PLMAIN.SONO AS SalesOrderNumber, -- Nitesh B : 7/30/2019 : Remove fRemoveLeadingZeros to get all records in minimum time    
  -- Remove leading zeros  
  --SUBSTRING(PLMAIN.PACKLISTNO, PATINDEX('%[^0 ]%', PLMAIN.PACKLISTNO+ ' '), LEN(PLMAIN.PACKLISTNO)) AS PackListNo,  
  --dbo.fRemoveLeadingZeros(PLMAIN.PACKLISTNO) AS PackListNo,     
  PLMAIN.PACKLISTNO AS PackListNo, -- Nitesh B : 7/30/2019 : Remove fRemoveLeadingZeros to get all records in minimum time    
  --Satish B : 03/28/2018 : Select packing list number with leading zeros for sorting  
  PLMAIN.PACKLISTNO AS PlNo,  
  SHIPBILL.CITY City,  
  SHIPBILL.State,  
  SHIPDATE DueDate,   
  (SELECT COUNT(*) AS ITEMS  FROM PLDETAIL WHERE PLDETAIL.PACKLISTNO  = PLMAIN.PACKLISTNO) AS Items,  
  CASE    
  WHEN PLMAIN.SONO='' THEN 'Manual'       
  ELSE 'Sales Order'  
  END AS Type
  --,   
  --: Shrikant B :  07/08/2019 : Added IsSFBL column for getting issfbl for sfbl warehouse 
  --   : Sachin B : 06/25/2020 : Fix the Issue manual packing list are not displaying Remove Join from SOdetail Table 
  --isSFBL AS IsSFBL  
 FROM PLMAIN, CUSTOMER,SHIPBILL ,SOMAIN, SODETAIL   
 WHERE PLMAIN.CUSTNO = CUSTOMER.CUSTNO   
--          : Sachin B : 07/24/2019 : remove customer SLINKADD join and added with plmain linkAddd to fix the issue of packing list created with latest customer in web with its address not displayed due to latest customer address structure change  
 --AND SHIPBILL.LINKADD  = PLMAIN.LINKADD  
  AND SHIPBILL.LINKADD  = PLMAIN.LINKADD --Nitesh B : 01/20/2020 : Change condition to get City and State from shipbill linked with plmain LINKADD    
 --: Shrikant B  : 07/08/2019 : Added sodetail table join for getting issfbl column for sfbl warehouse  
 --   : Sachin B : 06/25/2020 : Fix the Issue manual packing list are not displaying Remove Join from SOdetail Table 
 --AND SODETAIL.SONO = PLMAIN.SONO  
 --Satish B 07-18-2017 Remove filter of SOMAIN.SONO=PLMAIN.SONO to get printed manual parts  
 --AND SOMAIN.SONO=PLMAIN.SONO   
 AND NOT PRINT_INVO=1 AND PRINTED=1 AND SOMAIN.POACK = 1  
 )  
--Sachin S-05-16-2016:Get the filtered list based on the column and fifty records at a time  
SELECT (SELECT ROW_NUMBER() OVER (ORDER BY PackListNo)) AS RowNum,*INTO #TEMP1 FROM packingList  
  
IF @filter <> '' AND @sortExpression <> ''  
  BEGIN  
   SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+Convert(VARCHAR,@sortExpression)+') AS RowNumber,*  from #TEMP1 )  
   select  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount   
   from CETTemp  t  WHERE '+@filter+' and  
   RowNumber BETWEEN '+Convert(VARCHAR,@StartRecord)+' AND '+Convert(VARCHAR,@EndRecord)--+' ORDER BY '+ @SortExpression+''  
   END  
  ELSE IF @filter = '' AND @sortExpression <> ''  
  BEGIN  
    SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+Convert(VARCHAR,@sortExpression)+') AS RowNumber,*  from #TEMP1 )  
 select  t.*,(SELECT COUNT(RowNumber) FROM CETTemp ) AS TotalCount from CETTemp  t  WHERE   
    RowNumber BETWEEN '+Convert(VARCHAR,@StartRecord)+' AND '+Convert(VARCHAR,@EndRecord)--+' ORDER BY '+ @sortExpression+''  
 END  
  ELSE IF @filter <> '' AND @sortExpression = ''  
  BEGIN  
      SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY RowNum ASC) AS RowNumber,*  from #TEMP1 )  
   select  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount from CETTemp  t  WHERE  '+@filter+' and  
      RowNumber BETWEEN '+Convert(VARCHAR,@StartRecord)+' AND '+Convert(VARCHAR,@EndRecord)+''  
   END  
   ELSE  
     BEGIN  
      SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY RowNum ASC) AS RowNumber,*  from #TEMP1 )  
   select  t.*,(SELECT COUNT(RowNumber) FROM CETTemp) AS TotalCount from CETTemp  t  WHERE   
   RowNumber BETWEEN '+Convert(VARCHAR,@StartRecord)+' AND '+Convert(VARCHAR,@EndRecord)+''  
   END  
   EXEC sp_executesql @SQL  
--Sachin S-05-16-2016:Drop temp table  
    DROP TABLE #TEMP1  
   END