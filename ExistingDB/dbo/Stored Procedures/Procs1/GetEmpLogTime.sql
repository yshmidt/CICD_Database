-- =============================================
-- Author:		Nitesh B	
-- Create date: 05/08/2018
-- Description: Get Emp Log Time
-- =============================================
CREATE PROCEDURE [dbo].[GetEmpLogTime]
(
@userId UNIQUEIDENTIFIER=NULL,
@fromDateTime AS SMALLDATETIME =NULL,
@toDateTime AS SMALLDATETIME = NULL
)
AS
BEGIN
	SET NOCOUNT ON
		SELECT DISTINCT FORMAT(DATE_IN,'MM/dd/yyyy') AS ShiftDate
					   ,SUM(DATEDIFF(MINUTE,DATE_IN,DATE_OUT)) AS TotalTime 
		FROM DEPT_LGT DL  INNER JOIN aspnet_Profile AP ON  DL.inUserId = AP.UserId 
	    WHERE DL.InUserId = @userId 
			  AND (FORMAT(DATE_IN,'MM/dd/yyyy') = FORMAT(@fromDateTime,'MM/dd/yyyy') OR DATE_IN >= @fromDateTime)
		      AND (FORMAT(DATE_OUT,'MM/dd/yyyy') = FORMAT(@toDateTime,'MM/dd/yyyy')  OR DATE_OUT <= @toDateTime) 
		      AND DL.UDeleted = 0
		GROUP BY FORMAT(DATE_IN,'MM/dd/yyyy')
        ORDER BY ShiftDate
END
