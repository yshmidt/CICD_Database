-- Author:  Sachin s  
-- Create date: 02-19-2016  
-- Description: Get all packing list with unreleased status  
-- Modified : Sachin S-05-16-2016 Change the order of columns as discussed in Call  
--   : Sachin S-05-16-2016:Get the filtered list based on the column and fifty records at a time  
--   : Sachin S-05-16-2016:Drop temp table  
--   : Satish B : 09/18/2017 : Uncomment +' ORDER BY '+ @sortExpression+''  
--   : Satish B : 01/18/18 : Removed selection of '*' and select count of INV_LINK from PLDETAIL  
--   : Satish B : 03/13/18 : Added the filter of PLDETAIL.SHIPPEDQTY>0 to get data in PL edit mode  
--   : Satish B : 03/28/2018 : Select packing list number with leading zeros for sorting  
--   : Shrikant B : 07/08/2019 : Added table SODETAIL for getting sfbl warehouse against sales order  
--   : Shrikant B : 07/08/2019 : Added join SODETAIL with plmain for getting sfbl warehouse against sales order  
--   : Shrikant B : 07/08/2019 : Added join Column isSFBL to show the sfbl warehouse against sales order  
--   : Sachin B : 07/24/2019 : remove customer SLINKADD join and added with plmain linkAddd to fix the issue of packing list created with latest customer in web with its address not displayed due to latest customer address structure change  
--   : Nitesh B : 7/30/2019 : Remove fRemoveLeadingZeros to get all records in minimum time    
--   : Nitesh B : 01/20/2020 : Change condition to get City and State from shipbill linked with plmain LINKADD   
--   : Sachin B : 06/25/2020 : Fix the Issue manual packing list are not displaying Remove Join from SOdetail Table
-- [dbo].sp_GetUnReleasedWithALL 0,50,'Type asc',''  
-- =============================================  
  
CREATE PROCEDURE [dbo].sp_GetUnReleasedWithALL  
 @startRecord INT,  
 @endRecord INT,   
 @sortExpression NVARCHAR(1000) = null,  
 @filter NVARCHAR(1000) = 'PackListNo DESC'  
AS  
DECLARE @SQL NVARCHAR(MAX)  
BEGIN  
 SET NOCOUNT ON;     
;WITH packingList as(  
--Sachin S-05-16-2016 Change the order of columns as discussed in Call  
 SELECT  DISTINCT  
  CUSTOMER.CREDITOK Credit,   
  CUSTOMER.CUSTNAME Company,   
  --SUBSTRING(PLMAIN.SONO, PATINDEX('%[^0 ]%', PLMAIN.SONO + ' '), LEN(PLMAIN.SONO)) AS SalesOrderNumber,  
  --dbo.fRemoveLeadingZeros(PLMAIN.SONO) AS SalesOrderNumber,    
  PLMAIN.SONO AS SalesOrderNumber,   -- Nitesh B : 7/30/2019 : Remove fRemoveLeadingZeros to get all records in minimum time    
  -- Remove leading zeros  
  --SUBSTRING(PLMAIN.PACKLISTNO, PATINDEX('%[^0 ]%', PLMAIN.PACKLISTNO+ ' '), LEN(PLMAIN.PACKLISTNO)) AS PackListNo,  
  --dbo.fRemoveLeadingZeros(PLMAIN.PACKLISTNO) AS PackListNo,     
  PLMAIN.PACKLISTNO AS PackListNo,  -- Nitesh B : 7/30/2019 : Remove fRemoveLeadingZeros to get all records in minimum time    
  --03/28/2018 : Satish B : Select packing list number with leading zeros for sorting  
  PLMAIN.PACKLISTNO AS PlNo,  
  SHIPBILL.CITY City,  
  SHIPBILL.State,  
  SHIPDATE DueDate,   
  --Satish B :01/18/18 : Removed selection of '*' and select count of INV_LINK from PLDETAIL  
  --(SELECT COUNT(*) AS ITEMS  from PLDETAIL where PLDETAIL.PACKLISTNO  = PLMAIN.PACKLISTNO) AS Items,  
  --Satish B :03/13/18 : Added the filter of PLDETAIL.SHIPPEDQTY>0 to get data in PL edit mode  
  (SELECT COUNT(INV_LINK) AS ITEMS  FROM PLDETAIL WHERE PLDETAIL.PACKLISTNO  = PLMAIN.PACKLISTNO AND PLDETAIL.SHIPPEDQTY>0) AS Items,  
  CASE    
  WHEN plmain.SONO='' THEN 'Manual'       
  ELSE 'Sales Order'  
  END as Type  
--   : Shrikant B : 07/08/2019 : Added join Column isSFBL to show the sfbl warehouse against sales order
--   : Sachin B : 06/25/2020 : Fix the Issue manual packing list are not displaying Remove Join from SOdetail Table  
  --,SODETAIL.isSFBL AS IsSFBL   
 FROM PLMAIN plmain, SHIPBILL,CUSTOMER,  
--   : Shrikant B : 07/08/2019 : Added table SODETAIL for getting sfbl warehouse against sales order  
  SODETAIL  
 --join SODETAIL sodet ON plmain.SONO = sodet.SONO  
WHERE  
   PLMAIN.CUSTNO = CUSTOMER.CUSTNO   
   --          : Sachin B : 07/24/2019 : remove customer SLINKADD join and added with plmain linkAddd to fix the issue of packing list created with latest customer in web with its address not displayed due to latest customer address structure change  
  -- AND SHIPBILL.LINKADD  = plmain.LINKADD   
   AND SHIPBILL.LINKADD  = PLMAIN.LINKADD --Nitesh B : 01/20/2020 : Change condition to get City and State from shipbill linked with plmain LINKADD    
--   : Shrikant B : 07/08/2019 : Added join SODETAIL with plmain for getting sfbl warehouse against sales order 
--   : Sachin B : 06/25/2020 : Fix the Issue manual packing list are not displaying Remove Join from SOdetail Table 
 -- AND plmain.SONO = SODETAIL.SONO  
  AND NOT PRINT_INVO=1   
  AND NOT PRINTED=1    
)  
--Sachin S-05-16-2016:Get the filtered list based on the column and fifty records at a time  
  
SELECT (SELECT ROW_NUMBER() OVER (ORDER BY PackListNo)) AS RowNum,*INTO #TEMP1 from packingList  
  
IF @filter <> '' AND @sortExpression <> ''  
  BEGIN  
   SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+Convert(VARCHAR,@sortExpression)+') AS RowNumber,*  from #TEMP1 )  
   select  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount   
   from CETTemp  t  WHERE '+@filter+' and  
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(VARCHAR,@EndRecord) +' ORDER BY '+ @SortExpression+'' --Satish B : 09/18/2017 : Uncomment +' ORDER BY '+ @sortExpression+''  
   END  
  ELSE IF @filter = '' AND @sortExpression <> ''  
  BEGIN  
    SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY '+Convert(VARCHAR,@sortExpression)+') AS RowNumber,*  from #TEMP1 )  
 select  t.*,(SELECT COUNT(RowNumber) FROM CETTemp ) AS TotalCount from CETTemp  t  WHERE   
    RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(VARCHAR,@EndRecord) +' ORDER BY '+ @sortExpression+''  --Satish B : 09/18/2017 : Uncomment +' ORDER BY '+ @sortExpression+''  
 END  
  ELSE IF @filter <> '' AND @sortExpression = ''  
  BEGIN  
      SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY RowNum ASC) AS RowNumber,*  from #TEMP1 )  
   select  t.* ,(SELECT COUNT(RowNumber) FROM CETTemp WHERE '+@filter+') AS TotalCount from CETTemp  t  WHERE  '+@filter+' and  
      RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(VARCHAR,@EndRecord)+''  
   END  
   ELSE  
     BEGIN  
      SET @SQL=N';with CETTemp AS(SELECT ROW_NUMBER() OVER(ORDER BY RowNum ASC) AS RowNumber,*  from #TEMP1 )  
   select  t.*,(SELECT COUNT(RowNumber) FROM CETTemp) AS TotalCount from CETTemp  t  WHERE   
   RowNumber BETWEEN '+Convert(VARCHAR,@StartRecord)+' AND '+Convert(VARCHAR,@EndRecord)+''  
   END  
   exec sp_executesql @SQL  
--Sachin S-05-16-2016:Drop temp table  
    DROP TABLE #TEMP1  
   END