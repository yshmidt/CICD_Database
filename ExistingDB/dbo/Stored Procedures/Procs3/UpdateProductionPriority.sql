
-- =============================================
-- Author:		Mahesh B.	
-- Create date: 03/13/2019 
-- Description:	Update the all the work centers from production control 
-- =============================================

CREATE PROCEDURE [dbo].[UpdateProductionPriority]
(
@p_wcPriority dbo.WorkCenterPriorityType READONLY
)
AS
BEGIN

SET NOCOUNT ON;	

IF OBJECT_ID(N'tempdb..#WOCenterTable') IS NOT NULL
DROP TABLE #WOCenterTable;

;WITH FirstWOCenter 
AS
(
 SELECT UNIQUEREC,
        WONO,
	    Dept_id,
		Curr_qty,
	    ROW_NUMBER() OVER (PARTITION BY WONO  ORDER BY NUMBER ) AS rownum   
        FROM DEPT_QTY  WHERE Curr_qty > 0)

	    SELECT dq.UNIQUEREC,
		       fwoc.WONO,
			   dq.Dept_id, 
			   fwoc.priority INTO #WOCenterTable 
	           FROM FirstWOCenter dq JOIN  @p_wcPriority fwoc ON dq.WONO = fwoc.woNo  WHERE rownum = 1 ;  
			
         UPDATE dept SET dept.DEPT_PRI = wcType.priority
		        FROM DEPT_QTY dept 
                JOIN #WOCenterTable wcType ON dept.WONO=wcType.WONO 

END