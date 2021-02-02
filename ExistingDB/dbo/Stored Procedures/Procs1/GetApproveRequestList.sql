-- =============================================            
-- Author:Satish B            
-- Create date: 08/23/2018            
-- Description : Get approve request list            
-- Modified 12/24/2018 Satish B: Remove @isApproved variable            
-- 12/24/2018 Satish B: Change filter remove @isApproved and add i.WFRequestId IN(SELECT WFRequestId FROM #wfConfigDetail where IsApproved = 1)            
-- 01/12/2018 Satish B: Add filter for selecting PO It's not Rejected only            
-- 06/12/2019 Satish B: Add extra parameter ,@recordId char(15) = null to fetch record coditionaly when fecting from notifications             
-- 06/14/2019 Satish B: Select to more coulmn in temp table and apply outer apply            
-- 06/14/2019 Satish B: Add    ,i.WFConfigId to select configid             
-- 06/16/2019 Satish B: Added a filter to restrict the user to see the request until its previous level user Approve the request             
-- 07/25/2019 Vijay G :Remove the filter condition of group user id            
-- 11/26/2019 Vijay G :Modified size of parameter from @recordId char(15) to @recordId char(20)          
-- 12/20/2019 Vijay G :Chnaged the wrong alias of join      
-- 05/11/2020 Shiv P : Addeed Join with POMAIN table     
-- 06/26/2020 Sachin B: Remove the Wrong Join with POMain Table   
-- 09/18/2020 Sachin B: Fix the Issue if 2 Setp Approval is pending then user will not able to approve greater then 2 step  
-- GetApproveRequestList '1320274c-f08d-4939-b363-40aefc4869c3' ,''1,10,1 output    
-- =============================================              
CREATE PROCEDURE GetApproveRequestList              
  @approverId uniqueidentifier = null            
  -- 06/12/2019 Satish B: Add extra parameter ,@recordId char(15) = null to fetch record coditionaly when fecting from notifications             
 ,@recordId char(20) = null    -- 11/26/2019 Vijay G :Modified size of parameter from @recordId char(15) to @recordId char(20)          
 ,@startRecord int =1            
    ,@endRecord int =10             
 ,@outTotalNumberOfRecord int OUTPUT            
 AS            
 BEGIN            
 SET NOCOUNT ON              
 --12/24/2018 Satish B: Remove @isApproved variable              
  SELECT COUNT(r.RecordId) AS RowCnt -- Get total counts             
   INTO #tempApproveList            
   FROM WFRequest r            
   INNER JOIN WFInstance i ON i.WFRequestId =r.WFRequestId            
   INNER JOIN WFConfig c ON c.WFConfigId = i.WFConfigId            
   INNER JOIN MnxWFMetaData m ON m.MetaDataId = c.MetaDataId            
   INNER JOIN aspnet_Profile a ON a.UserId=r.RequestorId            
   -- 07/25/2019 Vijay G :Remove the filter condition of group user id            
   WHERE i.Approver =@approverId             
  --Get previous step details to check weather previous step is approved or not            
-- 06/14/2019 Satish B: select to more coulmn in temp table and apply outer apply            
SELECT IsApproved,WFRequestId,StepNumber,RecordId            
  INTO #wfConfigDetail            
  FROM (             
   SELECT DISTINCT i.IsApproved,i.WFRequestId,c.StepNumber,r.RecordId         
   FROM WFConfig c              
   INNER JOIN WFInstance i ON c.WFConfigId=i.WFConfigId            
   INNER JOIN WFRequest r ON r.WFRequestId=i.WFRequestId            
    -- 07/25/2019 Vijay G :Remove the filter condition of group user id            
    OUTER APPLY   
    (            
    SELECT r.RecordId   
    FROM WFConfig c   
    INNER JOIN WFInstance i ON c.WFConfigId=i.WFConfigId              
    INNER JOIN WFRequest r ON r.WFRequestId=i.WFRequestId WHERE i.approver=@approverId   
    ) AI--OR approverid IN (SELECT fkgroupid FROM aspmnx_groupUsers WHERE fkuserid=@approverId)) AI              
            WHERE (  
     c.StepNumber IN   
     (  
      SELECT CASE WHEN stepnumber > 1 THEN stepnumber-1 ELSE stepnumber END stepnumber             
      FROM WFConfig JOIN WFInstance wfi ON WFConfig.WFConfigId=wfi.WFConfigId   
      -- 12/20/2019 Vijay G :Chnaged the wrong alias of join     
      WHERE  wfi.Approver=@approverId                                      
      --approverid=@approverId               
      --OR approverid IN (SELECT fkgroupid FROM aspmnx_groupUsers WHERE fkuserid=@approverId)              
     ) AND r.RecordId =AI.RecordId  
      )  
   )as IsApproved  
  -- 09/18/2020 Sachin B: Fix the Issue if 2 Setp Approval is pending then user will not able to approve greater then 2 step  
  SELECT *           
  INTO #configDatails          
  FROM     
  (              
  SELECT child.WFInstanceId,RecordId,StepNumber   
  FROM WFInstance parent  
  INNER JOIN   
  (  
     SELECT i.WFInstanceId, r.recordid,c.stepnumber,  
      ROW_NUMBER() over (PARTITION BY r.WFRequestId ORDER BY c.stepNumber) AS rn  
     FROM WFRequest r  
     INNER JOIN WFInstance i ON r.WFRequestId = i.WFRequestId  
     INNER JOIN WFConfig c ON c.WFConfigId =i.WFConfigId   
     WHERE i.IsApproved =0 --AND r.RequestorId = @approverId   
  ) AS child   
  ON parent.WFInstanceId = child.WFInstanceId AND child.rn = 1   
  ) AS Instant        
                 
              
  SELECT DISTINCT r.RecordId            
   ,RTRIM(m.MetaDataName)+' '+'('+r.RecordId+')' AS ModuleName             
   ,m.MetaDataName AS BaseModule            
   ,a.FirstName +' '+ a.LastName AS ApproverInit             
   ,r.RequestDate             
  ,c.StepNumber AS ApproveStep             
   ,c.IsAll             
-- 06/14/2019 Satish B: Add    ,i.WFConfigId to select configid             
   ,i.WFConfigId            
   ,c.IsGroup            
   ,c.ApproverId            
   ,r.ModuleId            
   ,i.ActionDate            
   ,CASE WHEN i.IsApproved=0 AND i.RejectToStep IS NULL THEN 'Pending'             
    ELSE             
   CASE WHEN i.IsApproved=1 THEN 'Approved' ELSE 'Rejected' END            
    END AS [Status]            
              
  FROM WFRequest r            
  INNER JOIN WFInstance i ON i.WFRequestId =r.WFRequestId  
  INNER JOIN #configDatails con ON i.WFInstanceId = con.WFInstanceId             
  INNER JOIN WFConfig c ON c.WFConfigId = i.WFConfigId            
  INNER JOIN MnxWFMetaData m ON m.MetaDataId = c.MetaDataId            
  INNER JOIN aspnet_Profile a ON a.UserId=r.RequestorId        
  ---- 05/11/2020 Shiv P : Addeed Join with POMAIN table      
  -- 06/26/2020 Sachin B: Remove the Wrong Join with POMain Table    
  --INNER JOIN POMAIN p ON p.PONUM=r.RecordId          
-- 07/25/2019 Vijay G :Remove the filter condition of group user id            
   WHERE i.Approver=@approverId          
  --(c.ApproverId =@approverId OR c.WFConfigId              
  --c.ApproverId IN (SELECT fkGroupId FROM aspmnx_groupUsers WHERE fkuserid=@approverId))              
     --12/24/2018 Satish B: Change filter remove @isApproved and add i.WFRequestId IN(SELECT WFRequestId FROM #wfConfigDetail where IsApproved = 1)            
     -- 06/16/2019 Satish B: Added a filter to restrict the user to see the request until its previous level user Approve the request             
     AND     
  (  
  r.RecordId IN(SELECT RecordId FROM #wfConfigDetail WHERE ISapproved=1)             
  OR  r.RecordId NOT IN(SELECT RecordId FROM #wfConfigDetail)   
  OR c.stepNumber=1  
  )            
     --01/12/2018 Satish B: Add filter for selecting PO It's not Rejected only            
     AND i.RejectToStep IS NULL            
     AND i.Approver=@approverId             
     AND r.WFComplete=0             
     AND i.IsApproved=0        
  --AND p.IsApproveProcess=1          
-- 06/12/2019 Satish B:Added filter to fetch record coditionaly when fecting from notifications             
     AND((@recordID<> null OR @recordID<>'' AND r.RecordId=@recordID)OR(@recordID= null OR @recordID='' AND 1=1))              
                
  ORDER BY r.RecordId             
  OFFSET(@startRecord-1) ROWS            
  FETCH NEXT @EndRecord ROWS ONLY;            
  SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempApproveList) -- Set total count to Out parameter             
END 