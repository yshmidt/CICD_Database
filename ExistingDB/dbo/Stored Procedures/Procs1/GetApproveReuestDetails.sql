-- =============================================      
-- Author:Satish B      
-- Create date: 08/28/2018      
-- Description : Get approve request list details      
-- Modified 12/24/2018 Satish B: Add new Parameter  @approverId uniqueidentifier = null      
-- Modified 12/24/2018 Satish B: Add new filter i.Approver =@approverId      
-- Modified 02/04/2019 Satish B:Change join filter  a.UserId=i.Approver to a.UserId=r.RequestorId      
-- Modified 02/25/2019 Satish B:Add additional filter condtion for group      
-- Modified 02/25/2019 Satish B:Add additional parameter (@IsGroup)      
-- Modified 05/22/2019 Satish B:Removed condition (w.IsAll=1) from case      
-- Modified 06/14/2019 Satish B:Added additional parameter ,@wfConfigId VARCHAR(15) = null      
-- Modified 06/14/2019 Satish B:Added filter fetch record against wfConfigId      
-- Modified 11/26/2019 Vijay G :Modified size of parameter from @recordId char(15) to @recordId char(20)   
-- 05/11/2020 Shiv P : Addeed Join with POMAIN table   
-- 07/07/2020 Sachin B: Remove the Wrong Join with POMain Table 
-- 09/08/2020 Sachin B: Remove and Condition AND i.Approver = @Approver 
-- exec GetApproveReuestDetails 'dc77b909-9b1c-4d71-9373-5ef085ded1ea','25','T00000000001852',1,100,0      
-- =============================================      
CREATE PROCEDURE GetApproveReuestDetails      
-- 12/24/2018 Satish B: Add new Parameter  @approverId uniqueidentifier = null      
  @approverId uniqueidentifier = null      
 ,@moduleId int = null      
 ,@recordId char(20) = null  -- Modified 11/26/2019 Vijay G :Modified size of parameter from @recordId char(15) to @recordId char(20)    
 ,@wfConfigId VARCHAR(15) = null      
 ,@Approver nvarchar(40) = null      
 ,@isNotSummary bit = 0      
 --02/25/2019 Satish B:Add additional parameter (@IsGroup)      
 ,@IsGroup bit = 0      
 ,@startRecord int =1      
 ,@endRecord int =10       
 ,@outTotalNumberOfRecord int OUTPUT      
 AS      
 BEGIN      
      
  SET NOCOUNT ON  
      
   SELECT COUNT(w.WFConfigId) AS RowCnt -- Get total counts       
   INTO #tempApproveList      
   FROM WFConfig w       
    INNER JOIN WFHeader h ON h.WFid=w.WFid      
    INNER JOIN MnxWFMetaData m ON m.MetaDataId=w.MetaDataId      
    INNER JOIN WFInstance i ON i.WFConfigId=w.WFConfigId      
    INNER JOIN WFRequest r ON r.WFRequestId=i.WFRequestId      
    INNER JOIN aspnet_Profile a ON a.UserId=i.Approver         
   WHERE h.ModuleId=@moduleId AND r.RecordId=@recordId      
   --12/24/2018 Satish B: Add new filter i.Approver =@approverId      
   AND ((@isNotSummary <> 1 AND i.Approver=@approverId) OR (r.requestorid=@approverId))      
      
  SELECT DISTINCT       
    w.WFConfigId      
   ,w.ConfigName       
   ,w.StepNumber      
   ,w.StartValue      
   ,w.EndValue      
   ,w.IsAll      
   ,w.IsGroup      
   ,w.OperatorType AS Condition      
      -- 05/22/2019 Satish B:Removed condition (w.IsAll=1) from case      
   ,CASE WHEN w.IsGroup=1 THEN i.Approver ELSE w.ApproverId END AS ApproverId      
   ,i.ActionDate      
   ,i.IsApproved      
   ,CASE WHEn w.IsGroup=1 THEN 'Group' ELSE 'Person' END AS Approver       
   ,m.MetaDataName      
   ,m.MetaDataId      
   ,CASE WHEN i.IsApproved=0 AND i.RejectToStep IS NULL THEN 'Pending'       
     ELSE       
    CASE WHEN i.IsApproved=1 THEN 'Approved' ELSE 'Rejected' END      
     END AS [Status]      
   ,CASE WHEN w.IsAll=1 AND w.IsGroup=1 THEN 'All'       
     ELSE       
    CASE WHEN w.IsAll=0 AND w.IsGroup=1 THEN 'Any'  ELSE '' END      
     END AS RequiresAllsApproval         
  ,a.FirstName +' '+ a.LastName AS RequestorName       
  ,i.RejectToStep      
  ,r.WFRequestId      
  FROM WFConfig w       
   INNER JOIN WFHeader h ON h.WFid=w.WFid      
   INNER JOIN MnxWFMetaData m ON m.MetaDataId=w.MetaDataId      
   INNER JOIN WFInstance i ON i.WFConfigId=w.WFConfigId      
   INNER JOIN WFRequest r ON r.WFRequestId=i.WFRequestId   
   -- 05/11/2020 Shiv P : Addeed Join with POMAIN table   
   -- 07/07/2020 Sachin B: Remove the Wrong Join with POMain Table  
   --INNER JOIN POMAIN p ON p.PONUM=r.RecordId     
   INNER JOIN aspnet_Profile a ON a.UserId=r.RequestorId -- 02/04/2019 Satish B:Change join filter  a.UserId=i.Approver to a.UserId=r.RequestorId      
   WHERE h.ModuleId=@moduleId        
   AND r.RecordId=@recordId       
      -- 06/14/2019 Satish B:Added filter fetch record against wfConfigId      
   AND (@wfConfigId='' OR @wfConfigId=NULL OR i.WFConfigId=@wfConfigId)      
     --AND i.RejectToStep = NULL      
     --12/24/2018 Satish B: Add new filter i.Approver =@approverId      
   AND (
			 (@isNotSummary <> 1 AND (i.Approver=@approverId OR i.Approver IN (SELECT fkGroupId FROM aspmnx_groupUsers WHERE fkuserid=@approverId))) 
			 -- 09/08/2020 Sachin B: Remove and Condition AND i.Approver = @Approver       
          OR (@isNotSummary = 1 AND r.requestorid=@approverId) --AND i.Approver = @Approver     
              --02/25/2019 Satish B:Add additional filter condtion for group      
          OR (@isNotSummary = 1 AND @IsGroup=1 AND (w.ApproverId =@Approver))
		 )--IN (SELECT fkGroupId FROM aspmnx_groupUsers WHERE fkuserid=@Approver))))      
   AND ((w.IsGroup=0 OR (w.IsAll=0 AND w.IsGroup=1)) OR (w.IsAll=1 AND w.IsGroup=1))      
  --AND p.IsApproveProcess=1  
  ORDER BY w.StepNumber        
  OFFSET(@startRecord-1) ROWS      
  FETCH NEXT @EndRecord ROWS ONLY;      
      
  SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempApproveList) -- Set total count to Out parameter       
END      
      