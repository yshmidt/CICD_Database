CREATE PROC [dbo].[Dept_qty4WonoView] @lcWono AS char(10) = ''
AS
SELECT Dept_qty.*, Dept_Name,0.00000 AS SetupTimem,0.00000 AS Runtimem, Depts.WcNote, Dept_qty.Capctyneed/3600 AS Process_Time_H
	FROM Dept_qty, Depts
	WHERE Dept_qty.Dept_id = Depts.Dept_id
	AND Wono = @lcWono
	ORDER BY Number