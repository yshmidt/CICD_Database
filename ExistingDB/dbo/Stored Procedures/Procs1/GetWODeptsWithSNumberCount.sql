
-- =============================================
-- Author:		Shripati U 	
-- Create date: <12/21/2017>
-- Description: Get work center details with serial number count of respective dept(center)
-- =============================================

CREATE PROCEDURE [dbo].[GetWODeptsWithSNumberCount]  
@woNO VARCHAR(10)
AS
BEGIN
	SET NOCOUNT ON;
    -- Insert statements for procedure here
 	
	SELECT dq.DEPT_ID AS ID, 
	       dt.DEPT_NAME AS Name, 
		   dq.CURR_QTY AS CurrentQty, 
		   dq.UniqueRec,
		   CAST(0 AS decimal) ReducedQty,
		   dq.Number,
		   dq.DEPTKEY,
	       COUNT(iser.SERIALNO) AS SNCount  
		   FROM Dept_Qty dq LEFT JOIN  InvtSer iser  ON dq.DEPTKEY = iser.ID_VALUE  AND iser.WONO = @woNO
		   INNER JOIN Depts dt ON  dq.DEPT_ID = dt.Dept_id 
	       WHERE  dq.WONO = @woNO AND dq.DEPT_ID NOT IN ('FGI','SCRP') AND dq.CURR_QTY > 0  
		   group by dq.DEPT_ID, DEPT_NAME,CURR_QTY,UniqueRec,dq.Number, dq.DEPTKEY
		   order by dq.Number
END