 -- ====================================================================================================================  
 -- Author:Sachin s  
 -- Create date: 03/10/2016  
 -- Description: Return Sales order Line items with Sorting and Filtering  
 -- Modified :Sachin s- 05/17/2016  Need warehouse        
 --    : Sachin S-05/28/2016 balance should be greater than 0  
 --    : Sachin S-08/25/2016 Get all the so line items remove slink address  
 --    : Satish B- 09-23-2016 Remove SHIPPEDREV column From Sales Order Detail Grid  
 --    : Satish B- 12-28-2016 Combine part class,part type and description as one column  
 --    : Satish B- 01-04-2017 Added ITAR column  
 --    : Satish B- 01-04-2017 Select inventor.Descript column  
 --    : Satish B- 03-06-2018 Added the @sortExpression to sort the line number in ascending order by default  
 --    : Satish B- 03-06-2018 Added the selection of LINE_No as LineNumber  
 --    : Satish B- 04-08-2018 Replace left join with inner join  
 --    : Satish B- 04-16-2018 Replace Inner join with Left join to display manual part which are added while creating sales order  
 --    : Satish B- 04-16-2018 Select U_of_meas from sodetail table if inventor.U_OF_MEAS is null or empty  
 --    : Satish B- 04-16-2018 Select description from sodetail if description from Inventor is null or empty  
 --    : Satish B- 01-15-2019 Added New column INV_LINK 
 --    : Shrikant B 05-05-2019 Added Column IsSFBL for SFBL warehouse identity  
 --    : Shivshankar P- 02/29/2020 Added condition to remove items with the status 'Cancel' 
 -- [dbo].GetSalesOrderDetailView '0000000902', 1, 150,'','LINE_NO asc',''  
 -- ====================================================================================================================  
 --[dbo].GetSalesOrderDetailView @startRecord = 1, @endRecord = 150, @sono = '0000000505', @filter = '',  @slinkAdd = ''  
 CREATE PROCEDURE [dbo].GetSalesOrderDetailView   
 @sono AS char(10) = '',  
 @startRecord int,  
 @endRecord int,   
 @slinkAdd nvarchar(10),  
 @sortExpression nvarchar(1000)= '',  
 @filter nvarchar(1000) =  ''  
AS  
DECLARE @SQL nvarchar(max)  
BEGIN  
-- Satish B- 03-06-2018 Added the @sortExpression to sort the line number in ascending order by default  
 IF (@sortExpression = '' OR @sortExpression = 'LINE_NO Asc' )  
 BEGIN  
  SET @sortExpression = 'LineNumber ASC'  
 END  
  
;WITH packingList as(SELECT    
       --Trim the zero's  
 dbo.fRemoveLeadingZeros(sodetail.LINE_NO) AS LINE_NO   
 -- Satish B- 03-06-2018 Added the selection of LINE_No as LineNumber  
 ,sodetail.LINE_NO AS LineNumber  
 ,inventor.Part_no  
 ,inventor.Revision  
  
 --Satish B- 12-28-2016 Combine part class,part type and description as one column  
 --Satish B- 04-16-2018 Select description from sodetail if description from Inventor is null or empty  
 ,ISNULL(ISNULL(inventor.Part_Class,SPACE(8)) +'/'+' '+ ISNULL(inventor.Part_Type,SPACE(8)) +'/'+' '+ inventor.DESCRIPT,sodetail.Sodet_Desc) AS ClassTypeDescript  
 --ISNULL(Part_Class,SPACE(8)) AS Part_Class,   
 --,inventor.Part_Class  
 --,inventor.Part_Type  
 -- Satish B- 01-04-2017 Select inventor.Descript column  
 ,inventor.Descript   
 ,inventor.Part_Sourc  
 --,sodetail.SHIPPEDQTY  
 ,0 AS  SHIPPEDQTY  
 ,sodetail.BALANCE  
 --Satish B- 04-16-2018 Select U_of_meas from sodetail table if inventor.U_OF_MEAS is null or empty  
 ,ISNULL(inventor.U_OF_MEAS,sodetail.UOFMEAS) AS U_of_meas  
 --,inventor.U_of_meas  
 ,inventor.UNIQ_KEY  
 ,inventor.CERT_REQ  
 -- Satish B- 01-04-2017 Added ITAR column  
 ,inventor.ITAR  
 --Sachin s- 05/17/2016  Need warehouse key  
 ,sodetail.W_KEY   
 ,sodetail.UNIQUELN  
 --,'' AS SHIPPEDREV  --Satish B- 09-23-2016 Remove SHIPPEDREV column From Sales Order Detail Grid  
 --,sodetail.SHIPPEDQTY AS BaseShippedQty  
 ,0 AS BaseShippedQty  
 ,sodetail.BALANCE AS BaseBalance  
  --bind the grid data  
  ,'' As PLPL_GL_NBR   
  ,''As PLCOG_GL_NBR   
  ,inventor.SERIALYES AS SerialYes   
   ,inventor.USEIPKEY   
   ,sodetail.BALANCE AS Ord_Qty  
   ,dbo.fn_GenerateUniqueNumber() AS INV_LINK -- Satish B- 01-15-2019 Added New column INV_LINK  
   ,(SELECT p.LOTDETAIL from PARTTYPE p WHERE p.PART_TYPE = inventor.PART_TYPE AND p.PART_CLASS = inventor.PART_CLASS) AS LOTDETAIL  
     --Sachin s : 08-23-2016 Filter list by Slinke addresss  
   ,ISNULL(sodetail.SLinkAdd, null) AS SLinkAdd
 --    : Shrikant B 05-05-2019 Added Column IsSFBL for SFBL warehouse identity  
  ,sodetail.IsSFBL    
  
   --Satish B- 04-08-2018 Replace left join with inner join  
   --Satish B : 04-16-2018 Replace Inner join with Left join to display manual part which are added while creating sales order  
 FROM Sodetail LEFT JOIN Inventor   
 ON Sodetail.Uniq_key = Inventor.Uniq_key    
 WHERE Sono = @sono   
 --Sachin S-08/25/2016 Get all the so line items remove slink address  
 --AND Sodetail.SLinkAdd=@slinkAdd    
 --Sachin S- balance should be greater than 0  
 AND ISNULL(sodetail.BALANCE, 0) > 0   
 --AND ISNULL(sodetail.SHIPPEDQTY, 0) < ISNULL(sodetail.BALANCE, 0)  
 AND sodetail.STATUS <> 'Cancel'   -- Shivshankar P- 02/29/2020 Added condition to remove items with the status 'Cancel' 
 ),  
   
temptable as(SELECT *  from packingList )  
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
  
  
  
   