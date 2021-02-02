CREATE PROC [dbo].[Dept_qty4WonoDispView] @lcWono AS char(10) = ''
AS
SELECT Wono, Dept_qty.Dept_id, Dept_name, Curr_qty, Dept_qty.Number, Deptkey, SerialStrt 
	FROM Dept_qty, Depts
	WHERE Dept_qty.Dept_id = Depts.Dept_id
	AND Wono = @lcWono
	ORDER BY Dept_qty.Number