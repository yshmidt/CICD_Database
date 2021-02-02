-- ==========================================================      
-- Author:Satish B    
-- Create date: 06/12/2019    
-- Description : Get approve request list  
-- 05/11/2020 Shiv P : Addeed Join with POMAIN table 
-- 07/08/2020 Satyawan H : Removed Join with POMAIN table
-- 07/08/2020 Satyawan H : Removed condition of is Approval with POMAIN
-- ==========================================================
CREATE PROCEDURE ApproveRequestListById      
  @approverId uniqueidentifier = null    
 AS    
 BEGIN    
 SET NOCOUNT ON      
 --12/24/2018 Satish B: Remove @isApproved variable    
  DECLARE @firstApprover bit = 0,@wfconfigCount int=0  
      
  SELECT COUNT(r.RecordId) AS RowCnt -- Get total counts     
   INTO #tempApproveList    
   FROM WFRequest r    
   INNER JOIN WFInstance i ON i.WFRequestId =r.WFRequestId    
   INNER JOIN WFConfig c ON c.WFConfigId = i.WFConfigId    
   INNER JOIN MnxWFMetaData m ON m.MetaDataId = c.MetaDataId    
   INNER JOIN aspnet_Profile a ON a.UserId=r.RequestorId  
   -- 07/08/2020 Satyawan H : Removed Join with POMAIN table
   -- INNER JOIN POMAIN p ON p.PONUM=r.RecordId     
   -- 07/08/2020 Satyawan H : Removed condition of is Approval with POMAIN
   WHERE c.ApproverId =@approverId  --AND p.IsApproveProcess=1  
  --Get previous step details to check weather previous step is approved or not   
    
    
     
SET @wfconfigCount= (SELECT COUNT(*) FROM WFConfig)  
SELECT IsApproved,WFRequestId,StepNumber,RecordId  
  INTO #wfConfigDetail    
  FROM (     
   SELECT DISTINCT i.IsApproved,i.WFRequestId,c.StepNumber,r.RecordId FROM WFConfig c    
    INNER JOIN WFInstance i ON c.WFConfigId=i.WFConfigId    
    INNER JOIN WFRequest r ON r.WFRequestId=i.WFRequestId     
 outer Apply (  
    SELECT r.RecordId FROM WFConfig c INNER JOIN WFInstance i ON c.WFConfigId=i.WFConfigId    
 INNER JOIN WFRequest r ON r.WFRequestId=i.WFRequestId WHERE approverid=@approverId  OR approverid IN (SELECT fkgroupid FROM aspmnx_groupUsers WHERE fkuserid=@approverId)) AI  
    WHERE (c.StepNumber IN (SELECT CASE WHEN stepnumber > 1 THEN stepnumber-1 ELSE stepnumber END stepnumber   
        FROM WFConfig WHERE approverid=@approverId  
        OR approverid IN (SELECT fkgroupid FROM aspmnx_groupUsers WHERE fkuserid=@approverId)) AND r.RecordId =AI.RecordId)) as IsApproved  
  
  
  SELECT @firstApprover=CASE WHEN @wfconfigCount=(SELECT COUNT(Wfinstanceid) FROM WFInstance   
          WHERE wfrequestid IN (SELECT WFRequestId FROM #wfConfigDetail WHERE stepnumber>1)) OR (SELECT Count(*) FROM #wfConfigDetail) = 0 Then 0 else 1 end  
  
  SELECT DISTINCT r.RecordId    
   ,RTRIM(m.MetaDataName)+' '+'('+r.RecordId+')' AS ModuleName     
   ,m.MetaDataName AS BaseModule    
   ,a.FirstName +' '+ a.LastName AS ApproverInit     
   ,r.RequestDate     
   ,c.StepNumber AS ApproveStep     
   ,c.IsAll     
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
  INNER JOIN WFConfig c ON c.WFConfigId = i.WFConfigId    
  INNER JOIN MnxWFMetaData m ON m.MetaDataId = c.MetaDataId    
  INNER JOIN aspnet_Profile a ON a.UserId=r.RequestorId 
  -- 05/11/2020 Shiv P : Addeed Join with POMAIN table 
  -- 07/08/2020 Satyawan H : Removed Join with POMAIN table
  -- INNER JOIN POMAIN p ON p.PONUM=r.RecordId       
   WHERE (c.ApproverId =@approverId OR c.ApproverId IN (SELECT fkGroupId FROM aspmnx_groupUsers WHERE fkuserid=@approverId))    
     AND   (r.RecordId IN(SELECT RecordId FROM #wfConfigDetail WHERE ISapproved=1)   
  OR  r.RecordId NOT IN(SELECT RecordId FROM #wfConfigDetail) OR c.stepNumber=1)  
     AND i.RejectToStep IS NULL    
     AND i.Approver=@approverId     
     AND r.WFComplete=0     
     AND i.IsApproved=0   
  -- 07/08/2020 Satyawan H : Removed condition of is Approval with POMAIN
  -- AND p.IsApproveProcess=1   
  ORDER BY r.RecordId     
END    