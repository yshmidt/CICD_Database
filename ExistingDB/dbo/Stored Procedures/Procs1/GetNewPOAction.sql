-- =============================================    
-- Author:  Shivshankar P    
-- Create date: 07/14/2018    
-- Description: Get information according to find screen of the MRP module    
-- Shivshankar P : Binded the supplier    
-- Shivshankar P 30/10/18: Added ref column and filtered against the part    
-- Shivshankar P 11/02/18: Removed filtered by quantity    
-- Shivshankar P 30/01/20: Apply sorting on PO change action    
-- Shivshankar P 03/03/20: Get Uniq_key,DTTakeAct FROM #mrpActtemp when @isTakeAllAct = 1    
-- Shivshankar P 03/17/20: MRP search functionality in "PO New Actions" screen    
-- Sachin B: 06/04/20: Fix the Issue for the SupName are Not Comming after save data  
-- Satyawan H 06/05/2020 : Modified the condition to take records upto the end date
-- Sachin B: 06/09/20: Fix the Issue for the Price 
-- Shivshankar P 09/15/20: Apply default sorting with PartNo, DTTakeAct on PO New action 
-- Sachin B 10/13/20: Apply default sorting with PartNo asc, DTTakeAct asc on PO new action 
-- Shivshankar P 11/12/20: Select PartNo becouse apply default sorting is with PartNo on PO New action 
-- [GetNewPOAction] @lcBomParentPart = '000-0003194'    
-- [GetNewPOAction] @dtActDate = '7/19/2019 12:00:00 AM', @uniq_Key = 'BF9JONIO75'    
-- =============================================    
CREATE PROCEDURE [dbo].[GetNewPOAction]     
 @buyer CHAR(35) ='',    
 @projectUnique CHAR(10)=' ',    
 @lcBomParentPart char(35)=' ',      
 @lcBomParentRev char(8)=' ' ,      
 @custNumber varchar(50)=' ',    
 @soNumber CHAR(10)=' ',    
 @ref CHAR(10)=' ',     
 @startDate SMALLDATETIME=NULL,    
 @endDate SMALLDATETIME=NULL,    
 @startRecord INT=1,    
 @endRecord INT=150,    
 @dtActDate DATE = NULL,    
 @uniq_Key CHAR(10) ='',    
 @isTakeAllAct BIT =0,    
 @sortExpression VARCHAR(MAX) = ''    
 --@quantity INT =0    
AS    
BEGIN    
  SET NOCOUNT ON;    
  DECLARE @sqlQuery NVARCHAR(MAX),@rowCount NVARCHAR(MAX)    
  -- Shivshankar P 03/17/20: MRP search functionality in "PO New Actions" screen    
  IF OBJECT_ID('tempdb..#tDemands') IS NOT NULL    
  DROP TABLE #tBOM    
    
  IF OBJECT_ID('tempdb..#tCustomer') IS NOT NULL    
  DROP TABLE #tCustomer    
    
  IF OBJECT_ID('tempdb..#tSOlist') IS NOT NULL    
  DROP TABLE #tSOlist    
    
  IF OBJECT_ID('tempdb..#tWolist') IS NOT NULL    
  DROP TABLE #tWolist    
   
   -- Shivshankar P 09/15/20: Apply default sorting with PartNo, DTTakeAct on PO new action 
   -- Sachin B 10/13/20: Apply default sorting with PartNo asc, DTTakeAct asc on PO new action 
    IF(@sortExpression = NULL OR @sortExpression = '')    
    BEGIN    
      SET @sortExpression = 'PartNo asc, DTTakeAct asc' 
    END	
	ELSE IF(@sortExpression <> NULL AND @sortExpression = 'PartNo asc')    
    BEGIN    
      SET @sortExpression = 'PartNo asc, DTTakeAct desc' 
    END
    ELSE IF(@sortExpression <> NULL AND @sortExpression = 'PartNo desc')    
    BEGIN    
      SET @sortExpression = 'PartNo desc, DTTakeAct desc' 
    END

  DECLARE @lcUniq_key AS char(10)=' ',@lnResult int=0     
  IF (@lcBomParentPart <>' ')      
     BEGIN      
     SELECT @lcUniq_key=Uniq_key FROM INVENTOR       
         where PART_NO=@lcBomParentPart       
         AND REVISION=@lcBomPArentRev       
         AND (PART_SOURC='MAKE' OR PART_SOURC='PHANTOM')      
     SET @lnResult=@@ROWCOUNT      
  END      
    
   SELECT i.UNIQ_KEY INTO #tBOM FROM MRPACT m JOIN BOM_DET det ON m.UNIQ_KEY=det.UNIQ_KEY    
   JOIN INVENTOR i ON i.uniq_key=det.UNIQ_KEY    
   WHERE BOMPARENT=@lcUniq_key    
    
   SELECT  i.UNIQ_KEY     
 INTO #tCustomer     
 FROM MRPACT m     
 JOIN BOM_DET det ON m.UNIQ_KEY=det.UNIQ_KEY    
 JOIN INVENTOR i ON i.uniq_key=det.UNIQ_KEY    
 JOIN WOENTRY wo ON wo.UNIQ_KEY=det.BOMPARENT    
 JOIN CUSTOMER c ON c.CUSTNO=wo.CUSTNO    
 WHERE c.CUSTNO like @custNumber    
    
 SELECT  i.UNIQ_KEY INTO #tSOlist FROM MRPACT m    
 JOIN INVENTOR i ON i.uniq_key=m.UNIQ_KEY    
 JOIN sodetail so ON so.UNIQ_KEY=m.UNIQ_KEY    
 WHERE so.SONO LIKE dbo.padl(@soNumber,10,'0')    
    
 SELECT  i.UNIQ_KEY INTO #tWolist FROM MRPACT m   
 JOIN BOM_DET det ON m.UNIQ_KEY=det.UNIQ_KEY    
 JOIN INVENTOR i ON i.uniq_key=det.UNIQ_KEY    
 JOIN WOENTRY wo ON wo.UNIQ_KEY=det.BOMPARENT    
 WHERE wo.WONO LIKE dbo.padl(@ref,10,'0')    
   
 IF(@uniq_Key = '' AND @isTakeAllAct=0)    
 BEGIN     
   SELECT DISTINCT DTTakeAct,    
    CASE WHEN REVISION IS NULL OR REVISION ='' THEN PART_NO ELSE PART_NO+'/'+REVISION  END AS PartNo    
    , sum(ReqQty) AS ReqQty    
    , '' IsChecked    
    ,TotalCount = COUNT(Act.UNIQ_KEY) OVER()     
    ,Act.UNIQ_KEY uniqKey    
    ,ActionNotes    
    ,CASE WHEN ISNULL(userMrp.UserField,'')='' THEN '' ELSE userMrp.UserField END Reviewed    
   INTO #MRPData    
   FROM MRPACT Act      
       INNER JOIN inventor on Act.UNIQ_KEY = inventor.UNIQ_KEY    
       OUTER APPLY(SELECT  CASE WHEN ISNULL(UserPartMfgr,'') ='' THEN  '' ELSE 'Changed'  END AS UserField    
                FROM MRPACT WHERE DTTAKEACT = act.DTTAKEACT and Act.UNIQMRPACT=UNIQMRPACT    
                GROUP BY DTTAKEACT ,UserPartMfgr ) userMrp    
    -- Satyawan H 06/05/2020 : Modified the condition to take records upto the end date  
       WHERE ACTION ='Release PO' AND ((@startDate IS NOT NULL AND @endDate IS NOT NULL AND Act.DTTAKEACT >= @startDate AND Act.DTTAKEACT <= @endDate) OR       
          (@startDate IS NULL AND @endDate IS NULL AND Act.DTTAKEACT=Act.DTTAKEACT))    
       AND ( ISNULL(ActionStatus,'') <> 'Success')    
       -- Shivshankar P 03/17/20: MRP search functionality in "PO New Actions" screen    
       AND ((ISNULL(@lcUniq_key,'') = '' AND 1=1) OR (ISNULL(@lcUniq_key,'') <> '' AND Act.UNIQ_KEY IN (SELECT UNIQ_KEY FROM #tBOM WHERE UNIQ_KEY = Act.UNIQ_KEY)))      
       AND ((ISNULL(@custNumber,'') = '' AND 1=1) OR (ISNULL(@custNumber,'') <> '' AND EXISTS (SELECT UNIQ_KEY FROM #tCustomer t WHERE t.UNIQ_KEY = Act.UNIQ_KEY)))    
       AND ((ISNULL(@soNumber,'') = '' AND 1=1) OR (ISNULL(@soNumber,'') <> '' AND EXISTS (SELECT UNIQ_KEY FROM #tSOlist  WHERE UNIQ_KEY = Act.UNIQ_KEY)))    
       AND ((ISNULL(@ref,'') = '' AND 1=1) OR (ISNULL(@ref,'') <> '' AND EXISTS (SELECT UNIQ_KEY FROM #tWolist WHERE UNIQ_KEY = Act.UNIQ_KEY)))    
       GROUP BY DTTakeAct ,PART_NO ,REVISION ,Act.UNIQ_KEY,ActionNotes,userMrp.UserField    
       ORDER BY Act.ActionNotes DESC,DTTAKEACT  DESC    
          
    -- Shivshankar P 30/01/20: Apply sorting on PO change action    
    SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #MRPData','',@sortExpression,'','uniqKey',@startRecord,@endRecord))           
       EXEC sp_executesql @rowCount        
    
    SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #MRPData','',@sortExpression,N'DTTAKEACT','',@startRecord,@endRecord))      
       EXEC sp_executesql @sqlQuery    
 END    
    
    
 IF(@uniq_Key <> '' OR @isTakeAllAct =1)    
  BEGIN     
   IF(@isTakeAllAct = 1)    
     BEGIN     
      SELECT @ENDRECORD =COUNT(UNIQMRPACT) FROM MRPACT WHERE ACTION  ='RELEASE PO' AND  ISNULL(ActionStatus,'') <> 'Success'       
      END       
       -- Sachin B: 06/04/20: Fix the Issue for the SupName are Not Comming after save data 
	   -- Shivshankar P 11/12/20: Select PartNo becouse apply default sorting is with PartNo on PO New action           
      SELECT CASE WHEN REVISION IS NULL OR REVISION ='' THEN PART_NO ELSE PART_NO+'/'+REVISION  END AS PartNo,
	         ReqDate, DTTakeAct, CASE WHEN UserReqQty != 0 THEN UserReqQty ELSE ReqQty END AS ReqQty, 
	          -- Sachin B: 06/09/20: Fix the Issue for the Price       
             CASE WHEN UserPrice != 0 THEN UserPrice ELSE ISNULL( ctr.Price,MRPACT.UserPrice) END AS Price,    
               
             CASE WHEN ISNULL(UserPartMfgr,'') != '' THEN UserPartMfgr +' / '+ UserMfgrPtNo ELSE RTRIM(SUBSTRING(PREFAVL,0,CHARINDEX(' ',PREFAVL,0))) + ' / '+    
                LTRIM(RIGHT(SUBSTRING(PREFAVL,CHARINDEX(' ',PREFAVL),300),120)) END AS MfgrNo, ISNULL(ctr.SupName,sup.SupName) as SupName,   
             CASE WHEN ISNULL(UserPartMfgr,'')='' THEN '' ELSE 'Changed' END Reviewed ,    
             CASE WHEN ISNULL(UserPartMfgr,'')='' THEN '' ELSE 1 END IsChecked    
             ,Balance, Mfgrs ,MRPACT.Uniq_key ,TotalCount = COUNT(MRPACT.Uniq_key) OVER()  -- Shivshankar P : Binded the supplier    
             ,Ref    -- Shivshankar P  (30/1018): Added ref column and filtered against the part    
             ,ReqQty AS OriginalReqQty ,    
            ctr.Price AS OriginalPrice,    
            RTRIM( SUBSTRING(PREFAVL,0,CHARINDEX(' ',PREFAVL,0))) AS OriginalPartMfgr,    
            LTRIM(RIGHT(SUBSTRING(PREFAVL,CHARINDEX(' ',PREFAVL),300),120)) AS MfgrPtNo,    
            ISNULL(ctr.UniqSupNo, MRPACT.UniqSupNo) AS OriginalUniqSup,UNIQMRPACT    
            ,ISNULL(ctr.UniqSupNo, MRPACT.UniqSupNo) AS UniqSupNo  
            --,CONTMFGR.*     
            INTO #mrpActtemp    
            FROM MRPACT    
   JOIN inventor on MRPACT.UNIQ_KEY = inventor.UNIQ_KEY    
   left join SUPINFO sup on sup.UNIQSUPNO =MRPACT.UNIQSUPNO  
               --JOIN CONTMFGR ON CONTMFGR.PARTMFGR =RTRIM( SUBSTRING(PREFAVL,0,CHARINDEX(' ',PREFAVL,0)))    
               --         AND CONTMFGR.mfgr_pt_no =  LTRIM(RIGHT(SUBSTRING(PREFAVL,CHARINDEX(' ',PREFAVL),300),120))    
                outer apply  
    (  
     select  SUPINFO.uniqsupno AS OriginalUniqSup    
     ,SUPINFO.uniqsupno,CONTPRIC.Price,SupName    
     from CONTPRIC   
     join CONTMFGR ON CONTPRIC.MFGR_UNIQ = CONTMFGR.MFGR_UNIQ      
                  JOIN CONTRACT ON CONTRACT.CONTR_UNIQ =CONTMFGR.CONTR_UNIQ AND MRPACT.UNIQ_KEY =CONTRACT.CONTR_UNIQ    
                  JOIN contractHeader  ON CONTRACT.ContractH_unique  = contractHeader.ContractH_unique    
                  JOIN SUPINFO  ON  ((ISNULL(MRPACT.UniqSupNo,'') !=  '' OR MRPACT.UniqSupNo !='')    
                  AND  MRPACT.UniqSupNo =   SUPINFO.UNIQSUPNO    
                  OR   (ISNULL(MRPACT.UniqSupNo,'') =  ''     
                  AND     
                 -- select * from mrpact    
                   contractHeader.uniqsupno =SUPINFO.uniqsupno))    
                  where --CONTPRIC.MFGR_UNIQ = CONTMFGR.MFGR_UNIQ    
                  CONTMFGR.PARTMFGR =RTRIM( SUBSTRING(PREFAVL,0,CHARINDEX(' ',PREFAVL,0)))    
                  AND CONTMFGR.mfgr_pt_no =  LTRIM(RIGHT(SUBSTRING(PREFAVL,CHARINDEX(' ',PREFAVL),300),120))     
                  ) as ctr      
                      
            WHERE ACTION ='Release PO'     
            AND     
            ((@isTakeAllAct=0 AND MRPACT.UNIQ_KEY = @uniq_Key    
    
             AND DTTakeAct =@dtActDate    
            )  OR (@isTakeAllAct=1 AND 1=1)) AND  ISNULL(ActionStatus,'') <> 'Success'    
                ORDER BY DTTAKEACT,MRPACT.ActionNotes,ctr.Price DESC    
                 OFFSET (@startRecord -1) ROWS      
                FETCH NEXT @endRecord ROWS ONLY;      
    
     IF(@isTakeAllAct = 1)    
        BEGIN     
        -- Shivshankar P 30/01/20: Apply sorting on PO change action    
        -- Shivshankar P 03/03/20: Get Uniq_key,DTTakeAct FROM #mrpActtemp when @isTakeAllAct = 1    
        SELECT Uniq_key,DTTakeAct FROM #mrpActtemp    
       --SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #mrpActtemp','',@sortExpression,'','Uniq_key',@startRecord,@endRecord))           
       --  EXEC sp_executesql @rowCount        
    
       -- SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT Uniq_key, DTTakeAct AS DtToTak from #mrpActtemp','',@sortExpression,N'Uniq_key','',@startRecord,@endRecord))      
       --EXEC sp_executesql @sqlQuery    
        END    
     ELSE     
        BEGIN     
        -- Shivshankar P 30/01/20: Apply sorting on PO change action    
      --SELECT * FROM #mrpActtemp    
      SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #mrpActtemp','',@sortExpression,'','Uniq_key',@startRecord,@endRecord))           
         EXEC sp_executesql @rowCount        
    
      SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #mrpActtemp','',@sortExpression,N'DTTakeAct','',@startRecord,@endRecord))      
         EXEC sp_executesql @sqlQuery    
        END    
  END    
END 