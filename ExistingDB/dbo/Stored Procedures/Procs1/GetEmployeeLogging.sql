-- =============================================
-- Author:		Nitesh B	
-- Create date: <01/15/2018>
-- Description:	Get Employee Logging history
-- Modifications 
   -- 05/28/2018 Nitesh B : Added new columns in Select list
   -- 05/28/2018 Nitesh B : Changed where condition
-- [dbo].[GetEmployeeLogging] '','Administrator','00VE7GBEKX',GETDATE(),GETDATE()
CREATE PROCEDURE [dbo].[GetEmployeeLogging]
(
@deptId CHAR(4)=NULL,
@fromDateTime AS SMALLDATETIME =NULL,
@toDateTime AS SMALLDATETIME = NULL
)
AS
BEGIN
	SET NOCOUNT ON
		SELECT DISTINCT ROW_NUMBER() OVER(ORDER BY UserId ASC) AS RowNumber
		               ,Userid
			 		   ,FirstName
					   ,LastName
					   ,Title
					   ,HRType AS HRExempt
					   -- 05/28/2018 Nitesh B : Added new columns in Select list
					   ,0.0 AS RT
					   ,0.0 AS OT
					   ,0.0 AS BT
					   ,0.0 AS SIC
					   ,0.0 AS LOA
					   ,0.0 AS PT
					   ,0.0 AS TR
					   ,0.0 AS VAC
					   ,ISNULL(CAST((CAST(SUM(DATEDIFF(MINUTE,DATE_IN,DATE_OUT)) AS FLOAT)/60)/COUNT(1) AS NUMERIC(10,2)),0) AS Total  
		FROM aspnet_Profile AP LEFT JOIN DEPT_LGT DL ON AP.UserId = DL.inUserId  --AP.dept_id = DL.dept_id
							   LEFT JOIN WRKSHIFT WS ON AP.SHIFT_NO = WS.SHIFT_NO 
		WHERE (@deptId IS NULL OR @deptId = '' OR AP.dept_id = @deptId OR AP.Department = @deptId)  -- 05/28/2018 Nitesh B : Changed where condition
		       AND FORMAT(DATE_IN,'MM/dd/yyyy') >= FORMAT(@fromDateTime,'MM/dd/yyyy') 
			   AND FORMAT(DATE_OUT,'MM/dd/yyyy') <= FORMAT(@toDateTime,'MM/dd/yyyy')
			   AND WONO <> ''
		GROUP BY Userid
				,FirstName
				,LastName
				,title
				,HRType
				,ISNULL(WS.TOT_MIN,0)
END