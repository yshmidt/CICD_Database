-- =============================================
-- Author:		Rajendra K	
-- Create date: <01/15/2018>
-- Description:	Get GetDepartment Logging history
-- [dbo].[GetDepartmentLogging] '','Administrator','00VE7GBEKX'
CREATE PROCEDURE GetDepartmentLogging
(
@fromDateTime AS SMALLDATETIME =NULL,
@toDateTime AS SMALLDATETIME = NULL
)
AS
BEGIN
	SET NOCOUNT ON
		SELECT AP.Department AS WCDept
			  ,COUNT(1) AS Employee
			  ,10 AS ActVSStd
		FROM Aspnet_Profile AP
			 INNER JOIN DEPT_LGT DL ON AP.UserId = DL.inUserId 
		WHERE Department <> '' AND OriginalDateIn > @FromDateTime AND OriginalDateOut < @ToDateTime
		GROUP BY Department 
	UNION 
		SELECT D.Dept_Name AS WCDept
			  ,COUNT(1) AS Employee
			  ,10 AS ActVSStd
		FROM Aspnet_Profile AP 
		     INNER JOIN DEPTS D ON AP.Dept_Id = D.Dept_Id
			 INNER JOIN DEPT_LGT DL ON AP.UserId = DL.inUserId 
		WHERE AP.Dept_Id <> '' AND OriginalDateIn > @FromDateTime AND OriginalDateOut < @ToDateTime
		GROUP BY D.Dept_Name
END
