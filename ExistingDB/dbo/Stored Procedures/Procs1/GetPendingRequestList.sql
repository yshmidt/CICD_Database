-- =============================================        
-- Author:Satish B        
-- Create date: 08/31/2018        
-- Description : Get pending list        
-- 06/12/2019 Remove lines from selection       
 -- 07/10/2019 Vijay G : Add extra filter condition to  avoid rejected record     
-- 09/08/2020 Sachin B : Added And Condition in Where clause i.IsApproved = 0  
-- 09/14/2020 Sachin B : Add logic for the Show only Cuurent Pending Request in My Request Pending section  
-- exec GetPendingRequestList '1520c898-b5e0-4bac-8652-5e704f21f3e9',1,100,0        
-- =============================================        
CREATE PROCEDURE GetPendingRequestList        
  @approverId uniqueidentifier = null        
 ,@startRecord int =1        
    ,@endRecord int =10         
 ,@outTotalNumberOfRecord int OUTPUT        
 AS        
 BEGIN        
  SET NOCOUNT ON          
     
   SELECT COUNT(r.RecordId) AS RowCnt -- Get total counts         
   INTO #tempApproveList        
   FROM WFRequest r        
   INNER JOIN WFInstance i ON i.WFRequestId =r.WFRequestId        
   INNER JOIN WFConfig c ON c.WFConfigId = i.WFConfigId        
   INNER JOIN MnxWFMetaData m ON m.MetaDataId = c.MetaDataId        
   LEFT JOIN aspnet_Profile a ON a.UserId=r.RequestorId        
   LEFT JOIN aspnet_Profile p ON p.UserId=c.ApproverId        
   LEFT JOIN aspmnx_Groups u ON u.groupId=c.ApproverId    
   -- 09/08/2020 Sachin B : Added And Condition in Where clause i.IsApproved = 0       
   WHERE r.RequestorId =@approverId  AND r.WFComplete=0 AND i.IsApproved = 0
        
  SELECT wfrequestid         
  INTO #groupDatails        
  FROM   
  (         
  SELECT distinct wfrequestid,RejectToStep FROM WFInstance GROUP BY wfrequestid,RejectToStep  
  ) AS Instant GROUP BY wfrequestid HAVING COUNT(1)>1     
    
  -- 09/14/2020 Sachin B : Add logic for the Show only Cuurent Pending Request in My Request Pending section
  SELECT *         
  INTO #configDatails        
  FROM   
  (         	  
		SELECT child.WFInstanceId 
		FROM WFInstance parent
		INNER JOIN 
		(
				 SELECT i.WFInstanceId, 
						ROW_NUMBER() over (PARTITION BY r.WFRequestId ORDER BY c.stepNumber) AS rn
				 FROM WFRequest r
				 INNER JOIN WFInstance i ON r.WFRequestId = i.WFRequestId
				 INNER JOIN WFConfig c ON c.WFConfigId =i.WFConfigId 
				 WHERE i.IsApproved =0 AND r.RequestorId = @approverId 
		) AS child 
		ON parent.WFInstanceId = child.WFInstanceId AND child.rn = 1 
  ) AS Instant   
          
  SELECT DISTINCT r.RecordId        
   , RTRIM(m.MetaDataName)+' '+'('+r.RecordId+')' AS SubmitedFor         
   ,a.FirstName +' '+ a.LastName AS OrigionalRequestor         
   ,ISNULL(p.FirstName +' '+p.LastName,u.groupName) AS NextApprover        
   ,r.RequestDate         
   ,c.StepNumber AS ApproveStep         
   ,c.IsAll         
   ,c.IsGroup        
   ,c.ApproverId        
   ,r.ModuleId        
-- 06/12/2019 Remove lines from selection         
   --,CASE WHEN i.IsApproved=0 AND i.RejectToStep IS NULL THEN 'Pending'         
   -- ELSE         
   --CASE WHEN i.IsApproved=1 THEN 'Approved' ELSE 'Rejected' END        
   -- END AS [Status]        
        
  FROM WFRequest r        
  INNER JOIN WFInstance i ON i.WFRequestId =r.WFRequestId        
  INNER JOIN WFConfig c ON c.WFConfigId = i.WFConfigId
  -- 09/14/2020 Sachin B : Add logic for the Show only Cuurent Pending Request in My Request Pending section   
  INNER JOIN #configDatails con ON i.WFInstanceId = con.WFInstanceId       
  INNER JOIN MnxWFMetaData m ON m.MetaDataId = c.MetaDataId        
  LEFT JOIN aspnet_Profile a ON a.UserId=r.RequestorId        
  LEFT JOIN aspnet_Profile p ON p.UserId=c.ApproverId        
  LEFT JOIN aspmnx_Groups u ON u.groupId=c.ApproverId   
    
  -- 09/08/2020 Sachin B : Added And Condition in Where clause i.IsApproved = 0        
  WHERE r.RequestorId =@approverId AND r.WFComplete=0 AND i.IsApproved = 0   
     AND ((i.wfrequestid NOT IN (SELECT wfrequestid FROM #groupDatails) OR ((i.wfrequestid IN (SELECT wfrequestid FROM #groupDatails)) AND i.IsApproved = 1) OR c.stepNumber=1))        
  -- 07/10/2019 Vijay G : Add extra filter condition to  avoid rejected record       
     AND i.RejectToStep IS NULL        
  ORDER BY c.StepNumber          
  OFFSET(@startRecord-1) ROWS        
  FETCH NEXT @EndRecord ROWS ONLY;        
        
  SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempApproveList) -- Set total count to Out parameter         
END        