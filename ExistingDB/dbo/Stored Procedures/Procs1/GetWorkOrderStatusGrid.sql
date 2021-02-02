-- =============================================
-- Author:SachinB
-- Create date: 08/19/2016
-- Description:	this procedure will be called from the SF module and Pull quantity available to each center
-- 02/06/2017 Sachin B add coulmn DeptID, DeptKey and Number column
-- 23/08/2017 Sachin B add coulmn INOUTSVS
-- 05/27/2019 Sachin B add coulmn IsOptional  
-- GetWorkOrderStatusGrid '0000000487'
-- =============================================

CREATE PROCEDURE GetWorkOrderStatusGrid 
@Wono CHAR(10)
AS
SET NOCOUNT ON; 

SELECT 
d.DEPT_ID as DeptID,
d.DEPTKEY as DeptKey,
d.NUMBER as Number,
d.DEPT_ID + ' - '+ dep.DEPT_NAME AS DepartmentName,
-- 23/08/2017 Sachin B add coulmn INOUTSVS
dep.INOUTSVS,
d.CURR_QTY AS Quantity,
d.IsOptional AS OPT
FROM WOENTRY w
INNER JOIN INVENTOR i ON i.UNIQ_KEY = w.UNIQ_KEY
INNER JOIN DEPT_QTY d ON d.WONO = w.WONO
INNER JOIN DEPTS dep ON dep.DEPT_ID =d.DEPT_ID
WHERE w.WONO =@Wono ORDER BY d.NUMBER
