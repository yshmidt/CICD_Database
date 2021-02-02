
-- =============================================  
-- Author: Shivshankar Patil   
-- Create date: <03/15/16>  
-- Description: <Get Approver Details>   
-- =============================================  
CREATE PROCEDURE [GetApproverDetail]
@moduleId INT=0,
@userId UNIQUEIDENTIFIER=null,
@isApproved BIT = 0

AS 
BEGIN
    SET NOCOUNT ON;

	DECLARE @currentStepNo INT =0
	SELECT @currentStepNo =StepNumber FROM WFConfig JOIN WFHeader ON WFConfig.WFid = WFHeader.WFid 
	JOIN WFINSTANCE ON  WFConfig.WFConfigId = WFInstance.WFConfigId
	WHERE WFHeader.ModuleId = @moduleId AND  ApproverId = @userId

	IF(@isApproved=0)
	BEGIN
			SELECT  StepNumber, ModuleId,IsApproved,ApproverId ,ModuleName ,RequestDate,totalStep AS ApproveStep ,ApproverInit
			FROM (
				SELECT WFInstance.IsApproved,WFHeader.ModuleId,ApproverId,MNXMODULE.ModuleName,WFREQUEST.RequestDate, WFRequest.RequestorId,

					   CASE WHEN IsGroup =1 THEN  AspMnx_Groups.groupName ELSE  RTRIM(asp.FirstName) + ' '  +  LTRIM(asp.LastName) END ApproverInit ,
				 CAST(StepNumber AS  VARCHAR(200))  + ' Step of ' +  CAST(WFConfigDt.totalStep  AS  VARCHAR(200)) AS totalStep,  
					   StepNumber
				FROM WFConfig  JOIN WFHeader  ON WFConfig.WFid = WFHeader.WFid 
					JOIN WFInstance ON  WFConfig.WFConfigId = WFInstance.WFConfigId
					JOIN WFRequest ON  WFRequest.ModuleId = WFHeader.ModuleId 
					JOIN MNXMODULE ON WFHEADER.MODULEID = MNXMODULE.MODULEID
					LEFT JOIN  ASPNET_PROFILE ON  WFCONFIG.APPROVERID =  ASPNET_PROFILE.USERID
					LEFT JOIN  AspMnx_Groups ON  WFCONFIG.APPROVERID =  AspMnx_Groups.groupId
					LEFT JOIN  ASPNET_PROFILE  asp ON  asp.UserId =  WFRequest.RequestorId
					OUTER APPLY (SELECT COUNT(WFConfigId) AS totalStep FROM   WFHeader JOIN WFConfig ON WFConfig.WFid = WFHeader.WFid) WFConfigDt
			) AS t
			WHERE
			 RequestorId = @userId  AND IsApproved =0;
       END

	 ELSE 
	   BEGIN
		SELECT prev_word, StepNumber, next_word,ModuleId,IsApproved,ApproverId ,ModuleName ,RequestDate,totalStep AS ApproveStep ,ApproverInit
		FROM (
			SELECT WFInstance.IsApproved,WFHeader.ModuleId,ApproverId,MNXMODULE.ModuleName,WFREQUEST.RequestDate,
			 CASE WHEN IsGroup =1 THEN  AspMnx_Groups.groupName ELSE  RTRIM(asp.FirstName) + ' '  +  LTRIM(asp.LastName) END ApproverInit ,
			 CAST(@currentStepNo - 1 AS  VARCHAR(200))  + ' Step of ' +  CAST(WFConfigDt.totalStep  AS  VARCHAR(200)) AS totalStep,  
				   lag(StepNumber) OVER (ORDER BY StepNumber) AS prev_word,
				   StepNumber,
				   lead(StepNumber) OVER (ORDER BY StepNumber) AS next_word
			FROM WFConfig  JOIN WFHeader  ON WFConfig.WFid = WFHeader.WFid 
				JOIN WFInstance ON  WFConfig.WFConfigId = WFInstance.WFConfigId
				JOIN WFRequest ON  WFRequest.ModuleId = WFHeader.ModuleId 
				JOIN MNXMODULE ON WFHEADER.MODULEID = MNXMODULE.MODULEID
				LEFT JOIN  ASPNET_PROFILE ON  WFCONFIG.APPROVERID =  ASPNET_PROFILE.USERID
				LEFT JOIN  AspMnx_Groups ON  WFCONFIG.APPROVERID =  AspMnx_Groups.groupId
				LEFT JOIN  ASPNET_PROFILE  asp ON  asp.UserId =  WFRequest.RequestorId
				OUTER APPLY (SELECT COUNT(WFConfigId) AS totalStep FROM   WFHeader JOIN WFConfig ON WFConfig.WFid = WFHeader.WFid) WFConfigDt
		) AS t
		WHERE ModuleId = @moduleId AND  ((StepNumber = @currentStepNo - 1 AND IsApproved=1 AND StepNumber <> @currentStepNo - 1 ) OR (IsApproved =0)) 
		AND  ApproverId = @userId
	END


END