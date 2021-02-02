﻿

CREATE PROCEDURE  [dbo].[GetWORoutingDetails] 
	@WorkOrderNumber NVARCHAR(10)
AS
BEGIN
	SELECT WOENTRY.WONO, 
	QUOTDEPT.DEPT_ID AS WorkCenter, 
	Dept_qty.CURR_QTY AS Quantity,
	Dept_qty.SerialStrt AS SNTracking, 
	DEPTS.INOUTSVS AS OutSourced 
		FROM Quotdept 
JOIN WOENTRY ON QUOTDEPT.Uniq_key=WOENTRY.UNIQ_KEY 
JOIN Dept_qty ON Dept_qty.WONO=WOENTRY.WONO and QUOTDEPT.UNIQNUMBER=DEPT_QTY.DEPTKEY
JOIN DEPTS ON DEPTS.DEPT_ID=QUOTDEPT.DEPT_ID
WHERE WOENTRY.WONO=@WorkOrderNumber ORDER BY Dept_qty.NUMBER
END