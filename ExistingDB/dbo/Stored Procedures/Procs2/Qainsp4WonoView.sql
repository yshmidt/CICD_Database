CREATE PROC [dbo].[Qainsp4WonoView] @lcWono AS char(10) = ' '
AS
	SELECT DISTINCT Depts.Dept_name, Qainsp.Dept_id, Number 
		FROM Qainsp, Depts 
		WHERE Depts.Dept_id=Qainsp.Dept_id
		AND Wono = @lcWono 
		ORDER BY Number





