-- =============================================
-- Author: Khandu N	
-- Create date: <07/22/16>
-- Description:	Update work center priority 
-- =============================================

CREATE PROCEDURE [dbo].[updateWCPriority] 
	@p_wcPriority dbo.WorkCenterPriorityType READONLY
		
AS
BEGIN
--Create user defined table type and update priority into DEPT_QTY table
UPDATE dept SET dept.DEPT_PRI = wcType.priority FROM DEPT_QTY dept 
JOIN @p_wcPriority wcType ON dept.UNIQUEREC = wcType.uniqKey AND dept.DEPT_ID = wcType.categoryId

END