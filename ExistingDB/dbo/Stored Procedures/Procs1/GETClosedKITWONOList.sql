 -- =============================================  
-- Author:  Rajendra K   
-- Create date: 01/02/2020 
-- Description: Used to Get Closed KIT and Closed Work Order data  
-- 06/02/2020 Sachin B : Add KIT Column in the select statement
-- [dbo].[GETClosedKITWONOList] '','Closed','',1,1000,1    
-- =============================================  
CREATE PROCEDURE [dbo].[GETClosedKITWONOList]    
(  
	@wONO VARCHAR(50) = '',  
	@status VARCHAR(30) = '', 
	@sortExpression NVARCHAR(200)= '',
	@startRecord int =1,  
	@endRecord int =10,  
	@rowCount INT OUT  
)  
AS  
BEGIN  
 SET NOCOUNT ON; 
  DECLARE @qryMain  NVARCHAR(MAX); 

 SET @sortExpression = CASE WHEN @sortExpression IS NULL OR @sortExpression = '' THEN 'W.WONO' ELSE RTRIM(LTRIM(@sortExpression)) END  

   SELECT @rowCount = COUNT(DISTINCT W.WONO)   
   FROM WoEntry W  
     INNER JOIN Inventor I ON W.UNIQ_KEY = I.Uniq_Key  
   WHERE (@wONO = '' OR W.WONO LIKE '%' + @wONO + '%'  
      OR RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE ' /'+ RTRIM(I.REVISION) END)   
      LIKE '%' + @wONO + '%')  
      AND KITSTATUS = 'KIT CLOSED' AND W.OPENCLOS = 'Closed'
-- 06/02/2020 Sachin B : Add KIT Column in the select statement
 SET @qryMain = 'SELECT DISTINCT wh.WAREHOUSE, W.WONO AS WONO '     
     +',dbo.fremoveLeadingZeros(W.WONO) AS WorkOrderNumber '  
     +',I.UNIQ_KEY '   
     +',W.DUE_DATE AS DueDate '  
     +',I.ITAR '  
     +','''' AS DPAS '  
     +',W.BLDQTY AS Bldqty '  
     +',I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '''' THEN I.REVISION ELSE ''/''+ I.REVISION END) AS PartRevision '  
     +',I.PART_CLASS +''/ '' + '  
     +' (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='''' THEN I.PART_TYPE ELSE I.PART_TYPE + ''/ ''+I.DESCRIPT END) AS Description '  
     +',C.CUSTNAME AS CustName '  
     +',COUNT(DISTINCT k.KASEQNUM) AS TotalBomItems '  
     +',(CASE WHEN COALESCE(COUNT(k.KASEQNUM),0) > 0 THEN ''Yes'' ELSE ''No'' END) AS Released '  
     +',W.KITSTATUS AS KitStatus '  
     +',W.OPENCLOS AS OpenClose '  
     +',I.Part_Sourc AS PartSourc '  
     +',CAST(CASE WHEN SUM(CASE WHEN K.ShortQty < 0 THEN ''0'' ELSE K.ShortQty END ) > 0 THEN 1 ELSE 0  END AS BIT) AS IsShortage '   
     +',CAST(SUM(CASE WHEN K.ShortQty < 0 THEN ''0'' ELSE K.ShortQty END ) AS NUMERIC(13,5)) AS ShortQty '  
     +',I.BOMCUSTNO AS CUSTNO,W.KIT '  
     +'FROM WoEntry W '  
     +'INNER JOIN Inventor I ON W.UNIQ_KEY = I.Uniq_Key '  
     +'INNER JOIN CUSTOMER C ON W.CUSTNO = C.CUSTNO '  
     +'INNER JOIN kamain K ON W.WONO = K.WONO '   
   + 'LEFT JOIN WAREHOUS wh ON W.KitUniqwh = wh.UNIQWH '   
   +'WHERE  '  
   +'(1= ('+ CASE WHEN  @wONO = '' THEN ' 1' ELSE '0' END +')'    
   +'OR W.WONO  LIKE ''%'+@wONO+'%'''   
      +'OR (RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '''' THEN I.REVISION ELSE '' /''+ RTRIM(I.REVISION) END) '  
   +'LIKE ''%'+@wONO+'%'' ))'  
   +' AND KITSTATUS = ''KIT CLOSED'' AND W.OPENCLOS = ''Closed'' '
   +'GROUP BY '    
    +'wh.WAREHOUSE '  
    +',W.WONO '     
    +',I.UNIQ_KEY '   
    +',Bldqty '  
    +',I.PART_CLASS '  
    +',I.DESCRIPT '  
    +',I.PART_TYPE '  
    +',W.DUE_DATE '  
    +',I.ITAR '  
    +',I.Revision '  
    +',I.Part_No '  
    +',C.CUSTNAME '  
    +',W.KITSTATUS '  
    +',W.OPENCLOS '  
    +',I.Part_Sourc '  
    +',I.BOMCUSTNO,W.KIT '  
    +' UNION '  
    +' SELECT DISTINCT wh.WAREHOUSE '  
    +',W.WONO AS WONO '     
    +',dbo.fremoveLeadingZeros(W.WONO) AS WorkOrderNumber '  
    +',I.UNIQ_KEY '  
    +',W.DUE_DATE AS DueDate '  
    +',I.ITAR '  
    +','''' AS DPAS '  
    +',W.BLDQTY AS Bldqty '  
    +',I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '''' THEN I.REVISION ELSE ''/''+ I.REVISION END) AS PartRevision '  
    +',I.PART_CLASS +''/ '' + '  
    +' (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='''' THEN I.PART_TYPE ELSE I.PART_TYPE + ''/ ''+I.DESCRIPT END) AS Description '  
    +',C.CUSTNAME AS CustName '  
    +',COUNT(B.UNIQ_KEY) AS TotalBomItems '  
    +',''No'' AS Released '  
    +',W.KITSTATUS AS KitStatus '  
    +',W.OPENCLOS AS OpenClose '  
    +',I.Part_Sourc AS PartSourc '  
    +',CAST(0 AS BIT) AS IsShortage '  
    +',CAST(0 AS NUMERIC(13,5)) AS ShortQty '  
    +',I.BOMCUSTNO AS CUSTNO,W.KIT '  
  +'FROM WoEntry W '  
  +'INNER JOIN Inventor I ON W.UNIQ_KEY = I.Uniq_Key '  
  +'INNER JOIN CUSTOMER C ON W.CUSTNO = C.CUSTNO '   
  +'LEFT JOIN BOM_DET B ON W.UNIQ_KEY = B.BOMPARENT '  
  + 'LEFT JOIN WAREHOUS wh ON W.KitUniqwh = wh.UNIQWH '  
 +'WHERE W.WONO NOT IN(SELECT WONO FROM KAMAIN) AND ('  
   +'(1= ('+ CASE WHEN @wONO = '' THEN ' 1' ELSE '0' END +')'    
   +'OR W.WONO  LIKE ''%'+@wONO+'%'''   
   +'OR (RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '''' THEN I.REVISION ELSE '' /''+ RTRIM(I.REVISION) END) '  
   +'LIKE ''%'+@wONO+'%'' )'  
   +') AND (KITSTATUS = ''KIT CLOSED'' AND W.OPENCLOS = ''Closed'' ))'
 +'GROUP BY '   
     +'wh.WAREHOUSE '   
     +',W.WONO '    
     +',I.UNIQ_KEY '  
     +',Bldqty '       
     +',I.PART_CLASS '  
     +',I.DESCRIPT '  
     +',I.PART_TYPE '  
     +',W.DUE_DATE '  
     +',I.ITAR '  
     +',I.Revision '  
     +',I.Part_No '  
     +',C.CUSTNAME '  
     +',W.KITSTATUS '  
     +',W.OPENCLOS '  
     +',I.Part_Sourc '  
     +',I.BOMCUSTNO,W.KIT '  
     +' ORDER BY '  
     + @sortExpression + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord-1)  
     + ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'  
      
     EXEC sp_executesql @qryMain   
END