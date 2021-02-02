CREATE PROC [dbo].[Qainsp4WonoDept_idView] @lcWono AS char(10) = ' ', @lcDept_id char(4) = ' '
AS
SELECT Wono, Dept_id, Lotsize, Inspqty, Failqty, PassQty, Inspby, Date, Qaseqmain
	FROM Qainsp 
	WHERE Wono = @lcWono
	AND Dept_id = @lcDept_id
	ORDER BY Date




