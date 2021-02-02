-- =============================================
-- Author:		Nitesh B	
-- Create date: <03/07/2018>
-- Description:	Get WorkCenter data
-- Modifications : 05/28/2018 Nitesh : Added Where condition
--				 : 05/31/2018 Nitesh : Added parameters @deptId and @isDept
--				 : 05/31/2018 Nitesh : Added filter of dept_id from aspnet_profile table
-- [dbo].[GetTMWorkCenterData] GETDATE(),GETDATE()

CREATE PROCEDURE [dbo].[GetTMWorkCenterData]
(
@fromDateTime AS SMALLDATETIME =NULL,
@toDateTime AS SMALLDATETIME = NULL,
--05/31/2018 Nitesh : Added parameters @deptId and @isDept
@deptId AS CHAR = '',
@isDept BIT = 0
)
AS
BEGIN
	SET NOCOUNT ON
	  SELECT CASE WHEN  AP.DEPT_ID IS NULL OR AP.DEPT_ID = '' THEN AP.Department ELSE AP.DEPT_ID END AS WorkCenter
	  ,COUNT(1) AS Employee
	  ,'1/2' AS ActVSStd
	  ,1 AS Act
	  ,1 AS Std
	  ,CAST(0 AS BIT) AS Released 
	  FROM aspnet_Profile AP LEFT JOIN DEPT_LGT DL ON AP.UserId = DL.inUserId
	  -- 05/28/2018 Nitesh : Added Where condition
	  WHERE FORMAT(DATE_IN,'MM/dd/yyyy') >= FORMAT(@fromDateTime,'MM/dd/yyyy') 
			AND FORMAT(DATE_OUT,'MM/dd/yyyy') <= FORMAT(@toDateTime,'MM/dd/yyyy')
			--05/31/2018 Nitesh : Added filter of dept_id from aspnet_profile table
			AND (@isDept = 0 OR AP.dept_id=@deptId)		
	  GROUP BY CASE WHEN  AP.DEPT_ID IS NULL OR AP.DEPT_ID = '' THEN AP.Department ELSE AP.DEPT_ID END
END