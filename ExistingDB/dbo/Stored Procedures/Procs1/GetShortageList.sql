  
-- =============================================  
-- Author : Rajendra K   
-- Create date : <04/27/2017>  
-- Description : Get ShortageList data  
-- Modification  
   -- 06/02/2017 Rajendra K : Added Uniq_Key to get PONumber details   
   -- 06/02/2017 Rajendra K : Remove leading zeros from WONO  
   -- 06/08/2017 Rajendra K : Replaced using PATINDEX(To remove leading zeros) by existing function 'fremoveLeadingZeros'  
   -- 06/09/2017 Rajendra K : Removed tables 'InvtMpnLink','MfgrMaster','INVT_RES','InvtLot' from join section  
   -- 06/09/2017 Rajendra K : Added POCount to check whether PONumber items exists for this record  
   -- 06/15/2017 Rajendra K : Changed logic to get POCount  
   -- 06/29/2017 Rajendra K : Changed condition in where clause  
   -- 60/29/2017 Rajendra K : Incresed datatype and size for input parameter '@searchKey'  
   -- 10/03/2017 Rajendra K : Added table 'poitschd' in join condition (in POCount sub-query) to get PO count  
   -- 10/03/2017 Rajendra K : Added condition in where clause (in POCount sub-query) to get PO count  
   -- 10/04/2017 Rajendra K : Removed Part_No from where clause as part_no is combined with revision in where clause  
   -- 10/04/2017 Rajendra K : Search key comparision script changed for PartType/PartyClass/Description  
   -- 10/04/2017 Rajendra K : PART_NO and REVISION separated from group by clause  
   -- 10/04/2017 Rajendra K : PART_CLASS,PART_TYPE and DESCRIPT separated from group by clause  
   -- 10/04/2017 Rajendra K : Removed tables INVTMFGR,INVT_RES,WAREHOUS,Depts from join section in  
   -- 10/04/2017 Rajendra K : replaced dept_id from depts table to Kamain table in group by caluse  
   -- 10/13/2017 Rajendra K : Set @searchKey  = RTRIM(LTRIM(@searchKey)) initially and use in query  
   -- 10/13/2017 Rajendra K : Removed using fremoveLeadingZeros in group by clause   
   -- 10/31/2017 Rajendra K : Replaced WONO by WorkOrderNumber in Order by clause  
   -- 10/31/2017 Rajendra K : Parameter name renamed as per naming conventions  
   -- 11/11/2017 Rajendra K : delcared new parameter @originalSearchKey and replaced @searchKey with @originalSearchKey  
   -- 11/14/2017 Rajendra K : Add new input paramter @sortExpression for dynamic sorting     
   -- 12/20/2017 Rajendra K : Added new column source  
   -- 04/24/2018 Rajendra K : Added new condition in where clause for WO Status  
   -- 05/10/2018 Rajendra K : Removed unnecessary columns from group by clause (From first select statement(used to get count))  
   -- 06/05/2018 Rajendra K : Changed condition in where clause  
   -- 11/27/2018 Rajenda K : add input parameter @filter
   -- 06/24/2019 Rajenda K : Removed total Count selection
   -- 06/24/2019 Rajenda K : Added table for total count & Changed Total Count Selection    
   -- 04/28/2020 Rajenda K : Added @sortExpression 
   -- 05/06/2020 Rajenda K : Added IGNOREKIT = 0    
   -- 06/08/2020 Rajenda K : Added CustpartNo with CustRev into  selection list   
   -- 21/12/2020 Rajenda K : Get the approved available Qty
   -- EXEC GetShortageList 1,5000,'','','',5000    
-- =============================================    
CREATE PROCEDURE [dbo].[GetShortageList]  
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
 DECLARE @originalSearchKey VARCHAR(250)= @searchKey -- 11/11/2017 Rajendra K : Declare and set OriginalSearchKey   
 DECLARE @qryMain  NVARCHAR(2000);  -- -- 11/11/2017 Rajendra K : Declare @qryMain for Dynamic sql   
 DECLARE @sqlQuery NVARCHAR(2000),@rowCount NVARCHAR(MAX);-- --11/27/2018 Rajendra K : Declare @sqlQuery for filter  
 SET @searchKey  = '%'+RTRIM(LTRIM(@searchKey))+'%' -- 11/11/2017 Rajendra K : Added % for used to like condition  
 --11/14/2017 Rajendra K : Set Default value to @sortExpression  
 IF(@sortExpression = NULL OR @sortExpression = '')  
 BEGIN  
 SET @sortExpression = 'WorkOrderNumber'  
 END
 
 -- 06/24/2019 Rajenda K : Added table for total count & Changed Total Count Selection 
 CREATE TABLE #CountTable(
	  totalCount INT
	)   
 
  -- 06/24/2019 Rajenda K : Removed total Count selection 
 --SELECT COUNT(K.KASEQNUM) AS CountRecords  
 --INTO #tempKitDetails   
 -- FROM INVENTOR I  
 --   RIGHT JOIN KAMAIN K ON k.UNIQ_KEY=I.UNIQ_KEY   
 --   INNER JOIN WOENTRY W ON W.WONO=k.WONO  
 --   -- 06/09/2017 Rajendra K : Removed tables 'InvtMpnLink','MfgrMaster','INVT_RES','InvtLot' from join section  
 --   -- 10/04/2017 Rajendra K : Removed tables INVTMFGR,INVT_RES,WAREHOUS,Depts from join section   
 --   WHERE K.SHORTQTY > 0 -- 06/29/2017 Rajenda K : Changed condtion in where clause  
 --   AND (  
 --   @originalSearchKey = NULL OR @originalSearchKey ='' --11/11/2017 Replace @searchKey with @originalSearchKey  
 --   -- 10/04/2017 Rajendra K : Removed Part_No from where clause as part_no is combined with revision in where clause  
 --   OR I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) LIKE @searchKey -- 11/11/2017 Rajendra K : Set % in set section  
 --   OR W.WONO LIKE @searchKey -- 11/11/2017 Rajendra K : Set % in set section  
 --   OR ISNULL(K.dept_id,'') LIKE @searchKey -- 11/11/2017 Rajendra K : Set % in set section  
 --   OR (I.PART_CLASS +' / ' + RTRIM(I.PART_TYPE) + ' / '+RTRIM(I.DESCRIPT))  LIKE  @searchKey) -- 10/04/2017 Rajendra K : Search key comparision script changed   
 --                                -- for PartType/PartyClass/Description  
 --                         -- 11/11/2017 Rajendra K : Set % in set section  
 --GROUP BY W.WONO --06/08/2017 Rajendra K : Replaced using PATINDEX(To remove leading zeros)by   
 --                --existing function 'fremoveLeadingZeros'  
 --   ,I.UNIQ_KEY --To get PONumber details  
 --   ,K.dept_id -- 10/04/2017 Rajendra K : replaced dept_id from depts table to Kamain table in group by caluse  
 --   ,W.DUE_DATE  
 --    -- 05/10/2018 Rajendra K : Removed unnecessary columns from group by clause  
 --   ,K.SHORTQTY  
 --   ,K.LINESHORT  
    
 SELECT   DISTINCT K.KASEQNUM   
    ,CAST(dbo.fremoveLeadingZeros(W.WONO) AS VARCHAR(MAX)) AS Wono --06/08/2017 Rajendra K : Replaced using PATINDEX(To remove leading zeros)by   
                         --existing function 'fremoveLeadingZeros'  
    ,I.UNIQ_KEY --To get PONumber details  
    ,K.dept_id AS WorkCenter  
    ,W.DUE_DATE AS DueDate  
    ,I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) AS PART_NO  
    ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE RTRIM(I.PART_CLASS) +' / ' END ) +   
    (CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN I.PART_TYPE ELSE RTRIM(I.PART_TYPE) + ' / '+RTRIM(I.DESCRIPT) END) AS Descript    
    ,K.SHORTQTY AS Shortage  
    ,0 AS PONumber  
    ,(SELECT COUNT(1) FROM POMAIN PM INNER JOIN  POITEMS PIT  ON PM.PONUM = PIT.PONUM    
      LEFT JOIN poitschd ps ON PIT.uniqlnno = ps.uniqlnno -- 10/03/2017 Rajendra K : Added table 'poitschd' in join condition  
   WHERE UNIQ_KEY = I.UNIQ_KEY   
      AND PM.postatus <> 'CANCEL' AND PM.postatus <>  'CLOSED'   
      AND PIT.lcancel = 0 AND ps.balance > 0) -- 10/03/2017 Rajendra K : Added condition in where clause to get PO count  
      AS POCount -- on 06/09/2017 Rajendra K : Added POCount  to check whether PONumber items exists for this record    
       -- 06/15/2017 - Rajenda K : Changed logic to get POCount  
    ,W.WONO AS WorkOrderNumber  
    ,I.PART_SOURC AS Source -- 12/20/2017 Rajendra K : Added for Source  
  
     -- 06/08/2020 Rajenda K : Added CustpartNo with CustRev into  selection list     
	,RTRIM(LTRIM(I.CUSTPARTNO)) + (CASE WHEN I.CUSTREV IS NULL OR I.CUSTREV = '' THEN I.CUSTREV ELSE '/'+ I.CUSTREV END) AS Custpartno  
	,ISNULL(invtMfgrTotal.Qty,0) as AvailableQty-- 21/12/2020 Rajenda K : Get the approved available Qty
 INTO #tempResult -- 11/14/2017 Rajendra K : Insert records into temp table  
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
    -- 06/09/2017 Rajenda K : Removed tables 'InvtMpnLink','MfgrMaster','INVT_RES','InvtLot' from join section   
    -- 10/04/2017 Rajendra K : Removed tables INVTMFGR,WAREHOUS,Depts from join section   
    WHERE K.SHORTQTY > 0 -- 06/29/2017 Rajenda K : Changed condtion in where clause  
    AND   W.OPENCLOS NOT IN ('Cancel','Closed') AND W.KITSTATUS <> 'KIT CLOSED' -- 04/24/2018 Rajendra K : Added new condition in where clause  
                    -- 06/05/2018 Rajendra K : Changed condition in where clause  
    AND (  
    @originalSearchKey = NULL OR @originalSearchKey ='' --11/11/2017 Replace @searchKey with @originalSearchKey  
    -- 10/04/2017 Rajendra K : Removed Part_No from where clause as part_no is combined with revision in where clause  
    OR I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) LIKE @searchKey -- 11/11/2017 Rajendra K : -- 11/11/2017 Rajendra K : Set % in set section  
   OR W.WONO LIKE @searchKey -- 11/11/2017 Rajendra K : Added % for used to like condition  
    OR ISNULL(K.dept_id,'') LIKE  @searchKey-- 11/11/2017 Rajendra K : -- 11/11/2017 Rajendra K : Set % in set section  
    OR (I.PART_CLASS +' / ' + RTRIM(I.PART_TYPE) + ' / '+RTRIM(I.DESCRIPT))  LIKE  @searchKey) -- 10/04/2017 Rajendra K : Search key comparision script changed   
	AND k.IGNOREKIT  = 0  -- 05/06/2020 Rajenda K : Added IGNOREKIT = 0 
                                 -- for PartType/PartyClass/Description  
                                 -- 11/11/2017 Rajendra K : Set % in set section  
          
 GROUP BY   K.KASEQNUM   
    ,W.WONO -- 10/13/2017 Rajendra K : Removed using fremoveLeadingZeros in group by clause  
    ,I.UNIQ_KEY --To get PONumber details  
    ,K.dept_id  
    ,W.DUE_DATE  
    -- 10/04/2017 Rajendra K : PART_NO and REVISION separated from group by clause  
    ,I.PART_NO   
    ,I.REVISION  
    -- 10/04/2017 Rajendra K : PART_CLASS,PART_TYPE and DESCRIPT separated from group by clause  
    ,I.PART_CLASS  
    ,I.PART_TYPE  
    ,I.DESCRIPT  
    ,K.SHORTQTY  
    ,K.LINESHORT  
    ,I.PART_SOURC -- 12/20/2017 Rajendra K : Added for Source  
	,I.CUSTPARTNO  -- 06/08/2020 Rajenda K : Added CustpartNo with CustRev into  selection list        
	,I.CUSTREV 
	,invtMfgrTotal.Qty  
       --11/14/2017  Rajendra K : Moved pagination in dynamic sql(@qryMain)  
  
 -- 11/14/2017 Rajendra K : Used Dynamic SQL for Sort and Pagination  
 --SET @qryMain ='SELECT *  
 --     FROM #tempResult ORDER BY '   
 --     + @sortExpression + ' OFFSET (' +CONVERT(VARCHAR(10), @startRecord-1)  
 --     + ') ROWS FETCH NEXT ' +CONVERT(VARCHAR(10), @endRecord )+ ' ROWS ONLY;'   
  
  -- 06/24/2019 Rajenda K : Added table for total count & Changed Total Count Selection 
  SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempResult',@Filter,'','','PART_NO',@startRecord,@endRecord))          
	INSERT INTO #CountTable EXEC sp_executesql @rowCount   
  
   SELECT @out_TotalNumberOfRecord = totalCount FROM #CountTable

  -- 04/28/2020 Rajenda K : Added @sortExpression 
  SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempResult ',@filter,@sortExpression,'Wono','',@startRecord,@endRecord))    
  
   -- 06/24/2019 Rajenda K : Removed total Count selection
   --SET @out_TotalNumberOfRecord = (SELECT COUNT(1) FROM #tempKitDetails)  
  
 --EXEC sp_executesql @qryMain -- 11/14/2017 Rajendra K : Get result  
 EXEC sp_executesql @sqlQuery--11/27/2018 Rajendra K : Get filter result  
END  