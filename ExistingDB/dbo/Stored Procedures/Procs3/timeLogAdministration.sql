-- =============================================  
-- Author:  Mahesh B
-- Create date: 02/04/2020
-- Description: get a list of all time records over the last x days  
-- timeLogAdministration '05-01-2019 18:56:44','05-03-2020 18:56:44',null,1
-- =============================================  
CREATE PROCEDURE [dbo].[timeLogAdministration]   
 @dateIn DATETIME = NULL,   
 @dateOut DATETIME = NULL,   
 @userId UNIQUEIDENTIFIER = NULL,   
 @isDelete BIT = 0,
 @gridId VARCHAR(50) = NULL  
AS  
BEGIN  

 SET NOCOUNT ON;  
    -- Insert statements for procedure here  
    IF @userId IS NULL  
    BEGIN  
     ;WITH timeLogFullLog AS(
      SELECT OriginalDateIn,DATE_IN AS InDate,au.UserName AS InInit,OriginalDateOut,DATE_OUT AS OutDate
			 ,au.UserName OutInit,(TIME_USED / 60) AS [Hours],WONO,DEPT_ID AS WC,TMLOGTP.TMLOG_DESC  AS [Type] ,DEPT_CUR.TMLOGTPUK
			 ,UNIQLOGIN,OVERTIME AS OT,comment,uDeleted AS Deleted,TMLOGTP.ALLOWENTERHOUR,CAST(NULL AS DATETIME) AS LastUpdateDate
			 ,N'' AS LastUpdatedBy
       FROM DEPT_CUR   
       INNER JOIN  TMLOGTP ON DEPT_CUR.TMLOGTPUK = TMLOGTP.TMLOGTPUK 
	   INNER JOIN aspnet_Users au ON au.userId = DEPT_CUR.inUserId
       WHERE 
			 ((CAST(OriginalDateIn AS DATE) BETWEEN CAST(@dateIn AS DATE)  AND CAST(@dateOut AS DATE)) AND (CAST(OriginalDateOut AS DATE) BETWEEN CAST(@dateIn AS DATE) AND CAST(@dateOut AS DATE)))
			 AND ((@isDelete=1 AND 1=1) OR (@isDelete=0 AND DEPT_CUR.uDeleted = 0)) 
			 AND TMLOGTP.TMLOGTPUK IN (SELECT TMLOGTPUK FROM TMLOGTP WHERE IsWorkOrder = 0)
       UNION ALL  
       SELECT	 OriginalDateIn,DATE_IN AS InDate
				,au.UserName AS InInit
				,OriginalDateOut,DATE_OUT AS OutDate
				,au.UserName OutInit
				--,(TIME_USED / 60) AS [Hours]
				,CASE WHEN ModTimeUsed > 0 THEN CAST((ModTimeUsed /60)  AS NUMERIC(10,2))
						  ELSE CAST((TIME_USED/60)  AS NUMERIC(10,2)) END AS [Hours]
				,WONO,DEPT_ID AS WC
				,TMLOGTP.TMLOG_DESC AS [Type] 
				,DEPT_LGT.TMLOGTPUK
				,UNIQLOGIN,OVERTIME AS OT
				,comment,uDeleted AS Deleted
				,TMLOGTP.ALLOWENTERHOUR
				,CAST(LastUpdatedDate AS DATETIME) AS LastUpdateDate
				,updateBy.UserName AS LastUpdatedBy
       FROM DEPT_LGT   
       INNER JOIN TMLOGTP ON DEPT_LGT.TMLOGTPUK = TMLOGTP.TMLOGTPUK
	   INNER JOIN aspnet_Users au ON au.userId = DEPT_LGT.inUserId
	   OUTER APPLY
	   (
			SELECT UserName FROM aspnet_Users WHERE UserId = DEPT_LGT.LastUpdatedBy
	   )AS updateBy
       WHERE 
	        ((CAST(OriginalDateIn AS DATE) BETWEEN CAST(@dateIn AS DATE)  AND CAST(@dateOut AS DATE)) AND (CAST(OriginalDateOut AS DATE) BETWEEN CAST(@dateIn AS DATE) AND CAST(@dateOut AS DATE))  
			OR ((DATE_IN IS NULL AND DATE_OUT IS NULL) AND ( CAST(LastUpdatedDate AS DATE) BETWEEN  CAST(@dateIn AS DATE) AND  CAST(@dateOut AS DATE))))
			AND ((@isDelete=1 AND 1=1) OR (@isDelete=0 AND DEPT_LGT.uDeleted = 0)) 
			AND TMLOGTP.TMLOGTPUK IN (SELECT TMLOGTPUK FROM TMLOGTP WHERE IsWorkOrder = 0)
	   )  
    
       SELECT * FROM timeLogFullLog ORDER BY InDate DESC;
    END  
    ELSE  
    BEGIN  
      ;WITH timeLogFullLog AS (
       SELECT OriginalDateIn,DATE_IN AS InDate,au.UserName AS InInit,OriginalDateOut,DATE_OUT AS OutDate
			 ,au.UserName OutInit,(TIME_USED / 60) AS [Hours],WONO,DEPT_ID AS WC,TMLOGTP.TMLOG_DESC  AS [Type] ,DEPT_CUR.TMLOGTPUK
			 ,UNIQLOGIN,OVERTIME AS OT,comment,uDeleted AS Deleted,TMLOGTP.ALLOWENTERHOUR,CAST(NULL AS DATETIME) AS LastUpdateDate
			 ,N'' AS LastUpdatedBy

       FROM DEPT_CUR   
       INNER JOIN TMLOGTP ON DEPT_CUR.TMLOGTPUK = TMLOGTP.TMLOGTPUK 
	   INNER JOIN aspnet_Users au ON au.userId = DEPT_CUR.inUserId
       WHERE inUserId = @userId AND OriginalDateIn >= @dateIn AND OriginalDateOut <= @dateOut AND uDeleted = @isDelete 
      UNION ALL  
      SELECT OriginalDateIn,DATE_IN AS InDate
			,au.UserName AS InInit
			,OriginalDateOut,DATE_OUT AS OutDate
			,au.UserName OutInit
			--,(TIME_USED / 60) AS [Hours]
			,CASE WHEN ModTimeUsed > 0 THEN CAST((ModTimeUsed /60)  AS NUMERIC(10,2))
						  ELSE CAST((TIME_USED/60)  AS NUMERIC(10,2)) END AS [Hours]
			,WONO,DEPT_ID AS WC
			,TMLOGTP.TMLOG_DESC AS [Type] 
			,DEPT_LGT.TMLOGTPUK
			,UNIQLOGIN,OVERTIME AS OT
			,comment,uDeleted AS Deleted
			,TMLOGTP.ALLOWENTERHOUR
			,CAST(LastUpdatedDate AS DATETIME) AS LastUpdateDate
			,updateBy.UserName AS LastUpdatedBy
       FROM DEPT_LGT   
       INNER JOIN TMLOGTP ON DEPT_LGT.TMLOGTPUK = TMLOGTP.TMLOGTPUK
	   INNER JOIN aspnet_Users au ON au.userId = DEPT_LGT.inUserId
	   OUTER APPLY
	   (
			SELECT UserName FROM aspnet_Users WHERE UserId = DEPT_LGT.LastUpdatedBy
	   )AS updateBy
        WHERE inUserId = @userId   
		AND ((CAST(OriginalDateIn AS DATE) BETWEEN CAST(@dateIn AS DATE)  AND CAST(@dateOut AS DATE)) AND (CAST(OriginalDateOut AS DATE) BETWEEN CAST(@dateIn AS DATE) AND CAST(@dateOut AS DATE))  
		OR ((DATE_IN IS NULL AND DATE_OUT IS NULL) AND ( CAST(LastUpdatedDate AS DATE) BETWEEN  CAST(@dateIn AS DATE) AND  CAST(@dateOut AS DATE))))  
		AND  ((@isDelete=1 AND 1=1) OR (@isDelete=0 AND DEPT_LGT.uDeleted = 0))  
		AND TMLOGTP.TMLOGTPUK IN (SELECT TMLOGTPUK FROM TMLOGTP WHERE IsWorkOrder = 0)
      )  
      SELECT * FROM timeLogFullLog ORDER BY InDate DESC; 
    END  
END