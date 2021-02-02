-- =============================================    
-- Author:  Satish B    
-- Create date: <03/14/2018>    
-- Description: Get work center details    
-- 12-13-2019 : MaheshB : Added LogType column    
-- 01-09-2020 : MaheshB :  Added changes for fetch only non deleted records 
-- 01-31-2020 : MaheshB :  Added changes for set the Employee Name
-- 02-12-2020 : MaheshB :  Added changes for set the Edited By username  
-- 03-03-2020 : Rajendra K : Added new parameters start date & end date
-- [dbo].[GetWorkOrderAssemblyDetails] '0000010200','_1LR0NALBN','GHT',1,500,0
-- =============================================    
CREATE PROCEDURE GetWorkOrderAssemblyDetails    
 @woNo CHAR(10)='',    
 @uniqKey CHAR(10)='',    
 @deptId CHAR(10)='',    
 @startRecord INT =1,    
 @endRecord INT =10,
 @outTotalNumberOfRecord INT OUTPUT,
 @startDate DATETIME = NULL,
 @endDate DATETIME = NULL

AS    
BEGIN    
 SET NOCOUNT ON    
 SELECT COUNT(dl.WONO) AS RowCnt -- Get total counts     
    INTO #tempWoLogDetailData    
 FROM DEPTS d       
 INNER JOIN DEPT_LGT dl ON dl.DEPT_ID=d.DEPT_ID    
 INNER JOIN WOENTRY w ON w.wono=dl.wono    
 INNER JOIN INVENTOR i ON i.uniq_key=w.uniq_key    
 -- MaheshB 12-13-2019 Added LogType column    
 LEFT JOIN TmLogTp l ON l.TMLOGTPUK=dl.TMLOGTPUK    
 INNER JOIN Aspnet_Profile p ON p.UserId=dl.InUserId    
 WHERE dl.WONO=@woNo    
   AND i.Uniq_Key=@uniqKey     
   AND d.DEPT_ID= @deptId    
 GROUP BY     
    i.UNIQ_KEY
   ,dl.WONO
   ,d.DEPT_ID
   ,dl.DATE_IN
   ,dl.DATE_OUT   
   ,l.TMLOG_DESC
   ,p.FirstName
   ,dl.UniqLogin
   ,l.ALLOWENTERHOUR
     
 SELECT d.DEPT_ID AS WorkCenter     
     ,i.uniq_Key AS UniqKey    
     ,dbo.fRemoveLeadingZeros(dl.WONO) AS WorkOrder    
     ,dl.DATE_IN AS InDate    
     ,dl.DATE_OUT AS OutDate    
     ,l.TMLOG_DESC AS LogType     
	 ,SUM(CASE WHEN ModTimeUsed > 0 THEN CAST((ModTimeUsed /60)  AS NUMERIC(10,2))
			   ELSE CAST((TIME_USED/60)  AS NUMERIC(10,2)) END) AS Hours
     ,empName.UserName AS EmpName    
     ,EditedBy.UserName AS EditedBy      
     ,dl.UniqLogin    
	 ,dl.TIME_USED  
	 ,dl.ModTimeUsed  
	 ,l.ALLOWENTERHOUR  
 FROM DEPTS d       
 INNER JOIN DEPT_LGT dl ON dl.DEPT_ID=d.DEPT_ID    
 INNER JOIN WOENTRY w ON w.wono=dl.wono    
 INNER JOIN INVENTOR i ON i.uniq_key=w.uniq_key    
 LEFT JOIN TmLogTp l ON l.TMLOGTPUK=dl.TMLOGTPUK    
 OUTER APPLY
 (
	SELECT UserName FROM aspnet_Users WHERE UserId = dl.inUserId
 )AS empName -- 01-31-2020 :Added changes for set the Employee Name
  OUTER APPLY  
 (  
 SELECT UserName FROM aspnet_Users WHERE UserId = dl.LastUpdatedBy  
 )AS EditedBy -- 02-12-2020 : MaheshB : Added changes for set the Edited By username  
 WHERE 
    -- 03-03-2020 : Rajendra K : Added new parameters start date & end date
   ((((@startDate IS NULL AND 1=1) AND (@endDate IS NULL AND 1=1)) OR (@startDate IS NOT NULL AND  dl.originalDateIn >= CAST(@startDate AS DATETIME)))
   OR ((DATE_IN IS NULL AND DATE_OUT IS NULL) AND ( CAST(LastUpdatedDate AS DATE) BETWEEN  CAST(@startDate AS DATE) AND  CAST(@endDate AS DATE))))
   AND dl.WONO=@woNo
   AND i.Uniq_Key=@uniqKey
   AND d.DEPT_ID= @deptId
   AND dl.uDeleted = 0 -- 01-09-2020 : MaheshB :  Added changes for fetch only non deleted records
 GROUP BY
    i.UNIQ_KEY
   ,dl.WONO  
   ,d.DEPT_ID
   ,dl.DATE_IN
   ,dl.DATE_OUT
   ,l.TMLOG_DESC
   ,EditedBy.UserName
   ,dl.UniqLogin
   ,dl.originalDateIn  
   ,dl.originalDateOut
   ,dl.TIME_USED
   ,dl.ModTimeUsed
   ,l.ALLOWENTERHOUR
   ,empName.UserName
 ORDER BY dl.WONO DESC
 OFFSET(@startRecord-1) ROWS
 FETCH NEXT @EndRecord ROWS ONLY;
    
 SET @outTotalNumberOfRecord = (SELECT COUNT(RowCnt) FROM #tempWoLogDetailData)
END 