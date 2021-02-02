-- =============================================
-- Author:		Nitesh B	
-- Create date: <31/07/2018>
-- Description:	Get Employee Logging history
-- Modifications 
  -- 05/16/2018 Nitesh B : Select uDeleted from DEPT_LGT table
  -- 05/20/2018 Nitesh B : Declare parameters @inMinutes and @outMinutes used in where conditions 
  -- 05/20/2018 Nitesh B : Replaced originalDateIn by DATE_IN and originalDateOut with DATE_OUT for all instances
  -- 05/20/2018 Nitesh B : Removed RT and OT from select list
  -- 05/20/2018 Nitesh B : Changed logic for TotalTime
  -- 05/16/2018 : Nitesh B : Changed logic for Where condition
-- [dbo].[GetEmployeeLoggingDetails] '681F01DC-4459-4586-B5DD-0067C6070AA2',GETDATE(),GETDATE()

CREATE PROCEDURE [dbo].[GetEmployeeLoggingDetails]
(
@userId UNIQUEIDENTIFIER=NULL,
@fromDateTime AS SMALLDATETIME =NULL
)
AS
BEGIN
	SET NOCOUNT ON
	    -- 05/20/2018 Nitesh B : Declare parameters @inMinutes and @outMinutes used in where conditions 
	    DECLARE @inMINUTES DECIMAL(10,4),@outMINUTES DECIMAL(10,4)
		SELECT @inMINUTES = (DHR_STRT *60) + (DMIN_STRT) FROM aspnet_Profile AP LEFT JOIN WRKSHIFT W ON AP.shift_no = W.SHIFT_NO WHERE AP.UserId = @userId
		SELECT @outMINUTES = (DHR_END *60) + (DMIN_END) FROM aspnet_Profile AP LEFT JOIN WRKSHIFT W ON AP.shift_no = W.SHIFT_NO WHERE AP.UserId = @userId

		-- 05/20/2018 Nitesh B : Replaced originalDateIn by DATE_IN and originalDateOut with DATE_OUT for all instances
		SELECT DISTINCT ROW_NUMBER() OVER(ORDER BY DATE_IN DESC) AS RowNumber
					   ,DATEADD(MINUTE,@outMINUTES,CAST(CAST(@fromDateTime AS DATE) AS DATETIME))
					   ,DL.UNIQLOGIN AS UniqLogin
					   ,DL.TMLOGTPUK AS TMLogUniq
					   ,TG.TMLOG_DESC AS LogType
					   ,DL.DEPT_ID AS WorkCenter
		               ,AP.Userid
			 		   ,DATE_IN AS DateIn
					   ,DATE_OUT AS DateOut
					   ,FORMAT(DATE_IN,'MM/dd/yyyy hh:mm tt') AS InDate
					   ,FORMAT(DATE_OUT,'MM/dd/yyyy hh:mm tt') AS OutDate
					   -- 05/20/2018 Nitesh B : Removed RT and OT from select list
					   ,CAST( (DATEDIFF(MINUTE,DATE_IN,DATE_OUT)) /60 AS VARCHAR(5))+ ':'+ 
					    RIGHT('0' + CAST( (DATEDIFF(MINUTE,DATE_IN,DATE_OUT)) %60 AS VARCHAR(2)), 2) AS TotalTime -- 05/20/2018 Nitesh B : Changed logic for TotalTime
					   ,APL.Initials AS EditedBy
					   ,DL.Comment AS Note
					   -- 05/16/2018 : Nitesh B : Select uDeleted from DEPT_LGT table
					   ,DL.uDeleted AS IsDeleted
		FROM DEPT_LGT DL  INNER JOIN aspnet_Profile AP ON  DL.inUserId = AP.UserId --AND DL.dept_id = AP.dept_id 
						  LEFT JOIN TMLOGTP TG ON DL.TMLOGTPUK = TG.TMLOGTPUK
						  LEFT JOIN aspnet_Profile APL ON DL.LastUpdatedBy = APL.UserId
	    WHERE DL.InUserId = @userId -- 05/16/2018 : Nitesh B : Changed logic for Where condition
		      AND DATE_OUT > DATEADD(MINUTE,@inMINUTES,CAST(CAST(@fromDateTime AS DATE) AS DATETIME))
			  AND DATE_OUT < DATEADD(MINUTE,@inMINUTES,CAST(CAST((DATEADD(DAY,1,@fromDateTime)) AS DATE) AS DATETIME))
		ORDER BY DATE_IN
END