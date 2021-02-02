
  
-- =============================================  
-- Author : Rajendra K   
-- Create date : <12/21/2017>  
-- Description : Get ShortageList data for PartNumbers  
-- Modification  
   -- 01/09/2018 Rajendra K : Added condition K.SHORTQTY > 0 in where clause  
   -- 04/24/2018 Rajendra K : Added new condition in where clause for WO Status  
   -- 05/10/2018 Rajendra K : Removed unnecessary columns from group by clause (From first select statement(used to get count))  
   -- 06/05/2018 Rajendra K : Changed condition in where clause  
   -- 11/27/2018 Rajenda K : Added input parameter @filter
   -- 06/24/2019 Rajenda K : Removed total Count selection
   -- 06/24/2019 Rajenda K : Added table for total count & Changed Total Count Selection 
   -- 04/28/2020 Rajenda K : Added @sortExpression   
   -- 05/06/2020 Rajenda K : Added IGNOREKIT = 0  
   -- 06/08/2020 Rajenda K : Added CustpartNo with CustRev into  selection list 
   -- 21/12/2020 Rajenda K : Get the approved available Qty
   -- EXEC GetPartShortageList 1,1000,'','Source desc','',1000  
-- =============================================  
  
CREATE PROCEDURE [dbo].[GetPartShortageList]  
(  
@startRecord int =1,  
@endRecord int =10,  
@searchKey VARCHAR(250)='', --06/29/2017 Rajenda K : Incresed datatype and size for input parameter '@searchKey'    
@sortExpression NVARCHAR(200)= '', -- 11/14/2017 Rajendra K :Added sortExpression  
@filter NVARCHAR(1000),--11/27/2018 Rajenda K : add input parameter @filter  
@out_TotalNumberOfRecord INT OUTPUT   
)  
AS  
BEGIN  
 SET NOCOUNT ON;  
 DECLARE @originalSearchKey VARCHAR(250)= @searchKey   
 DECLARE @qryMain  NVARCHAR(2000);   
 DECLARE @sqlQuery NVARCHAR(2000),@rowCount NVARCHAR(MAX);-- --11/27/2018 Rajendra K : Declare @sqlQuery for filter   
 SET @searchKey  = '%'+RTRIM(LTRIM(@searchKey))+'%'   
 IF(@sortExpression = NULL OR @sortExpression = '')  
 BEGIN  
 SET @sortExpression = 'PART_NO'  
 END  

  -- 06/24/2019 Rajenda K : Added table for total count & Changed Total Count Selection 
CREATE TABLE #CountTable(
	  totalCount INT
	)
  
  -- 06/24/2019 Rajenda K : Removed total Count selection
 --SELECT COUNT(I.UNIQ_KEY) AS CountRecords  
 --INTO #tempKitDetails   
 -- FROM INVENTOR I  
 --   RIGHT JOIN KAMAIN K ON k.UNIQ_KEY=I.UNIQ_KEY   
 --   INNER JOIN WOENTRY W ON W.WONO=k.WONO  
 --   WHERE K.SHORTQTY > 0   
 --   AND (  
 --   @originalSearchKey = NULL OR @originalSearchKey =''   
 --   OR I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) LIKE @searchKey   
 --   OR W.WONO LIKE @searchKey  
 --   OR ISNULL(K.dept_id,'') LIKE @searchKey  
 --   OR (I.PART_CLASS +' / ' + RTRIM(I.PART_TYPE) + ' / '+RTRIM(I.DESCRIPT))  LIKE  @searchKey)   
 --GROUP BY    
 --    I.UNIQ_KEY   
  -- 05/10/2018 Rajendra K : Removed unnecessary columns from group by clause   
  
 SELECT DISTINCT   
     I.UNIQ_KEY   
    ,I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) AS PART_NO  
    ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE RTRIM(I.PART_CLASS) +' / ' END ) +   
    (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN I.PART_TYPE ELSE RTRIM(I.PART_TYPE) + ' / '+RTRIM(I.DESCRIPT) END) AS Descript    
    ,SUM(K.SHORTQTY) AS Shortage  
    ,0 AS PONumber  
    ,0 AS WO  
    ,(SELECT COUNT(1) FROM POMAIN PM INNER JOIN  POITEMS PIT  ON PM.PONUM = PIT.PONUM    
      LEFT JOIN poitschd ps ON PIT.uniqlnno = ps.uniqlnno   
      WHERE UNIQ_KEY = I.UNIQ_KEY   
     AND PM.postatus <> 'CANCEL' AND PM.postatus <>  'CLOSED'   
     AND PIT.lcancel = 0 AND ps.balance > 0)   
     AS POCount   
    ,I.PART_SOURC AS Source   
	-- 06/08/2020 Rajenda K : Added CustpartNo with CustRev into  selection list     
	,RTRIM(LTRIM(I.CUSTPARTNO)) + (CASE WHEN I.CUSTREV IS NULL OR I.CUSTREV = '' THEN I.CUSTREV ELSE '/'+ I.CUSTREV END) AS Custpartno 
	,ISNULL(invtMfgrTotal.Qty,0) as AvailableQty-- 21/12/2020 Rajenda K : Get the approved available Qty
 INTO #tempResult   
 FROM INVENTOR I  
    RIGHT JOIN KAMAIN K ON k.UNIQ_KEY=I.UNIQ_KEY   
    INNER JOIN WOENTRY W ON W.WONO=k.WONO 
	OUTER APPLY-- 21/12/2020 Rajenda K : Get the approved available Qty
	 (
		SELECT  SUM(QTY_OH) - SUM(RESERVED) AS Qty FROM INVTMFGR IM    
		INNER JOIN InvtMPNLink pn ON im.UNIQMFGRHD =  pn.uniqmfgrhd   
		INNER JOIN MfgrMaster mf ON pn.MfgrMasterId = mf.MfgrMasterId   
		AND (NOT EXISTS (SELECT bomParent,K.UNIQ_KEY   
				FROM ANTIAVL A       
				WHERE A.BOMPARENT = k.BOMPARENT          
				AND A.UNIQ_KEY = K.UNIQ_KEY    
				AND A.PARTMFGR = mf.PARTMFGR     
				AND A.MFGR_PT_NO = mf.MFGR_PT_NO)  
            )    
	  WHERE IM.UNIQ_KEY = k.UNIQ_KEY  
	) AS invtMfgrTotal  
    WHERE K.SHORTQTY >0  -- 01/09/2018 Rajenda K : Changed condtion in where clause  
    AND  I.UNIQ_KEY IS NOT NULL      
    AND  W.OPENCLOS NOT IN ('Cancel','Closed') AND W.KITSTATUS <> 'KIT CLOSED' -- 04/24/2018 Rajendra K : Added new condition in where clause  
                    -- 06/05/2018 Rajendra K : Changed condition in where clause  
    AND (  
    @originalSearchKey = NULL OR @originalSearchKey =''  
    OR I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) LIKE @searchKey   
    OR (I.PART_CLASS +' / ' + RTRIM(I.PART_TYPE) + ' / '+RTRIM(I.DESCRIPT))  LIKE  @searchKey      
    )   
	AND k.IGNOREKIT  = 0   -- 05/06/2020 Rajenda K : Added IGNOREKIT = 0      
 GROUP BY     
     I.UNIQ_KEY   
    ,I.PART_NO   
    ,I.REVISION  
    ,I.PART_CLASS  
    ,I.PART_TYPE  
    ,I.DESCRIPT  
    ,I.PART_SOURC  
   
	,I.CUSTPARTNO  -- 06/08/2020 Rajenda K : Added CustpartNo with CustRev into  selection list        
	,I.CUSTREV
	,invtMfgrTotal.Qty 
 --SET @qryMain ='SELECT *  
 --     FROM #tempResult ORDER BY '   
 --     + @sortExpression + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord-1)  
 --     + ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'
  
  -- 06/24/2019 Rajenda K : Added table for total count & Changed Total Count Selection 
 	SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempResult',@Filter,'','','PART_NO',@startRecord,@endRecord))          
	INSERT INTO #CountTable EXEC sp_executesql @rowCount   
  
   SELECT @out_TotalNumberOfRecord = totalCount FROM #CountTable
   
   -- 06/24/2019 Rajenda K : Removed total Count selection
   -- SET @out_TotalNumberOfRecord = (SELECT COUNT(1) FROM #tempKitDetails)  
   -- 04/28/2020 Rajenda K : Added @sortExpression   
   SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempResult ',@filter,@sortExpression,'PART_NO','',@startRecord,@endRecord))    
 --EXEC sp_executesql @qryMain  
 EXEC sp_executesql @sqlQuery  
END  