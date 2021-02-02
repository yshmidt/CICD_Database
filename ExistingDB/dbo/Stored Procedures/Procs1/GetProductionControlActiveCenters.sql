
-- =============================================
-- Author:		Mahesh B	
-- Create date: 09/10/2017 
-- Description:	Get the all active work centers for work orders
--  06/10/2019 Mahesh B : Added REPLACE Stat. to replace " "  to "_" for Dept_id 
--  10/01/2020 Sachin B : Added Left join with the WOENTRY table to get Dept_id having only Open WO 
-- =============================================

CREATE PROCEDURE [dbo].[GetProductionControlActiveCenters]
	-- Add the parameters for the stored procedure here
AS	
BEGIN
 SET NOCOUNT ON;
  --  06/10/2019 Mahesh B : Added REPLACE Stat. to replace " "  to "_" for Dept_id 
  --  10/01/2020 Sachin B : Added Left join with the WOENTRY table to get Dept_id having only Open WO 
    SELECT DISTINCT REPLACE(REPLACE(RTRIM(LTRIM(D.Dept_id)),'-','_'),' ','_') AS Dept_id,D.NUMBER 
	                    FROM DEPTS D 
						INNER JOIN DEPT_QTY dq ON d.DEPT_ID=dq.DEPT_ID 
						LEFT JOIN WOENTRY  ON WOENTRY.WONO = dq.wono
						WHERE (dq.CURR_QTY > 0 AND  dq.CURR_QTY IS NOT NULL) AND WOENTRY.OPENCLOS NOT IN ('Closed','Cancel')
						ORDER BY D.NUMBER
END

